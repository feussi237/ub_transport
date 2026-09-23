<?php

namespace Tests\Feature;

use App\Models\Booking;
use App\Models\Payment;
use App\Models\Trip;
use App\Models\TripSeat;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesTransportFixtures;
use Tests\TestCase;

class AdminManagementTest extends TestCase
{
    use RefreshDatabase, CreatesTransportFixtures;

    private function confirmedBooking(): array
    {
        ['trip' => $trip, 'tripSeats' => $tripSeats] = $this->makeAgencyWithTrip();
        $passenger = $this->makePassenger();

        $booking = Booking::create([
            'trip_id' => $trip->id,
            'user_id' => $passenger->id,
            'trip_seat_id' => $tripSeats->first()->id,
            'status' => Booking::STATUS_CONFIRMED,
        ]);
        $tripSeats->first()->update(['status' => TripSeat::STATUS_BOOKED]);

        return compact('trip', 'passenger', 'booking');
    }

    public function test_a_non_admin_cannot_access_admin_endpoints(): void
    {
        $passenger = $this->makePassenger();

        $this->actingAs($passenger, 'sanctum')->getJson('/api/admin/bookings')->assertStatus(403);
    }

    public function test_admin_can_list_and_suspend_a_booking(): void
    {
        $admin = $this->makeAdmin();
        ['booking' => $booking] = $this->confirmedBooking();

        $this->actingAs($admin, 'sanctum')->getJson('/api/admin/bookings')->assertOk()->assertJsonCount(1, 'data');

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/admin/bookings/{$booking->id}/suspend", ['reason' => 'Suspected fraud'])
            ->assertOk()
            ->assertJsonFragment(['status' => 'cancelled']);

        $this->assertSame(TripSeat::STATUS_AVAILABLE, $booking->tripSeat->fresh()->status);
    }

    public function test_admin_can_list_and_update_any_agencys_trip(): void
    {
        $admin = $this->makeAdmin();
        ['trip' => $trip] = $this->makeAgencyWithTrip();

        $this->actingAs($admin, 'sanctum')->getJson('/api/admin/trips')->assertOk()->assertJsonCount(1, 'data');

        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/admin/trips/{$trip->id}", ['status' => Trip::STATUS_CANCELLED])
            ->assertOk()
            ->assertJsonFragment(['status' => 'cancelled']);
    }

    public function test_admin_can_list_and_refund_a_payment(): void
    {
        $admin = $this->makeAdmin();
        ['booking' => $booking] = $this->confirmedBooking();

        $payment = Payment::create([
            'booking_id' => $booking->id,
            'provider' => 'mtn_momo',
            'amount' => 6000,
            'status' => Payment::STATUS_SUCCESS,
            'transaction_ref' => 'ref-admin-1',
            'paid_at' => now(),
        ]);

        $this->actingAs($admin, 'sanctum')->getJson('/api/admin/payments')->assertOk()->assertJsonCount(1, 'data');

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/admin/payments/{$payment->id}/refund", ['reason' => 'Duplicate charge'])
            ->assertOk()
            ->assertJsonFragment(['status' => 'refunded']);
    }

    public function test_admin_can_read_and_update_system_settings(): void
    {
        $admin = $this->makeAdmin();

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/admin/settings')
            ->assertOk()
            ->assertJsonFragment(['default_commission_rate' => '10']);

        $this->actingAs($admin, 'sanctum')
            ->patchJson('/api/admin/settings', ['default_commission_rate' => 12, 'maintenance_mode' => 'true'])
            ->assertOk()
            ->assertJsonFragment(['maintenance_mode' => 'true']);
    }

    public function test_admin_reports_reflect_platform_activity(): void
    {
        $admin = $this->makeAdmin();
        ['booking' => $booking] = $this->confirmedBooking();
        Payment::create([
            'booking_id' => $booking->id,
            'provider' => 'orange_money',
            'amount' => 6000,
            'status' => Payment::STATUS_SUCCESS,
            'transaction_ref' => 'ref-admin-2',
            'paid_at' => now(),
        ]);

        $report = $this->actingAs($admin, 'sanctum')->getJson('/api/admin/reports')->assertOk()->json();

        $this->assertSame(1, $report['bookings_confirmed']);
        $this->assertEquals(6000, $report['revenue_total']);
        $this->assertNotEmpty($report['top_agencies']);
    }
}
