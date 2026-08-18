<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Delivery\DeliveryStateMachine;
use App\Domain\Delivery\Enums\DeliveryStatus;
use App\Domain\Delivery\Exceptions\InvalidDeliveryStateTransitionException;
use PHPUnit\Framework\TestCase;

class DeliveryStateMachineTest extends TestCase
{
    /**
     * Test valid transitions in the nominal delivery flow.
     */
    public function test_nominal_flow_transitions_are_valid(): void
    {
        $flow = [
            DeliveryStatus::DRAFT,
            DeliveryStatus::OPEN,
            DeliveryStatus::ASSIGNED,
            DeliveryStatus::DRIVER_ACCEPTED,
            DeliveryStatus::GOING_TO_PICKUP,
            DeliveryStatus::AT_PICKUP,
            DeliveryStatus::PICKED_UP,
            DeliveryStatus::IN_TRANSIT,
            DeliveryStatus::AT_DESTINATION,
            DeliveryStatus::DELIVERED,
        ];

        for ($i = 0; $i < \count($flow) - 1; $i++) {
            $this->assertTrue(
                DeliveryStateMachine::canTransition($flow[$i], $flow[$i + 1]),
                sprintf(
                    'Expected transition from %s to %s to be valid',
                    $flow[$i]->value,
                    $flow[$i + 1]->value
                )
            );
        }
    }

    /**
     * Test negotiation path is valid.
     */
    public function test_negotiation_path_transitions_are_valid(): void
    {
        $flow = [
            DeliveryStatus::OPEN,
            DeliveryStatus::NEGOTIATING,
            DeliveryStatus::ASSIGNED,
        ];

        for ($i = 0; $i < \count($flow) - 1; $i++) {
            $this->assertTrue(
                DeliveryStateMachine::canTransition($flow[$i], $flow[$i + 1]),
                sprintf(
                    'Expected negotiation transition from %s to %s to be valid',
                    $flow[$i]->value,
                    $flow[$i + 1]->value
                )
            );
        }
    }

    /**
     * Test failure/return flow transitions are valid.
     */
    public function test_failure_and_return_flow_transitions_are_valid(): void
    {
        $flow = [
            DeliveryStatus::PICKED_UP,
            DeliveryStatus::DELIVERY_FAILED,
            DeliveryStatus::RETURN_REQUIRED,
            DeliveryStatus::RETURN_IN_PROGRESS,
            DeliveryStatus::RETURNED,
            DeliveryStatus::CANCELLED,
        ];

        for ($i = 0; $i < \count($flow) - 1; $i++) {
            $this->assertTrue(
                DeliveryStateMachine::canTransition($flow[$i], $flow[$i + 1]),
                sprintf(
                    'Expected failure/return transition from %s to %s to be valid',
                    $flow[$i]->value,
                    $flow[$i + 1]->value
                )
            );
        }
    }

    /**
     * Test that invalid transitions are rejected.
     */
    public function test_invalid_transitions_throw_exception(): void
    {
        $invalidTransitions = [
            [DeliveryStatus::DELIVERED, DeliveryStatus::OPEN],
            [DeliveryStatus::CANCELLED, DeliveryStatus::DRIVER_ACCEPTED],
            [DeliveryStatus::DRAFT, DeliveryStatus::DELIVERED],
            [DeliveryStatus::AT_PICKUP, DeliveryStatus::GOING_TO_PICKUP],
        ];

        foreach ($invalidTransitions as [$from, $to]) {
            $this->assertFalse(
                DeliveryStateMachine::canTransition($from, $to),
                sprintf(
                    'Expected transition from %s to %s to be invalid',
                    $from->value,
                    $to->value
                )
            );

            $this->expectException(InvalidDeliveryStateTransitionException::class);
            DeliveryStateMachine::validateTransition($from, $to);
        }
    }

    /**
     * Test getValidTransitions returns correct state collection.
     */
    public function test_get_valid_transitions_returns_correct_states(): void
    {
        $validFromOpen = DeliveryStateMachine::getValidTransitions(DeliveryStatus::OPEN);

        $this->assertCount(3, $validFromOpen);
        $this->assertTrue($validFromOpen->contains(DeliveryStatus::NEGOTIATING));
        $this->assertTrue($validFromOpen->contains(DeliveryStatus::ASSIGNED));
        $this->assertTrue($validFromOpen->contains(DeliveryStatus::CANCELLED));
    }

