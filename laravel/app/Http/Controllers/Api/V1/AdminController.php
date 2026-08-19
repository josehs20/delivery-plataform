<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Domain\Delivery\DeliveryStateMachine;
use App\Domain\Delivery\Enums\DeliveryStatus;
use App\Domain\Delivery\Enums\PaymentStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AdminAssignDeliveryRequest;
use App\Http\Requests\Api\V1\AdminCancelDeliveryRequest;
use App\Http\Requests\Api\V1\AdminDriverRejectRequest;
use App\Http\Requests\Api\V1\AdminRefundRequest;
use App\Models\AuditLog;
use App\Models\Delivery;
use App\Models\Driver;
use App\Models\DriverPayout;
use App\Models\Payment;
use App\Models\Refund;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Painel administrativo (docs/docs/api/41-admin-api.md).
 *
 * Grupo protegido por `auth:sanctum` + `can:access-admin` (papel `admin`).
 * Toda intervenção importante gera entrada em `audit_logs` (ADR-008) e, quando
 * afeta uma entrega, também um `DeliveryEvent`.
 */
final class AdminController extends Controller
{
    private const ACTIVE_DRIVER_STATUSES = ['ONLINE', 'AVAILABLE'];

    // ========================================================================
    // Dashboard — métricas globais (cards do painel admin no Flutter)
    // ========================================================================

    /**
     * GET /api/v1/admin/metrics
     *
     * Métricas calculadas no servidor (nunca na UI): entregas hoje, faturamento
     * capturado, motoboys online e cadastros pendentes.
     */
    public function metrics(): JsonResponse
    {
        $today = now()->startOfDay();

        $deliveriesToday = Delivery::where('created_at', '>=', $today)->count();

        $revenue = Payment::where('status', PaymentStatus::CAPTURED->value)
            ->where('captured_at', '>=', $today)
            ->sum('amount');

        $driversOnline = Driver::whereIn('operational_status', self::ACTIVE_DRIVER_STATUSES)->count();

        $pendingDrivers = Driver::where('approval_status', 'PENDING')->count();

        return response()->json([
            'data' => [
                'deliveries_today' => $deliveriesToday,
                'revenue' => number_format((float) $revenue, 2, '.', ''),
                'currency' => 'BRL',
                'drivers_online' => $driversOnline,
                'pending_drivers' => $pendingDrivers,
            ],
        ], 200);
    }

    // ========================================================================
    // Gestão de motoboys e cadastros
    // ========================================================================

    /**
     * GET /api/v1/admin/drivers/pending
     *
     * Fila de cadastros aguardando aprovação, com usuário, documentos e veículo.
     */
    public function pendingDrivers(): JsonResponse
    {
        $drivers = Driver::with(['user', 'documents', 'vehicle'])
            ->where('approval_status', 'PENDING')
            ->latest('created_at')
            ->paginate((int) request()->query('per_page', 15));

        return response()->json([
            'data' => [
                'drivers' => $drivers->items(),
                'pagination' => $this->pagination($drivers),
            ],
        ], 200);
    }

    /**
     * POST /api/v1/admin/drivers/{driver}/approve
     *
     * Aprova o cadastro: APPROVED + documentos marcados como VERIFIED.
     * Idempotente quando o motorista já está aprovado.
     */
    public function approveDriver(string $id): JsonResponse
    {
        /** @var Driver $driver */
        $driver = Driver::with('documents')->findOrFail($id);

        if ($driver->approval_status !== 'APPROVED') {
            DB::transaction(function () use ($driver): void {
                $before = $driver->only(['approval_status', 'operational_status']);

                $driver->update([
                    'approval_status' => 'APPROVED',
                    'approved_at' => now(),
                    'rejection_reason' => null,
                ]);

                $driver->documents()->update([
                    'verification_status' => 'VERIFIED',
                    'verified_by' => auth()->id(),
                    'verified_at' => now(),
                ]);

                $this->recordAuditLog(
                    action: 'DRIVER_APPROVED',
                    entityType: 'driver',
                    entityId: (string) $driver->id,
                    before: $before,
                    after: ['approval_status' => 'APPROVED'],
                    metadata: ['driver_user_id' => $driver->user_id],
                );
            });
        }

        return response()->json([
            'data' => ['driver' => $driver->fresh(['user', 'documents', 'vehicle'])],
            'message' => 'Motorista aprovado com sucesso.',
        ], 200);
    }

