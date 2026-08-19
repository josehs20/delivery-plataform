<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Business;
use App\Models\BusinessUser;
use App\Models\Driver;
use App\Models\DriverVehicle;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * Contas de demonstração para o ambiente local de desenvolvimento.
 *
 * Cobertura dos atores (docs/docs/product/02-actors-and-permissions.md):
 *
 * - comércio: `test@example.com`   / `password` (papel `business` + estabelecimento);
 * - motoboy:  `driver@example.com` / `password` (papel `driver` + veículo aprovado).
 *
 * O usuário administrador essencial é criado por `AdminUserSeeder`
 * (rodado pelo `DatabaseSeeder` e pelo `DevelopmentSeeder`).
 *
 * Idempotente (firstOrCreate) e sem depender do evento `creating` para gerar a
 * chave primária (IDs explícitos), evitando o erro
 * "Field 'id' doesn't have a default value".
 */
class AccountSeeder extends Seeder
{
    public function run(): void
    {
        $businessUser = $this->ensureUser(
            email: 'test@example.com',
            name: 'Test Business',
            phone: '+5531999990001',
        );
        $businessUser->assignRole('business');

        $business = Business::firstOrCreate(
            ['document_number' => '11222333000181'],
            [
                'legal_name' => 'Test Business LTDA',
                'trade_name' => 'Test Business',
                'status' => 'ACTIVE',
            ],
        );

        BusinessUser::firstOrCreate(
            ['business_id' => $business->id, 'user_id' => $businessUser->id],
            ['role' => 'OWNER', 'status' => 'ACTIVE'],
        );

        $driverUser = $this->ensureUser(
            email: 'driver@example.com',
            name: 'Test Driver',
            phone: '+5531999990002',
        );
        $driverUser->assignRole('driver');

        $driver = Driver::firstOrCreate(
            ['user_id' => $driverUser->id],
            [
                'national_document' => '11122233344',
                'approval_status' => 'APPROVED',
                'operational_status' => 'ONLINE',
                'approved_at' => now(),
            ],
        );

        DriverVehicle::firstOrCreate(
            ['driver_id' => $driver->id],
            ['vehicle_type' => 'MOTORCYCLE', 'plate' => 'ABC1D23', 'status' => 'ACTIVE'],
        );
    }

    private function ensureUser(string $email, string $name, string $phone): User
    {
        return User::firstOrCreate(
            ['email' => $email],
            [
                'id' => (string) Str::ulid(),
                'name' => $name,
                'phone' => $phone,
                'password_hash' => Hash::make('password'),
                'status' => 'ACTIVE',
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
            ],
        );
    }
}
