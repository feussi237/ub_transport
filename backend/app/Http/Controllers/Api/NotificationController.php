<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserNotification;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\HttpException;

class NotificationController extends Controller
{
    /** Booking confirmations, delay/cancellation alerts and departure reminders for the signed-in user. */
    public function index(Request $request)
    {
        return $request->user()->notifications()->latest('sent_at')->paginate(20);
    }

    public function markRead(Request $request, UserNotification $notification)
    {
        $this->authorizeOwner($request, $notification);

        $notification->update(['is_read' => true]);

        return $notification;
    }

    public function markAllRead(Request $request)
    {
        $request->user()->notifications()->where('is_read', false)->update(['is_read' => true]);

        return response()->json(['message' => 'All notifications marked as read.']);
    }

    private function authorizeOwner(Request $request, UserNotification $notification): void
    {
        if ($notification->user_id !== $request->user()->id) {
            throw new HttpException(403, 'This notification does not belong to you.');
        }
    }
}
