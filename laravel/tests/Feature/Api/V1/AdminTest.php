<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Models\AuditLog;
use App\Models\Business;
use App\Models\BusinessUser;
use App\Models\Delivery;
use App\Models\Driver;
use App\Models\DriverPayout;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Painel administrativo (docs/docs/api/41-admin-api.md):
 * permissões (403 para driver/business) e fluxos felizes por módulo.
 */
class AdminTest extends TestCase
{
    use RefreshDatabase;

    private function createAdminUser(): User
    {
        $user = User::factory()->create();
        $user->assignRole('admin');

        return $user;
    }

    private function createBusinessUser(): User
    {
        $user = User::factory()->withRole('business')->create();

        $business = Business::create([
            'legal_name' => 'Loja Teste LTDA',
            'trade_name' => 'Loja Teste',
            'document_number' => '11'.str_pad((string) random_int(0, 999999999999), 12, '0', STR_PAD_LEFT),
            'status' => 'ACTIVE',
        ]);

        BusinessUser::create([
            'business_id' => $business->id,
            'user_id' => $user->id,
            'role' => 'OWNER',
            'status' => 'ACTIVE',
        ]);

        return $user;
    }

    private function createDriverUser(array $overrides = []): User
    {
        $user = User::factory()->withRole('driver')->create();

        Driver::create(array_merge([
            'user_id' => $user->id,
            'national_document' => '1234567890'.Str::random(1),
            'approval_status' => 'APPROVED',
            'operational_status' => 'AVAILABLE',
        ], $overrides));

        return $user;
    }

    private function createPendingDriver(): User
    {
        $user = $this->createDriverUser([
            'approval_status' => 'PENDING',
            'operational_status' => 'OFFLINE',
        ]);
        $driver = $user->drivers()->first();

        $driver->documents()->create([
            'document_type' => 'CNH',
            'document_number' => '12345678901',
            'object_key' => 'documents/cnh-front.jpg',
            'verification_status' => 'PENDING',
        ]);
        $driver->documents()->create([
            'document_type' => 'SELFIE',
            'object_key' => 'documents/selfie.jpg',
            'verification_status' => 'PENDING',
        ]);
        $driver->vehicles()->create([
            'vehicle_type' => 'MOTORCYCLE',
            'plate' => 'ABC1D23',
            'status' => 'ACTIVE',
        ]);

        return $user;
    }

    private function createOpenDelivery(User $businessUser, array $attributes = []): Delivery
    {
        return Delivery::create(array_merge([
            'business_id' => $businessUser->businesses()->first()->id,
            'status' => 'OPEN',
            'pricing_mode' => 'CALCULATED',
            'currency' => 'BRL',
            'suggested_amount' => '25.00',
            'origin_snapshot' => ['address' => 'Rua A, 100', 'latitude' => -20.3155, 'longitude' => -40.3128],
            'destination_snapshot' => ['address' => 'Rua B, 200', 'latitude' => -20.3200, 'longitude' => -40.3000],
            'recipient_name' => 'João da Silva',
            'recipient_phone' => '27999999999',
            'published_at' => now(),
        ], $attributes));
    }

    private function createCapturedPayment(Delivery $delivery, string $amount = '25.00'): Payment
    {
        return Payment::create([
            'delivery_id' => $delivery->id,
            'payer_type' => 'business',
            'payer_id' => $delivery->business_id,
            'provider' => 'MOCK',
            'amount' => $amount,
            'currency' => 'BRL',
            'status' => 'CAPTURED',
            'captured_at' => now(),
        ]);
    }

    // ========================================================================
    // Permissões
    // ========================================================================

    #[Test]
    public function unauthenticated_requests_are_rejected(): void
    {
        $this->getJson('/api/v1/admin/metrics')->assertUnauthorized();
        $this->getJson('/api/v1/admin/drivers/pending')->assertUnauthorized();
    }

