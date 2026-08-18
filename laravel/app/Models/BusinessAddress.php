<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BusinessAddress extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'business_addresses';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'business_id',
        'label',
        'postal_code',
        'state',
        'city',
        'district',
        'street',
        'number',
        'complement',
        'reference',
        'latitude',
        'longitude',
        'is_primary',
    ];

    protected $casts = [
        'id' => 'string',
        'latitude' => 'decimal:7',
        'longitude' => 'decimal:7',
        'is_primary' => 'boolean',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class, 'business_id');
    }
}
