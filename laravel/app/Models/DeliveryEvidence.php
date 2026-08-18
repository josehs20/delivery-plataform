<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryEvidence extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'delivery_evidences';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'evidence_type',
        'object_key',
        'captured_at',
        'latitude',
        'longitude',
        'captured_by_type',
        'captured_by_id',
        'metadata',
    ];

    protected $casts = [
        'id' => 'string',
        'latitude' => 'decimal:7',
        'longitude' => 'decimal:7',
        'captured_at' => 'datetime',
        'metadata' => 'array',
    ];

    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class, 'delivery_id');
    }
}
