<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserNotification extends Model
{
    protected $table = 'user_notifications';

    public const TYPE_BOOKING = 'booking';
    public const TYPE_DELAY = 'delay';
    public const TYPE_CANCELLATION = 'cancellation';
    public const TYPE_REMINDER = 'reminder';

    public const CHANNEL_PUSH = 'push';
    public const CHANNEL_SMS = 'sms';

    protected $fillable = ['user_id', 'type', 'channel', 'title', 'body', 'is_read', 'sent_at'];

    protected function casts(): array
    {
        return [
            'is_read' => 'boolean',
            'sent_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
