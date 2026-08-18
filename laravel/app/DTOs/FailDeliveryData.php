<?php

declare(strict_types=1);

namespace App\DTOs;

final readonly class FailDeliveryData
{
    public function __construct(
        public string $deliveryId,
        public string $reason,
        public ?string $description = null,
        public array $evidenceIds = [],
    ) {}
}
