<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ResolvesAgency;
use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Message;
use App\Models\Payment;
use App\Models\Trip;
use Illuminate\Http\Request;

class AgencyStatsController extends Controller
{
    use ResolvesAgency;

    /** Everything the agency dashboard's overview needs in one call. */
    public function index(Request $request)
    {
        $agency = $this->currentAgency($request);
        $tripIds = Trip::where('agency_id', $agency->id)->pluck('id');

        $bookingsQuery = Booking::whereIn('trip_id', $tripIds);

        $revenue = Payment::where('status', Payment::STATUS_SUCCESS)
            ->whereHas('booking', fn ($q) => $q->whereIn('trip_id', $tripIds))
            ->sum('amount');

        $staffIds = $agency->staff()->pluck('user_id');
        $unreadMessages = Message::whereIn('receiver_id', $staffIds)->whereNull('read_at')->count();

        return response()->json([
            'trips_total' => $tripIds->count(),
            'trips_upcoming' => Trip::where('agency_id', $agency->id)
                ->where('status', Trip::STATUS_SCHEDULED)
                ->where('departure_at', '>', now())
                ->count(),
            'bookings_total' => (clone $bookingsQuery)->count(),
            'bookings_confirmed' => (clone $bookingsQuery)->where('status', Booking::STATUS_CONFIRMED)->count(),
            'revenue_total' => (float) $revenue,
            'average_rating' => round((float) $agency->reviews()->where('is_flagged', false)->avg('rating'), 1) ?: null,
            'reviews_count' => $agency->reviews()->where('is_flagged', false)->count(),
            'unread_messages_count' => $unreadMessages,
        ]);
    }
}
