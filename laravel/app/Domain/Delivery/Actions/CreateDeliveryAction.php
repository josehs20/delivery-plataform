<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Actions;

use App\Domain\Delivery\Enums\DeliveryStatus;
use App\DTOs\CreateDeliveryData;
use App\Models\Delivery;
use App\Models\DeliveryEvent;
use Illuminate\Support\Facades\DB;

/**
 * CreateDeliveryAction
 *
 * Orchestrates delivery creation (ADR-004 transaction boundary):
 * - computes pricing from the provided mode (CALCULATED or MANUAL);
 * - persists the delivery, its items and the initial audit event;
 * - returns the created delivery.
 */
final class CreateDeliveryAction
{
    /**
     * @throws \Throwable
     */
    public function execute(CreateDeliveryData $data, string $businessId): Delivery
    {
        return DB::transaction(function () use ($data, $businessId): Delivery {
            $pricing = $this->calculatePricing($data->pricing, $data->origin, $data->destination);

            $delivery = Delivery::create([
                'business_id' => $businessId,
                'status' => DeliveryStatus::DRAFT->value,
                'pricing_mode' => $pricing['mode'],
                'currency' => $pricing['currency'],
                'suggested_amount' => $pricing['suggested_amount'],
                'merchant_offered_amount' => $pricing['merchant_offered_amount'],
                'origin_snapshot' => $data->origin,
                'destination_snapshot' => $data->destination,
                'recipient_name' => $data->recipient['name'] ?? null,
                'recipient_phone' => $data->recipient['phone'] ?? null,
                'recipient_reference' => $data->recipient['reference'] ?? null,
                'pickup_deadline' => $data->pickupDeadline,
            ]);

            foreach ($data->items as $item) {
                $delivery->items()->create([
                    'name' => $item['name'],
                    'description' => $item['description'] ?? null,
                    'category' => $item['category'] ?? null,
                    'quantity' => (int) ($item['quantity'] ?? 1),
                    'approximate_weight' => $item['approximate_weight'] ?? null,
                    'dimensions' => $item['dimensions'] ?? null,
                    'special_handling' => $item['special_handling'] ?? null,
                    'notes' => $item['notes'] ?? null,
                ]);
            }

            $this->createDeliveryEvent(
                deliveryId: $delivery->id,
                eventType: 'DELIVERY_CREATED',
                actorType: 'BUSINESS',
                actorId: $businessId,
                source: 'API',
                metadata: [
                    'items_count' => \count($data->items),
                    'pricing_mode' => $pricing['mode'],
                    'pricing_breakdown' => $pricing['breakdown'],
                ]
            );

            return $delivery;
        });
    }

    /**
     * Calculate pricing based on the configured mode.
     *
     * - CALCULATED: base fee + per-km rate over the haversine distance
     *   (docs/domain/06-pricing-and-negotiation.md; values in config/delivery.php).
     * - MANUAL: the merchant informs the value directly.
     *
     * @param array<string, mixed> $pricingData
     * @param array<string, mixed> $origin
     * @param array<string, mixed> $destination
     * @return array<string, mixed>
     */
    private function calculatePricing(array $pricingData, array $origin, array $destination): array
    {
        $mode = strtoupper((string) ($pricingData['mode'] ?? 'CALCULATED')) === 'MANUAL'
            ? 'MANUAL'
            : 'CALCULATED';

        $currency = (string) ($pricingData['currency'] ?? config('delivery.pricing.currency', 'BRL'));

        if ($mode === 'MANUAL') {
            $amount = $pricingData['amount'] ?? $pricingData['manual_value'] ?? null;

            return [
                'mode' => 'MANUAL',
                'currency' => $currency,
                'suggested_amount' => null,
                'merchant_offered_amount' => $amount !== null ? number_format((float) $amount, 2, '.', '') : null,
                'breakdown' => ['mode' => 'MANUAL'],
            ];
        }

        $distanceKm = $this->distanceKm($origin, $destination);
        $baseFee = (float) config('delivery.pricing.base_fee', 10.00);
        $perKm = (float) config('delivery.pricing.per_km', 1.50);
        $suggested = number_format($baseFee + ($perKm * $distanceKm), 2, '.', '');

        return [
            'mode' => 'CALCULATED',
            'currency' => $currency,
            'suggested_amount' => $suggested,
            'merchant_offered_amount' => null,
            'breakdown' => [
                'base_fee' => number_format($baseFee, 2, '.', ''),
                'per_km' => number_format($perKm, 2, '.', ''),
                'distance_km' => round($distanceKm, 2),
            ],
        ];
    }

    /**
     * Haversine distance in kilometers between two coordinate snapshots.
     *
     * @param array<string, mixed> $origin
     * @param array<string, mixed> $destination
     */
    private function distanceKm(array $origin, array $destination): float
    {
        $lat1 = (float) ($origin['latitude'] ?? 0);
        $lng1 = (float) ($origin['longitude'] ?? 0);
        $lat2 = (float) ($destination['latitude'] ?? 0);
        $lng2 = (float) ($destination['longitude'] ?? 0);

        if ($lat1 === 0.0 || $lng1 === 0.0 || $lat2 === 0.0 || $lng2 === 0.0) {
            return 0.0;
        }

        $earthRadiusKm = 6371.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return $earthRadiusKm * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    /**
     * Create an audit trail event for the delivery (ADR-008).
     *
     * @param array<string, mixed> $metadata
     */
    private function createDeliveryEvent(
        string $deliveryId,
        string $eventType,
        string $actorType,
        string $actorId,
        string $source,
        array $metadata = []
    ): DeliveryEvent {
        return DeliveryEvent::create([
            'delivery_id' => $deliveryId,
            'event_type' => $eventType,
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'source' => $source,
            'metadata' => $metadata,
            'occurred_at' => now(),
        ]);
    }

}
