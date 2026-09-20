<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesTransportFixtures;
use Tests\TestCase;

class MessageTest extends TestCase
{
    use RefreshDatabase, CreatesTransportFixtures;

    public function test_a_passenger_can_message_an_agency_and_read_the_thread(): void
    {
        ['staff' => $staff, 'trip' => $trip] = $this->makeAgencyWithTrip();
        $passenger = $this->makePassenger();

        $this->actingAs($passenger, 'sanctum')->postJson('/api/messages', [
            'receiver_id' => $staff->id,
            'trip_id' => $trip->id,
            'body' => 'À quelle heure part le bus ?',
        ])->assertCreated();

        $this->actingAs($staff, 'sanctum')->postJson('/api/messages', [
            'receiver_id' => $passenger->id,
            'trip_id' => $trip->id,
            'body' => 'Départ à 8h précises.',
        ])->assertCreated();

        $thread = $this->actingAs($passenger, 'sanctum')
            ->getJson("/api/messages?with={$staff->id}&trip_id={$trip->id}")
            ->assertOk()
            ->json();

        $this->assertCount(2, $thread);
    }

    public function test_the_public_agency_endpoint_exposes_a_contact_user_for_messaging(): void
    {
        ['agency' => $agency, 'staff' => $staff] = $this->makeAgencyWithTrip();

        $this->getJson("/api/agencies/{$agency->id}")
            ->assertOk()
            ->assertJson(['contact_user_id' => $staff->id]);
    }
}