    /**
     * Test terminal state detection.
     */
    public function test_terminal_states_detection(): void
    {
        $this->assertTrue(DeliveryStateMachine::isTerminal(DeliveryStatus::DELIVERED));
        $this->assertTrue(DeliveryStateMachine::isTerminal(DeliveryStatus::CANCELLED));

        $this->assertFalse(DeliveryStateMachine::isTerminal(DeliveryStatus::OPEN));
        $this->assertFalse(DeliveryStateMachine::isTerminal(DeliveryStatus::IN_TRANSIT));
    }

    /**
     * Test successful delivery detection.
     */
    public function test_successful_delivery_detection(): void
    {
        $this->assertTrue(DeliveryStateMachine::isSuccessfulDelivery(DeliveryStatus::DELIVERED));
        $this->assertFalse(DeliveryStateMachine::isSuccessfulDelivery(DeliveryStatus::DELIVERY_FAILED));
        $this->assertFalse(DeliveryStateMachine::isSuccessfulDelivery(DeliveryStatus::CANCELLED));
    }

    /**
     * Test failure flow detection.
     */
    public function test_failure_flow_detection(): void
    {
        $failureStates = [
            DeliveryStatus::DELIVERY_FAILED,
            DeliveryStatus::RETURN_REQUIRED,
            DeliveryStatus::RETURN_IN_PROGRESS,
            DeliveryStatus::RETURNED,
        ];

        foreach ($failureStates as $status) {
            $this->assertTrue(
                DeliveryStateMachine::isFailureFlow($status),
                sprintf('Expected %s to be in failure flow', $status->value)
            );
        }

        $this->assertFalse(DeliveryStateMachine::isFailureFlow(DeliveryStatus::OPEN));
    }

    /**
     * Test cancellation detection.
     */
    public function test_cancellation_detection(): void
    {
        $this->assertTrue(DeliveryStateMachine::isCancelled(DeliveryStatus::CANCELLED));
        $this->assertFalse(DeliveryStateMachine::isCancelled(DeliveryStatus::OPEN));
        $this->assertFalse(DeliveryStateMachine::isCancelled(DeliveryStatus::DELIVERED));
    }

    /**
     * Test active delivery detection.
     */
    public function test_active_delivery_detection(): void
    {
        $activeStates = [
            DeliveryStatus::DRAFT,
            DeliveryStatus::OPEN,
            DeliveryStatus::NEGOTIATING,
            DeliveryStatus::ASSIGNED,
            DeliveryStatus::DRIVER_ACCEPTED,
            DeliveryStatus::GOING_TO_PICKUP,
            DeliveryStatus::AT_PICKUP,
            DeliveryStatus::PICKED_UP,
            DeliveryStatus::IN_TRANSIT,
            DeliveryStatus::AT_DESTINATION,
        ];

        foreach ($activeStates as $status) {
            $this->assertTrue(
                DeliveryStateMachine::isActive($status),
                sprintf('Expected %s to be active', $status->value)
            );
        }

        $inactiveStates = [
            DeliveryStatus::DELIVERED,
            DeliveryStatus::CANCELLED,
            DeliveryStatus::DELIVERY_FAILED,
        ];

        foreach ($inactiveStates as $status) {
            $this->assertFalse(
                DeliveryStateMachine::isActive($status),
                sprintf('Expected %s to be inactive', $status->value)
            );
        }
    }

    /**
     * Test cancellation is possible before pickup.
     */
    public function test_cancellation_before_pickup_is_allowed(): void
    {
        $prePickupStates = [
            DeliveryStatus::DRAFT,
            DeliveryStatus::OPEN,
            DeliveryStatus::NEGOTIATING,
            DeliveryStatus::ASSIGNED,
            DeliveryStatus::DRIVER_ACCEPTED,
        ];

        foreach ($prePickupStates as $status) {
            $this->assertTrue(
                DeliveryStateMachine::canTransition($status, DeliveryStatus::CANCELLED),
                sprintf('Expected cancellation from %s to be allowed', $status->value)
            );
        }
    }

    /**
     * Test direct assignment from OPEN (without negotiation).
     */
    public function test_direct_assignment_from_open(): void
    {
        $this->assertTrue(
            DeliveryStateMachine::canTransition(
                DeliveryStatus::OPEN,
                DeliveryStatus::ASSIGNED
            )
        );
    }
}
