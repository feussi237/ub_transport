<?php

namespace App\Services\Payments;

use App\Models\Payment;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * MTN Mobile Money Collections API (request-to-pay): prompts the payer's
 * phone directly for approval. Requires a subscription key, API user and
 * API key provisioned from the MTN MoMo Developer Portal
 * (https://momodeveloper.mtn.com) for the "Collections" product.
 *
 * Configure via config('services.mtn_momo'): base_url, subscription_key,
 * api_user, api_key, target_environment, currency, callback_url.
 *
 * Not verified against a live sandbox — built to match MTN's published
 * Collections API contract. Test against your own sandbox credentials
 * before relying on it.
 */
class MtnMomoGateway implements PaymentGateway
{
    private function config(string $key): ?string
    {
        return config("services.mtn_momo.{$key}");
    }

    public function requestToPay(Payment $payment, string $phoneNumber): array
    {
        $token = $this->getAccessToken();
        if ($token === null) {
            return ['status' => 'failed', 'provider_reference' => null, 'redirect_url' => null, 'message' => 'Could not authenticate with MTN MoMo.'];
        }

        $reference = $payment->transaction_ref;

        $response = Http::withToken($token)
            ->withHeaders([
                'X-Reference-Id' => $reference,
                'X-Target-Environment' => $this->config('target_environment') ?? 'sandbox',
                'Ocp-Apim-Subscription-Key' => $this->config('subscription_key'),
                'Content-Type' => 'application/json',
            ])
            ->post(rtrim($this->config('base_url'), '/').'/collection/v1_0/requesttopay', [
                'amount' => (string) round($payment->amount, 0),
                'currency' => $this->config('currency') ?? 'XAF',
                'externalId' => (string) $payment->booking_id,
                'payer' => [
                    'partyIdType' => 'MSISDN',
                    'partyId' => $this->normalizePhone($phoneNumber),
                ],
                'payerMessage' => 'UB Transport ticket payment',
                'payeeNote' => "Booking #{$payment->booking_id}",
            ]);

        // MTN returns 202 Accepted with no body — the charge is now pending
        // on the payer's phone; poll checkStatus() or wait for the callback.
        if ($response->status() === 202) {
            return ['status' => 'pending', 'provider_reference' => $reference, 'redirect_url' => null, 'message' => null];
        }

        Log::warning('MTN MoMo requestToPay failed', ['status' => $response->status(), 'body' => $response->body()]);

        return ['status' => 'failed', 'provider_reference' => $reference, 'redirect_url' => null, 'message' => 'MTN MoMo declined the request.'];
    }

    public function checkStatus(Payment $payment): array
    {
        $token = $this->getAccessToken();
        if ($token === null) {
            return ['status' => 'pending', 'message' => 'Could not reach MTN MoMo to confirm status yet.'];
        }

        $response = Http::withToken($token)
            ->withHeaders([
                'X-Target-Environment' => $this->config('target_environment') ?? 'sandbox',
                'Ocp-Apim-Subscription-Key' => $this->config('subscription_key'),
            ])
            ->get(rtrim($this->config('base_url'), '/')."/collection/v1_0/requesttopay/{$payment->provider_reference}");

        if ($response->failed()) {
            return ['status' => 'pending', 'message' => null];
        }

        $status = strtoupper($response->json('status') ?? 'PENDING');

        return match ($status) {
            'SUCCESSFUL' => ['status' => 'success', 'message' => null],
            'FAILED' => ['status' => 'failed', 'message' => $response->json('reason') ?? 'Payment failed.'],
            default => ['status' => 'pending', 'message' => null],
        };
    }

    private function getAccessToken(): ?string
    {
        $response = Http::withBasicAuth($this->config('api_user') ?? '', $this->config('api_key') ?? '')
            ->withHeaders(['Ocp-Apim-Subscription-Key' => $this->config('subscription_key')])
            ->post(rtrim($this->config('base_url'), '/').'/collection/token/');

        if ($response->failed()) {
            Log::warning('MTN MoMo auth failed', ['status' => $response->status(), 'body' => $response->body()]);

            return null;
        }

        return $response->json('access_token');
    }

    /** MTN MoMo expects the MSISDN without a leading '+'. */
    private function normalizePhone(string $phone): string
    {
        return ltrim($phone, '+');
    }
}
