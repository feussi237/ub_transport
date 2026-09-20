<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ResolvesAgency;
use App\Http\Controllers\Controller;
use App\Models\Agency;
use App\Models\Booking;
use App\Models\Trip;
use App\Models\UserNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpKernel\Exception\HttpException;

class TripController extends Controller
{
    use ResolvesAgency;

    /** Public search — no authentication required so guests can browse before signing up. */
    public function index(Request $request)
    {
        $query = Trip::query()
            ->with(['agency:id,name', 'bus:id,category,plate_number'])
            ->withCount(['tripSeats as available_seats_count' => function ($q) {
                $q->where('status', 'available');
            }])
            ->where('status', '!=', Trip::STATUS_CANCELLED);

        if ($request->filled('origin_city')) {
            $query->where('origin_city', $request->string('origin_city'));
        }

        if ($request->filled('destination_city')) {
            $query->where('destination_city', $request->string('destination_city'));
        }

        if ($request->filled('date')) {
            $query->whereDate('departure_at', $request->date('date'));
        }

        if ($request->filled('category')) {
            $query->whereHas('bus', fn ($q) => $q->where('category', $request->string('category')));
        }

        if ($request->filled('max_price')) {
            $query->where('price', '<=', $request->float('max_price'));
        }

        return $query->orderBy('departure_at')->paginate(20);
    }

    public function show(Trip $trip)
    {
        return $trip->load([
            'agency:id,name,commission_rate',
            'bus:id,category,plate_number',
            'tripSeats.seat',
        ]);
    }

    /** All of the signed-in agency staff member's own trips (any status) — used by the agency dashboard. */
    public function agencyIndex(Request $request)
    {
        $agency = $this->currentAgency($request);

        return $agency->trips()
            ->with('bus:id,category,plate_number')
            ->withCount(['tripSeats as booked_seats_count' => function ($q) {
                $q->where('status', '!=', 'available');
            }])
            ->latest('departure_at')
            ->paginate(30);
    }

    /** Agency creates a trip; seat availability rows are generated from the bus's seat map. */
    public function store(Request $request)
    {
        $agency = $this->currentAgency($request);

        if (! $agency->isVerified()) {
            throw new HttpException(403, 'Your agency must be verified by an administrator before publishing trips.');
        }

        $data = $request->validate([
            'bus_id' => ['required', 'exists:buses,id'],
            'origin_city' => ['required', 'string'],
            'destination_city' => ['required', 'string'],
            'departure_at' => ['required', 'date', 'after:now'],
            'arrival_at_estimate' => ['nullable', 'date', 'after:departure_at'],
            'price' => ['required', 'numeric', 'min:0'],
        ]);

        $bus = $agency->buses()->findOrFail($data['bus_id']);

        $trip = DB::transaction(function () use ($agency, $bus, $data) {
            $trip = $agency->trips()->create([...$data, 'bus_id' => $bus->id]);

            $trip->tripSeats()->createMany(
                $bus->seats->map(fn ($seat) => ['seat_id' => $seat->id])->all()
            );

            return $trip;
        });

        return response()->json($trip->load('tripSeats.seat'), 201);
    }

    /** Agency updates schedule/price, or flags a trip as delayed/cancelled. */
    public function update(Request $request, Trip $trip)
    {
        $this->authorizeAgencyTrip($request, $trip);

        $data = $request->validate([
            'departure_at' => ['sometimes', 'date'],
            'arrival_at_estimate' => ['sometimes', 'nullable', 'date'],
            'price' => ['sometimes', 'numeric', 'min:0'],
            'status' => ['sometimes', Rule::in([Trip::STATUS_SCHEDULED, Trip::STATUS_DELAYED, Trip::STATUS_CANCELLED, Trip::STATUS_COMPLETED])],
        ]);

        $trip->update($data);

        if (isset($data['status']) && in_array($data['status'], [Trip::STATUS_DELAYED, Trip::STATUS_CANCELLED], true)) {
            $this->notifyPassengersOfStatusChange($trip);
        }

        return $trip;
    }

    /** Pushes a delay/cancellation notification to every passenger with a non-cancelled booking on this trip. */
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
                    ? "Your trip {$trip->origin_city} → {$trip->destination_city} has been cancelled by the agency."
                    : "Your trip {$trip->origin_city} → {$trip->destination_city} has been delayed. Check the new departure time.",
                'sent_at' => now(),
            ]);
        }
    }

    private function authorizeAgencyTrip(Request $request, Trip $trip): void
    {
        if ($trip->agency_id !== $this->currentAgency($request)->id) {
            throw new HttpException(403, 'This trip does not belong to your agency.');
        }
    }
}