    /**
     * POST /api/v1/admin/drivers/{driver}/reject
     *
     * Rejeita o cadastro com justificativa obrigatória (`reason`).
     */
    public function rejectDriver(AdminDriverRejectRequest $request, string $id): JsonResponse
    {
        /** @var Driver $driver */
        $driver = Driver::with('documents')->findOrFail($id);
        $reason = (string) $request->input('reason');

        DB::transaction(function () use ($driver, $reason): void {
            $before = $driver->only(['approval_status']);

            $driver->update([
                'approval_status' => 'REJECTED',
                'rejection_reason' => $reason,
            ]);

            $driver->documents()->update([
                'verification_status' => 'REJECTED',
                'rejection_reason' => $reason,
                'verified_by' => auth()->id(),
                'verified_at' => now(),
            ]);

            $this->recordAuditLog(
                action: 'DRIVER_REJECTED',
                entityType: 'driver',
                entityId: (string) $driver->id,
                before: $before,
                after: ['approval_status' => 'REJECTED', 'rejection_reason' => $reason],
                metadata: ['reason' => $reason, 'driver_user_id' => $driver->user_id],
            );
        });

        return response()->json([
            'data' => ['driver' => $driver->fresh(['user', 'documents', 'vehicle'])],
            'message' => 'Cadastro rejeitado.',
        ], 200);
    }

    /**
     * POST /api/v1/admin/drivers/{driver}/suspend
     *
     * Suspende a conta operacional do motorista: deixa de receber novas corridas
     * (o despacho filtra `operational_status` em ONLINE/AVAILABLE — DispatchService).
     */
    public function suspendDriver(string $id): JsonResponse
    {
        /** @var Driver $driver */
        $driver = Driver::findOrFail($id);

        DB::transaction(function () use ($driver): void {
            $before = $driver->only(['approval_status', 'operational_status']);

            $driver->update(['operational_status' => 'SUSPENDED']);

            $this->recordAuditLog(
                action: 'DRIVER_SUSPENDED',
                entityType: 'driver',
                entityId: (string) $driver->id,
                before: $before,
                after: ['operational_status' => 'SUSPENDED'],
                metadata: ['driver_user_id' => $driver->user_id],
            );
        });

        return response()->json([
            'data' => ['driver' => $driver->fresh(['user', 'documents', 'vehicle'])],
            'message' => 'Motorista suspenso.',
        ], 200);
    }

    // ========================================================================
    // Torre de controle de entregas
    // ========================================================================

    /**
     * GET /api/v1/admin/deliveries
     *
     * Listagem administrativa com filtros avançados:
     * `status`, `date_from`, `date_to`, `business_id`, `driver_id`, `search`.
     */
    public function deliveries(): JsonResponse
    {
        $query = Delivery::with(['business', 'currentDriver.user', 'items', 'events'])
            ->latest('created_at');

        if (request()->filled('status')) {
            $query->where('status', (string) request()->query('status'));
        }

        if (request()->filled('date_from')) {
            $query->where('created_at', '>=', request()->date('date_from')?->startOfDay());
        }

        if (request()->filled('date_to')) {
            $query->where('created_at', '<=', request()->date('date_to')?->endOfDay());
        }

        if (request()->filled('business_id')) {
            $query->where('business_id', (string) request()->query('business_id'));
        }

        if (request()->filled('driver_id')) {
            $query->where('current_driver_id', (string) request()->query('driver_id'));
        }

        if (request()->filled('search')) {
            $search = (string) request()->query('search');
            $query->where(function ($q) use ($search): void {
                $q->where('recipient_name', 'like', "%{$search}%")
                    ->orWhere('recipient_phone', 'like', "%{$search}%")
                    ->orWhere('id', 'like', "%{$search}%");
            });
        }

        $deliveries = $query->paginate((int) request()->query('per_page', 15));

        return response()->json([
            'data' => [
                'deliveries' => $deliveries->items(),
                'pagination' => $this->pagination($deliveries),
            ],
        ], 200);
    }

