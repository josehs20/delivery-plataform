<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryCancellation extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'delivery_cancellations';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'cancelled_by_type',
        'cancelled_by_id',
        'reason',
        'description',
        'financial_resolution',
    ];

    protected $casts = [
        'id' => 'string',
    ];

    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class, 'delivery_id');
    }
}
