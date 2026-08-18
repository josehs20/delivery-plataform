<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Delivery;
use App\Models\User;

/**
 * Delivery authorization policy.
 *
 * Ownership and state preconditions are enforced here and/or in the
 * controllers/use-cases, following docs/laravel/docs/06-authorization.md.
 */
class DeliveryPolicy
{
    public function create(User $user): bool
    {
        return $user->hasRole('business');
    }

    public function update(User $user, Delivery $delivery): bool
    {
        return $user->hasRole('business')
            && $user->businesses()->where('businesses.id', $delivery->business_id)->exists();
    }

    public function view(User $user, Delivery $delivery): bool
    {
        if ($user->hasRole('business')) {
            return $user->businesses()->where('businesses.id', $delivery->business_id)->exists();
        }

        if ($user->hasRole('driver')) {
            $driver = $user->drivers()->first();

            return $driver !== null
                && $delivery->assignments()->where('driver_id', $driver->id)->exists();
        }

        return false;
    }

    public function accept(User $user, Delivery $delivery): bool
    {
        if (! $user->hasRole('driver')) {
            return false;
        }

        $driver = $user->drivers()->first();

        return $driver !== null
            && $delivery->offers()->where('driver_id', $driver->id)->where('status', 'PENDING')->exists();
    }

    public function transition(User $user, Delivery $delivery): bool
    {
        if (! $user->hasRole('driver')) {
            return false;
        }

        $driver = $user->drivers()->first();

        return $driver !== null
            && $delivery->assignments()->where('driver_id', $driver->id)->where('status', 'ACTIVE')->exists();
    }

    public function cancel(User $user, Delivery $delivery): bool
    {
        return $user->hasRole('business')
            && $user->businesses()->where('businesses.id', $delivery->business_id)->exists();
    }
}
