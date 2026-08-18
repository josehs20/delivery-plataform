<?php

declare(strict_types=1);

namespace App\Domain\Delivery;

use App\Domain\Delivery\Enums\DeliveryStatus;
use App\Domain\Delivery\Exceptions\InvalidDeliveryStateTransitionException;
use Illuminate\Support\Collection;

final class DeliveryStateMachine
{
    /**
     * Defines valid transitions between delivery states.
     * Key is the source state, value is an array of allowed destination states.
     *
     * @var array<string, array<string>>
     */
    private static array $transitionMap = [
        // Initial creation and publishing
        DeliveryStatus::DRAFT->value => [
            DeliveryStatus::OPEN->value,
            DeliveryStatus::CANCELLED->value,
        ],

        // Open (awaiting acceptance)
        DeliveryStatus::OPEN->value => [
            DeliveryStatus::NEGOTIATING->value,  // timeout without direct acceptance
            DeliveryStatus::ASSIGNED->value,     // direct driver acceptance or admin assignment
            DeliveryStatus::CANCELLED->value,
        ],

        // Negotiation period
        DeliveryStatus::NEGOTIATING->value => [
            DeliveryStatus::ASSIGNED->value,     // counter-offer accepted by business
            DeliveryStatus::CANCELLED->value,
        ],

        // Assignment (driver selected, awaiting confirmation)
        DeliveryStatus::ASSIGNED->value => [
            DeliveryStatus::DRIVER_ACCEPTED->value,
            DeliveryStatus::CANCELLED->value,
        ],

        // Driver confirmed acceptance
        DeliveryStatus::DRIVER_ACCEPTED->value => [
            DeliveryStatus::GOING_TO_PICKUP->value,
            DeliveryStatus::CANCELLED->value,
        ],

        // Driver heading to pickup location
        DeliveryStatus::GOING_TO_PICKUP->value => [
            DeliveryStatus::AT_PICKUP->value,
            DeliveryStatus::CANCELLED->value,
        ],

        // Driver arrived at pickup
        DeliveryStatus::AT_PICKUP->value => [
            DeliveryStatus::PICKED_UP->value,
            DeliveryStatus::CANCELLED->value,
        ],

        // Items picked up, heading to destination
        DeliveryStatus::PICKED_UP->value => [
            DeliveryStatus::IN_TRANSIT->value,
            DeliveryStatus::DELIVERY_FAILED->value,
            DeliveryStatus::CANCELLED->value,
        ],

        // In transit to destination
        DeliveryStatus::IN_TRANSIT->value => [
            DeliveryStatus::AT_DESTINATION->value,
            DeliveryStatus::DELIVERY_FAILED->value,
            DeliveryStatus::CANCELLED->value,
        ],

        // Driver arrived at destination
        DeliveryStatus::AT_DESTINATION->value => [
            DeliveryStatus::DELIVERED->value,
            DeliveryStatus::DELIVERY_FAILED->value,
            DeliveryStatus::CANCELLED->value,
        ],

        // Delivery completed with proof
        DeliveryStatus::DELIVERED->value => [],

        // Delivery attempt failed
        DeliveryStatus::DELIVERY_FAILED->value => [
            DeliveryStatus::RETURN_REQUIRED->value,
            DeliveryStatus::CANCELLED->value,
        ],

        // Return of goods required
        DeliveryStatus::RETURN_REQUIRED->value => [
            DeliveryStatus::RETURN_IN_PROGRESS->value,
            DeliveryStatus::CANCELLED->value,
        ],

        // Return in execution
        DeliveryStatus::RETURN_IN_PROGRESS->value => [
            DeliveryStatus::RETURNED->value,
        ],

        // Return completed
        DeliveryStatus::RETURNED->value => [
            DeliveryStatus::CANCELLED->value,
        ],

        // Delivery cancelled
        DeliveryStatus::CANCELLED->value => [],
    ];

    /**
     * Check if a transition between two states is allowed.
     *
     * @throws InvalidDeliveryStateTransitionException
     */
    public static function validateTransition(DeliveryStatus $from, DeliveryStatus $to): void
    {
        if (! self::canTransition($from, $to)) {
            throw InvalidDeliveryStateTransitionException::fromTransition($from, $to);
        }
    }

    /**
     * Check if a transition between two states is allowed (boolean).
     */
    public static function canTransition(DeliveryStatus $from, DeliveryStatus $to): bool
    {
        $allowedTransitions = self::$transitionMap[$from->value] ?? [];

        return \in_array($to->value, $allowedTransitions, true);
    }

    /**
     * Get all valid destination states from a given source state.
     */
    public static function getValidTransitions(DeliveryStatus $from): Collection
    {
        $allowedValues = self::$transitionMap[$from->value] ?? [];

        return collect($allowedValues)
            ->map(static fn (string $value): DeliveryStatus => DeliveryStatus::from($value));
    }

    /**
     * Check if a state is a terminal state (no further transitions possible).
     */
    public static function isTerminal(DeliveryStatus $status): bool
    {
        $transitions = self::$transitionMap[$status->value] ?? [];

        return \count($transitions) === 0;
    }

    /**
     * Check if state is in the delivery success flow.
     */
    public static function isSuccessfulDelivery(DeliveryStatus $status): bool
    {
        return $status === DeliveryStatus::DELIVERED;
    }

    /**
     * Check if state indicates delivery failure/return flow.
     */
    public static function isFailureFlow(DeliveryStatus $status): bool
    {
        return \in_array($status, [
            DeliveryStatus::DELIVERY_FAILED,
            DeliveryStatus::RETURN_REQUIRED,
            DeliveryStatus::RETURN_IN_PROGRESS,
            DeliveryStatus::RETURNED,
        ], true);
    }

    /**
     * Check if state indicates cancellation.
     */
    public static function isCancelled(DeliveryStatus $status): bool
    {
        return $status === DeliveryStatus::CANCELLED;
    }

    /**
     * Check if delivery is still active (not terminal or failed).
     */
    public static function isActive(DeliveryStatus $status): bool
    {
        return ! (
            self::isTerminal($status) ||
            self::isSuccessfulDelivery($status) ||
            self::isFailureFlow($status) ||
            self::isCancelled($status)
        );
    }
}
