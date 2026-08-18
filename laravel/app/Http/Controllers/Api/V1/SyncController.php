<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Domain\Delivery\DeliveryStateMachine;
use App\Domain\Delivery\Services\DeliveryTransitionResolver;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\SyncOperationsRequest;
use App\Models\Delivery;
use App\Models\DeliveryEvent;
use App\Models\DeliveryEvidence;
use App\Models\DeliveryLocation;
use App\Models\SyncOperation;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SyncController extends Controller
{
    public function __construct(
        private readonly DeliveryTransitionResolver $transitionResolver,
    ) {}

    /**
     * POST /api/v1/sync
     *
     * Processes the offline operation queue sent by a mobile driver when the
     * connection is recovered (ADR-002, docs/domain/11-offline-and-synchronization.md).
     *
     * Supported entities:
     * - delivery:  STATE_TRANSITION (arrive-pickup, pickup, arrive-destination, complete, fail)
     * - location:  CREATE/UPDATE  (GPS position)
     * - proof:     CREATE         (photo/signature evidence)
     * - event:     CREATE         (audit trail event)
     *
     * Idempotency (ADR-005): the unique (client_id, operation_id) constraint on
     * sync_operations guarantees a retried operation is never applied twice.
     * Failures are isolated per operation (partial batch processing).
     */
    public function sync(SyncOperationsRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();

        if (! $user->hasRole('driver')) {
            throw new AuthorizationException('Apenas motoristas podem sincronizar.');
        }

        $driver = $user->drivers()->first();

        if (! $driver) {
            throw new AuthorizationException('Motorista não encontrado.');
        }

        $operations = $request->input('operations');
        $deviceId = (string) ($request->header('X-Device-Id') ?? 'unknown');

        $results = [];

        DB::transaction(function () use (&$results, $operations, $driver, $user, $deviceId): void {
            $sorted = collect($operations)
                ->sortBy(fn (array $op): array => [
                    -($op['priority'] ?? 3), // Higher priority first.
                    $op['created_at'],
                ])
                ->values();

            foreach ($sorted as $operation) {
                $operationId = (string) $operation['id'];
                $entity = (string) $operation['entity'];
                $operationType = (string) $operation['operation'];
                $payload = $operation['payload'];
                $idempotencyKey = (string) $operation['idempotency_key'];

                // Idempotency: already-processed operations return the cached result.
                $existing = SyncOperation::where('client_id', $user->id)
                    ->where('operation_id', $operationId)
                    ->first();

                if ($existing) {
                    $results[] = [
                        'operation_id' => $operationId,
                        'status' => 'ALREADY_PROCESSED',
                        'idempotency_key' => $idempotencyKey,
                        'message' => 'Operação já foi processada.',
                    ];

                    continue;
                }

                $record = SyncOperation::create([
                    'client_id' => $user->id,
                    'device_id' => $deviceId,
                    'operation_id' => $operationId,
                    'entity_type' => $entity,
                    'entity_id' => (string) ($payload['delivery_id'] ?? $payload['id'] ?? ''),
                    'operation_type' => $operationType,
                    'payload' => $payload,
                    'client_created_at' => $operation['created_at'],
                    'received_at' => now(),
                    'status' => 'PENDING',
                    'retry_count' => 0,
                ]);

                try {
                    $result = $this->processOperation(
                        entity: $entity,
                        operation: $operationType,
                        payload: $payload,
                        driver: $driver,
                        user: $user,
                        idempotencyKey: $idempotencyKey,
                    );

                    $record->update([
                        'status' => 'PROCESSED',
                        'processed_at' => now(),
                    ]);

                    $results[] = [
                        'operation_id' => $operationId,
                        'status' => 'PROCESSED',
                        'idempotency_key' => $idempotencyKey,
                        'data' => $result,
                    ];
                } catch (\Throwable $e) {
                    $record->update([
                        'status' => 'FAILED',
                        'processed_at' => now(),
                        'error_code' => class_basename($e),
                        'error_message' => $e->getMessage(),
                    ]);

                    $results[] = [
                        'operation_id' => $operationId,
                        'status' => 'FAILED',
                        'idempotency_key' => $idempotencyKey,
                        'error_code' => class_basename($e),
                        'error_message' => $e->getMessage(),
                    ];
                }
            }
        });

        return response()->json([
            'data' => [
                'results' => $results,
            ],
        ], 200);
    }

    /**
     * Dispatch an operation to the appropriate domain processor.
     *
     * @param array<string, mixed> $payload
     * @return array<string, mixed>
     */
    private function processOperation(
        string $entity,
        string $operation,
        array $payload,
        $driver,
        User $user,
        string $idempotencyKey,
    ): array {
        return match ($entity) {
            'delivery' => $this->processDeliveryTransition($operation, $payload, $driver, $user, $idempotencyKey),
            'location' => $this->processLocationOperation($operation, $payload, $driver),
            'proof' => $this->processProofOperation($operation, $payload, $driver),
            'event' => $this->processEventOperation($operation, $payload, $driver, $user),
            default => throw ValidationException::withMessages([
                'entity' => 'Entidade de sincronização inválida.',
            ]),
        };
    }

    /**
     * Process a delivery state-transition operation.
     *
     * @param array<string, mixed> $payload
     * @return array<string, mixed>
     */
    private function processDeliveryTransition(
        string $operation,
        array $payload,
        $driver,
        User $user,
        string $idempotencyKey,
    ): array {
        if ($operation !== 'STATE_TRANSITION' && $operation !== 'UPDATE') {
            throw ValidationException::withMessages([
                'operation' => 'Operação de entrega inválida.',
            ]);
        }

        $action = (string) ($payload['action'] ?? '');
        $deliveryId = (string) ($payload['delivery_id'] ?? '');

        if ($action === '' || $deliveryId === '') {
            throw ValidationException::withMessages([
                'payload' => 'action e delivery_id são obrigatórios.',
            ]);
        }

        /** @var Delivery $delivery */
        $delivery = Delivery::whereKey($deliveryId)->lockForUpdate()->firstOrFail();

        if (! $delivery->assignments()->where('driver_id', $driver->id)->where('status', 'ACTIVE')->exists()) {
            throw new AuthorizationException('Motorista não está atribuído a esta entrega.');
        }

        $path = $this->transitionResolver->targetStatesFor($action, $delivery->status);

        if ($path === []) {
            throw ValidationException::withMessages([
                'delivery' => 'Transição não permitida neste estado.',
            ]);
        }

        $steps = [];
        $cursor = $delivery->status;
        foreach ($path as $next) {
            DeliveryStateMachine::validateTransition($cursor, $next);
            $steps[] = $next;
            $cursor = $next;
        }

        $target = end($steps);
        $updates = ['status' => $target->value];

        if (in_array(\App\Domain\Delivery\Enums\DeliveryStatus::PICKED_UP, $steps, true)) {
            $updates['picked_up_at'] = now();
        }
        if (in_array(\App\Domain\Delivery\Enums\DeliveryStatus::DELIVERED, $steps, true)) {
            $updates['delivered_at'] = now();
        }

        $delivery->update($updates);

        foreach ($steps as $step) {
            $delivery->events()->create([
                'event_type' => 'DELIVERY_'.$step->value,
                'actor_type' => 'driver',
                'actor_id' => $user->id,
                'source' => 'SYNC',
                'idempotency_key' => $idempotencyKey.':'.$step->value,
                'metadata' => ['action' => $action],
                'occurred_at' => now(),
            ]);
        }

        return [
            'delivery_id' => $delivery->id,
            'status' => $delivery->status->value,
            'steps' => array_map(static fn ($step) => $step->value, $steps),
        ];
    }

    /**
     * Persist a driver GPS location.
     *
     * @param array<string, mixed> $payload
     * @return array<string, mixed>
     */
    private function processLocationOperation(string $operation, array $payload, $driver): array
    {
        if (! in_array($operation, ['CREATE', 'UPDATE'], true)) {
            throw new \InvalidArgumentException('Location operation must be CREATE or UPDATE.');
        }

        $deliveryId = (string) ($payload['delivery_id'] ?? '');
        $latitude = (float) ($payload['latitude'] ?? 0);
        $longitude = (float) ($payload['longitude'] ?? 0);

        if ($deliveryId === '' || $latitude === 0.0 || $longitude === 0.0) {
            throw ValidationException::withMessages([
                'payload' => 'delivery_id, latitude e longitude são obrigatórios.',
            ]);
        }

        $delivery = Delivery::whereKey($deliveryId)->firstOrFail();

        if (! $delivery->assignments()->where('driver_id', $driver->id)->where('status', 'ACTIVE')->exists()) {
            throw new AuthorizationException('Motorista não está atribuído a esta entrega.');
        }

        $location = $delivery->locations()->create([
            'driver_id' => $driver->id,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'accuracy' => $payload['accuracy'] ?? null,
            'speed' => $payload['speed'] ?? null,
            'heading' => $payload['heading'] ?? null,
            'recorded_at' => $payload['recorded_at'] ?? now(),
            'received_at' => now(),
            'source' => 'SYNC',
        ]);

        return [
            'location_id' => $location->id,
            'delivery_id' => $delivery->id,
        ];
    }

    /**
     * Persist proof-of-delivery evidence (photo, signature, ...).
     *
     * @param array<string, mixed> $payload
     * @return array<string, mixed>
     */
    private function processProofOperation(string $operation, array $payload, $driver): array
    {
        if ($operation !== 'CREATE') {
            throw new \InvalidArgumentException('Proof operation must be CREATE.');
        }

        $type = (string) ($payload['type'] ?? '');
        $data = (string) ($payload['data'] ?? '');
        $deliveryId = (string) ($payload['delivery_id'] ?? '');

        if ($type === '' || $data === '' || $deliveryId === '') {
            throw ValidationException::withMessages([
                'payload' => 'type, data e delivery_id são obrigatórios.',
            ]);
        }

        $delivery = Delivery::whereKey($deliveryId)->firstOrFail();

        if (! $delivery->assignments()->where('driver_id', $driver->id)->where('status', 'ACTIVE')->exists()) {
            throw new AuthorizationException('Motorista não está atribuído a esta entrega.');
        }

        $evidence = $delivery->evidences()->create([
            'evidence_type' => $type,
            'object_key' => $data,
            'captured_at' => $payload['captured_at'] ?? now(),
            'captured_by_type' => 'driver',
            'captured_by_id' => $driver->id,
            'metadata' => $payload['metadata'] ?? [],
        ]);

        return [
            'evidence_id' => $evidence->id,
            'type' => $evidence->evidence_type,
            'captured_at' => $evidence->captured_at->toIso8601String(),
        ];
    }

    /**
     * Record a custom audit trail event.
     *
     * @param array<string, mixed> $payload
     * @return array<string, mixed>
     */
    private function processEventOperation(string $operation, array $payload, $driver, User $user): array
    {
        if ($operation !== 'CREATE') {
            throw new \InvalidArgumentException('Event operation must be CREATE.');
        }

        $type = (string) ($payload['type'] ?? '');
        $deliveryId = (string) ($payload['delivery_id'] ?? '');
        $data = $payload['data'] ?? [];

        if ($type === '' || $deliveryId === '') {
            throw ValidationException::withMessages([
                'payload' => 'type e delivery_id são obrigatórios.',
            ]);
        }

        $delivery = Delivery::whereKey($deliveryId)->firstOrFail();

        $event = $delivery->events()->create([
            'event_type' => $type,
            'actor_type' => 'driver',
            'actor_id' => $user->id,
            'source' => 'SYNC',
            'metadata' => is_array($data) ? $data : ['data' => $data],
            'occurred_at' => now(),
        ]);

        return [
            'event_id' => $event->id,
            'type' => $event->event_type,
            'created_at' => $event->created_at->toIso8601String(),
        ];
    }


}
