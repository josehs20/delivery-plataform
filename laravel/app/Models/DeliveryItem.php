<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryItem extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'delivery_items';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'delivery_id',
        'name',
        'description',
        'category',
        'quantity',
        'approximate_weight',
        'dimensions',
        'special_handling',
        'notes',
    ];

    protected $casts = [
        'id' => 'string',
        'quantity' => 'integer',
        'approximate_weight' => 'decimal:2',
        'dimensions' => 'array',
    ];

    public function delivery(): BelongsTo
    {
        return $this->belongsTo(Delivery::class, 'delivery_id');
    }
}
