<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriverVehicle extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'driver_vehicles';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'driver_id',
        'vehicle_type',
        'brand',
        'model',
        'year',
        'color',
        'plate',
        'status',
    ];

    protected $casts = [
        'id' => 'string',
        'year' => 'integer',
    ];

    public function driver(): BelongsTo
    {
        return $this->belongsTo(Driver::class, 'driver_id');
    }
}
