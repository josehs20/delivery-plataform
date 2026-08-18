<?php

declare(strict_types=1);

namespace App\Models;

use App\Domain\Delivery\Enums\CounterOfferStatus;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CounterOffer extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'counter_offers';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'driver_id',
        'previous_counter_offer_id',
        'amount',
        'currency',
        'status',
        'message',
        'valid_until',
        'responded_at',
    ];

    protected $casts = [
        'id' => 'string',
        'status' => CounterOfferStatus::class,
        'amount' => 'decimal:2',
        'valid_until' => 'datetime',
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

    public function previousCounterOffer(): BelongsTo
    {
        return $this->belongsTo(self::class, 'previous_counter_offer_id');
    }

    public function supersedingCounterOffers(): HasMany
    {
        return $this->hasMany(self::class, 'previous_counter_offer_id');
    }
}
