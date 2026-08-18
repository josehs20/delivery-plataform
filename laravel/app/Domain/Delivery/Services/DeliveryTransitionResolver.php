<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Services;

use App\Domain\Delivery\Enums\DeliveryStatus;

/**
 * Resolves the ordered list of DeliveryStatus values that a driver action must
 * walk through, according to docs/domain/17-delivery-state-machine.md.
 *
 * The same mapping is used by the HTTP layer and by offline synchronization so
 * that both paths validate transitions identically.
 */
final class DeliveryTransitionResolver
{
    /**
     * @return array<int, DeliveryStatus>
     */
    public function targetStatesFor(string $action, DeliveryStatus $current): array
    {
        return match ($action) {
            'arrive-pickup' => match ($current) {
                // ASSIGNED is reached after the driver accepts an offer; the
                // driver then heads to the pickup point (walking through the
                // valid state-machine hops: ASSIGNED -> DRIVER_ACCEPTED -> ...).
                DeliveryStatus::ASSIGNED => [
                    DeliveryStatus::DRIVER_ACCEPTED,
                    DeliveryStatus::GOING_TO_PICKUP,
                    DeliveryStatus::AT_PICKUP,
                ],
                DeliveryStatus::DRIVER_ACCEPTED => [DeliveryStatus::GOING_TO_PICKUP, DeliveryStatus::AT_PICKUP],
                DeliveryStatus::GOING_TO_PICKUP => [DeliveryStatus::AT_PICKUP],
                default => [],
            },
            'pickup' => match ($current) {
                DeliveryStatus::AT_PICKUP => [DeliveryStatus::PICKED_UP],
                default => [],
            },
            'arrive-destination' => match ($current) {
                DeliveryStatus::PICKED_UP => [DeliveryStatus::IN_TRANSIT, DeliveryStatus::AT_DESTINATION],
                DeliveryStatus::IN_TRANSIT => [DeliveryStatus::AT_DESTINATION],
                default => [],
            },
            'complete' => match ($current) {
                DeliveryStatus::AT_DESTINATION => [DeliveryStatus::DELIVERED],
                DeliveryStatus::IN_TRANSIT => [DeliveryStatus::AT_DESTINATION, DeliveryStatus::DELIVERED],
                default => [],
            },
            'fail' => match ($current) {
                DeliveryStatus::PICKED_UP,
                DeliveryStatus::IN_TRANSIT,
                DeliveryStatus::AT_DESTINATION => [DeliveryStatus::DELIVERY_FAILED],
                default => [],
            },
            'return-start' => match ($current) {
                DeliveryStatus::DELIVERY_FAILED => [DeliveryStatus::RETURN_REQUIRED, DeliveryStatus::RETURN_IN_PROGRESS],
                DeliveryStatus::RETURN_REQUIRED => [DeliveryStatus::RETURN_IN_PROGRESS],
                default => [],
            },
            default => [],
        };
    }
}
