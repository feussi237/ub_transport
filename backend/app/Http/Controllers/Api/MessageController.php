<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Message;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    /** Conversation between the current user and another user, optionally scoped to a trip. */
    public function index(Request $request)
    {
        $data = $request->validate([
            'with' => ['required', 'exists:users,id'],
            'trip_id' => ['nullable', 'exists:trips,id'],
        ]);

        $userId = $request->user()->id;

        return Message::where(function ($q) use ($userId, $data) {
            $q->where('sender_id', $userId)->where('receiver_id', $data['with']);
        })->orWhere(function ($q) use ($userId, $data) {
            $q->where('sender_id', $data['with'])->where('receiver_id', $userId);
        })
            ->when($data['trip_id'] ?? null, fn ($q, $tripId) => $q->where('trip_id', $tripId))
            ->orderBy('created_at')
            ->get();
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
}
