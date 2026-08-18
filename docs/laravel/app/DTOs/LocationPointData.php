<?php

declare(strict_types=1);

namespace App\DTOs;

final readonly class LocationPointData
{
    public function __construct(
        public float $latitude,
        public float $longitude,
        public ?float $accuracy,
        public ?float $speed,
        public ?float $heading,
        public string $recordedAt,
        public string $clientEventId,
    ) {}
}
