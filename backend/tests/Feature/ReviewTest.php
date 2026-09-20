<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Trip;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesTransportFixtures;
use Tests\TestCase;

class ReviewTest extends TestCase
{
    use RefreshDatabase, CreatesTransportFixtures;

    public function test_a_passenger_cannot_review_a_trip_they_never_completed(): void
    {
        ['agency' => $agency, 'trip' => $trip] = $this->makeAgencyWithTrip();
        $passenger = $this->makePassenger();

        $this->actingAs($passenger, 'sanctum')
            ->postJson("/api/agencies/{$agency->id}/reviews", [
                'trip_id' => $trip->id,
                'rating' => 5,
                'comment' => 'Great trip!',
            ])
            ->assertStatus(403);
    }

    public function test_a_passenger_can_review_a_completed_trip_they_booked(): void
    {
        ['agency' => $agency, 'trip' => $trip, 'tripSeats' => $tripSeats] = $this->makeAgencyWithTrip([
            'status' => Trip::STATUS_COMPLETED,
            'departure_at' => now()->subDays(2),
        ]);
        $passenger = $this->makePassenger();

        Booking::create([
            'trip_id' => $trip->id,
            'user_id' => $passenger->id,
            'trip_seat_id' => $tripSeats->first()->id,
            'status' => Booking::STATUS_CONFIRMED,
        ]);

        $this->actingAs($passenger, 'sanctum')
            ->postJson("/api/agencies/{$agency->id}/reviews", [
                'trip_id' => $trip->id,
                'rating' => 4,
                'comment' => 'Confortable, à l\'heure.',
            ])
            ->assertCreated();

        $this->assertDatabaseHas('reviews', ['agency_id' => $agency->id, 'user_id' => $passenger->id, 'rating' => 4]);
    }

    public function test_reviews_for_an_agency_are_publicly_listed(): void
    {
        ['agency' => $agency] = $this->makeAgencyWithTrip();

        $this->getJson("/api/agencies/{$agency->id}/reviews")->assertOk();
    }
}
