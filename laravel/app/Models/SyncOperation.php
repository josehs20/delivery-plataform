<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;

class SyncOperation extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'sync_operations';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'client_id',
        'device_id',
        'operation_id',
        'entity_type',
        'entity_id',
        'operation_type',
        'payload',
        'client_created_at',
        'received_at',
        'processed_at',
        'status',
        'retry_count',
        'error_code',
        'error_message',
    ];

    protected $casts = [
        'id' => 'string',
        'entity_id' => 'string',
        'payload' => 'array',
        'client_created_at' => 'datetime',
        'received_at' => 'datetime',
        'processed_at' => 'datetime',
        'retry_count' => 'integer',
    ];
}
