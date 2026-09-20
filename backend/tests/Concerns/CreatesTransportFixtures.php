<?php

namespace Tests\Concerns;

use App\Models\Agency;
use App\Models\AgencyStaff;
use App\Models\Bus;
use App\Models\Role;
use App\Models\Seat;
use App\Models\Trip;
use App\Models\TripSeat;
use App\Models\User;

trait CreatesTransportFixtures
{
    protected function makeRoles(): void
    {
        foreach ([Role::ADMIN, Role::AGENCY_STAFF, Role::PASSENGER] as $name) {
            Role::firstOrCreate(['name' => $name]);
        }
    }

    protected function makePassenger(array $overrides = []): User
    {
        $this->makeRoles();

        return User::factory()->create(array_merge([
            'role_id' => Role::where('name', Role::PASSENGER)->first()->id,
            'phone' => '+2376'.fake()->unique()->numerify('########'),
        ], $overrides));
    }

    protected function makeAdmin(array $overrides = []): User
    {
        $this->makeRoles();

        return User::factory()->create(array_merge([
            'role_id' => Role::where('name', Role::ADMIN)->first()->id,
            'phone' => '+2376'.fake()->unique()->numerify('########'),
        ], $overrides));
    }

    /** Verified agency with one staff user, one 10-seat VIP bus, and a scheduled trip with seats generated. */
    protected function makeAgencyWithTrip(array $tripOverrides = []): array
    {
        $this->makeRoles();

        $agency = Agency::create([
            'name' => 'Test Express',
            'registration_no' => 'REG-'.fake()->unique()->numerify('######'),
            'status' => Agency::STATUS_VERIFIED,
            'contact_phone' => '+237600000000',
            'verified_at' => now(),
        ]);

        $staff = User::factory()->create([
            'role_id' => Role::where('name', Role::AGENCY_STAFF)->first()->id,
            'phone' => '+2376'.fake()->unique()->numerify('########'),
        ]);

        AgencyStaff::create(['agency_id' => $agency->id, 'user_id' => $staff->id, 'position' => 'manager']);

        $bus = Bus::create([
            'agency_id' => $agency->id,
            'plate_number' => 'CE-'.fake()->unique()->numerify('####'),
            'category' => 'vip',
            'seat_count' => 4,
        ]);

        $seats = collect(range(1, 4))->map(fn ($n) => Seat::create([
            'bus_id' => $bus->id,
            'seat_number' => (string) $n,
            'seat_type' => 'vip',
        ]));

        $trip = Trip::create(array_merge([
            'agency_id' => $agency->id,
            'bus_id' => $bus->id,
            'origin_city' => 'Douala',
            'destination_city' => 'Yaoundé',
            'departure_at' => now()->addDay(),
            'price' => 6000,
            'status' => Trip::STATUS_SCHEDULED,
        ], $tripOverrides));

        $tripSeats = $seats->map(fn ($seat) => TripSeat::create(['trip_id' => $trip->id, 'seat_id' => $seat->id]));

        return compact('agency', 'staff', 'bus', 'trip', 'tripSeats');
    }
}
