<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();

        if (! $user || $user->is_locked) {
            return response()->json(['message' => 'Account locked or unauthenticated.'], 403);
        }

        if (! in_array($user->role?->name, $roles, true)) {
            return response()->json(['message' => 'You do not have access to this resource.'], 403);
        }

        return $next($request);
    }
}
