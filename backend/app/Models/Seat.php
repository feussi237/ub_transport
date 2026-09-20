<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Seat extends Model
{
    protected $fillable = ['bus_id', 'seat_number', 'seat_type'];

    public function bus(): BelongsTo
    {
        return $this->belongsTo(Bus::class);
    }

    public function tripSeats(): HasMany
    {
        return $this->hasMany(TripSeat::class);
    }
}
