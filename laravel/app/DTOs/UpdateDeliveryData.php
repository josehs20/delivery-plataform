<?php

declare(strict_types=1);

namespace App\DTOs;

final readonly class UpdateDeliveryData
{
    public function __construct(
        public string $deliveryId,
        public ?array $origin = null,
        public ?array $destination = null,
        public ?array $recipient = null,
        public ?array $items = null,
        public ?array $pricing = null,
        public ?string $pickupDeadline = null,
    ) {}
}
