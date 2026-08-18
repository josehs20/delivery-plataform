<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BusinessUser extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'business_users';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'business_id',
        'user_id',
        'role',
        'status',
    ];

    protected $casts = [
        'id' => 'string',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class, 'business_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
