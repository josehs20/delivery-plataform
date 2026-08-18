<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Business;
use App\Models\Delivery;
use App\Models\DeliveryCancellation;
use App\Models\DeliveryFailure;
use App\Models\DeliveryLocation;
use App\Models\DeliveryOffer;
use App\Models\Driver;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Dataset de entregas para o teste manual do app e da API.
 *
 * Cria um exemplo de entrega em cada estágio da máquina de estados
 * (docs/docs/domain/17-delivery-state-machine.md), com itens, endereços,
 * ofertas, atribuições, eventos de auditoria (ADR-008) e evidências
 * consistentes. Também grava a localização do motorista na região de coleta
 * (ADR-006), permitindo que o `publish` crie ofertas por proximidade.
 *
 * Idempotente: se o business já possui entregas, nada é criado novamente.
 */
class DeliveryFlowSeeder extends Seeder
{
    private const ORIGIN = [
        'address' => 'Rua da Padaria, 100 — Centro, Belo Horizonte/MG',
        'latitude' => -19.9167,
        'longitude' => -43.9345,
        'reference' => 'Portão lateral',
    ];

    private const DESTINATION = [
        'address' => 'Av. Amazonas, 1500 — Centro, Belo Horizonte/MG',
        'latitude' => -19.9250,
        'longitude' => -43.9400,
        'reference' => 'Recepção',
    ];

    /** Estados do fluxo nominal, em ordem — gera a trilha de eventos. */
    private const DRIVER_STATES = [
        'DRIVER_ACCEPTED',
        'GOING_TO_PICKUP',
        'AT_PICKUP',
        'PICKED_UP',
        'IN_TRANSIT',
        'AT_DESTINATION',
        'DELIVERED',
    ];

    public function run(): void
    {
        /** @var User $businessUser */
        $businessUser = User::where('email', 'test@example.com')->firstOrFail();
        /** @var Business $business */
        $business = $businessUser->businesses()->firstOrFail();

        if (Delivery::where('business_id', $business->id)->exists()) {
            $this->command?->info('DeliveryFlowSeeder: business já possui entregas — nada a fazer.');

            return;
        }

        /** @var User $driverUser */
        $driverUser = User::where('email', 'driver@example.com')->firstOrFail();
        /** @var Driver $driver */
        $driver = $driverUser->drivers()->firstOrFail();

        $this->seedDraft($business, $businessUser);
        $this->seedOpen($business, $businessUser, $driver);
        $this->seedAcceptedFlow($business, $businessUser, $driver, $driverUser);
        $this->seedTerminal($business, $businessUser, $driver, $driverUser);
    }

    private function seedDraft(Business $business, User $businessUser): void
    {
        $delivery = $this->createDelivery(
            business: $business,
            name: 'Entrega Rascunho — Padaria',
            status: 'DRAFT',
            pricingMode: 'CALCULATED',
            suggestedAmount: '15.00',
            recipient: ['name' => 'Carlos Souza', 'phone' => '+5531988880001'],
            items: [
                ['name' => 'Pão francês', 'category' => 'FROZEN', 'quantity' => 10, 'approximate_weight' => 1.5, 'notes' => 'Manter congelado.'],
                ['name' => 'Bolo de chocolate', 'category' => 'GENERAL', 'quantity' => 1, 'approximate_weight' => 2.0],
            ],
        );

        $this->addEvent($delivery, 'DELIVERY_CREATED', 'business', $businessUser->id, ['pricing_mode' => 'CALCULATED']);
    }

