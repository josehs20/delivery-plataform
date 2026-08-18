<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Enums;

enum DeliveryStatus: string
{
    case DRAFT = 'DRAFT';
    case OPEN = 'OPEN';
    case NEGOTIATING = 'NEGOTIATING';
    case ASSIGNED = 'ASSIGNED';
    case DRIVER_ACCEPTED = 'DRIVER_ACCEPTED';
    case GOING_TO_PICKUP = 'GOING_TO_PICKUP';
    case AT_PICKUP = 'AT_PICKUP';
    case PICKED_UP = 'PICKED_UP';
    case IN_TRANSIT = 'IN_TRANSIT';
    case AT_DESTINATION = 'AT_DESTINATION';
    case DELIVERED = 'DELIVERED';
    case DELIVERY_FAILED = 'DELIVERY_FAILED';
    case RETURN_REQUIRED = 'RETURN_REQUIRED';
    case RETURN_IN_PROGRESS = 'RETURN_IN_PROGRESS';
    case RETURNED = 'RETURNED';
    case CANCELLED = 'CANCELLED';
}
