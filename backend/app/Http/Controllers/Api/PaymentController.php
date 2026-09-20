<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Payment;
use App\Models\Ticket;
use App\Models\TripSeat;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpKernel\Exception\HttpException;

class PaymentController extends Controller
{
    /**
     * Starts a Mobile Money payment for a pending booking.
     *
     * This creates the pending Payment row and, in production, would call out to the
     * MTN MoMo / Orange Money collection API here and return their redirect/USSD
     * prompt reference. That provider call is not wired up in this scaffold — swap
     * the TODO below for the real SDK/HTTP call, then let handleWebhook() below
     * reconcile the result instead of trusting the client.
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

        // TODO: call the MTN MoMo / Orange Money collection API with $payment->transaction_ref
        // as the external reference, then return here. Do not confirm the booking yet —
        // that happens in handleWebhook() once the provider confirms the charge.

        return response()->json($payment, 201);
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

        DB::transaction(function () use ($payment, $data) {
            $payment->update(['status' => $data['status'], 'paid_at' => now()]);

            if ($data['status'] !== 'success') {
                return;
            }

            $booking = $payment->booking;
            $booking->update(['status' => Booking::STATUS_CONFIRMED]);
            $booking->tripSeat->update(['status' => TripSeat::STATUS_BOOKED, 'locked_until' => null]);

            Ticket::create([
                'booking_id' => $booking->id,
                'qr_code' => (string) Str::uuid(),
            ]);
        });

        return response()->json(['message' => 'Payment reconciled.']);
    }

    private function authorizeOwner(Request $request, Booking $booking): void
    {
        if ($booking->user_id !== $request->user()->id) {
            throw new HttpException(403, 'This booking does not belong to you.');
        }
    }
}
