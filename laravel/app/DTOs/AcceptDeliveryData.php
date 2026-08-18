<?php

declare(strict_types=1);

namespace App\DTOs;

final readonly class AcceptDeliveryData
{
    public function __construct(
        public string $deliveryId,
        public string $idempotencyKey,
    ) {}
}
