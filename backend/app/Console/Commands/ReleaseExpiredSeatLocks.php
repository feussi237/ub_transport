<?php

namespace App\Console\Commands;

use App\Models\Booking;
use App\Models\TripSeat;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class ReleaseExpiredSeatLocks extends Command
{
    protected $signature = 'bookings:release-expired-locks';

    protected $description = 'Releases seats whose payment lock expired without a completed payment, and cancels their pending booking.';

    public function handle(): int
    {
        $expired = TripSeat::where('status', TripSeat::STATUS_LOCKED)
            ->where('locked_until', '<', now())
            ->get();

        foreach ($expired as $tripSeat) {
            DB::transaction(function () use ($tripSeat) {
                $tripSeat->update(['status' => TripSeat::STATUS_AVAILABLE, 'locked_until' => null]);

                Booking::where('trip_seat_id', $tripSeat->id)
                    ->where('status', Booking::STATUS_PENDING)
                    ->update(['status' => Booking::STATUS_CANCELLED, 'cancellation_reason' => 'Payment window expired.']);
            });
        }

        $this->info("Released {$expired->count()} expired seat lock(s).");

        return self::SUCCESS;
    }
}
