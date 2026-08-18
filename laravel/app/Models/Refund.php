<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Refund extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'refunds';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'payment_id',
        'amount',
        'reason',
        'provider_reference',
        'status',
        'requested_at',
        'completed_at',
    ];

    protected $casts = [
        'id' => 'string',
        'amount' => 'decimal:2',
        'requested_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class, 'payment_id');
    }
}
