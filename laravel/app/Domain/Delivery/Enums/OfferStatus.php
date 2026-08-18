<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Enums;

enum OfferStatus: string
{
    case PENDING = 'PENDING';
    case ACCEPTED = 'ACCEPTED';
    case REJECTED = 'REJECTED';
    case EXPIRED = 'EXPIRED';
    case CANCELLED = 'CANCELLED';
}
