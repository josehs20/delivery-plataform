<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Permission;
use App\Models\Role;
use Illuminate\Database\Seeder;

/**
 * Seeder estrutural/essencial de papéis e permissões.
 *
 * Cria os papéis fundamentais (`admin`, `business`, `driver`) e as permissões
 * exigidas pelos gates registrados em `AppServiceProvider` (e pelo middleware
 * `can:` das rotas), com a matriz de vínculo papel ↔ permissão derivada de
 * `docs/docs/product/02-actors-and-permissions.md`.
 *
 * Idempotente (firstOrCreate + attach único): pode rodar quantas vezes for
 * necessário, inclusive em produção/homologação via `php artisan db:seed`.
 */
class RolePermissionSeeder extends Seeder
{
    public const ROLES = [
        'admin',
        'business',
        'driver',
    ];

    /**
     * Permissão => papéis que a possuem (matriz documentada em
     * docs/docs/product/02-actors-and-permissions.md).
     *
     * @var array<string, array<int, string>>
     */
    public const PERMISSIONS = [
        'create-delivery' => ['business', 'admin'],
        'update-delivery' => ['business', 'admin'],
        'accept-delivery' => ['driver', 'admin'],
        'transition-delivery' => ['driver', 'admin'],
        'cancel-delivery' => ['business', 'admin'],
        'access-admin' => ['admin'],
    ];

    public function run(): void
    {
        $roles = [];

        foreach (self::ROLES as $roleName) {
            $roles[$roleName] = Role::firstOrCreate(['name' => $roleName]);
        }

        foreach (self::PERMISSIONS as $permissionName => $roleNames) {
            $permission = Permission::firstOrCreate(['name' => $permissionName]);

            foreach ($roleNames as $roleName) {
                $role = $roles[$roleName];

                if (! $role->permissions()->where('permissions.id', $permission->id)->exists()) {
                    $role->permissions()->attach($permission);
                }
            }
        }
    }
}
