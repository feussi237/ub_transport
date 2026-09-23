<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Booking;
use App\Models\Trip;
use App\Models\UserNotification;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TripController extends Controller
{
    public function index(Request $request)
    {
        $query = Trip::with(['agency:id,name', 'bus:id,category,plate_number']);

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('agency_id')) {
            $query->where('agency_id', $request->integer('agency_id'));
        }

        return $query->latest('departure_at')->paginate(30);
    }

    /** Admin override — same effect as the agency's own trip update, but usable on any agency's trip. */
    public function update(Request $request, Trip $trip)
    {
        $data = $request->validate([
            'status' => ['sometimes', Rule::in(['scheduled', 'delayed', 'cancelled', 'completed'])],
        ]);

        $trip->update($data);

        if (isset($data['status']) && in_array($data['status'], [Trip::STATUS_DELAYED, Trip::STATUS_CANCELLED], true)) {
            $this->notifyPassengersOfStatusChange($trip);
        }

        AuditLog::record($request->user(), 'trip.updated_by_admin', $trip);

        return $trip->fresh(['agency:id,name', 'bus:id,category,plate_number']);
    }

    private function notifyPassengersOfStatusChange(Trip $trip): void
    {
        $isCancelled = $trip->status === Trip::STATUS_CANCELLED;

        $passengerIds = Booking::where('trip_id', $trip->id)
            ->where('status', '!=', Booking::STATUS_CANCELLED)
            ->pluck('user_id');

        foreach ($passengerIds as $userId) {
            UserNotification::create([
                'user_id' => $userId,
                'type' => $isCancelled ? UserNotification::TYPE_CANCELLATION : UserNotification::TYPE_DELAY,
                'channel' => UserNotification::CHANNEL_PUSH,
                'title' => $isCancelled ? 'Trip cancelled' : 'Trip delayed',
                'body' => $isCancelled
                    ? "Your trip {$trip->origin_city} → {$trip->destination_city} has been cancelled."
                    : "Your trip {$trip->origin_city} → {$trip->destination_city} has been delayed. Check the new departure time.",
                'sent_at' => now(),
            ]);
        }
    }
}
