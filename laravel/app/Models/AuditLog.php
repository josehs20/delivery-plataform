<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    use HasUuidPrimaryKey;

    protected $table = 'audit_logs';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'actor_type',
        'actor_id',
        'action',
        'entity_type',
        'entity_id',
        'before_snapshot',
        'after_snapshot',
        'metadata',
        'ip_address',
        'user_agent',
        'occurred_at',
    ];

    protected $casts = [
        'id' => 'string',
        'before_snapshot' => 'array',
        'after_snapshot' => 'array',
        'metadata' => 'array',
        'occurred_at' => 'datetime',
    ];
}
