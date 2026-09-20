<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Agency;
use App\Models\AgencyStaff;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AuthController extends Controller
{
    /** Passenger self-registration, used by the mobile app. */
    public function registerPassenger(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'phone' => ['required', 'string', 'unique:users,phone'],
            'password' => ['required', 'string', 'min:8'],
            'preferred_language' => ['sometimes', Rule::in(['fr', 'en'])],
        ]);

        $passengerRole = Role::where('name', Role::PASSENGER)->firstOrFail();

        $user = User::create([
            'role_id' => $passengerRole->id,
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'],
            'password' => $data['password'],
            'preferred_language' => $data['preferred_language'] ?? 'fr',
        ]);

        return response()->json([
            'user' => $user->load('role'),
            'token' => $user->createToken('mobile')->plainTextToken,
        ], 201);
    }

    /**
     * Agency self-registration: creates the agency (pending admin approval) plus its
     * first staff account. The agency cannot publish trips until an admin verifies it.
     */
    public function registerAgency(Request $request)
    {
        $data = $request->validate([
            'agency_name' => ['required', 'string', 'max:255'],
            'registration_no' => ['required', 'string', 'unique:agencies,registration_no'],
            'contact_phone' => ['required', 'string'],
            'contact_email' => ['nullable', 'email'],
            'address' => ['nullable', 'string'],
            'staff_name' => ['required', 'string', 'max:255'],
            'staff_email' => ['required', 'email', 'unique:users,email'],
            'staff_phone' => ['required', 'string', 'unique:users,phone'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        [$user, $agency] = DB::transaction(function () use ($data) {
            $agency = Agency::create([
                'name' => $data['agency_name'],
                'registration_no' => $data['registration_no'],
                'status' => Agency::STATUS_PENDING,
                'contact_phone' => $data['contact_phone'],
                'contact_email' => $data['contact_email'] ?? null,
                'address' => $data['address'] ?? null,
            ]);

            $agencyRole = Role::where('name', Role::AGENCY_STAFF)->firstOrFail();

            $user = User::create([
                'role_id' => $agencyRole->id,
                'name' => $data['staff_name'],
                'email' => $data['staff_email'],
                'phone' => $data['staff_phone'],
                'password' => $data['password'],
            ]);

            AgencyStaff::create([
                'agency_id' => $agency->id,
                'user_id' => $user->id,
                'position' => 'manager',
            ]);

            return [$user, $agency];
        });

        return response()->json([
            'user' => $user->load('role'),
            'agency' => $agency,
            'token' => $user->createToken('agency-portal')->plainTextToken,
            'message' => 'Agency registered. It can be used once an administrator verifies it.',
        ], 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        if (! Auth::attempt(['email' => $data['email'], 'password' => $data['password']])) {
            return response()->json(['message' => 'Invalid credentials.'], 401);
        }

        /** @var User $user */
        $user = Auth::user();

        if ($user->is_locked) {
            return response()->json(['message' => 'This account has been locked.'], 403);
        }

        return response()->json([
            'user' => $user->load('role', 'agencyStaff.agency'),
            'token' => $user->createToken('session')->plainTextToken,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out.']);
    }

    public function me(Request $request)
    {
        return $request->user()->load('role', 'agencyStaff.agency');
    }
}
