<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Agency;

class AgencyController extends Controller
{
    /**
     * Public agency profile. Exposes `contact_user_id` (the agency's first
     * staff account) so the mobile app knows who to address when a passenger
     * starts a conversation about one of the agency's trips.
     */
    public function show(Agency $agency)
    {
        $agency->loadCount('reviews')->load(['staff' => fn ($q) => $q->oldest()->limit(1)]);

        return response()->json([
            'id' => $agency->id,
            'name' => $agency->name,
            'status' => $agency->status,
            'contact_phone' => $agency->contact_phone,
            'contact_email' => $agency->contact_email,
            'reviews_count' => $agency->reviews_count,
            'contact_user_id' => $agency->staff->first()?->user_id,
        ]);
    }
}
