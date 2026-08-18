<?php

declare(strict_types=1);

namespace App\DTOs;

final readonly class SyncOperationData
{
    public function __construct(
        public string $operationId,
        public string $deviceId,
        public string $entityType,
        public string $entityId,
        public string $operationType,
        public string $clientCreatedAt,
        public ?int $clientSequence,
        public array $payload,
    ) {}
}
