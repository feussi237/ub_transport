<?php

namespace Tests\Feature;

use App\Models\UserNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesTransportFixtures;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase, CreatesTransportFixtures;

    public function test_a_user_only_sees_their_own_notifications(): void
    {
        $me = $this->makePassenger();
        $someoneElse = $this->makePassenger();

        UserNotification::create([
            'user_id' => $me->id, 'type' => 'booking', 'channel' => 'push',
            'title' => 'Mine', 'body' => 'For me', 'sent_at' => now(),
        ]);
        UserNotification::create([
            'user_id' => $someoneElse->id, 'type' => 'booking', 'channel' => 'push',
            'title' => 'Not mine', 'body' => 'Not for me', 'sent_at' => now(),
        ]);

        $data = $this->actingAs($me, 'sanctum')->getJson('/api/notifications')->assertOk()->json('data');

        $this->assertCount(1, $data);
        $this->assertSame('Mine', $data[0]['title']);
    }

    public function test_marking_a_notification_read_is_owner_restricted(): void
    {
        $me = $this->makePassenger();
        $stranger = $this->makePassenger();

        $notification = UserNotification::create([
            'user_id' => $me->id, 'type' => 'reminder', 'channel' => 'push',
            'title' => 'Reminder', 'body' => 'Départ demain', 'sent_at' => now(),
        ]);

        $this->actingAs($stranger, 'sanctum')
            ->postJson("/api/notifications/{$notification->id}/read")
            ->assertStatus(403);

        $this->actingAs($me, 'sanctum')
            ->postJson("/api/notifications/{$notification->id}/read")
            ->assertOk();

        $this->assertDatabaseHas('user_notifications', ['id' => $notification->id, 'is_read' => true]);
    }

    public function test_mark_all_read(): void
    {
        $me = $this->makePassenger();
        UserNotification::create(['user_id' => $me->id, 'type' => 'booking', 'channel' => 'push', 'title' => 'A', 'body' => 'A', 'sent_at' => now()]);
        UserNotification::create(['user_id' => $me->id, 'type' => 'booking', 'channel' => 'push', 'title' => 'B', 'body' => 'B', 'sent_at' => now()]);

        $this->actingAs($me, 'sanctum')->postJson('/api/notifications/read-all')->assertOk();

        $this->assertDatabaseCount('user_notifications', 2);
        $this->assertSame(0, UserNotification::where('is_read', false)->count());
    }
}
