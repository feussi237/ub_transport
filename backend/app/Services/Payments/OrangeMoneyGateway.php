<?php

namespace App\Services\Payments;

use App\Models\Payment;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Orange Money Web Payment API: unlike MTN's direct phone prompt, this is a
 * redirect/checkout flow — the client must open the returned 'redirect_url'
 * in a browser so the payer can authorize with their Orange Money PIN, then
 * the app polls checkStatus() once the payer returns. Requires a client id/
 * secret and merchant key from the Orange Developer Center
 * (https://developer.orange.com) for the "Orange Money Web Payment" API.
 *
 * Configure via config('services.orange_money'): base_url, client_id,
 * client_secret, merchant_key, return_url, cancel_url, notif_url, currency.
 *
 * Not verified against a live sandbox — built to match Orange's published
 * Web Payment API contract, which has varied by country/version in the
 * past. Confirm the exact paths/params in your own merchant onboarding
 * docs before relying on it.
 */
class OrangeMoneyGateway implements PaymentGateway
{
    private function config(string $key): ?string
    {
        return config("services.orange_money.{$key}");
    }

    public function requestToPay(Payment $payment, string $phoneNumber): array
    {
        $token = $this->getAccessToken();
        if ($token === null) {
            return ['status' => 'failed', 'provider_reference' => null, 'redirect_url' => null, 'message' => 'Could not authenticate with Orange Money.'];
        }

        $response = Http::withToken($token)
            ->post(rtrim($this->config('base_url'), '/').'/orange-money-webpay/cm/v1/webpayment', [
                'merchant_key' => $this->config('merchant_key'),
                'currency' => $this->config('currency') ?? 'OUV',
                'order_id' => $payment->transaction_ref,
                'amount' => (int) round($payment->amount, 0),
                'return_url' => $this->config('return_url'),
                'cancel_url' => $this->config('cancel_url'),
                'notif_url' => $this->config('notif_url'),
                'lang' => 'fr',
                'reference' => "UB Transport booking #{$payment->booking_id}",
            ]);

        if ($response->failed()) {
            Log::warning('Orange Money webpayment init failed', ['status' => $response->status(), 'body' => $response->body()]);

            return ['status' => 'failed', 'provider_reference' => null, 'redirect_url' => null, 'message' => 'Orange Money declined the request.'];
        }

        $payToken = $response->json('pay_token');

        return [
            'status' => 'pending',
            'provider_reference' => $payToken,
            'redirect_url' => $response->json('payment_url'),
            'message' => null,
        ];
    }

    public function checkStatus(Payment $payment): array
    {
        $token = $this->getAccessToken();
        if ($token === null) {
            return ['status' => 'pending', 'message' => 'Could not reach Orange Money to confirm status yet.'];
        }

        $response = Http::withToken($token)
            ->post(rtrim($this->config('base_url'), '/').'/orange-money-webpay/cm/v1/transactionstatus', [
                'order_id' => $payment->transaction_ref,
                'amount' => (int) round($payment->amount, 0),
                'pay_token' => $payment->provider_reference,
            ]);

        if ($response->failed()) {
            return ['status' => 'pending', 'message' => null];
        }

        $status = strtoupper($response->json('status') ?? 'PENDING');

        return match ($status) {
            'SUCCESS' => ['status' => 'success', 'message' => null],
            'FAILED' => ['status' => 'failed', 'message' => 'Payment failed.'],
            default => ['status' => 'pending', 'message' => null],
        };
    }

    private function getAccessToken(): ?string
    {
        $response = Http::withBasicAuth($this->config('client_id') ?? '', $this->config('client_secret') ?? '')
            ->asForm()
            ->post(rtrim($this->config('base_url'), '/').'/oauth/v3/token', [
                'grant_type' => 'client_credentials',
            ]);

        if ($response->failed()) {
            Log::warning('Orange Money auth failed', ['status' => $response->status(), 'body' => $response->body()]);

            return null;
        }

        return $response->json('access_token');
    }
}
