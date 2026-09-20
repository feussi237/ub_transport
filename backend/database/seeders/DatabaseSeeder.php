<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        foreach ([Role::ADMIN, Role::AGENCY_STAFF, Role::PASSENGER] as $roleName) {
            Role::firstOrCreate(['name' => $roleName]);
        }

        $adminRole = Role::where('name', Role::ADMIN)->first();

        User::firstOrCreate(
            ['email' => 'admin@ubtransport.cm'],
            [
                'role_id' => $adminRole->id,
                'name' => 'UB Transport Admin',
                'phone' => '+237600000000',
                'password' => 'change-me-now',
                'preferred_language' => 'fr',
            ]
        );

        $this->call(DemoDataSeeder::class);
    }
}
