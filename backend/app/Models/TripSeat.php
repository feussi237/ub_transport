<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class TripSeat extends Model
{
    public const STATUS_AVAILABLE = 'available';
    public const STATUS_LOCKED = 'locked';
    public const STATUS_BOOKED = 'booked';

    protected $fillable = ['trip_id', 'seat_id', 'status', 'locked_until'];

    protected function casts(): array
    {
        return [
            'locked_until' => 'datetime',
        ];
    }

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    public function seat(): BelongsTo
    {
        return $this->belongsTo(Seat::class);
    }

    public function booking(): HasOne
    {
        return $this->hasOne(Booking::class);
    }
}
