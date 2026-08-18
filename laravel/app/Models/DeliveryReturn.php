<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryReturn extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'delivery_returns';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'initiated_by_type',
        'initiated_by_id',
        'status',
        'pickup_confirmed_at',
        'returned_at',
        'return_evidence_id',
        'merchant_confirmed_at',
    ];

    protected $casts = [
        'id' => 'string',
        'pickup_confirmed_at' => 'datetime',
        'returned_at' => 'datetime',
        'merchant_confirmed_at' => 'datetime',
    ];

    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class, 'delivery_id');
    }

    public function returnEvidence(): BelongsTo
    {
        return $this->belongsTo(DeliveryEvidence::class, 'return_evidence_id');
    }
}
