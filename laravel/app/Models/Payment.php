<?php

declare(strict_types=1);

namespace App\Models;

use App\Domain\Delivery\Enums\PaymentStatus;
use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Payment extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'payments';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'payer_type',
        'payer_id',
        'provider',
        'provider_payment_reference',
        'amount',
        'currency',
        'status',
        'authorized_at',
        'captured_at',
        'failed_at',
    ];

    protected $casts = [
        'id' => 'string',
        'status' => PaymentStatus::class,
        'amount' => 'decimal:2',
        'authorized_at' => 'datetime',
        'captured_at' => 'datetime',
        'failed_at' => 'datetime',
    ];

    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class, 'delivery_id');
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(PaymentTransaction::class, 'payment_id');
    }

    public function refunds(): HasMany
    {
        return $this->hasMany(Refund::class, 'payment_id');
    }
}
