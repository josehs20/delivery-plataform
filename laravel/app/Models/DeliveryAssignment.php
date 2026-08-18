<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryAssignment extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'delivery_assignments';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'driver_id',
        'source_type',
        'source_reference_id',
        'agreed_amount',
        'status',
        'assigned_at',
        'accepted_at',
        'released_at',
    ];

    protected $casts = [
        'id' => 'string',
        'agreed_amount' => 'decimal:2',
        'assigned_at' => 'datetime',
        'accepted_at' => 'datetime',
        'released_at' => 'datetime',
    ];

    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class, 'delivery_id');
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(Driver::class, 'driver_id');
    }
}
