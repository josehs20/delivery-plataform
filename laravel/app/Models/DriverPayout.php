<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriverPayout extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'driver_payouts';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'driver_id',
        'delivery_id',
        'gross_amount',
        'platform_fee',
        'other_fees',
        'net_amount',
        'status',
        'available_at',
        'paid_at',
        'provider_reference',
    ];

    protected $casts = [
        'id' => 'string',
        'gross_amount' => 'decimal:2',
        'platform_fee' => 'decimal:2',
        'other_fees' => 'decimal:2',
        'net_amount' => 'decimal:2',
        'available_at' => 'datetime',
        'paid_at' => 'datetime',
    ];

    public function driver(): BelongsTo
    {
        return $this->belongsTo(Driver::class, 'driver_id');
    }

    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class, 'delivery_id');
    }
}
