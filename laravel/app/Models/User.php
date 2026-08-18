<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Collection;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, HasUuidPrimaryKey, Notifiable;

    protected $table = 'users';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'name',
        'email',
        'phone',
        'password_hash',
        'status',
        'email_verified_at',
        'phone_verified_at',
        'last_login_at',
    ];

    protected $hidden = [
        'password_hash',
        'remember_token',
    ];

    protected $casts = [
        'id' => 'string',
        'email_verified_at' => 'datetime',
        'phone_verified_at' => 'datetime',
        'last_login_at' => 'datetime',
    ];

    /*
    |--------------------------------------------------------------------------
    | Authentication
    |--------------------------------------------------------------------------
    */

    public function getAuthPassword(): string
    {
        return (string) $this->password_hash;
    }

    public function getPasswordAttribute(): ?string
    {
        return $this->password_hash;
    }

    public function setPasswordAttribute(?string $value): void
    {
        if ($value !== null) {
            $this->attributes['password_hash'] = $value;
        }
    }

    public function getIsBlockedAttribute(): bool
    {
        return $this->status === 'BLOCKED';
    }

    /*
    |--------------------------------------------------------------------------
    | Roles / Permissions (user_roles + role_permissions)
    |--------------------------------------------------------------------------
    */

    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class, 'user_roles', 'user_id', 'role_id');
    }

    /**
     * Check whether the user has any of the given role names.
     *
     * @param string|array<int, string> $roles
     */
    public function hasRole(string|array $roles): bool
    {
        return \count(array_intersect((array) $roles, $this->getRoleNames())) > 0;
    }

    /**
     * @return array<int, string>
     */
    public function getRoleNames(): array
    {
        return $this->roles()->pluck('roles.name')->all();
    }

    public function assignRole(string $role): self
    {
        $roleModel = Role::firstOrCreate(['name' => $role]);

        if (! $this->roles()->where('roles.id', $roleModel->id)->exists()) {
            $this->roles()->attach($roleModel);
        }

        return $this;
    }

    /**
     * @return Collection<int, Permission>
     */
    public function getAllPermissions(): Collection
    {
        return $this->roles()
            ->with('permissions')
            ->get()
            ->flatMap(static fn (Role $role) => $role->permissions)
            ->unique('id')
            ->values();
    }

    public function hasPermissionTo(string $permission): bool
    {
        return $this->getAllPermissions()->contains('name', $permission);
    }

    /*
    |--------------------------------------------------------------------------
    | Relationships
    |--------------------------------------------------------------------------
    */

    public function businessLinks(): HasMany
    {
        return $this->hasMany(BusinessUser::class, 'user_id');
    }

    public function businesses(): BelongsToMany
    {
        return $this->belongsToMany(Business::class, 'business_users', 'user_id', 'business_id')
            ->withPivot(['role', 'status'])
            ->withTimestamps();
    }

    public function sessions(): HasMany
    {
        return $this->hasMany(UserSession::class, 'user_id');
    }

    public function driver(): HasOne
    {
        return $this->hasOne(Driver::class, 'user_id');
    }

    public function drivers(): HasMany
    {
        return $this->hasMany(Driver::class, 'user_id');
    }

    public function notifications(): HasMany
    {
        return $this->hasMany(Notification::class, 'user_id');
    }
}
