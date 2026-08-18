<?php

declare(strict_types=1);

namespace App\DTOs;

final readonly class CompleteDeliveryData
{
    public function __construct(
        public string $deliveryId,
        public ?string $recipientName = null,
        public array $evidenceIds = [],
        public ?string $notes = null,
    ) {}
}
