<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriverServicePreference extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'driver_service_preferences';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'driver_id',
        'accepts_categories',
        'excluded_categories',
        'max_distance_km',
        'max_concurrent_deliveries',
        'enabled',
    ];

    protected $casts = [
        'id' => 'string',
        'accepts_categories' => 'array',
        'excluded_categories' => 'array',
        'max_distance_km' => 'decimal:2',
        'max_concurrent_deliveries' => 'integer',
        'enabled' => 'boolean',
    ];

    public function driver(): BelongsTo
    {
        return $this->belongsTo(Driver::class, 'driver_id');
    }
}
