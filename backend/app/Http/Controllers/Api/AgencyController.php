<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ResolvesAgency;
use App\Http\Controllers\Controller;
use App\Models\Agency;
use Illuminate\Http\Request;

class AgencyController extends Controller
{
    use ResolvesAgency;

    /**
     * Public agency profile. Exposes `contact_user_id` (the agency's first
     * staff account) so the mobile app knows who to address when a passenger
     * starts a conversation about one of the agency's trips.
     */
    public function show(Agency $agency)
    {
        $agency->loadCount('reviews')->load(['staff' => fn ($q) => $q->oldest()->limit(1)]);
        $averageRating = $agency->reviews()->where('is_flagged', false)->avg('rating');

        return response()->json([
            'id' => $agency->id,
            'name' => $agency->name,
            'status' => $agency->status,
            'contact_phone' => $agency->contact_phone,
            'contact_email' => $agency->contact_email,
            'reviews_count' => $agency->reviews_count,
            'average_rating' => $averageRating ? round($averageRating, 1) : null,
            'contact_user_id' => $agency->staff->first()?->user_id,
        ]);
    }

    /** Lets the signed-in agency staff member edit their own agency's contact details. */
    public function updateOwnProfile(Request $request)
    {
        $agency = $this->currentAgency($request);

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'contact_phone' => ['sometimes', 'string'],
            'contact_email' => ['sometimes', 'nullable', 'email'],
            'address' => ['sometimes', 'nullable', 'string'],
        ]);

        $agency->update($data);

        return $agency;
    }
}
