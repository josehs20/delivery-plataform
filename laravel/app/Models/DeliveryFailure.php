<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryFailure extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'delivery_failures';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'reason',
        'description',
        'reported_by_type',
        'reported_by_id',
        'requires_return',
        'resolution_status',
    ];

    protected $casts = [
        'id' => 'string',
        'requires_return' => 'boolean',
    ];

    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class, 'delivery_id');
    }
}
