<?php

namespace App\Services;

use App\Models\Agency;
use App\Models\Booking;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * Answers a passenger's question in natural language by giving an external
 * LLM (any OpenAI-compatible chat-completions API) a small set of read-only
 * "tools" it can call against the real database — trip search, the caller's
 * own bookings, and agency ratings. The model decides which tool(s) it
 * needs, this service executes them, and feeds the results back until the
 * model is ready to answer in plain text.
 *
 * Every tool is read-only and, where the data is personal (bookings), is
 * hard-scoped to the authenticated user — the model can never see or act
 * on another passenger's data, and can never write to the database.
 */
class AiAssistantService
{
    private const MAX_TOOL_ROUNDS = 4;

    public function __construct(private readonly User $user)
    {
    }

    public static function isConfigured(): bool
    {
        return filled(config('services.ai.key'));
    }

    /**
     * @param  array<int, array{role: string, content: string}>  $history  Prior turns, oldest first.
     * @return array{reply: string, tool_calls: array<int, string>} The final answer plus which tools were used (for transparency/logging).
     */
    public function ask(string $message, array $history = []): array
    {
        if (! self::isConfigured()) {
            throw new RuntimeException('AI assistant is not configured.');
        }

        $messages = [
            ['role' => 'system', 'content' => $this->systemPrompt()],
            ...array_slice($history, -10),
            ['role' => 'user', 'content' => $message],
        ];

        $toolsUsed = [];

        for ($round = 0; $round < self::MAX_TOOL_ROUNDS; $round++) {
            $response = $this->chatCompletion($messages);
            $choice = $response['choices'][0]['message'] ?? null;

            if (! $choice) {
                throw new RuntimeException('The AI provider returned an unexpected response.');
            }

            $toolCalls = $choice['tool_calls'] ?? [];

            if (empty($toolCalls)) {
                return ['reply' => trim($choice['content'] ?? ''), 'tool_calls' => $toolsUsed];
            }

            $messages[] = $choice;

            foreach ($toolCalls as $call) {
                $name = $call['function']['name'] ?? '';
                $args = json_decode($call['function']['arguments'] ?? '{}', true) ?? [];
                $toolsUsed[] = $name;

                $messages[] = [
                    'role' => 'tool',
                    'tool_call_id' => $call['id'],
                    'content' => json_encode($this->runTool($name, $args)),
                ];
            }
        }

        return ['reply' => "I wasn't able to fully answer that — could you rephrase or ask something more specific?", 'tool_calls' => $toolsUsed];
    }

    private function chatCompletion(array $messages): array
    {
        $response = Http::withToken(config('services.ai.key'))
            ->timeout(20)
            ->post(rtrim(config('services.ai.base_url'), '/').'/chat/completions', [
                'model' => config('services.ai.model'),
                'messages' => $messages,
                'tools' => $this->toolDefinitions(),
                'temperature' => 0.3,
            ]);

        if ($response->failed()) {
            Log::warning('AI assistant provider error', ['status' => $response->status(), 'body' => $response->body()]);
            throw new RuntimeException('The AI provider request failed.');
        }

        return $response->json();
    }

    private function systemPrompt(): string
    {
        return "You are the UB Transport passenger assistant for an inter-city bus booking app in Cameroon. ".
            "Answer questions about trips, prices, schedules, seat availability, the passenger's own bookings, and agency ratings ".
            "using the provided tools — never guess or invent trip times, prices, or booking details; always call a tool for anything factual. ".
            "If a tool returns no results, say so plainly rather than making something up. Keep answers short and conversational. ".
            "Prices are in FCFA. The current passenger is {$this->user->name} (user id {$this->user->id}).";
    }

