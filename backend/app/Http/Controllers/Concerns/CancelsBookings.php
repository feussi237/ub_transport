<?php

namespace App\Http\Controllers\Concerns;

use App\Models\Booking;
use App\Models\TripSeat;
use Illuminate\Support\Facades\DB;

trait CancelsBookings
{
    /** Marks a booking cancelled and frees its seat back up, in one transaction. */
    protected function releaseBooking(Booking $booking, ?string $reason): void
    {
        DB::transaction(function () use ($booking, $reason) {
            $booking->update([
                'status' => Booking::STATUS_CANCELLED,
                'cancellation_reason' => $reason,
            ]);

            $booking->tripSeat->update(['status' => TripSeat::STATUS_AVAILABLE, 'locked_until' => null]);
        });
    }
}