    private function seedOpen(Business $business, User $businessUser, Driver $driver): void
    {
        // OPEN com oferta PENDING do motorista (alvo do teste de aceite) +
        // localização do motorista na região de coleta (habilita o dispatch).
        $open = $this->createDelivery(
            business: $business,
            name: 'Entrega Aguardando Ofertas — Floricultura',
            status: 'OPEN',
            pricingMode: 'MANUAL',
            merchantOfferedAmount: '20.00',
            recipient: ['name' => 'Ana Lima', 'phone' => '+5531988880002'],
            items: [
                ['name' => 'Buquê de rosas', 'category' => 'GENERAL', 'quantity' => 1, 'approximate_weight' => 0.8],
            ],
        );
        $open->forceFill(['published_at' => now()->subMinutes(5)])->save();

        $this->addEvent($open, 'DELIVERY_CREATED', 'business', $businessUser->id, ['pricing_mode' => 'MANUAL']);
        $this->addEvent($open, 'DELIVERY_PUBLISHED', 'business', $businessUser->id);

        $this->addOffer($open, $driver, 'PENDING', '20.00');

        DeliveryLocation::create([
            'delivery_id' => $open->id,
            'driver_id' => $driver->id,
            'latitude' => -19.9165,
            'longitude' => -43.9340,
            'accuracy' => 5.0,
            'recorded_at' => now(),
            'received_at' => now(),
            'source' => 'SEED',
        ]);

        // OPEN sem oferta (controle — comércio vê entrega aguardando motoboy).
        $openNoOffer = $this->createDelivery(
            business: $business,
            name: 'Entrega Sem Ofertas — Livraria',
            status: 'OPEN',
            pricingMode: 'CALCULATED',
            suggestedAmount: '14.50',
            recipient: ['name' => 'Bruno Rocha', 'phone' => '+5531988880003'],
            items: [
                ['name' => 'Caixa de livros', 'category' => 'GENERAL', 'quantity' => 1, 'approximate_weight' => 5.0],
            ],
        );
        $openNoOffer->forceFill(['published_at' => now()->subMinutes(3)])->save();

        $this->addEvent($openNoOffer, 'DELIVERY_CREATED', 'business', $businessUser->id, ['pricing_mode' => 'CALCULATED']);
        $this->addEvent($openNoOffer, 'DELIVERY_PUBLISHED', 'business', $businessUser->id);
    }

    private function seedAcceptedFlow(Business $business, User $businessUser, Driver $driver, User $driverUser): void
    {
        $scenarios = [
            'DRIVER_ACCEPTED' => [
                'Entrega a Caminho da Coleta — Farmácia',
                ['name' => 'Débora Alves', 'phone' => '+5531988880004'],
                [['name' => 'Remédios controlados', 'category' => 'HAZMAT', 'quantity' => 2, 'approximate_weight' => 0.5]],
            ],
            'AT_PICKUP' => [
                'Entrega no Ponto de Coleta — Restaurante',
                ['name' => 'Eduardo Prado', 'phone' => '+5531988880005'],
                [['name' => 'Marmitas', 'category' => 'FROZEN', 'quantity' => 4, 'approximate_weight' => 6.0]],
            ],
            'PICKED_UP' => [
                'Entrega Coletada — Mercado',
                ['name' => 'Fátima Nunes', 'phone' => '+5531988880006'],
                [['name' => 'Cesta de mercado', 'category' => 'GENERAL', 'quantity' => 1, 'approximate_weight' => 8.5]],
            ],
            'IN_TRANSIT' => [
                'Entrega em Trânsito — Petshop',
                ['name' => 'Gustavo Reis', 'phone' => '+5531988880007'],
                [['name' => 'Ração 10kg', 'category' => 'GENERAL', 'quantity' => 2, 'approximate_weight' => 20.0]],
            ],
            'AT_DESTINATION' => [
                'Entrega no Destino — Eletrônicos',
                ['name' => 'Helena Ramos', 'phone' => '+5531988880008'],
                [['name' => 'Fone de ouvido', 'category' => 'FRAGILE', 'quantity' => 1, 'approximate_weight' => 0.3]],
            ],
        ];

        foreach ($scenarios as $status => [$name, $recipient, $items]) {
            $this->createAcceptedDelivery(
                business: $business,
                businessUser: $businessUser,
                driver: $driver,
                driverUser: $driverUser,
                name: $name,
                status: $status,
                amount: '18.50',
                recipient: $recipient,
                items: $items,
            );
        }
    }

