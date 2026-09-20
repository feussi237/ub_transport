<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ResolvesAgency;
use App\Http\Controllers\Controller;
use App\Models\Message;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    use ResolvesAgency;

    /** Conversation between the current user and another user, optionally scoped to a trip. */
    public function index(Request $request)
    {
        $data = $request->validate([
            'with' => ['required', 'exists:users,id'],
            'trip_id' => ['nullable', 'exists:trips,id'],
        ]);

        $userId = $request->user()->id;

        $messages = Message::where(function ($q) use ($userId, $data) {
            $q->where('sender_id', $userId)->where('receiver_id', $data['with']);
        })->orWhere(function ($q) use ($userId, $data) {
            $q->where('sender_id', $data['with'])->where('receiver_id', $userId);
        })
            ->when($data['trip_id'] ?? null, fn ($q, $tripId) => $q->where('trip_id', $tripId))
            ->orderBy('created_at')
            ->get();

        // Reading the thread marks everything addressed to me as read.
        Message::where('sender_id', $data['with'])->where('receiver_id', $userId)->whereNull('read_at')->update(['read_at' => now()]);

        return $messages;
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'receiver_id' => ['required', 'exists:users,id'],
            'trip_id' => ['nullable', 'exists:trips,id'],
            'body' => ['required', 'string', 'max:2000'],
        ]);

        $message = Message::create([...$data, 'sender_id' => $request->user()->id]);

        return response()->json($message, 201);
    }

    /**
     * The agency's inbox: one row per passenger who has exchanged messages
     * with any of the agency's staff, most recent message first.
     */
    public function agencyConversations(Request $request)
    {
        $agency = $this->currentAgency($request);
        $staffIds = $agency->staff()->pluck('user_id');

        $partnerIds = Message::where(function ($q) use ($staffIds) {
            $q->whereIn('sender_id', $staffIds);
        })->orWhere(function ($q) use ($staffIds) {
            $q->whereIn('receiver_id', $staffIds);
        })
            ->get(['sender_id', 'receiver_id'])
            ->flatMap(fn ($m) => [$m->sender_id, $m->receiver_id])
            ->unique()
            ->reject(fn ($id) => $staffIds->contains($id))
            ->values();

        return $partnerIds->map(function ($passengerId) use ($staffIds) {
            $last = Message::where(function ($q) use ($staffIds, $passengerId) {
                $q->whereIn('sender_id', $staffIds)->where('receiver_id', $passengerId);
            })->orWhere(function ($q) use ($staffIds, $passengerId) {
                $q->where('sender_id', $passengerId)->whereIn('receiver_id', $staffIds);
            })->latest('created_at')->with(['sender:id,name', 'receiver:id,name'])->first();

            $unread = Message::where('sender_id', $passengerId)->whereIn('receiver_id', $staffIds)->whereNull('read_at')->count();

            return [
                'passenger_id' => $passengerId,
                'passenger_name' => $last?->sender_id === $passengerId ? $last?->sender?->name : $last?->receiver?->name,
                'last_message' => $last?->body,
                'last_message_at' => $last?->created_at,
                'unread_count' => $unread,
            ];
        })->sortByDesc('last_message_at')->values();
    }
}
