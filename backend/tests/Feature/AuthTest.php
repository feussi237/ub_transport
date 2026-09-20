<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesTransportFixtures;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase, CreatesTransportFixtures;

    public function test_a_passenger_can_register_and_receives_a_token(): void
    {
        $this->makeRoles();

        $response = $this->postJson('/api/auth/register/passenger', [
            'name' => 'Alice Passenger',
            'email' => 'alice@example.com',
            'phone' => '+237690000001',
            'password' => 'password123',
        ]);

        $response->assertCreated()->assertJsonStructure(['user', 'token']);
        $this->assertDatabaseHas('users', ['email' => 'alice@example.com']);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        $user = $this->makePassenger(['email' => 'bob@example.com', 'password' => 'correct-password']);

        $this->postJson('/api/auth/login', [
            'email' => $user->email,
            'password' => 'wrong-password',
        ])->assertStatus(401);
    }

    public function test_a_locked_account_cannot_log_in(): void
    {
        $user = $this->makePassenger(['email' => 'carol@example.com', 'password' => 'password123', 'is_locked' => true]);

        $this->postJson('/api/auth/login', [
            'email' => $user->email,
            'password' => 'password123',
        ])->assertStatus(403);
    }

    public function test_me_endpoint_requires_authentication(): void
    {
        $this->getJson('/api/me')->assertStatus(401);
    }

    public function test_a_user_can_update_their_own_profile(): void
    {
        $user = $this->makePassenger(['name' => 'Old Name']);

        $this->actingAs($user, 'sanctum')
            ->patchJson('/api/me', ['name' => 'New Name', 'phone' => '+237699999999'])
            ->assertOk()
            ->assertJsonFragment(['name' => 'New Name', 'phone' => '+237699999999']);
    }

    public function test_a_user_cannot_take_someone_elses_email_when_updating_profile(): void
    {
        $this->makePassenger(['email' => 'taken@example.com']);
        $me = $this->makePassenger(['email' => 'me@example.com']);

        $this->actingAs($me, 'sanctum')
            ->patchJson('/api/me', ['email' => 'taken@example.com'])
            ->assertStatus(422);
    }
}
