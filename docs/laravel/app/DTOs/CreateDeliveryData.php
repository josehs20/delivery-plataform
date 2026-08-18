<?php

declare(strict_types=1);

namespace App\DTOs;

final readonly class CreateDeliveryData
{
    public function __construct(
        public array $origin,
        public array $destination,
        public array $recipient,
        public array $items,
        public array $pricing,
        public ?string $pickupDeadline,
    ) {}
}
