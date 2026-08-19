<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Cobertura do fluxo de logout (docs/api/30-auth-api.md):
 * a rota `POST /api/v1/auth/logout` deve estar registrada, protegida por
 * Sanctum, revogar o token atual e responder 200 com o envelope canônico.
 */
class AuthLogoutTest extends TestCase
{
    use RefreshDatabase;

    #[Test]
    public function logout_requires_an_authenticated_token(): void
    {
        $this->postJson('/api/v1/auth/logout')
            ->assertUnauthorized();
    }

    #[Test]
    public function logout_revokes_the_current_token_and_returns_the_canonical_envelope(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('api-token')->plainTextToken;

        $this->assertDatabaseCount('personal_access_tokens', 1);

        $this->withToken($token)
            ->postJson('/api/v1/auth/logout')
            ->assertOk()
            ->assertJsonPath('data.message', 'Successfully logged out');

        // O token foi revogado/removido no banco (ADR: sessão não reutilizável).
        $this->assertDatabaseCount('personal_access_tokens', 0);

        // O guard do Sanctum mantém o usuário em cache dentro do mesmo teste;
        // resetamos para que a próxima requisição re-resolva o token (revogado).
        app('auth')->forgetGuards();

        // O mesmo token não autentica mais as rotas protegidas.
        $this->withToken($token)
            ->getJson('/api/v1/me')
            ->assertUnauthorized();
    }

    #[Test]
    public function logout_only_revokes_the_current_users_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('api-token')->plainTextToken;

        // Um segundo token do mesmo usuário permanece válido após o logout do atual.
        $otherToken = $user->createToken('other-device')->plainTextToken;

        $this->withToken($token)
            ->postJson('/api/v1/auth/logout')
            ->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 1);

        // Reset do guard (cache por requisição no mesmo teste) para re-resolver
        // o segundo token e comprovar que ele continua válido.
        app('auth')->forgetGuards();

        $this->withToken($otherToken)
            ->getJson('/api/v1/me')
            ->assertOk();
    }

    #[Test]
    public function logout_works_for_an_admin_session(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('admin');
        Sanctum::actingAs($admin);

        $this->postJson('/api/v1/auth/logout')
            ->assertOk()
            ->assertJsonPath('data.message', 'Successfully logged out');
    }
}
