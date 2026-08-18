<?php

declare(strict_types=1);

namespace App\DTOs;

final readonly class LocationPointData
{
    public function __construct(
        public float $latitude,
        public float $longitude,
        public ?float $accuracy = null,
        public ?float $speed = null,
        public ?float $heading = null,
        public ?string $recordedAt = null,
        public ?string $clientEventId = null,
    ) {}
}
