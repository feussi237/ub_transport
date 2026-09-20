<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Agency;
use App\Models\AuditLog;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AgencyController extends Controller
{
    public function index(Request $request)
    {
        $query = Agency::query();

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        return $query->latest()->paginate(20);
    }

    public function approve(Request $request, Agency $agency)
    {
        $agency->update([
            'status' => Agency::STATUS_VERIFIED,
            'verified_at' => now(),
        ]);

        AuditLog::record($request->user(), 'agency.verified', $agency);

        return $agency;
    }

    public function suspend(Request $request, Agency $agency)
    {
        $data = $request->validate([
            'reason' => ['required', 'string'],
        ]);

        $agency->update(['status' => Agency::STATUS_SUSPENDED]);

        AuditLog::record($request->user(), 'agency.suspended', $agency, $data['reason']);

        return $agency;
    }

    public function updateCommission(Request $request, Agency $agency)
    {
        $data = $request->validate([
            'commission_rate' => ['required', 'numeric', 'min:0', 'max:100'],
        ]);

        $agency->update($data);

        AuditLog::record($request->user(), 'agency.commission_updated', $agency);

        return $agency;
    }
}
