<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Payment;
use App\Models\TripSeat;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\Concerns\CreatesTransportFixtures;
use Tests\TestCase;

class PaymentGatewayTest extends TestCase
{
    use RefreshDatabase, CreatesTransportFixtures;

    protected function setUp(): void
    {
        parent::setUp();
        // Each test sets its own simulation/provider config explicitly.
        config(['services.payment_simulation_mode' => true]);
    }

    private function bookASeat(): array
    {
        ['tripSeats' => $seats] = $this->makeAgencyWithTrip();
        $passenger = $this->makePassenger(['phone' => '+237690000011']);
        $seat = $seats->first();

        $booking = $this->actingAs($passenger, 'sanctum')
            ->postJson('/api/bookings', ['trip_seat_id' => $seat->id])
            ->assertCreated()
            ->json();

        return compact('passenger', 'seat', 'booking');
    }

    public function test_simulation_mode_confirms_the_booking_immediately_on_initiate(): void
    {
        ['passenger' => $passenger, 'booking' => $booking, 'seat' => $seat] = $this->bookASeat();

        $response = $this->actingAs($passenger, 'sanctum')
            ->postJson("/api/bookings/{$booking['id']}/pay", ['provider' => 'mtn_momo'])
            ->assertCreated()
            ->json();

        $this->assertSame('success', $response['status']);
        $this->assertDatabaseHas('bookings', ['id' => $booking['id'], 'status' => 'confirmed']);
        $this->assertDatabaseHas('tickets', ['booking_id' => $booking['id']]);
        $this->assertSame(TripSeat::STATUS_BOOKED, TripSeat::find($seat->id)->status);
    }

    public function test_real_mtn_gateway_is_used_when_simulation_is_off_and_credentials_are_set(): void
    {
        config([
            'services.payment_simulation_mode' => false,
            'services.mtn_momo.subscription_key' => 'test-sub-key',
            'services.mtn_momo.api_user' => 'test-user',
            'services.mtn_momo.api_key' => 'test-key',
        ]);

        ['passenger' => $passenger, 'booking' => $booking] = $this->bookASeat();

        Http::fake([
            '*/collection/token/' => Http::response(['access_token' => 'fake-token'], 200),
            '*/collection/v1_0/requesttopay' => Http::response(null, 202),
        ]);

        $response = $this->actingAs($passenger, 'sanctum')
            ->postJson("/api/bookings/{$booking['id']}/pay", ['provider' => 'mtn_momo'])
            ->assertCreated()
            ->json();

        // A push-based provider stays pending until the payer approves — the
        // booking must NOT be confirmed yet.
        $this->assertSame('pending', $response['status']);
        $this->assertDatabaseHas('bookings', ['id' => $booking['id'], 'status' => 'pending']);

        Http::assertSent(fn ($request) => str_contains($request->url(), 'requesttopay')
            && $request['payer']['partyId'] === '237690000011');
    }

    public function test_polling_payment_status_reconciles_once_mtn_confirms_success(): void
    {
        config([
            'services.payment_simulation_mode' => false,
            'services.mtn_momo.subscription_key' => 'test-sub-key',
            'services.mtn_momo.api_user' => 'test-user',
            'services.mtn_momo.api_key' => 'test-key',
        ]);

        ['passenger' => $passenger, 'booking' => $booking, 'seat' => $seat] = $this->bookASeat();

        Http::fake([
            '*/collection/token/' => Http::response(['access_token' => 'fake-token'], 200),
            '*/collection/v1_0/requesttopay' => Http::response(null, 202),
        ]);

        $this->actingAs($passenger, 'sanctum')
            ->postJson("/api/bookings/{$booking['id']}/pay", ['provider' => 'mtn_momo'])
            ->assertCreated();

        Http::fake([
            '*/collection/token/' => Http::response(['access_token' => 'fake-token'], 200),
            '*/collection/v1_0/requesttopay/*' => Http::response(['status' => 'SUCCESSFUL'], 200),
        ]);

        $this->actingAs($passenger, 'sanctum')
            ->getJson("/api/bookings/{$booking['id']}/payment-status")
            ->assertOk()
            ->assertJsonFragment(['status' => 'confirmed']);

        $this->assertSame(TripSeat::STATUS_BOOKED, TripSeat::find($seat->id)->status);
    }

    public function test_an_unconfigured_provider_falls_back_to_simulation_even_with_simulation_off(): void
    {
        config(['services.payment_simulation_mode' => false]);
        // mtn_momo config left blank on purpose.

        ['passenger' => $passenger, 'booking' => $booking] = $this->bookASeat();

        $response = $this->actingAs($passenger, 'sanctum')
            ->postJson("/api/bookings/{$booking['id']}/pay", ['provider' => 'mtn_momo'])
            ->assertCreated()
            ->json();

        $this->assertSame('success', $response['status']);
    }

    public function test_a_passenger_cannot_check_payment_status_for_someone_elses_booking(): void
    {
        ['booking' => $booking] = $this->bookASeat();
        $stranger = $this->makePassenger();

        $this->actingAs($stranger, 'sanctum')
            ->getJson("/api/bookings/{$booking['id']}/payment-status")
            ->assertStatus(403);
    }

    public function test_cannot_pay_for_a_booking_that_is_already_confirmed(): void
    {
        ['passenger' => $passenger, 'booking' => $booking] = $this->bookASeat();

        $this->actingAs($passenger, 'sanctum')
            ->postJson("/api/bookings/{$booking['id']}/pay", ['provider' => 'mtn_momo'])
            ->assertCreated();

        $this->actingAs($passenger, 'sanctum')
            ->postJson("/api/bookings/{$booking['id']}/pay", ['provider' => 'mtn_momo'])
            ->assertStatus(409);
    }
}