    /**
     * POST /api/v1/admin/deliveries/{delivery}/assign
     *
     * Atribuição/reatribuição manual. Respeita as mesmas invariantes da
     * atribuição automática (ADR-004): motorista aprovado, estado compatível,
     * concorrência serializada com lockForUpdate.
     */
    public function assignDelivery(AdminAssignDeliveryRequest $request, string $id): JsonResponse
    {
        /** @var User $admin */
        $admin = auth()->user();
        $driverId = (string) $request->input('driver_id');

        $delivery = DB::transaction(function () use ($id, $driverId, $admin): Delivery {
            /** @var Delivery $delivery */
            $delivery = Delivery::whereKey($id)->lockForUpdate()->firstOrFail();

            /** @var Driver $driver */
            $driver = Driver::whereKey($driverId)->firstOrFail();

            if ($driver->approval_status !== 'APPROVED') {
                throw ValidationException::withMessages([
                    'driver_id' => 'Motorista precisa estar aprovado para receber entregas.',
                ]);
            }

            $allowed = [DeliveryStatus::OPEN->value, DeliveryStatus::NEGOTIATING->value,
                DeliveryStatus::ASSIGNED->value, DeliveryStatus::DRIVER_ACCEPTED->value];

            if (! \in_array($delivery->status->value, $allowed, true)) {
                throw ValidationException::withMessages([
                    'delivery' => 'Entrega não pode ser atribuída neste estado.',
                ]);
            }

            $before = ['status' => $delivery->status->value, 'current_driver_id' => $delivery->current_driver_id];

            // Reatribuição: encerra a atribuição ativa anterior.
            $delivery->assignments()->where('status', 'ACTIVE')->update([
                'status' => 'RELEASED',
                'released_at' => now(),
            ]);

            $delivery->assignments()->create([
                'driver_id' => $driver->id,
                'source_type' => 'ADMIN',
                'source_reference_id' => $admin->id,
                'agreed_amount' => $delivery->accepted_amount ?? $delivery->suggested_amount,
                'status' => 'ACTIVE',
                'assigned_at' => now(),
            ]);

            $delivery->update([
                'current_driver_id' => $driver->id,
                'status' => DeliveryStatus::ASSIGNED->value,
            ]);

            $delivery->events()->create([
                'event_type' => 'ADMIN_ASSIGNED',
                'actor_type' => 'admin',
                'actor_id' => $admin->id,
                'source' => 'API',
                'metadata' => ['driver_id' => $driver->id],
                'occurred_at' => now(),
            ]);

            $this->recordAuditLog(
                action: 'DELIVERY_ASSIGNED',
                entityType: 'delivery',
                entityId: (string) $delivery->id,
                before: $before,
                after: ['status' => $delivery->status->value, 'current_driver_id' => $driver->id],
                metadata: ['driver_id' => $driver->id, 'admin_user_id' => $admin->id],
            );

            return $delivery;
        });

        return response()->json([
            'data' => ['delivery' => $delivery->load(['business', 'currentDriver.user', 'items'])],
            'message' => 'Entrega atribuída com sucesso.',
        ], 200);
    }

