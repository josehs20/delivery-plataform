<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * Usuário administrador essencial do sistema.
 *
 * Conta de operação da plataforma (docs/docs/product/02-actors-and-permissions.md),
 * necessária para a aplicação iniciar em produção/homologação. Idempotente
 * (firstOrCreate por email).
 */
class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::firstOrCreate(
            ['email' => 'admin@example.com'],
            [
                'id' => (string) Str::ulid(),
                'name' => 'Admin do Sistema',
                'phone' => '+5531999990000',
                'password_hash' => Hash::make('password'),
                'status' => 'ACTIVE',
                'email_verified_at' => now(),
                'phone_verified_at' => now(),
            ],
        );

        $admin->assignRole('admin');
    }
}
