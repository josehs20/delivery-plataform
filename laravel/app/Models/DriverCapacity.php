<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriverCapacity extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'driver_capacities';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'driver_id',
        'max_weight',
        'max_volumes',
        'notes',
    ];

    protected $casts = [
        'id' => 'string',
        'max_weight' => 'decimal:2',
        'max_volumes' => 'integer',
    ];

    public function driver(): BelongsTo
    {
        return $this->belongsTo(Driver::class, 'driver_id');
    }
}