    private function seedTerminal(Business $business, User $businessUser, Driver $driver, User $driverUser): void
    {
        // DELIVERED — fluxo nominal completo + evidência de assinatura.
        $this->createAcceptedDelivery(
            business: $business,
            businessUser: $businessUser,
            driver: $driver,
            driverUser: $driverUser,
            name: 'Entrega Entregue — Presentes',
            status: 'DELIVERED',
            amount: '22.00',
            recipient: ['name' => 'Igor Barros', 'phone' => '+5531988880009'],
            items: [
                ['name' => 'Kit de presentes', 'category' => 'FRAGILE', 'quantity' => 1, 'approximate_weight' => 1.2],
            ],
        );

        // CANCELLED — cancelamento pré-coleta com auditoria.
        $cancelled = $this->createDelivery(
            business: $business,
            name: 'Entrega Cancelada — Moda',
            status: 'CANCELLED',
            pricingMode: 'CALCULATED',
            suggestedAmount: '16.00',
            recipient: ['name' => 'Julia Campos', 'phone' => '+5531988880010'],
            items: [
                ['name' => 'Roupas (saco)', 'category' => 'GENERAL', 'quantity' => 1, 'approximate_weight' => 3.0],
            ],
        );
        $cancelled->forceFill(['cancelled_at' => now()->subHours(2)])->save();

        $this->addEvent($cancelled, 'DELIVERY_CREATED', 'business', $businessUser->id, ['pricing_mode' => 'CALCULATED']);
        $this->addEvent($cancelled, 'DELIVERY_CANCELLED', 'business', $businessUser->id, ['reason' => 'Cliente desistiu.']);

        DeliveryCancellation::create([
            'delivery_id' => $cancelled->id,
            'cancelled_by_type' => 'business',
            'cancelled_by_id' => $businessUser->id,
            'reason' => 'Cliente desistiu.',
            'description' => 'Pedido cancelado antes da coleta.',
            'financial_resolution' => 'NO_REFUND',
        ]);

        // DELIVERY_FAILED — falha após a coleta (devolução pendente).
        $failed = $this->createDelivery(
            business: $business,
            name: 'Entrega Falhou — Perfumaria',
            status: 'DELIVERY_FAILED',
            pricingMode: 'CALCULATED',
            suggestedAmount: '17.50',
            recipient: ['name' => 'Karla Mendes', 'phone' => '+5531988880011'],
            items: [
                ['name' => 'Perfume importado', 'category' => 'FRAGILE', 'quantity' => 1, 'approximate_weight' => 0.4],
            ],
        );
        $failed->forceFill([
            'current_driver_id' => $driver->id,
            'accepted_at' => now()->subHours(5),
            'accepted_amount' => '17.50',
            'picked_up_at' => now()->subHours(3),
        ])->save();

        $offer = $this->addOffer($failed, $driver, 'ACCEPTED', '17.50');
        $this->addAssignment($failed, $driver, $offer, '17.50');

        $this->addEvent($failed, 'DELIVERY_CREATED', 'business', $businessUser->id, ['pricing_mode' => 'CALCULATED']);
        $this->addEvent($failed, 'DELIVERY_PUBLISHED', 'business', $businessUser->id);
        $this->addEvent($failed, 'DELIVERY_ASSIGNED', 'driver', $driverUser->id, ['driver_id' => $driver->id, 'offer_id' => $offer->id]);
        foreach (['DELIVERY_DRIVER_ACCEPTED', 'DELIVERY_GOING_TO_PICKUP', 'DELIVERY_AT_PICKUP', 'DELIVERY_PICKED_UP'] as $eventType) {
            $this->addEvent($failed, $eventType, 'driver', $driverUser->id);
        }
        $this->addEvent($failed, 'DELIVERY_DELIVERY_FAILED', 'driver', $driverUser->id, ['reason' => 'Destinatário ausente.']);

        DeliveryFailure::create([
            'delivery_id' => $failed->id,
            'reason' => 'Destinatário ausente.',
            'description' => 'Três tentativas sem sucesso.',
            'reported_by_type' => 'driver',
            'reported_by_id' => $driver->id,
            'requires_return' => true,
            'resolution_status' => 'PENDING',
        ]);
    }

    /**
     * Cria uma entrega do fluxo nominal já aceita pelo motorista
     * (DRIVER_ACCEPTED → DELIVERED), com oferta ACCEPTED, atribuição ACTIVE e
     * trilha de eventos coerente com a máquina de estados.
     *
     * @param array<string, mixed> $recipient
     * @param array<int, array<string, mixed>> $items
     */
    private function createAcceptedDelivery(
        Business $business,
        User $businessUser,
        Driver $driver,
        User $driverUser,
        string $name,
        string $status,
        string $amount,
        array $recipient,
        array $items,
    ): Delivery {
        $delivery = $this->createDelivery(
            business: $business,
            name: $name,
            status: $status,
            pricingMode: 'CALCULATED',
            suggestedAmount: $amount,
            acceptedAmount: $amount,
            recipient: $recipient,
            items: $items,
        );

        $delivery->forceFill([
            'current_driver_id' => $driver->id,
            'accepted_at' => now()->subHours(6),
            'published_at' => now()->subHours(7),
        ])->save();

        if (in_array($status, ['PICKED_UP', 'IN_TRANSIT', 'AT_DESTINATION', 'DELIVERED'], true)) {
            $delivery->forceFill(['picked_up_at' => now()->subHours(4)])->save();
        }
        if ($status === 'DELIVERED') {
            $delivery->forceFill(['delivered_at' => now()->subHours(1)])->save();
        }

        $this->addEvent($delivery, 'DELIVERY_CREATED', 'business', $businessUser->id, ['pricing_mode' => 'CALCULATED']);
        $this->addEvent($delivery, 'DELIVERY_PUBLISHED', 'business', $businessUser->id);

        $offer = $this->addOffer($delivery, $driver, 'ACCEPTED', $amount);
        $this->addAssignment($delivery, $driver, $offer, $amount);

        $this->addEvent($delivery, 'DELIVERY_ASSIGNED', 'driver', $driverUser->id, ['driver_id' => $driver->id, 'offer_id' => $offer->id]);
        $this->addStatusChain($delivery, $status, $driverUser->id);

        if ($status === 'DELIVERED') {
            $delivery->evidences()->create([
                'evidence_type' => 'SIGNATURE',
                'object_key' => 'seed://signature/entrega-entregue.png',
                'captured_at' => now()->subHours(1),
                'captured_by_type' => 'driver',
                'captured_by_id' => $driver->id,
                'metadata' => ['source' => 'SEED'],
            ]);
        }

        return $delivery;
    }

