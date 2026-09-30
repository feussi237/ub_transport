<?php

namespace Tests\Feature;

use App\Models\Booking;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\Concerns\CreatesTransportFixtures;
use Tests\TestCase;

class AssistantTest extends TestCase
{
    use RefreshDatabase, CreatesTransportFixtures;

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.ai.key' => null]);
    }

    public function test_asking_without_an_api_key_configured_returns_a_clear_error(): void
    {
        $passenger = $this->makePassenger();

        $this->actingAs($passenger, 'sanctum')
            ->postJson('/api/assistant/ask', ['message' => 'When is the next bus to Yaoundé?'])
            ->assertStatus(503);
    }

    public function test_a_plain_answer_with_no_tool_call_is_returned_directly(): void
    {
        config(['services.ai.key' => 'test-key']);
        $passenger = $this->makePassenger();

        Http::fake([
            '*/chat/completions' => Http::response([
                'choices' => [
                    ['message' => ['role' => 'assistant', 'content' => 'Hello! How can I help with your trip?']],
                ],
            ]),
        ]);

        $this->actingAs($passenger, 'sanctum')
            ->postJson('/api/assistant/ask', ['message' => 'Hi'])
            ->assertOk()
            ->assertJson(['reply' => 'Hello! How can I help with your trip?']);
    }

    public function test_a_tool_call_is_executed_against_the_real_database_and_fed_back(): void
    {
        config(['services.ai.key' => 'test-key']);
        ['trip' => $trip] = $this->makeAgencyWithTrip([
            'origin_city' => 'Douala',
            'destination_city' => 'Yaoundé',
        ]);
        $passenger = $this->makePassenger();

        Http::fake([
            '*/chat/completions' => Http::sequence()
                ->push([
                    'choices' => [[
                        'message' => [
                            'role' => 'assistant',
                            'tool_calls' => [[
                                'id' => 'call_1',
                                'function' => ['name' => 'search_trips', 'arguments' => json_encode(['origin_city' => 'Douala'])],
                            ]],
                        ],
                    ]],
                ])
                ->push([
                    'choices' => [
                        ['message' => ['role' => 'assistant', 'content' => 'There is one trip from Douala to Yaoundé.']],
                    ],
                ]),
        ]);

        $response = $this->actingAs($passenger, 'sanctum')
            ->postJson('/api/assistant/ask', ['message' => 'Any trips from Douala?'])
            ->assertOk()
            ->json();

        $this->assertSame('There is one trip from Douala to Yaoundé.', $response['reply']);
        $this->assertContains('search_trips', $response['tool_calls']);

        // The second request sent to the provider must carry the real trip data as a tool result.
        Http::assertSent(function ($request) use ($trip) {
            $body = $request->data();
            foreach ($body['messages'] ?? [] as $m) {
                if (($m['role'] ?? null) === 'tool' && str_contains($m['content'], (string) $trip->id)) {
                    return true;
                }
            }
            return false;
        });
    }

    public function test_get_my_bookings_tool_is_scoped_to_the_calling_passenger_only(): void
    {
        config(['services.ai.key' => 'test-key']);
        ['trip' => $trip, 'tripSeats' => $seats] = $this->makeAgencyWithTrip();

        $me = $this->makePassenger();
        $stranger = $this->makePassenger();

        Booking::create(['trip_id' => $trip->id, 'user_id' => $me->id, 'trip_seat_id' => $seats[0]->id, 'status' => 'confirmed']);
        Booking::create(['trip_id' => $trip->id, 'user_id' => $stranger->id, 'trip_seat_id' => $seats[1]->id, 'status' => 'confirmed']);

        Http::fake([
            '*/chat/completions' => Http::sequence()
                ->push([
                    'choices' => [[
                        'message' => [
                            'role' => 'assistant',
                            'tool_calls' => [[
                                'id' => 'call_1',
                                'function' => ['name' => 'get_my_bookings', 'arguments' => '{}'],
                            ]],
                        ],
                    ]],
                ])
                ->push([
                    'choices' => [['message' => ['role' => 'assistant', 'content' => 'You have 1 booking.']]],
                ]),
        ]);

        $this->actingAs($me, 'sanctum')
            ->postJson('/api/assistant/ask', ['message' => 'What are my bookings?'])
            ->assertOk();

        Http::assertSent(function ($request) {
            $body = $request->data();
            foreach ($body['messages'] ?? [] as $m) {
                if (($m['role'] ?? null) === 'tool') {
                    $payload = json_decode($m['content'], true);
                    return ($payload['count'] ?? null) === 1;
                }
            }
            return false;
        });
    }

    public function test_message_is_required(): void
    {
        config(['services.ai.key' => 'test-key']);
        $passenger = $this->makePassenger();

        $this->actingAs($passenger, 'sanctum')
            ->postJson('/api/assistant/ask', [])
            ->assertStatus(422);
    }
}