    /** @return array<int, array<string, mixed>> */
    private function toolDefinitions(): array
    {
        return [
            $this->tool('search_trips', 'Search upcoming bus trips by route and/or date.', [
                'origin_city' => ['type' => 'string', 'description' => 'Departure city, e.g. Douala'],
                'destination_city' => ['type' => 'string', 'description' => 'Arrival city, e.g. Yaoundé'],
                'date' => ['type' => 'string', 'description' => 'Departure date, format YYYY-MM-DD'],
            ]),
            $this->tool('get_my_bookings', "Get the current passenger's own bookings, optionally filtered by status.", [
                'status' => ['type' => 'string', 'enum' => ['pending', 'confirmed', 'cancelled'], 'description' => 'Optional status filter'],
            ]),
            $this->tool('get_agency_info', 'Get an agency\'s rating, review count and contact details by name.', [
                'agency_name' => ['type' => 'string', 'description' => 'The agency name, or part of it'],
            ]),
        ];
    }

    private function tool(string $name, string $description, array $properties): array
    {
        return [
            'type' => 'function',
            'function' => [
                'name' => $name,
                'description' => $description,
                'parameters' => [
                    'type' => 'object',
                    'properties' => $properties,
                    'required' => [],
                ],
            ],
        ];
    }

    /** Executes exactly one of the allow-listed tools above — never arbitrary code or SQL. */
    private function runTool(string $name, array $args): mixed
    {
        return match ($name) {
            'search_trips' => $this->searchTrips($args),
            'get_my_bookings' => $this->getMyBookings($args),
            'get_agency_info' => $this->getAgencyInfo($args),
            default => ['error' => "Unknown tool: {$name}"],
        };
    }

    private function searchTrips(array $args): array
    {
        $query = Trip::query()
            ->with('agency:id,name')
            ->withCount(['tripSeats as available_seats_count' => fn ($q) => $q->where('status', 'available')])
            ->where('status', '!=', Trip::STATUS_CANCELLED)
            ->where('departure_at', '>=', now());

        if (! empty($args['origin_city'])) {
            $query->where('origin_city', 'like', '%'.$args['origin_city'].'%');
        }
        if (! empty($args['destination_city'])) {
            $query->where('destination_city', 'like', '%'.$args['destination_city'].'%');
        }
        if (! empty($args['date'])) {
            $query->whereDate('departure_at', $args['date']);
        }

        $trips = $query->orderBy('departure_at')->limit(8)->get();

        if ($trips->isEmpty()) {
            return ['count' => 0, 'trips' => []];
        }

        return [
            'count' => $trips->count(),
            'trips' => $trips->map(fn (Trip $t) => [
                'id' => $t->id,
                'agency' => $t->agency?->name,
                'origin' => $t->origin_city,
                'destination' => $t->destination_city,
                'departure_at' => $t->departure_at->toDateTimeString(),
                'price_fcfa' => (float) $t->price,
                'seats_available' => $t->available_seats_count,
                'status' => $t->status,
            ])->all(),
        ];
    }

    private function getMyBookings(array $args): array
    {
        $query = Booking::where('user_id', $this->user->id)->with(['trip.agency', 'tripSeat.seat']);

        if (! empty($args['status'])) {
            $query->where('status', $args['status']);
        }

        $bookings = $query->latest()->limit(10)->get();

        return [
            'count' => $bookings->count(),
            'bookings' => $bookings->map(fn (Booking $b) => [
                'id' => $b->id,
                'status' => $b->status,
                'agency' => $b->trip?->agency?->name,
                'route' => $b->trip ? "{$b->trip->origin_city} → {$b->trip->destination_city}" : null,
                'departure_at' => $b->trip?->departure_at?->toDateTimeString(),
                'seat' => $b->tripSeat?->seat?->seat_number,
            ])->all(),
        ];
    }

    private function getAgencyInfo(array $args): array
    {
        if (empty($args['agency_name'])) {
            return ['error' => 'agency_name is required'];
        }

        $agency = Agency::where('name', 'like', '%'.$args['agency_name'].'%')
            ->where('status', Agency::STATUS_VERIFIED)
            ->withCount('reviews')
            ->first();

        if (! $agency) {
            return ['found' => false];
        }

        return [
            'found' => true,
            'name' => $agency->name,
            'average_rating' => round((float) $agency->reviews()->avg('rating'), 1) ?: null,
            'reviews_count' => $agency->reviews_count,
            'contact_phone' => $agency->contact_phone,
        ];
    }
}