    /**
     * @param array<string, mixed> $recipient
     * @param array<int, array<string, mixed>> $items
     */
    private function createDelivery(
        Business $business,
        string $name,
        string $status,
        string $pricingMode,
        ?string $suggestedAmount = null,
        ?string $merchantOfferedAmount = null,
        ?string $acceptedAmount = null,
        array $recipient = ['name' => 'Cliente', 'phone' => '+5531988880000'],
        array $items = [],
    ): Delivery {
        $delivery = Delivery::create([
            'business_id' => $business->id,
            'status' => $status,
            'pricing_mode' => $pricingMode,
            'currency' => 'BRL',
            'suggested_amount' => $suggestedAmount,
            'merchant_offered_amount' => $merchantOfferedAmount,
            'accepted_amount' => $acceptedAmount,
            'origin_snapshot' => self::ORIGIN,
            'destination_snapshot' => self::DESTINATION,
            'recipient_name' => (string) ($recipient['name'] ?? 'Cliente'),
            'recipient_phone' => (string) ($recipient['phone'] ?? '+5531988880000'),
            'recipient_reference' => isset($recipient['reference']) ? (string) $recipient['reference'] : null,
            'pickup_deadline' => now()->addHours(3),
        ]);

        foreach ($items as $item) {
            $delivery->items()->create([
                'name' => (string) $item['name'],
                'description' => isset($item['description']) ? (string) $item['description'] : null,
                'category' => (string) $item['category'],
                'quantity' => (int) ($item['quantity'] ?? 1),
                'approximate_weight' => isset($item['approximate_weight']) ? (float) $item['approximate_weight'] : null,
                'dimensions' => $item['dimensions'] ?? null,
                'special_handling' => isset($item['special_handling']) ? (string) $item['special_handling'] : null,
                'notes' => isset($item['notes']) ? (string) $item['notes'] : null,
            ]);
        }

        return $delivery;
    }

    private function addOffer(Delivery $delivery, Driver $driver, string $status, string $amount): DeliveryOffer
    {
        return DeliveryOffer::create([
            'delivery_id' => $delivery->id,
            'driver_id' => $driver->id,
            'status' => $status,
            'offered_amount' => $amount,
            'available_until' => now()->addMinutes(15),
            'sent_at' => now()->subMinutes(10),
            'responded_at' => $status === 'PENDING' ? null : now()->subHours(5),
        ]);
    }

    private function addAssignment(Delivery $delivery, Driver $driver, DeliveryOffer $offer, string $amount): void
    {
        $delivery->assignments()->create([
            'driver_id' => $driver->id,
            'source_type' => 'OFFER',
            'source_reference_id' => $offer->id,
            'agreed_amount' => $amount,
            'status' => 'ACTIVE',
            'assigned_at' => now()->subHours(6),
            'accepted_at' => now()->subHours(5),
        ]);
    }

    private function addStatusChain(Delivery $delivery, string $targetStatus, string $actorId): void
    {
        foreach (self::DRIVER_STATES as $state) {
            $this->addEvent($delivery, 'DELIVERY_'.$state, 'driver', $actorId);
            if ($state === $targetStatus) {
                break;
            }
        }
    }

    /**
     * @param array<string, mixed> $metadata
     */
    private function addEvent(Delivery $delivery, string $eventType, string $actorType, string $actorId, array $metadata = []): void
    {
        $delivery->events()->create([
            'event_type' => $eventType,
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'source' => 'SEED',
            'metadata' => $metadata,
            'occurred_at' => now(),
        ]);
    }
}
