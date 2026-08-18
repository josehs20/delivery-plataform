<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Models\Business;
use App\Models\BusinessUser;
use App\Models\Delivery;
use App\Models\DeliveryOffer;
use App\Models\Driver;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Integration tests for the Delivery API (docs/api/44-api-testing.md).
 */
class DeliveryTest extends TestCase
{
    use RefreshDatabase;

    private function createBusinessUser(): User
    {
        $user = User::factory()->withRole('business')->create();

        $business = Business::create([
            'legal_name' => 'Loja Teste LTDA',
            'trade_name' => 'Loja Teste',
            // Unique per call: the businesses table has a unique index on document_number.
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

    private function createDriverUser(array $attributes = []): User
    {
        $user = User::factory()->withRole('driver')->create();

        Driver::create(array_merge([
            'user_id' => $user->id,
            'national_document' => '1234567890'.Str::random(1),
            'approval_status' => 'APPROVED',
            'operational_status' => 'AVAILABLE',
        ], $attributes));

        return $user;
    }

    /**
     * @param array<string, mixed> $overrides
     * @return array<string, mixed>
     */
    private function deliveryPayload(array $overrides = []): array
    {
        return array_merge([
            'origin' => ['address' => 'Rua A, 100', 'latitude' => -20.3155, 'longitude' => -40.3128],
            'destination' => ['address' => 'Rua B, 200', 'latitude' => -20.3200, 'longitude' => -40.3000],
            'recipient' => ['name' => 'João da Silva', 'phone' => '27999999999'],
            'items' => [
                ['name' => 'Caixa de produtos', 'category' => 'GENERAL', 'quantity' => 2, 'approximate_weight' => 5.0],
            ],
            'pricing' => ['mode' => 'CALCULATED'],
            'pickup_deadline' => now()->addHours(2)->format('Y-m-d\TH:i:s\Z'),
        ], $overrides);
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

    private function createPendingOffer(Delivery $delivery, User $driverUser, string $amount = '25.00'): DeliveryOffer
    {
        $driver = $driverUser->drivers()->first();

        return DeliveryOffer::create([
            'delivery_id' => $delivery->id,
            'driver_id' => $driver->id,
            'status' => 'PENDING',
            'offered_amount' => $amount,
            'available_until' => now()->addMinutes(15),
            'sent_at' => now(),
        ]);
    }

    #[Test]
    public function unauthenticated_requests_are_rejected(): void
    {
        $this->getJson('/api/v1/deliveries')->assertUnauthorized();
    }

    #[Test]
    public function business_can_create_delivery_in_draft_with_items(): void
    {
        $user = $this->createBusinessUser();

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/deliveries', $this->deliveryPayload())
            ->assertCreated()
            ->assertJsonPath('data.delivery.status', 'DRAFT');

        $this->assertDatabaseHas('deliveries', ['status' => 'DRAFT']);
        $this->assertDatabaseCount('delivery_items', 1);
        $this->assertDatabaseHas('delivery_events', ['event_type' => 'DELIVERY_CREATED']);
    }

    #[Test]
    public function driver_cannot_create_delivery(): void
    {
        $driver = $this->createDriverUser();

        $this->actingAs($driver, 'sanctum')
            ->postJson('/api/v1/deliveries', $this->deliveryPayload())
            ->assertForbidden();
    }

    #[Test]
    public function business_can_publish_and_cancel_delivery(): void
    {
        $user = $this->createBusinessUser();
        $delivery = $this->createOpenDelivery($user, ['status' => 'DRAFT']);

        $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/publish")
            ->assertOk()
            ->assertJsonPath('data.delivery.status', 'OPEN');

        $this->assertDatabaseHas('delivery_events', ['event_type' => 'DELIVERY_PUBLISHED']);

        $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/cancel", ['reason' => 'NO_LONGER_NEEDED'])
            ->assertOk()
            ->assertJsonPath('data.delivery.status', 'CANCELLED');

        $this->assertDatabaseHas('delivery_events', ['event_type' => 'DELIVERY_CANCELLED']);
    }

    #[Test]
    public function non_owner_business_cannot_cancel_other_delivery(): void
    {
        $owner = $this->createBusinessUser();
        $delivery = $this->createOpenDelivery($owner);
        $intruder = $this->createBusinessUser();

        $this->actingAs($intruder, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/cancel", ['reason' => 'NO_LONGER_NEEDED'])
            ->assertForbidden();
    }

    #[Test]
    public function driver_accepts_and_completes_delivery_with_proof(): void
    {
        $businessUser = $this->createBusinessUser();
        $driverUser = $this->createDriverUser();
        $driver = $driverUser->drivers()->first();

        $delivery = $this->createOpenDelivery($businessUser);
        $this->createPendingOffer($delivery, $driverUser);

        // Each retryable operation must use its own idempotency key (ADR-005),
        // otherwise the middleware returns the cached response of the first call.
        $acceptKey = (string) Str::uuid();
        $arriveKey = (string) Str::uuid();
        $pickupKey = (string) Str::uuid();
        $destinationKey = (string) Str::uuid();
        $completeKey = (string) Str::uuid();

        // Accept (OPEN -> ASSIGNED)
        $this->actingAs($driverUser, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/accept", [
                'offer_id' => $delivery->offers()->first()->id,
                'idempotency_key' => $acceptKey,
            ])
            ->assertOk()
            ->assertJsonPath('data.delivery.status', 'ASSIGNED');

        $this->assertDatabaseHas('delivery_assignments', [
            'delivery_id' => $delivery->id,
            'driver_id' => $driver->id,
            'status' => 'ACTIVE',
        ]);

        // arrive-pickup (walks DRIVER_ACCEPTED -> GOING_TO_PICKUP -> AT_PICKUP)
        $this->actingAs($driverUser, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/arrive-pickup", ['idempotency_key' => $arriveKey])
            ->assertOk()
            ->assertJsonPath('data.delivery.status', 'AT_PICKUP');

        // pickup
        $this->actingAs($driverUser, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/pickup", ['idempotency_key' => $pickupKey])
            ->assertOk()
            ->assertJsonPath('data.delivery.status', 'PICKED_UP');

        // arrive-destination (walks PICKED_UP -> IN_TRANSIT -> AT_DESTINATION)
        $this->actingAs($driverUser, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/arrive-destination", ['idempotency_key' => $destinationKey])
            ->assertOk()
            ->assertJsonPath('data.delivery.status', 'AT_DESTINATION');

        // complete with proof
        $this->actingAs($driverUser, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/complete", [
                'idempotency_key' => $completeKey,
                'proof' => ['type' => 'PHOTO', 'data' => 'evidence-object-key-123'],
            ])
            ->assertOk()
            ->assertJsonPath('data.delivery.status', 'DELIVERED');

        $this->assertDatabaseHas('delivery_evidences', ['evidence_type' => 'PHOTO']);
        $this->assertDatabaseHas('delivery_events', ['event_type' => 'DELIVERY_DELIVERED']);
    }

    #[Test]
    public function complete_requires_proof_of_delivery(): void
    {
        $businessUser = $this->createBusinessUser();
        $driverUser = $this->createDriverUser();
        $delivery = $this->createOpenDelivery($businessUser);
        $this->createPendingOffer($delivery, $driverUser);

        $this->actingAs($driverUser, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/accept", [
                'offer_id' => $delivery->offers()->first()->id,
                'idempotency_key' => (string) Str::uuid(),
            ])
            ->assertOk();

        $this->actingAs($driverUser, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/complete", [
                'idempotency_key' => (string) Str::uuid(),
            ])
            ->assertUnprocessable();
    }

    #[Test]
    public function only_one_driver_can_win_a_delivery(): void
    {
        $businessUser = $this->createBusinessUser();
        $driverOne = $this->createDriverUser();
        $driverTwo = $this->createDriverUser(['national_document' => '99988877766']);
        $delivery = $this->createOpenDelivery($businessUser);
        $this->createPendingOffer($delivery, $driverOne);
        $this->createPendingOffer($delivery, $driverTwo);

        $this->actingAs($driverOne, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/accept", [
                'offer_id' => $delivery->offers()->where('driver_id', $driverOne->drivers()->first()->id)->first()->id,
                'idempotency_key' => (string) Str::uuid(),
            ])
            ->assertOk()
            ->assertJsonPath('data.delivery.status', 'ASSIGNED');

        $this->actingAs($driverTwo, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/accept", [
                'offer_id' => $delivery->offers()->where('driver_id', $driverTwo->drivers()->first()->id)->first()->id,
                'idempotency_key' => (string) Str::uuid(),
            ])
            ->assertUnprocessable();
    }

    #[Test]
    public function invalid_state_transition_is_rejected(): void
    {
        $businessUser = $this->createBusinessUser();
        $delivery = $this->createOpenDelivery($businessUser);

        // A driver without an active assignment cannot transition the delivery.
        $driverUser = $this->createDriverUser();

        $this->actingAs($driverUser, 'sanctum')
            ->postJson("/api/v1/deliveries/{$delivery->id}/pickup", [
                'idempotency_key' => (string) Str::uuid(),
            ])
            // A driver without an active assignment is denied by the policy
            // (can:transition-delivery) before any business validation.
            ->assertForbidden();
    }

    #[Test]
    public function business_can_list_own_deliveries(): void
    {
        $user = $this->createBusinessUser();
        $this->createOpenDelivery($user);

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/deliveries')
            ->assertOk()
            ->assertJsonCount(1, 'data.deliveries');
    }

    #[Test]
    public function sync_requires_driver_role(): void
    {
        $businessUser = $this->createBusinessUser();

        $this->actingAs($businessUser, 'sanctum')
            ->postJson('/api/v1/sync', [
                'sync_token' => (string) Str::uuid(),
                'operations' => [
                    [
                        'id' => (string) Str::uuid(),
                        'idempotency_key' => (string) Str::uuid(),
                        'entity' => 'location',
                        'operation' => 'CREATE',
                        'payload' => ['delivery_id' => (string) Str::ulid(), 'latitude' => -20.3, 'longitude' => -40.3],
                        'created_at' => now()->toIso8601String(),
                    ],
                ],
            ])
            ->assertForbidden();
    }


}
