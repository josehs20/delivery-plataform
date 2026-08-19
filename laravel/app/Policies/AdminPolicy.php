<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\User;

/**
 * Autorização do grupo administrativo (`/api/v1/admin/*`).
 *
 * O papel `admin` (operação da plataforma — docs/docs/product/02-actors-and-permissions.md)
 * é o único com acesso ao painel administrativo. Cada método cobre um módulo
 * para que a política possa evoluir granularmente sem alterar as rotas.
 */
final class AdminPolicy
{
    /**
     * Acesso geral ao grupo /admin/* (usado pelo gate `access-admin`).
     */
    public function access(User $user): bool
    {
        return $user->hasRole('admin');
    }

    /**
     * Gestão de cadastros de motoboys (aprovar/rejeitar/suspender).
     */
    public function manageDrivers(User $user): bool
    {
        return $this->access($user);
    }

    /**
     * Torre de controle de entregas (listar com filtros, atribuir, cancelar).
     */
    public function manageDeliveries(User $user): bool
    {
        return $this->access($user);
    }

    /**
     * Financeiro: pagamentos, reembolsos e repasses.
     */
    public function manageFinance(User $user): bool
    {
        return $this->access($user);
    }

    /**
     * Consulta da trilha de auditoria.
     */
    public function viewAuditLogs(User $user): bool
    {
        return $this->access($user);
    }
}
