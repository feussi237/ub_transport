<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\SystemSetting;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class SettingController extends Controller
{
    public function index()
    {
        return SystemSetting::allWithDefaults();
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'default_commission_rate' => ['sometimes', 'numeric', 'min:0', 'max:100'],
            'seat_lock_minutes' => ['sometimes', 'integer', 'min:1', 'max:60'],
            'support_phone' => ['sometimes', 'string'],
            'support_email' => ['sometimes', 'email'],
            'maintenance_mode' => ['sometimes', Rule::in(['true', 'false'])],
        ]);

        foreach ($data as $key => $value) {
            SystemSetting::set($key, (string) $value);
        }

        AuditLog::record($request->user(), 'settings.updated', null, implode(',', array_keys($data)));

        return SystemSetting::allWithDefaults();
    }
}
