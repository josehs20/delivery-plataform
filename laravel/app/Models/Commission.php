<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Commission extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'commissions';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'commission_type',
        'rate',
        'fixed_amount',
        'calculated_amount',
        'currency',
        'snapshot',
    ];

    protected $casts = [
        'id' => 'string',
        'rate' => 'decimal:4',
        'fixed_amount' => 'decimal:2',
        'calculated_amount' => 'decimal:2',
        'snapshot' => 'array',
    ];

    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class, 'delivery_id');
    }
}
