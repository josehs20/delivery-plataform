<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriverDocument extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'driver_documents';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'driver_id',
        'document_type',
        'document_number',
        'expires_at',
        'object_key',
        'verification_status',
        'verified_by',
        'verified_at',
        'rejection_reason',
    ];

    protected $casts = [
        'id' => 'string',
        'expires_at' => 'date',
        'verified_at' => 'datetime',
    ];

    public function driver(): BelongsTo
    {
        return $this->belongsTo(Driver::class, 'driver_id');
    }

    public function verifier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }
}
