<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Enums;

enum PaymentStatus: string
{
    case PENDING = 'PENDING';
    case AUTHORIZED = 'AUTHORIZED';
    case CAPTURED = 'CAPTURED';
    case FAILED = 'FAILED';
    case CANCELLED = 'CANCELLED';
    case REFUNDED = 'REFUNDED';
    case PARTIALLY_REFUNDED = 'PARTIALLY_REFUNDED';
}
