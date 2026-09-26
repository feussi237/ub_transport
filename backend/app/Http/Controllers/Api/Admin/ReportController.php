<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Agency;
use App\Models\Booking;
use App\Models\Payment;
use App\Models\Trip;
use App\Models\User;

class ReportController extends Controller
{
    public function index()
    {
        $revenueByMonth = Payment::where('status', Payment::STATUS_SUCCESS)
            ->where('paid_at', '>=', now()->subMonths(5)->startOfMonth())
            ->get(['amount', 'paid_at'])
            ->groupBy(fn ($payment) => $payment->paid_at->format('Y-m'))
            ->map(fn ($group, $month) => ['month' => $month, 'total' => (float) $group->sum('amount')])
            ->sortBy('month')
            ->values();

        $topAgencies = Agency::query()
            ->select('agencies.id', 'agencies.name')
            ->selectRaw('COUNT(bookings.id) as bookings_count')
            ->join('trips', 'trips.agency_id', '=', 'agencies.id')
            ->leftJoin('bookings', 'bookings.trip_id', '=', 'trips.id')
            ->groupBy('agencies.id', 'agencies.name')
            ->orderByDesc('bookings_count')
            ->limit(5)
            ->get();

        return response()->json([
            'agencies_total' => Agency::count(),
            'agencies_verified' => Agency::where('status', Agency::STATUS_VERIFIED)->count(),
            'agencies_pending' => Agency::where('status', Agency::STATUS_PENDING)->count(),
            'users_total' => User::count(),
            'passengers_total' => User::whereHas('role', fn ($q) => $q->where('name', 'passenger'))->count(),
            'trips_total' => Trip::count(),
            'bookings_total' => Booking::count(),
            'bookings_confirmed' => Booking::where('status', Booking::STATUS_CONFIRMED)->count(),
            'bookings_cancelled' => Booking::where('status', Booking::STATUS_CANCELLED)->count(),
            'revenue_total' => (float) Payment::where('status', Payment::STATUS_SUCCESS)->sum('amount'),
            'revenue_by_month' => $revenueByMonth,
            'top_agencies' => $topAgencies,
        ]);
    }
}