    #[Test]
    public function driver_and_business_cannot_access_admin_list_routes(): void
    {
        $business = $this->createBusinessUser();
        $driver = $this->createDriverUser();

        $listRoutes = [
            '/api/v1/admin/metrics',
            '/api/v1/admin/drivers/pending',
            '/api/v1/admin/deliveries',
            '/api/v1/admin/payments',
            '/api/v1/admin/refunds',
            '/api/v1/admin/payouts',
            '/api/v1/admin/audit-logs',
        ];

        foreach ([$business, $driver] as $user) {
            foreach ($listRoutes as $route) {
                $this->actingAs($user, 'sanctum')->getJson($route)->assertForbidden();
            }
        }
    }

    #[Test]
    public function driver_and_business_cannot_execute_admin_actions(): void
    {
        $business = $this->createBusinessUser();
        $pending = $this->createPendingDriver();
        $delivery = $this->createOpenDelivery($business);
        $payment = $this->createCapturedPayment($delivery);
        $approvedDriver = $this->createDriverUser();

        $pendingDriverId = $pending->drivers()->first()->id;
        $approvedDriverId = $approvedDriver->drivers()->first()->id;

        $actionRoutes = [
            "/api/v1/admin/drivers/{$pendingDriverId}/approve",
            "/api/v1/admin/drivers/{$pendingDriverId}/reject",
            "/api/v1/admin/drivers/{$pendingDriverId}/suspend",
            "/api/v1/admin/deliveries/{$delivery->id}/assign",
            "/api/v1/admin/deliveries/{$delivery->id}/cancel",
            '/api/v1/admin/refunds',
        ];

        foreach ([$business, $approvedDriver] as $user) {
            foreach ($actionRoutes as $route) {
                $this->actingAs($user, 'sanctum')
                    ->postJson($route, [
                        'driver_id' => $approvedDriverId,
                        'reason' => 'teste',
                        'payment_id' => $payment->id,
                        'amount' => '5.00',
                    ])
                    ->assertForbidden();
            }
        }
    }

    // ========================================================================
    // Dashboard / métricas
    // ========================================================================

    #[Test]
    public function admin_can_read_dashboard_metrics(): void
    {
        $admin = $this->createAdminUser();
        $business = $this->createBusinessUser();
        $this->createOpenDelivery($business);
        $delivery = $this->createOpenDelivery($business);
        $this->createCapturedPayment($delivery, '25.00');
        $this->createPendingDriver();
        $online = $this->createDriverUser(['operational_status' => 'ONLINE']);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/metrics')
            ->assertOk()
            ->assertJsonPath('data.deliveries_today', 2)
            ->assertJsonPath('data.revenue', '25.00')
            ->assertJsonPath('data.drivers_online', 1)
            ->assertJsonPath('data.pending_drivers', 1);
    }

    // ========================================================================
    // Gestão de motoboys
    // ========================================================================

    #[Test]
    public function admin_can_list_pending_drivers_with_documents_and_vehicle(): void
    {
        $admin = $this->createAdminUser();
        $this->createPendingDriver();
        $this->createDriverUser(); // aprovado — não deve aparecer na fila

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/drivers/pending')
            ->assertOk()
            ->assertJsonCount(1, 'data.drivers')
            ->assertJsonPath('data.pagination.total', 1)
            ->assertJsonStructure([
                'data' => ['drivers' => [['user', 'documents', 'vehicle']], 'pagination'],
            ]);
    }

