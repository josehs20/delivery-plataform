<?php

declare(strict_types=1);

namespace App\DTOs;

final readonly class CreateCounterOfferData
{
    public function __construct(
        public string $deliveryId,
        public string $amount,
        public string $currency,
        public ?string $message = null,
    ) {}
}
