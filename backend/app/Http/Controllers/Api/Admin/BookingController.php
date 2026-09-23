<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Concerns\CancelsBookings;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Booking;
use Illuminate\Http\Request;

class BookingController extends Controller
{
    use CancelsBookings;

    public function index(Request $request)
    {
        $query = Booking::with(['trip.agency', 'tripSeat.seat', 'user:id,name,phone', 'ticket', 'payments']);

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('agency_id')) {
            $query->whereHas('trip', fn ($q) => $q->where('agency_id', $request->integer('agency_id')));
        }

        return $query->latest()->paginate(30);
    }

    /** Admin-forced cancellation — a dispute, fraud, or a passenger who can't be reached any other way. */
    public function suspend(Request $request, Booking $booking)
    {
        if ($booking->status === Booking::STATUS_CANCELLED) {
            return response()->json(['message' => 'Booking already cancelled.'], 409);
        }

        $data = $request->validate(['reason' => ['required', 'string']]);

        $this->releaseBooking($booking, $data['reason']);

        AuditLog::record($request->user(), 'booking.suspended', $booking, $data['reason']);

        return $booking->fresh(['trip', 'tripSeat.seat']);
    }
}
