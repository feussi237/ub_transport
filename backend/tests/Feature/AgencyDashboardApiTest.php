<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Payment;
use App\Models\Review;
use App\Models\Trip;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesTransportFixtures;
use Tests\TestCase;

class AgencyDashboardApiTest extends TestCase
{
    use RefreshDatabase, CreatesTransportFixtures;

    public function test_agency_staff_can_update_their_own_agency_profile(): void
    {
        ['staff' => $staff, 'agency' => $agency] = $this->makeAgencyWithTrip();

        $this->actingAs($staff, 'sanctum')
            ->patchJson('/api/agency/profile', ['contact_phone' => '+237611112222'])
            ->assertOk()
            ->assertJsonFragment(['contact_phone' => '+237611112222']);

        $this->assertSame('+237611112222', $agency->fresh()->contact_phone);
    }

    public function test_agency_staff_can_update_their_own_bus(): void
    {
        ['staff' => $staff, 'bus' => $bus] = $this->makeAgencyWithTrip();

        $this->actingAs($staff, 'sanctum')
            ->patchJson("/api/agency/buses/{$bus->id}", ['category' => 'express'])
            ->assertOk()
            ->assertJsonFragment(['category' => 'express']);
    }

    public function test_agency_staff_cannot_update_a_bus_belonging_to_another_agency(): void
    {
        ['bus' => $bus] = $this->makeAgencyWithTrip();
        ['staff' => $otherStaff] = $this->makeAgencyWithTrip();

        $this->actingAs($otherStaff, 'sanctum')
            ->patchJson("/api/agency/buses/{$bus->id}", ['category' => 'express'])
            ->assertStatus(403);
    }

    public function test_agency_stats_reflect_bookings_revenue_and_reviews(): void
    {
        ['staff' => $staff, 'agency' => $agency, 'trip' => $trip, 'tripSeats' => $tripSeats] = $this->makeAgencyWithTrip([
            'status' => Trip::STATUS_COMPLETED,
        ]);
        $passenger = $this->makePassenger();

        $booking = Booking::create([
            'trip_id' => $trip->id,
            'user_id' => $passenger->id,
            'trip_seat_id' => $tripSeats->first()->id,
            'status' => Booking::STATUS_CONFIRMED,
        ]);
        Payment::create([
            'booking_id' => $booking->id,
            'provider' => 'mtn_momo',
            'amount' => 6000,
            'status' => Payment::STATUS_SUCCESS,
            'transaction_ref' => 'ref-1',
            'paid_at' => now(),
        ]);
        Review::create([
            'agency_id' => $agency->id,
            'user_id' => $passenger->id,
            'trip_id' => $trip->id,
            'rating' => 5,
        ]);

        $stats = $this->actingAs($staff, 'sanctum')->getJson('/api/agency/stats')->assertOk()->json();

        $this->assertSame(1, $stats['bookings_confirmed']);
        $this->assertEquals(6000, $stats['revenue_total']);
        $this->assertEquals(5.0, $stats['average_rating']);
        $this->assertSame(1, $stats['reviews_count']);
    }

    public function test_agency_conversations_lists_passengers_with_unread_counts(): void
    {
        ['staff' => $staff, 'trip' => $trip] = $this->makeAgencyWithTrip();
        $passenger = $this->makePassenger(['name' => 'Chatty Passenger']);

        $this->actingAs($passenger, 'sanctum')->postJson('/api/messages', [
            'receiver_id' => $staff->id,
            'trip_id' => $trip->id,
            'body' => 'Hello agency',
        ])->assertCreated();

        $conversations = $this->actingAs($staff, 'sanctum')
            ->getJson('/api/agency/conversations')
            ->assertOk()
            ->json();

        $this->assertCount(1, $conversations);
        $this->assertSame('Chatty Passenger', $conversations[0]['passenger_name']);
        $this->assertSame(1, $conversations[0]['unread_count']);

        // Staff reads the thread -> unread count drops to zero afterwards.
        $this->actingAs($staff, 'sanctum')->getJson("/api/messages?with={$passenger->id}&trip_id={$trip->id}")->assertOk();

        $conversations = $this->actingAs($staff, 'sanctum')->getJson('/api/agency/conversations')->assertOk()->json();
        $this->assertSame(0, $conversations[0]['unread_count']);
    }
}
