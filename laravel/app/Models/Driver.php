<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Driver extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'drivers';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'national_document',
        'approval_status',
        'operational_status',
        'last_online_at',
        'approved_at',
    ];

    protected $casts = [
        'id' => 'string',
        'last_online_at' => 'datetime',
        'approved_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function documents(): HasMany
    {
        return $this->hasMany(DriverDocument::class, 'driver_id');
    }

    public function vehicle(): HasOne
    {
        return $this->hasOne(DriverVehicle::class, 'driver_id');
    }

    public function vehicles(): HasMany
    {
        return $this->hasMany(DriverVehicle::class, 'driver_id');
    }

    public function capacity(): HasOne
    {
        return $this->hasOne(DriverCapacity::class, 'driver_id');
    }

    public function servicePreferences(): HasOne
    {
        return $this->hasOne(DriverServicePreference::class, 'driver_id');
    }

    public function offers(): HasMany
    {
        return $this->hasMany(DeliveryOffer::class, 'driver_id');
    }

    public function counterOffers(): HasMany
    {
        return $this->hasMany(CounterOffer::class, 'driver_id');
    }

    public function assignments(): HasMany
    {
        return $this->hasMany(DeliveryAssignment::class, 'driver_id');
    }

    public function locations(): HasMany
    {
        return $this->hasMany(DeliveryLocation::class, 'driver_id');
    }

    public function payouts(): HasMany
    {
        return $this->hasMany(DriverPayout::class, 'driver_id');
    }

    /**
     * Deliveries currently linked to this driver (ADR-010: multiple active
     * deliveries per driver are supported).
     */
    public function deliveries(): HasMany
    {
        return $this->hasMany(Delivery::class, 'current_driver_id');
    }
}
