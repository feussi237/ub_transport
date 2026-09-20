<?php

namespace Tests\Feature;

use App\Models\TripSeat;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesTransportFixtures;
use Tests\TestCase;

class BookingFlowTest extends TestCase
{
    use RefreshDatabase, CreatesTransportFixtures;

    public function test_a_guest_can_search_trips_without_authentication(): void
    {
        $this->makeAgencyWithTrip();

        $this->getJson('/api/trips?origin_city=Douala&destination_city=Yaoundé')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_a_passenger_can_book_pay_and_receive_a_ticket(): void
    {
        ['trip' => $trip, 'tripSeats' => $tripSeats] = $this->makeAgencyWithTrip();
        $passenger = $this->makePassenger(['password' => 'password123']);
        $seat = $tripSeats->first();

        // 1. Book -> seat gets locked, booking is pending.
        $booking = $this->actingAs($passenger, 'sanctum')
            ->postJson('/api/bookings', ['trip_seat_id' => $seat->id])
            ->assertCreated()
            ->json();

        $this->assertSame(TripSeat::STATUS_LOCKED, TripSeat::find($seat->id)->status);

        // 2. Initiate payment.
        $payment = $this->actingAs($passenger, 'sanctum')
            ->postJson("/api/bookings/{$booking['id']}/pay", ['provider' => 'mtn_momo'])
            ->assertCreated()
            ->json();

        // 3. Provider confirms via webhook -> booking confirmed, seat booked, ticket issued.
        $this->postJson('/api/payments/webhook', [
            'transaction_ref' => $payment['transaction_ref'],
            'status' => 'success',
        ])->assertOk();

        $this->assertDatabaseHas('bookings', ['id' => $booking['id'], 'status' => 'confirmed']);
        $this->assertDatabaseHas('tickets', ['booking_id' => $booking['id']]);
        $this->assertSame(TripSeat::STATUS_BOOKED, TripSeat::find($seat->id)->status);
    }

    public function test_a_second_passenger_cannot_book_an_already_locked_seat(): void
    {
        ['tripSeats' => $tripSeats] = $this->makeAgencyWithTrip();
        $seat = $tripSeats->first();

        $first = $this->makePassenger();
        $second = $this->makePassenger();

        $this->actingAs($first, 'sanctum')->postJson('/api/bookings', ['trip_seat_id' => $seat->id])->assertCreated();

        $this->actingAs($second, 'sanctum')->postJson('/api/bookings', ['trip_seat_id' => $seat->id])
            ->assertStatus(409);
    }

    public function test_a_passenger_can_only_cancel_their_own_booking(): void
    {
        ['tripSeats' => $tripSeats] = $this->makeAgencyWithTrip();
        $seat = $tripSeats->first();

        $owner = $this->makePassenger();
        $stranger = $this->makePassenger();

        $booking = $this->actingAs($owner, 'sanctum')
            ->postJson('/api/bookings', ['trip_seat_id' => $seat->id])
            ->json();

        $this->actingAs($stranger, 'sanctum')
            ->postJson("/api/bookings/{$booking['id']}/cancel")
            ->assertStatus(403);

        $this->actingAs($owner, 'sanctum')
            ->postJson("/api/bookings/{$booking['id']}/cancel")
            ->assertOk();
    }

    public function test_agency_staff_can_list_bookings_made_on_their_own_trips_only(): void
    {
        ['staff' => $ownStaff, 'tripSeats' => $ownSeats] = $this->makeAgencyWithTrip();
        ['tripSeats' => $otherSeats] = $this->makeAgencyWithTrip();

        $passenger = $this->makePassenger();
        $this->actingAs($passenger, 'sanctum')->postJson('/api/bookings', ['trip_seat_id' => $ownSeats->first()->id])->assertCreated();
        $this->actingAs($passenger, 'sanctum')->postJson('/api/bookings', ['trip_seat_id' => $otherSeats->first()->id])->assertCreated();

        $data = $this->actingAs($ownStaff, 'sanctum')->getJson('/api/agency/bookings')->assertOk()->json('data');

        $this->assertCount(1, $data);
    }
}
