<?php

declare(strict_types=1);

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Seeder raiz do ambiente de desenvolvimento.
 *
 * 1. AccountSeeder      — contas dos três atores (admin, comércio, motoboy);
 * 2. DeliveryFlowSeeder — entregas de exemplo em cada estágio da máquina de
 *                         estados, para o teste manual do app/API.
 */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(AccountSeeder::class);
        $this->call(DeliveryFlowSeeder::class);
    }
}
