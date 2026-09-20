<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Ticket extends Model
{
    public const BOARDING_UNUSED = 'unused';
    public const BOARDING_BOARDED = 'boarded';

    protected $fillable = ['booking_id', 'qr_code', 'boarding_status', 'boarded_at'];

    protected function casts(): array
    {
        return [
            'boarded_at' => 'datetime',
        ];
    }

    public function booking(): BelongsTo
    {
        return $this->belongsTo(Booking::class);
    }
}
