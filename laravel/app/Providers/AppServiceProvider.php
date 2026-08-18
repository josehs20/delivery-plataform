<?php

namespace App\Providers;

use App\Models\Delivery;
use App\Models\User;
use App\Policies\DeliveryPolicy;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(Delivery::class, DeliveryPolicy::class);

        // String gates used by the route middleware (can:create-delivery, ...).
        // Ownership/state preconditions are enforced in controllers/use-cases.
        Gate::define('create-delivery', fn (User $user): bool => $user->hasRole('business'));
        Gate::define('update-delivery', fn (User $user): bool => $user->hasRole('business'));
        Gate::define('accept-delivery', fn (User $user): bool => $user->hasRole('driver'));
        Gate::define('transition-delivery', fn (User $user): bool => $user->hasRole('driver'));
        Gate::define('cancel-delivery', fn (User $user): bool => $user->hasRole('business'));
    }
}
