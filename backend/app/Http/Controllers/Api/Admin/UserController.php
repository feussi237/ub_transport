<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $query = User::with('role');

        if ($request->filled('role')) {
            $query->whereHas('role', fn ($q) => $q->where('name', $request->string('role')));
        }

        return $query->latest()->paginate(20);
    }

    public function lock(Request $request, User $user)
    {
        $data = $request->validate(['reason' => ['required', 'string']]);

        $user->update(['is_locked' => true]);
        $user->tokens()->delete();

        AuditLog::record($request->user(), 'user.locked', $user, $data['reason']);

        return $user;
    }

    public function unlock(Request $request, User $user)
    {
        $user->update(['is_locked' => false]);

        AuditLog::record($request->user(), 'user.unlocked', $user);

        return $user;
    }
}
