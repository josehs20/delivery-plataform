<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Exceptions;

use App\Domain\Delivery\Enums\DeliveryStatus;
use Exception;

final class InvalidDeliveryStateTransitionException extends Exception
{
    public static function fromTransition(DeliveryStatus $from, DeliveryStatus $to): self
    {
        return new self(
            sprintf(
                'Invalid delivery state transition: %s → %s',
                $from->value,
                $to->value
            )
        );
    }

    public static function withContext(
        DeliveryStatus $from,
        DeliveryStatus $to,
        string $reason
    ): self {
        return new self(
            sprintf(
                'Invalid delivery state transition: %s → %s. Reason: %s',
                $from->value,
                $to->value,
                $reason
            )
        );
    }
}
