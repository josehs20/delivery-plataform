<?php

declare(strict_types=1);

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Support\Str;

/**
 * Validate that an attribute is a valid ULID.
 *
 * The project uses ULIDs as primary keys (ADR-011, App\Models\Concerns\HasUuidPrimaryKey),
 * so IDs must pass the ULID format instead of the built-in "uuid" rule.
 */
final class Ulid implements ValidationRule
{
    /**
     * Run the validation rule.
     *
     * @param  Closure(string): \Illuminate\Translation\PotentiallyTranslatedString  $fail
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! Str::isUlid($value)) {
            $fail('O campo :attribute deve ser um ULID válido.');
        }
    }
}
