<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\CancelsBookings;
use App\Http\Controllers\Concerns\ResolvesAgency;
use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\TripSeat;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

class BookingController extends Controller
{
    use ResolvesAgency;
    use CancelsBookings;

    private const SEAT_LOCK_MINUTES = 5;

    public function index(Request $request)
    {
        return $request->user()->bookings()
            ->with(['trip.agency', 'tripSeat.seat', 'ticket', 'payments'])
            ->latest()
            ->paginate(20);
    }

    /**
     * Locks the chosen seat for SEAT_LOCK_MINUTES while the passenger pays.
     * The row lock (lockForUpdate) inside the transaction is what stops two
     * passengers from grabbing the same seat at the same time.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'trip_seat_id' => ['required', 'exists:trip_seats,id'],
        ]);

        $booking = DB::transaction(function () use ($request, $data) {
            $tripSeat = TripSeat::where('id', $data['trip_seat_id'])->lockForUpdate()->firstOrFail();

            if ($tripSeat->status !== TripSeat::STATUS_AVAILABLE) {
                throw new HttpException(409, 'This seat is no longer available.');
            }

            $tripSeat->update([
                'status' => TripSeat::STATUS_LOCKED,
                'locked_until' => now()->addMinutes(self::SEAT_LOCK_MINUTES),
            ]);

            return Booking::create([
                'trip_id' => $tripSeat->trip_id,
                'user_id' => $request->user()->id,
                'trip_seat_id' => $tripSeat->id,
                'status' => Booking::STATUS_PENDING,
            ]);
        });

        return response()->json(
            $booking->load('trip.agency', 'tripSeat.seat')->loadMissing('trip.bus'),
            201
        );
    }

    public function show(Request $request, Booking $booking)
    {
        $this->authorizeOwner($request, $booking);

        return $booking->load('trip.agency', 'tripSeat.seat', 'ticket', 'payments');
    }

    /** Bookings across all of the signed-in agency staff member's own trips — used by the agency dashboard. */
    public function agencyBookings(Request $request)
    {
        $agency = $this->currentAgency($request);

        return Booking::whereHas('trip', fn ($q) => $q->where('agency_id', $agency->id))
            ->with(['trip', 'tripSeat.seat', 'user:id,name,phone', 'ticket', 'payments'])
            ->latest()
            ->paginate(30);
    }

    /**
     * Passenger-initiated cancellation. Refund eligibility (full refund >24h before
     * departure) is enforced here rather than trusted from the client.
     */
    public function cancel(Request $request, Booking $booking)
    {
        $this->authorizeOwner($request, $booking);

        if ($booking->status === Booking::STATUS_CANCELLED) {
            throw new HttpException(409, 'Booking already cancelled.');
        }

        $data = $request->validate(['reason' => ['nullable', 'string']]);
        $refundEligible = now()->diffInHours($booking->trip->departure_at, false) >= 24;

        $this->releaseBooking($booking, $data['reason'] ?? null);

        return response()->json([
            'booking' => $booking,
            'refund_eligible' => $refundEligible,
        ]);
    }

    private function authorizeOwner(Request $request, Booking $booking): void
    {
        if ($booking->user_id !== $request->user()->id) {
            throw new HttpException(403, 'This booking does not belong to you.');
        }
    }
}
