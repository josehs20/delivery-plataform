<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryEvent extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'delivery_events';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'event_type',
        'actor_type',
        'actor_id',
        'source',
        'idempotency_key',
        'metadata',
        'occurred_at',
    ];

    protected $casts = [
        'id' => 'string',
        'metadata' => 'array',
        'occurred_at' => 'datetime',
    ];

    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class, 'delivery_id');
    }
}
