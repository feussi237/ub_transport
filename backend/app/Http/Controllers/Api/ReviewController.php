<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Agency;
use App\Models\Booking;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\HttpException;

class ReviewController extends Controller
{
    public function index(Agency $agency)
    {
        return $agency->reviews()->where('is_flagged', false)->with('user:id,name')->latest()->paginate(20);
    }

    /** Passenger rates an agency after a completed trip they actually booked. */
    public function store(Request $request, Agency $agency)
    {
        $data = $request->validate([
            'trip_id' => ['required', 'exists:trips,id'],
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:2000'],
        ]);

        $hasCompletedBooking = Booking::where('user_id', $request->user()->id)
            ->where('trip_id', $data['trip_id'])
            ->where('status', Booking::STATUS_CONFIRMED)
            ->whereHas('trip', fn ($q) => $q->where('agency_id', $agency->id)->where('status', 'completed'))
            ->exists();

        if (! $hasCompletedBooking) {
            throw new HttpException(403, 'You can only review a trip you completed with this agency.');
        }

        $review = $agency->reviews()->create([...$data, 'user_id' => $request->user()->id]);

        return response()->json($review, 201);
    }
}
