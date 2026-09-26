<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SystemSetting extends Model
{
    protected $fillable = ['key', 'value'];

    /** Keys the admin dashboard is allowed to read/write, with their defaults. */
    public const DEFAULTS = [
        'default_commission_rate' => '10',
        'seat_lock_minutes' => '5',
        'support_phone' => '+237600000000',
        'support_email' => 'support@ubtransport.cm',
        'maintenance_mode' => 'false',
    ];

    public static function allWithDefaults(): array
    {
        $stored = static::query()->pluck('value', 'key')->all();

        return array_merge(self::DEFAULTS, $stored);
    }

    public static function set(string $key, string $value): void
    {
        static::updateOrCreate(['key' => $key], ['value' => $value]);
    }
}
