<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Trip;
use App\Models\UserNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesTransportFixtures;
use Tests\TestCase;

class TripManagementTest extends TestCase
{
    use RefreshDatabase, CreatesTransportFixtures;

    public function test_an_unverified_agency_cannot_publish_trips(): void
    {
        ['staff' => $staff, 'bus' => $bus, 'agency' => $agency] = $this->makeAgencyWithTrip();
        $agency->update(['status' => \App\Models\Agency::STATUS_PENDING]);

        $this->actingAs($staff, 'sanctum')->postJson('/api/agency/trips', [
            'bus_id' => $bus->id,
            'origin_city' => 'Douala',
            'destination_city' => 'Kribi',
            'departure_at' => now()->addDays(3)->toISOString(),
            'price' => 3000,
        ])->assertStatus(403);
    }

    public function test_delaying_a_trip_notifies_every_booked_passenger(): void
    {
        ['staff' => $staff, 'trip' => $trip, 'tripSeats' => $tripSeats] = $this->makeAgencyWithTrip();

        $passenger = $this->makePassenger();
        Booking::create([
            'trip_id' => $trip->id,
            'user_id' => $passenger->id,
            'trip_seat_id' => $tripSeats->first()->id,
            'status' => Booking::STATUS_CONFIRMED,
        ]);

        $this->actingAs($staff, 'sanctum')
            ->patchJson("/api/agency/trips/{$trip->id}", ['status' => Trip::STATUS_DELAYED])
            ->assertOk();

        $this->assertDatabaseHas('user_notifications', [
            'user_id' => $passenger->id,
            'type' => UserNotification::TYPE_DELAY,
        ]);
    }

    public function test_cancelling_a_trip_does_not_notify_already_cancelled_bookings(): void
    {
        ['staff' => $staff, 'trip' => $trip, 'tripSeats' => $tripSeats] = $this->makeAgencyWithTrip();

        $passenger = $this->makePassenger();
        Booking::create([
            'trip_id' => $trip->id,
            'user_id' => $passenger->id,
            'trip_seat_id' => $tripSeats->first()->id,
            'status' => Booking::STATUS_CANCELLED,
        ]);

        $this->actingAs($staff, 'sanctum')
            ->patchJson("/api/agency/trips/{$trip->id}", ['status' => Trip::STATUS_CANCELLED])
            ->assertOk();

        $this->assertDatabaseMissing('user_notifications', ['user_id' => $passenger->id]);
    }

    public function test_another_agencys_staff_cannot_update_a_trip_they_do_not_own(): void
    {
        ['trip' => $trip] = $this->makeAgencyWithTrip();
        ['staff' => $otherStaff] = $this->makeAgencyWithTrip();

        $this->actingAs($otherStaff, 'sanctum')
            ->patchJson("/api/agency/trips/{$trip->id}", ['status' => Trip::STATUS_DELAYED])
            ->assertStatus(403);
    }

    public function test_agency_staff_only_see_their_own_trips_in_the_dashboard_listing(): void
    {
        ['staff' => $ownStaff] = $this->makeAgencyWithTrip();
        $this->makeAgencyWithTrip();

        $data = $this->actingAs($ownStaff, 'sanctum')->getJson('/api/agency/trips')->assertOk()->json('data');

        $this->assertCount(1, $data);
    }
}