    #[Test]
    public function admin_can_approve_driver(): void
    {
        $admin = $this->createAdminUser();
        $pending = $this->createPendingDriver();
        $driverId = $pending->drivers()->first()->id;

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/drivers/{$driverId}/approve")
            ->assertOk()
            ->assertJsonPath('data.driver.approval_status', 'APPROVED');

        $this->assertDatabaseHas('drivers', ['id' => $driverId, 'approval_status' => 'APPROVED']);
        $this->assertDatabaseHas('driver_documents', ['verification_status' => 'VERIFIED']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'DRIVER_APPROVED', 'entity_type' => 'driver']);
    }

    #[Test]
    public function admin_can_reject_driver_with_reason(): void
    {
        $admin = $this->createAdminUser();
        $pending = $this->createPendingDriver();
        $driverId = $pending->drivers()->first()->id;

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/drivers/{$driverId}/reject", ['reason' => 'Documento vencido.'])
            ->assertOk()
            ->assertJsonPath('data.driver.approval_status', 'REJECTED');

        $this->assertDatabaseHas('drivers', [
            'id' => $driverId,
            'approval_status' => 'REJECTED',
            'rejection_reason' => 'Documento vencido.',
        ]);
        $this->assertDatabaseHas('audit_logs', ['action' => 'DRIVER_REJECTED']);
    }

    #[Test]
    public function reject_requires_a_reason(): void
    {
        $admin = $this->createAdminUser();
        $pending = $this->createPendingDriver();
        $driverId = $pending->drivers()->first()->id;

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/drivers/{$driverId}/reject")
            ->assertUnprocessable();
    }

    #[Test]
    public function admin_can_suspend_driver(): void
    {
        $admin = $this->createAdminUser();
        $driver = $this->createDriverUser(['operational_status' => 'ONLINE']);
        $driverId = $driver->drivers()->first()->id;

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/drivers/{$driverId}/suspend")
            ->assertOk()
            ->assertJsonPath('data.driver.operational_status', 'SUSPENDED');

        $this->assertDatabaseHas('drivers', ['id' => $driverId, 'operational_status' => 'SUSPENDED']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'DRIVER_SUSPENDED']);
    }

    // ========================================================================
    // Torre de controle de entregas
    // ========================================================================

    #[Test]
    public function admin_can_filter_deliveries(): void
    {
        $admin = $this->createAdminUser();
        $business = $this->createBusinessUser();
        $delivered = $this->createOpenDelivery($business, ['status' => 'DELIVERED', 'recipient_name' => 'Maria Lima']);
        $open = $this->createOpenDelivery($business);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/deliveries?status=OPEN')
            ->assertOk()
            ->assertJsonCount(1, 'data.deliveries')
            ->assertJsonPath('data.deliveries.0.id', $open->id);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/deliveries?search=Maria')
            ->assertOk()
            ->assertJsonCount(1, 'data.deliveries')
            ->assertJsonPath('data.deliveries.0.id', $delivered->id);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/deliveries?business_id='.$business->businesses()->first()->id)
            ->assertOk()
            ->assertJsonCount(2, 'data.deliveries');
    }

    #[Test]
    public function admin_can_assign_delivery_to_an_approved_driver(): void
    {
        $admin = $this->createAdminUser();
        $business = $this->createBusinessUser();
        $delivery = $this->createOpenDelivery($business);
        $driver = $this->createDriverUser();
        $driverId = $driver->drivers()->first()->id;

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/deliveries/{$delivery->id}/assign", ['driver_id' => $driverId])
            ->assertOk()
            ->assertJsonPath('data.delivery.status', 'ASSIGNED')
            ->assertJsonPath('data.delivery.current_driver_id', $driverId);

        $this->assertDatabaseHas('delivery_assignments', [
            'delivery_id' => $delivery->id,
            'driver_id' => $driverId,
            'source_type' => 'ADMIN',
            'status' => 'ACTIVE',
        ]);
        $this->assertDatabaseHas('delivery_events', ['event_type' => 'ADMIN_ASSIGNED']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'DELIVERY_ASSIGNED']);
    }

    #[Test]
    public function admin_cannot_assign_an_unapproved_driver(): void
    {
        $admin = $this->createAdminUser();
        $business = $this->createBusinessUser();
        $delivery = $this->createOpenDelivery($business);
        $pending = $this->createPendingDriver();
        $pendingDriverId = $pending->drivers()->first()->id;

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/deliveries/{$delivery->id}/assign", ['driver_id' => $pendingDriverId])
            ->assertUnprocessable();

        $this->assertDatabaseCount('delivery_assignments', 0);
    }

    #[Test]
    public function admin_can_cancel_delivery_with_refund_type(): void
    {
        $admin = $this->createAdminUser();
        $business = $this->createBusinessUser();
        $delivery = $this->createOpenDelivery($business);

        $this->actingAs($admin, 'sanctum')
            ->postJson("/api/v1/admin/deliveries/{$delivery->id}/cancel", [
                'reason' => 'Fraude identificada.',
                'refund_type' => 'FULL',
            ])
            ->assertOk()
            ->assertJsonPath('data.delivery.status', 'CANCELLED');

        $this->assertDatabaseHas('delivery_cancellations', [
            'delivery_id' => $delivery->id,
            'cancelled_by_type' => 'admin',
            'financial_resolution' => 'FULL',
        ]);
        $this->assertDatabaseHas('delivery_events', ['event_type' => 'DELIVERY_CANCELLED']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'DELIVERY_CANCELLED']);
    }

    // ========================================================================
    // Financeiro, reembolsos e repasses
    // ========================================================================

    #[Test]
    public function admin_can_list_payments(): void
    {
        $admin = $this->createAdminUser();
        $business = $this->createBusinessUser();
        $delivery = $this->createOpenDelivery($business);
        $payment = $this->createCapturedPayment($delivery);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/payments')
            ->assertOk()
            ->assertJsonCount(1, 'data.payments')
            ->assertJsonPath('data.payments.0.id', $payment->id)
            ->assertJsonPath('data.payments.0.status', 'CAPTURED');
    }

    #[Test]
    public function admin_can_create_a_partial_refund(): void
    {
        $admin = $this->createAdminUser();
        $business = $this->createBusinessUser();
        $delivery = $this->createOpenDelivery($business);
        $payment = $this->createCapturedPayment($delivery);

        $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/refunds', [
                'payment_id' => $payment->id,
                'amount' => '10.00',
                'reason' => 'Cancelamento parcial.',
            ])
            ->assertCreated()
            ->assertJsonPath('data.refund.amount', '10.00')
            ->assertJsonPath('data.refund.status', 'PENDING');

        $this->assertDatabaseHas('refunds', ['payment_id' => $payment->id, 'amount' => '10.00']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'REFUND_CREATED']);
    }

    #[Test]
    public function refund_cannot_exceed_the_remaining_amount(): void
    {
        $admin = $this->createAdminUser();
        $business = $this->createBusinessUser();
        $delivery = $this->createOpenDelivery($business);
        $payment = $this->createCapturedPayment($delivery, '25.00');

        // Total (25.00) é permitido.
        $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/refunds', [
                'payment_id' => $payment->id,
                'amount' => '25.00',
                'reason' => 'Reembolso total.',
            ])
            ->assertCreated();

        // Saldo restante = 0 → novo reembolso deve falhar.
        $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/admin/refunds', [
                'payment_id' => $payment->id,
                'amount' => '5.00',
                'reason' => 'Excedente.',
            ])
            ->assertUnprocessable();
    }

    #[Test]
    public function admin_can_list_payouts(): void
    {
        $admin = $this->createAdminUser();
        $driver = $this->createDriverUser();
        $business = $this->createBusinessUser();
        $delivery = $this->createOpenDelivery($business);

        DriverPayout::create([
            'driver_id' => $driver->drivers()->first()->id,
            'delivery_id' => $delivery->id,
            'gross_amount' => '25.00',
            'platform_fee' => '2.50',
            'net_amount' => '22.50',
            'status' => 'PENDING',
        ]);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/payouts')
            ->assertOk()
            ->assertJsonCount(1, 'data.payouts')
            ->assertJsonPath('data.payouts.0.net_amount', '22.50');
    }

    // ========================================================================
    // Auditoria
    // ========================================================================

    #[Test]
    public function admin_can_filter_audit_logs(): void
    {
        $admin = $this->createAdminUser();

        AuditLog::create([
            'actor_type' => 'admin',
            'actor_id' => $admin->id,
            'action' => 'DRIVER_APPROVED',
            'entity_type' => 'driver',
            'metadata' => [],
            'occurred_at' => now(),
        ]);
        AuditLog::create([
            'actor_type' => 'admin',
            'actor_id' => $admin->id,
            'action' => 'DELIVERY_CANCELLED',
            'entity_type' => 'delivery',
            'metadata' => [],
            'occurred_at' => now(),
        ]);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/audit-logs?action=DELIVERY_CANCELLED')
            ->assertOk()
            ->assertJsonCount(1, 'data.audit_logs')
            ->assertJsonPath('data.audit_logs.0.action', 'DELIVERY_CANCELLED');

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/audit-logs?entity_type=driver')
            ->assertOk()
            ->assertJsonCount(1, 'data.audit_logs');
    }
}
