<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Business extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'businesses';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'legal_name',
        'trade_name',
        'document_number',
        'status',
    ];

    protected $casts = [
        'id' => 'string',
    ];

    public function users(): HasMany
    {
        return $this->hasMany(BusinessUser::class, 'business_id');
    }

    public function userLinks(): HasMany
    {
        return $this->hasMany(BusinessUser::class, 'business_id');
    }

    public function deliveries(): HasMany
    {
        return $this->hasMany(Delivery::class, 'business_id');
    }

    public function addresses(): HasMany
    {
        return $this->hasMany(BusinessAddress::class, 'business_id');
    }
}
