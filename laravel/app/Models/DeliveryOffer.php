<?php

declare(strict_types=1);

namespace App\Models;

use App\Domain\Delivery\Enums\OfferStatus;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryOffer extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'delivery_offers';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'driver_id',
        'status',
        'offered_amount',
        'available_until',
        'sent_at',
        'responded_at',
    ];

    protected $casts = [
        'id' => 'string',
        'status' => OfferStatus::class,
        'offered_amount' => 'decimal:2',
        'available_until' => 'datetime',
        'sent_at' => 'datetime',
        'responded_at' => 'datetime',
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
