<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Payment;
use App\Models\Ticket;
use App\Models\TripSeat;
use App\Services\Payments\PaymentGatewayFactory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpKernel\Exception\HttpException;

class PaymentController extends Controller
{
    /**
     * Starts a Mobile Money payment for a pending booking. Resolves to a
     * real gateway (MTN MoMo / Orange Money) or the simulation gateway
     * depending on configuration — see PaymentGatewayFactory. A push-based
     * provider leaves the payment "pending" until the payer approves on
     * their phone; the simulation gateway confirms immediately.
     */
    public function initiate(Request $request, Booking $booking)
    {
        $this->authorizeOwner($request, $booking);

        $data = $request->validate([
            'provider' => ['required', Rule::in(['mtn_momo', 'orange_money'])],
        ]);

        if ($booking->status !== Booking::STATUS_PENDING) {
            throw new HttpException(409, 'This booking is not awaiting payment.');
        }

        $payment = Payment::create([
            'booking_id' => $booking->id,
            'provider' => $data['provider'],
            'amount' => $booking->trip->price,
            'status' => Payment::STATUS_PENDING,
            'transaction_ref' => (string) Str::uuid(),
        ]);

        $gateway = PaymentGatewayFactory::for($data['provider']);
        $result = $gateway->requestToPay($payment, $request->user()->phone);

        $payment->update(['provider_reference' => $result['provider_reference'] ?? null]);

        if ($result['status'] === 'success') {
            $this->reconcile($payment, 'success');
        } elseif ($result['status'] === 'failed') {
            $payment->update(['status' => Payment::STATUS_FAILED]);
        }

        return response()->json([
            ...$payment->fresh()->toArray(),
            'redirect_url' => $result['redirect_url'] ?? null,
            'provider_message' => $result['message'] ?? null,
        ], 201);
    }

    /**
     * The client polls this after initiate() for a push/redirect-based
     * provider, since webhook delivery can't be relied on outside a public
     * production URL. Reconciles against the provider's own status check.
     */
    public function status(Request $request, Booking $booking)
    {
        $this->authorizeOwner($request, $booking);

        $payment = $booking->payments()->latest()->first();

        if (! $payment) {
            throw new HttpException(404, 'No payment found for this booking.');
        }

        if ($payment->status === Payment::STATUS_PENDING) {
            $gateway = PaymentGatewayFactory::for($payment->provider);
            $result = $gateway->checkStatus($payment);

            if (in_array($result['status'], ['success', 'failed'], true)) {
                $this->reconcile($payment, $result['status']);
            }
        }

        return $booking->fresh(['trip.agency', 'tripSeat.seat', 'ticket', 'payments']);
    }

    /**
     * Provider webhook: reconciles a payment against MTN/Orange's own confirmation
     * rather than the mobile client, and is idempotent against repeat deliveries.
     */
    public function handleWebhook(Request $request)
    {
        $data = $request->validate([
            'transaction_ref' => ['required', 'string'],
            'status' => ['required', Rule::in(['success', 'failed'])],
        ]);

        $payment = Payment::where('transaction_ref', $data['transaction_ref'])->firstOrFail();

        if ($payment->status !== Payment::STATUS_PENDING) {
            return response()->json(['message' => 'Already processed.']);
        }

        $this->reconcile($payment, $data['status']);

        return response()->json(['message' => 'Payment reconciled.']);
    }

    /** Shared by initiate() (simulation's instant result), status() (polling a real gateway), and the webhook. */
    private function reconcile(Payment $payment, string $status): void
    {
        DB::transaction(function () use ($payment, $status) {
            $payment->update(['status' => $status, 'paid_at' => $status === 'success' ? now() : null]);

            if ($status !== 'success') {
                return;
            }

            $booking = $payment->booking;

            if ($booking->status === Booking::STATUS_CONFIRMED) {
                return;
            }

            $booking->update(['status' => Booking::STATUS_CONFIRMED]);
            $booking->tripSeat->update(['status' => TripSeat::STATUS_BOOKED, 'locked_until' => null]);

            Ticket::firstOrCreate(
                ['booking_id' => $booking->id],
                ['qr_code' => (string) Str::uuid()]
            );
        });
    }

    private function authorizeOwner(Request $request, Booking $booking): void
    {
        if ($booking->user_id !== $request->user()->id) {
            throw new HttpException(403, 'This booking does not belong to you.');
        }
    }
}