    /**
     * POST /api/v1/admin/deliveries/{delivery}/cancel
     *
     * Cancelamento administrativo forçado (`reason` + `refund_type` opcional).
     * Valida a máquina de estados e gera auditoria + evento.
     */
    public function cancelDelivery(AdminCancelDeliveryRequest $request, string $id): JsonResponse
    {
        /** @var User $admin */
        $admin = auth()->user();
        $reason = (string) $request->input('reason');
        $refundType = (string) ($request->input('refund_type') ?? 'NONE');

        $delivery = DB::transaction(function () use ($id, $reason, $refundType, $admin): Delivery {
            /** @var Delivery $delivery */
            $delivery = Delivery::whereKey($id)->lockForUpdate()->firstOrFail();

            DeliveryStateMachine::validateTransition($delivery->status, DeliveryStatus::CANCELLED);

            $delivery->cancellation()->create([
                'cancelled_by_type' => 'admin',
                'cancelled_by_id' => $admin->id,
                'reason' => $reason,
                'financial_resolution' => $refundType,
            ]);

            $delivery->update([
                'status' => DeliveryStatus::CANCELLED->value,
                'cancelled_at' => now(),
            ]);

            $delivery->events()->create([
                'event_type' => 'DELIVERY_CANCELLED',
                'actor_type' => 'admin',
                'actor_id' => $admin->id,
                'source' => 'API',
                'metadata' => ['reason' => $reason, 'refund_type' => $refundType],
                'occurred_at' => now(),
            ]);

            $this->recordAuditLog(
                action: 'DELIVERY_CANCELLED',
                entityType: 'delivery',
                entityId: (string) $delivery->id,
                before: ['status' => $delivery->status->value],
                after: ['status' => DeliveryStatus::CANCELLED->value],
                metadata: ['reason' => $reason, 'refund_type' => $refundType, 'admin_user_id' => $admin->id],
            );

            return $delivery;
        });

        return response()->json([
            'data' => ['delivery' => $delivery->load(['business', 'currentDriver.user', 'items', 'cancellation'])],
            'message' => 'Entrega cancelada.',
        ], 200);
    }

    // ========================================================================
    // Financeiro, reembolsos e repasses
    // ========================================================================

    /**
     * GET /api/v1/admin/payments
     *
     * Extrato global de pagamentos dos comércios (filtros: `status`, `date_from`, `date_to`).
     */
    public function payments(): JsonResponse
    {
        $query = Payment::with(['delivery.business', 'refunds'])->latest('created_at');

        if (request()->filled('status')) {
            $query->where('status', (string) request()->query('status'));
        }

        if (request()->filled('date_from')) {
            $query->where('created_at', '>=', request()->date('date_from')?->startOfDay());
        }

        if (request()->filled('date_to')) {
            $query->where('created_at', '<=', request()->date('date_to')?->endOfDay());
        }

        $payments = $query->paginate((int) request()->query('per_page', 15));

        return response()->json([
            'data' => [
                'payments' => $payments->items(),
                'pagination' => $this->pagination($payments),
            ],
        ], 200);
    }

    /**
     * GET /api/v1/admin/refunds
     *
     * Histórico de reembolsos emitidos.
     */
    public function listRefunds(): JsonResponse
    {
        $refunds = Refund::with(['payment.delivery.business'])
            ->latest('created_at')
            ->paginate((int) request()->query('per_page', 15));

        return response()->json([
            'data' => [
                'refunds' => $refunds->items(),
                'pagination' => $this->pagination($refunds),
            ],
        ], 200);
    }

    /**
     * POST /api/v1/admin/refunds
     *
     * Emissão de reembolso parcial ou total para um pagamento de comércio.
     * Nunca excede o valor ainda não reembolsado do pagamento.
     */
    public function createRefund(AdminRefundRequest $request): JsonResponse
    {
        /** @var User $admin */
        $admin = auth()->user();
        $paymentId = (string) $request->input('payment_id');
        $amount = (string) $request->input('amount');
        $reason = (string) $request->input('reason');

        $refund = DB::transaction(function () use ($paymentId, $amount, $reason, $admin): Refund {
            /** @var Payment $payment */
            $payment = Payment::whereKey($paymentId)->lockForUpdate()->firstOrFail();

            $alreadyRefunded = (float) $payment->refunds()->sum('amount');
            $remaining = (float) $payment->amount - $alreadyRefunded;

            if ((float) $amount > $remaining) {
                throw ValidationException::withMessages([
                    'amount' => 'Valor do reembolso excede o saldo disponível do pagamento.',
                ]);
            }

            $refund = $payment->refunds()->create([
                'amount' => $amount,
                'reason' => $reason,
                'status' => 'PENDING',
                'requested_at' => now(),
            ]);

            $this->recordAuditLog(
                action: 'REFUND_CREATED',
                entityType: 'refund',
                entityId: (string) $refund->id,
                metadata: ['payment_id' => $paymentId, 'amount' => $amount, 'reason' => $reason, 'admin_user_id' => $admin->id],
            );

            return $refund;
        });

        return response()->json([
            'data' => ['refund' => $refund->load('payment.delivery.business')],
            'message' => 'Reembolso registrado.',
        ], 201);
    }

