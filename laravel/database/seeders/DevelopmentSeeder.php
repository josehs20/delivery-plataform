<?php

declare(strict_types=1);

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Massa de dados de desenvolvimento (opcional e isolada).
 *
 * NÃO faz parte do `DatabaseSeeder` e NÃO roda em `migrate:fresh --seed`.
 * Inclui contas de demonstração (comércio/motoboy) e entregas de exemplo em
 * vários estágios da máquina de estados para preencher telas/dashboards.
 *
 * Uso (ambiente local apenas):
 *
 *     php artisan db:seed --class=DevelopmentSeeder
 *
 * Ou, em conjunto com uma base limpa:
 *
 *     php artisan migrate:fresh --seed --seeder=DevelopmentSeeder
 *
 * Regras de negócio do MVP (docs/docs/domain/11-offline-and-synchronization.md):
 * ofertas de marketplace e operações críticas NÃO são simuladas aqui como se
 * fossem dados de produção — este dataset é apenas visual/manual.
 */
class DevelopmentSeeder extends Seeder
{
    public function run(): void
    {
        // Essencial (idempotente): papéis/permissões e admin de sistema.
        $this->call(RolePermissionSeeder::class);
        $this->call(AdminUserSeeder::class);

        // Demonstração: contas comércio/motoboy + entregas em cada estágio.
        $this->call(AccountSeeder::class);
        $this->call(DeliveryFlowSeeder::class);
    }
}
