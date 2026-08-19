<?php

declare(strict_types=1);

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Seeder raiz — apenas o ESSENCIAL para a aplicação iniciar em produção ou
 * homologação (dados estruturais, idempotentes e sem massa fake):
 *
 * 1. RolePermissionSeeder — papéis (admin, business, driver) e permissões;
 * 2. AdminUserSeeder      — usuário administrador de sistema.
 *
 * Dados de demonstração (contas comércio/motoboy + entregas de exemplo) NÃO
 * ficam aqui: rode `php artisan db:seed --class=DevelopmentSeeder` em ambiente
 * local quando precisar preencher telas/dashboards.
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(RolePermissionSeeder::class);
        $this->call(AdminUserSeeder::class);
    }
}