    /**
     * GET /api/v1/admin/payouts
     *
     * Lotes de repasses para motoboys (filtro opcional: `status`).
     */
    public function payouts(): JsonResponse
    {
        $query = DriverPayout::with(['driver.user', 'delivery'])->latest('created_at');

        if (request()->filled('status')) {
            $query->where('status', (string) request()->query('status'));
        }

        $payouts = $query->paginate((int) request()->query('per_page', 15));

        return response()->json([
            'data' => [
                'payouts' => $payouts->items(),
                'pagination' => $this->pagination($payouts),
            ],
        ], 200);
    }

    // ========================================================================
    // Auditoria e monitoramento
    // ========================================================================

    /**
     * GET /api/v1/admin/audit-logs
     *
     * Consulta paginada de `audit_logs` com filtros por data, usuário, ação e
     * tipo de recurso (`action`, `entity_type`, `user_id`, `date_from`, `date_to`).
     */
    public function auditLogs(): JsonResponse
    {
        $query = AuditLog::query()->latest('occurred_at');

        if (request()->filled('action')) {
            $query->where('action', (string) request()->query('action'));
        }

        if (request()->filled('entity_type')) {
            $query->where('entity_type', (string) request()->query('entity_type'));
        }

        if (request()->filled('user_id')) {
            $query->where('actor_id', (string) request()->query('user_id'));
        }

        if (request()->filled('date_from')) {
            $query->where('occurred_at', '>=', request()->date('date_from')?->startOfDay());
        }

        if (request()->filled('date_to')) {
            $query->where('occurred_at', '<=', request()->date('date_to')?->endOfDay());
        }

        $logs = $query->paginate((int) request()->query('per_page', 15));

        return response()->json([
            'data' => [
                'audit_logs' => $logs->items(),
                'pagination' => $this->pagination($logs),
            ],
        ], 200);
    }

    // ========================================================================
    // Helpers
    // ========================================================================

    /**
     * Registra uma intervenção administrativa na trilha de auditoria (ADR-008).
     *
     * @param  array<string, mixed>  $before
     * @param  array<string, mixed>  $after
     * @param  array<string, mixed>  $metadata
     */
    private function recordAuditLog(
        string $action,
        string $entityType,
        ?string $entityId,
        array $before = [],
        array $after = [],
        array $metadata = []
    ): void {
        AuditLog::create([
            'actor_type' => 'admin',
            'actor_id' => auth()->id(),
            'action' => $action,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'before_snapshot' => $before ?: null,
            'after_snapshot' => $after ?: null,
            'metadata' => $metadata ?: null,
            'ip_address' => request()->ip(),
            'user_agent' => substr((string) request()->userAgent(), 0, 500) ?: null,
            'occurred_at' => now(),
        ]);
    }

    /**
     * Envelope de paginação usado em todas as listagens administrativas.
     *
     * @return array<string, mixed>
     */
    private function pagination(LengthAwarePaginator $paginator): array
    {
        return [
            'total' => $paginator->total(),
            'per_page' => $paginator->perPage(),
            'current_page' => $paginator->currentPage(),
            'last_page' => $paginator->lastPage(),
        ];
    }
}
