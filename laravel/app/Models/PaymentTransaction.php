<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentTransaction extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'payment_transactions';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'payment_id',
        'transaction_type',
        'provider',
        'provider_reference',
        'amount',
        'status',
        'payload_snapshot',
        'occurred_at',
    ];

    protected $casts = [
        'id' => 'string',
        'amount' => 'decimal:2',
        'payload_snapshot' => 'array',
        'occurred_at' => 'datetime',
    ];

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class, 'payment_id');
    }
}
