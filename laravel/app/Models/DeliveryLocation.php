<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryLocation extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'delivery_locations';

    /** A tabela usa recorded_at/received_at (sem created_at/updated_at). */
    public $timestamps = false;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'driver_id',
        'latitude',
        'longitude',
        'accuracy',
        'speed',
        'heading',
        'recorded_at',
        'received_at',
        'source',
    ];

    protected $casts = [
        'id' => 'string',
        'latitude' => 'decimal:7',
        'longitude' => 'decimal:7',
        'accuracy' => 'decimal:2',
        'speed' => 'decimal:2',
        'heading' => 'decimal:2',
        'recorded_at' => 'datetime',
        'received_at' => 'datetime',
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
