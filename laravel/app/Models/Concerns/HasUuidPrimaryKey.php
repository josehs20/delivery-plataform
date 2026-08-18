<?php

declare(strict_types=1);

namespace App\Models\Concerns;

use Illuminate\Support\Str;

/**
 * Auto-generates a ULID primary key before insert for models that use
 * non-incrementing string/UUID primary keys (ADR-011).
 */
trait HasUuidPrimaryKey
{
    public static function bootHasUuidPrimaryKey(): void
    {
        static::creating(function ($model): void {
            if (empty($model->{$model->getKeyName()})) {
                $model->{$model->getKeyName()} = (string) Str::ulid();
            }
        });
    }
}
