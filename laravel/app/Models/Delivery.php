<?php

declare(strict_types=1);

namespace App\Models;

use App\Domain\Delivery\Enums\DeliveryStatus;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Delivery extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'deliveries';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'business_id',
        'current_driver_id',
        'status',
        'pricing_mode',
        'currency',
        'suggested_amount',
        'merchant_offered_amount',
        'accepted_amount',
        'origin_snapshot',
        'destination_snapshot',
        'recipient_name',
        'recipient_phone',
        'recipient_reference',
        'pickup_deadline',
        'published_at',
        'accepted_at',
        'picked_up_at',
        'delivered_at',
        'cancelled_at',
    ];

    protected $casts = [
        'id' => 'string',
        'status' => DeliveryStatus::class,
        'origin_snapshot' => 'array',
        'destination_snapshot' => 'array',
        'suggested_amount' => 'decimal:2',
        'merchant_offered_amount' => 'decimal:2',
        'accepted_amount' => 'decimal:2',
        'pickup_deadline' => 'datetime',
        'published_at' => 'datetime',
        'accepted_at' => 'datetime',
        'picked_up_at' => 'datetime',
        'delivered_at' => 'datetime',
        'cancelled_at' => 'datetime',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class, 'business_id');
    }

    public function currentDriver(): BelongsTo
    {
        return $this->belongsTo(Driver::class, 'current_driver_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(DeliveryItem::class, 'delivery_id');
    }

    public function offers(): HasMany
    {
        return $this->hasMany(DeliveryOffer::class, 'delivery_id');
    }

    public function counterOffers(): HasMany
    {
        return $this->hasMany(CounterOffer::class, 'delivery_id');
    }

    public function assignments(): HasMany
    {
        return $this->hasMany(DeliveryAssignment::class, 'delivery_id');
    }

    /**
     * Latest active assignment (convenience relation used by drivers).
     */
    public function assignment(): HasOne
    {
        return $this->hasOne(DeliveryAssignment::class, 'delivery_id')->latestOfMany('assigned_at');
    }

    public function events(): HasMany
    {
        return $this->hasMany(DeliveryEvent::class, 'delivery_id');
    }

    public function locations(): HasMany
    {
        return $this->hasMany(DeliveryLocation::class, 'delivery_id');
    }

    public function evidences(): HasMany
    {
        return $this->hasMany(DeliveryEvidence::class, 'delivery_id');
    }

    /**
     * Most recent proof-of-delivery evidence.
     */
    public function evidence(): HasOne
    {
        return $this->hasOne(DeliveryEvidence::class, 'delivery_id')->latestOfMany('captured_at');
    }

    public function failures(): HasMany
    {
        return $this->hasMany(DeliveryFailure::class, 'delivery_id');
    }

    public function cancellation(): HasOne
    {
        return $this->hasOne(DeliveryCancellation::class, 'delivery_id');
    }

    public function returns(): HasMany
    {
        return $this->hasMany(DeliveryReturn::class, 'delivery_id');
    }

    public function payment(): HasOne
    {
        return $this->hasOne(Payment::class, 'delivery_id');
    }

    public function commission(): HasOne
    {
        return $this->hasOne(Commission::class, 'delivery_id');
    }
}
