<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Domain\Delivery\Actions\CreateDeliveryAction;
use App\Domain\Delivery\DeliveryStateMachine;
use App\Domain\Delivery\Enums\DeliveryStatus;
use App\Domain\Delivery\Enums\OfferStatus;
use App\Domain\Delivery\Services\DeliveryTransitionResolver;
use App\Domain\Delivery\Services\DispatchService;
use App\DTOs\CreateDeliveryData;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\{
    AcceptDeliveryRequest,
    CancelDeliveryRequest,
    CreateDeliveryRequest,
    DeliveryStateTransitionRequest,
    UpdateDeliveryRequest,
};
use App\Models\Delivery;
use App\Models\DeliveryOffer;
use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class DeliveryController extends Controller
{
    public function __construct(
        private readonly CreateDeliveryAction $createDeliveryAction,
        private readonly DispatchService $dispatchService,
        private readonly DeliveryTransitionResolver $transitionResolver,
    ) {}

    /**
     * GET /api/v1/deliveries
     *
     * Lists deliveries scoped by role:
     * - business: their own deliveries;
     * - driver: deliveries assigned to them.
     */
    public function index(): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();
        $perPage = (int) request()->query('per_page', 15);
        $page = (int) request()->query('page', 1);

        if ($user->hasRole('admin')) {
            // Admin (docs/docs/product/02-actors-and-permissions.md): acesso
            // operacional — vê entregas, ofertas e auditoria da plataforma.
            $query = Delivery::with(['items', 'offers', 'assignments', 'events'])
                ->latest('created_at');
        } elseif ($user->hasRole('business')) {
            $business = $user->businesses()->first();

            if (! $business) {
                throw new AuthorizationException('Usuário não é um negócio.');
            }

            $query = Delivery::where('business_id', $business->id)
                ->with(['items', 'offers', 'assignments', 'events'])
                ->latest('created_at');
        } elseif ($user->hasRole('driver')) {
            $driver = $user->drivers()->first();

            if (! $driver) {
                throw new AuthorizationException('Motorista não encontrado.');
            }

            $query = Delivery::whereHas('assignments', fn ($q) => $q->where('driver_id', $driver->id))
                ->with(['items', 'assignment.driver.user', 'events'])
                ->latest('created_at');
        } else {
            throw new AuthorizationException('Unauthorized.');
        }

        $deliveries = $query->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'data' => [
                'deliveries' => $deliveries->items(),
                'pagination' => [
                    'total' => $deliveries->total(),
                    'per_page' => $deliveries->perPage(),
                    'current_page' => $deliveries->currentPage(),
                    'last_page' => $deliveries->lastPage(),
                ],
            ],
        ], 200);
    }

    /**
     * GET /api/v1/deliveries/{id}
     *
     * Returns a single delivery. Only the owning business or an assigned
     * driver may view it.
     */
    public function show(string $id): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();

        $delivery = Delivery::with([
            'items',
            'assignment.driver.user',
            'offers.driver.user',
            'events',
            'evidences',
            'locations',
        ])->findOrFail($id);

        $this->authorizeAccess($user, $delivery);

        return response()->json([
            'data' => [
                'delivery' => $delivery,
            ],
        ], 200);
    }

    /**
     * POST /api/v1/deliveries
     *
     * Creates a delivery in DRAFT state. Pricing is always calculated
     * server-side (CALCULATED or MANUAL).
     */
    public function store(CreateDeliveryRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();
        $business = $user->businesses()->first();

        if (! $business) {
            throw new AuthorizationException('Usuário não é um negócio.');
        }

        $data = new CreateDeliveryData(
            origin: $request->input('origin'),
            destination: $request->input('destination'),
            recipient: $request->input('recipient'),
            items: $request->input('items'),
            pricing: $request->input('pricing'),
            pickupDeadline: $request->input('pickup_deadline'),
        );

        $delivery = $this->createDeliveryAction->execute($data, $business->id);

        return response()->json([
            'data' => [
                'delivery' => $delivery->load(['items', 'events']),
                'message' => 'Entrega criada com sucesso.',
            ],
        ], 201);
    }

    /**
     * PUT /api/v1/deliveries/{id}
     *
     * Updates a delivery while it is still in DRAFT state.
     */
    public function update(UpdateDeliveryRequest $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();
        $business = $user->businesses()->first();

        $delivery = Delivery::findOrFail($id);

        if ($delivery->business_id !== $business->id) {
            throw new AuthorizationException('Unauthorized.');
        }

        if ($delivery->status !== DeliveryStatus::DRAFT) {
            throw ValidationException::withMessages([
                'delivery' => 'Entrega não pode ser editada neste estado.',
            ]);
        }

        DB::transaction(function () use ($request, $delivery): void {
            if ($request->filled('origin')) {
                $delivery->origin_snapshot = $request->input('origin');
            }

            if ($request->filled('destination')) {
                $delivery->destination_snapshot = $request->input('destination');
            }

            if ($request->filled('recipient')) {
                $recipient = $request->input('recipient');
                $delivery->recipient_name = $recipient['name'] ?? $delivery->recipient_name;
                $delivery->recipient_phone = $recipient['phone'] ?? $delivery->recipient_phone;
                $delivery->recipient_reference = $recipient['reference'] ?? $delivery->recipient_reference;
            }

            if ($request->filled('pickup_deadline')) {
                $delivery->pickup_deadline = $request->input('pickup_deadline');
            }

            $delivery->save();

            if ($request->filled('items')) {
                $delivery->items()->delete();
                foreach ($request->input('items') as $item) {
                    $delivery->items()->create([
                        'name' => $item['name'],
                        'description' => $item['description'] ?? null,
                        'category' => $item['category'] ?? null,
                        'quantity' => (int) ($item['quantity'] ?? 1),
                        'approximate_weight' => $item['approximate_weight'] ?? null,
                        'dimensions' => $item['dimensions'] ?? null,
                        'special_handling' => $item['special_handling'] ?? null,
                        'notes' => $item['notes'] ?? null,
                    ]);
                }
            }
        });

        return response()->json([
            'data' => [
                'delivery' => $delivery->fresh(['items']),
                'message' => 'Entrega atualizada com sucesso.',
            ],
        ], 200);
    }

    /**
     * POST /api/v1/deliveries/{id}/publish
     *
     * Publishes a DRAFT delivery (DRAFT → OPEN), records the audit event and
     * triggers geospatial dispatch to nearby drivers (ADR-006).
     */
    public function publish(string $id): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();
        $business = $user->businesses()->first();

        $delivery = Delivery::findOrFail($id);

        if ($delivery->business_id !== $business->id) {
            throw new AuthorizationException('Unauthorized.');
        }

        if ($delivery->status !== DeliveryStatus::DRAFT) {
            throw ValidationException::withMessages([
                'delivery' => 'Somente entregas em rascunho podem ser publicadas.',
            ]);
        }

        $published = DB::transaction(function () use ($delivery, $user): Delivery {
            DeliveryStateMachine::validateTransition(DeliveryStatus::DRAFT, DeliveryStatus::OPEN);

            $delivery->update([
                'status' => DeliveryStatus::OPEN->value,
                'published_at' => now(),
            ]);

            $this->recordEvent($delivery, 'DELIVERY_PUBLISHED', 'business', $user->id);

            return $delivery;
        });

        // Dispatch offers to nearby eligible drivers (best-effort; dispatch
        // failures must not block the publication).
        try {
            $this->dispatchService->createOffersForDelivery($published);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('Delivery dispatch failed', [
                'delivery_id' => $published->id,
                'error' => $e->getMessage(),
            ]);
        }

        return response()->json([
            'data' => [
                'delivery' => $published->load(['items', 'offers', 'events']),
                'message' => 'Entrega publicada com sucesso.',
            ],
        ], 200);
    }

    /**
     * POST /api/v1/deliveries/{id}/accept
     *
     * Driver accepts an offer. The acceptance is serialized with a row lock
     * (ADR-004) so that only one driver can win, and it is idempotent for the
     * same driver retrying (ADR-005).
     */
    public function accept(AcceptDeliveryRequest $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();
        $driver = $user->drivers()->first();

        if (! $driver) {
            throw new AuthorizationException('Usuário não é um motorista.');
        }

        $idempotencyKey = (string) $request->input('idempotency_key');
        $offerId = (string) $request->input('offer_id');

        $delivery = DB::transaction(function () use ($id, $driver, $offerId, $idempotencyKey, $user): Delivery {
            /** @var Delivery|null $locked */
            $locked = Delivery::whereKey($id)->lockForUpdate()->first();

            if (! $locked) {
                abort(404);
            }

            // Idempotency: same driver retrying an already-accepted delivery.
            $existingActive = $locked->assignments()->where('status', 'ACTIVE')->first();

            if ($existingActive && $existingActive->driver_id === $driver->id) {
                return $locked;
            }

            if ($existingActive) {
                throw ValidationException::withMessages([
                    'delivery' => 'Entrega já foi aceita por outro motorista.',
                ]);
            }

            if (! in_array($locked->status, [DeliveryStatus::OPEN, DeliveryStatus::NEGOTIATING], true)) {
                throw ValidationException::withMessages([
                    'delivery' => 'Entrega não pode ser aceita neste estado.',
                ]);
            }

            $offer = DeliveryOffer::whereKey($offerId)
                ->where('delivery_id', $locked->id)
                ->where('driver_id', $driver->id)
                ->first();

            if (! $offer) {
                throw ValidationException::withMessages([
                    'offer_id' => 'Oferta não é válida.',
                ]);
            }

            if ($offer->status !== OfferStatus::PENDING) {
                throw ValidationException::withMessages([
                    'offer_id' => 'Oferta não está mais disponível.',
                ]);
            }

            DeliveryStateMachine::validateTransition($locked->status, DeliveryStatus::ASSIGNED);

            // Close competing offers (only one winner per delivery).
            DeliveryOffer::where('delivery_id', $locked->id)
                ->where('status', OfferStatus::PENDING->value)
                ->where('id', '!=', $offer->id)
                ->update(['status' => OfferStatus::REJECTED->value, 'responded_at' => now()]);

            $locked->assignments()->create([
                'driver_id' => $driver->id,
                'source_type' => 'OFFER',
                'source_reference_id' => $offer->id,
                'agreed_amount' => $offer->offered_amount,
                'status' => 'ACTIVE',
                'assigned_at' => now(),
                'accepted_at' => now(),
            ]);

            $locked->update([
                'status' => DeliveryStatus::ASSIGNED->value,
                'current_driver_id' => $driver->id,
                'accepted_at' => now(),
                'accepted_amount' => $offer->offered_amount,
            ]);

            $offer->update([
                'status' => OfferStatus::ACCEPTED->value,
                'responded_at' => now(),
            ]);

            $this->recordEvent($locked, 'DELIVERY_ASSIGNED', 'driver', $user->id, $idempotencyKey, [
                'driver_id' => $driver->id,
                'offer_id' => $offer->id,
            ]);

            return $locked;
        });

        return response()->json([
            'data' => [
                'delivery' => $delivery,
                'message' => 'Entrega aceita com sucesso.',
            ],
        ], 200);
    }

    /**
     * POST /api/v1/deliveries/{id}/arrive-pickup|pickup|arrive-destination|complete|fail|return/start
     *
     * Generic driver state-transition endpoint. Every step is validated against
     * the state machine (ADR-003), recorded as an audit event, and protected by
     * an idempotency key (ADR-005).
     */
    public function transitionState(DeliveryStateTransitionRequest $request, string $id, string $action): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();
        $driver = $user->drivers()->first();

        if (! $driver) {
            throw new AuthorizationException('Usuário não é um motorista.');
        }

        $idempotencyKey = (string) $request->input('idempotency_key');

        $delivery = DB::transaction(function () use ($id, $driver, $action, $idempotencyKey, $request, $user): Delivery {
            /** @var Delivery $locked */
            $locked = Delivery::whereKey($id)->lockForUpdate()->firstOrFail();

            if (! $locked->assignments()->where('driver_id', $driver->id)->where('status', 'ACTIVE')->exists()) {
                throw new AuthorizationException('Unauthorized.');
            }

            $path = $this->transitionResolver->targetStatesFor($action, $locked->status);

            if ($path === []) {
                throw ValidationException::withMessages([
                    'delivery' => 'Transição não permitida neste estado.',
                ]);
            }

            if ($action === 'complete' && ! $request->has('proof')) {
                throw ValidationException::withMessages([
                    'proof' => 'Prova de entrega é obrigatória.',
                ]);
            }

            if ($action === 'fail' && ! $request->filled('reason')) {
                throw ValidationException::withMessages([
                    'reason' => 'Motivo é obrigatório.',
                ]);
            }

            $originalStatus = $locked->status;

            $steps = [];
            $cursor = $originalStatus;
            foreach ($path as $next) {
                DeliveryStateMachine::validateTransition($cursor, $next);
                $steps[] = $next;
                $cursor = $next;
            }

            if ($request->has('proof')) {
                $proof = $request->input('proof');
                $locked->evidences()->create([
                    'evidence_type' => $proof['type'],
                    'object_key' => $proof['data'],
                    'captured_at' => now(),
                    'captured_by_type' => 'driver',
                    'captured_by_id' => $driver->id,
                    'metadata' => ['delivery_action' => $action],
                ]);
            }

            $target = end($steps);
            $updates = ['status' => $target->value];

            if (in_array(DeliveryStatus::PICKED_UP, $steps, true)) {
                $updates['picked_up_at'] = now();
            }
            if (in_array(DeliveryStatus::DELIVERED, $steps, true)) {
                $updates['delivered_at'] = now();
            }

            $locked->update($updates);

            if ($action === 'fail') {
                $locked->failures()->create([
                    'reason' => (string) $request->input('reason'),
                    'description' => $request->input('description'),
                    'reported_by_type' => 'driver',
                    'reported_by_id' => $driver->id,
                    'requires_return' => in_array($originalStatus, [
                        DeliveryStatus::PICKED_UP,
                        DeliveryStatus::IN_TRANSIT,
                        DeliveryStatus::AT_DESTINATION,
                    ], true),
                    'resolution_status' => 'PENDING',
                ]);
            }

            if ($action === 'return-start') {
                $locked->returns()->create([
                    'initiated_by_type' => 'driver',
                    'initiated_by_id' => $driver->id,
                    'status' => 'IN_PROGRESS',
                ]);
            }

            if ($action === 'return-confirm') {
                $locked->returns()->where('status', 'IN_PROGRESS')->update([
                    'status' => 'COMPLETED',
                    'merchant_confirmed_at' => now(),
                ]);
            }

            foreach ($steps as $step) {
                // Suffix per step keeps (source, idempotency_key) unique in delivery_events.
                $this->recordEvent($locked, 'DELIVERY_'.$step->value, 'driver', $user->id, $idempotencyKey !== null ? $idempotencyKey.':'.$step->value : null, [
                    'action' => $action,
                ]);
            }

            return $locked;
        });

        return response()->json([
            'data' => [
                'delivery' => $delivery,
                'message' => sprintf('Entrega %s com sucesso.', $this->getActionMessage($action)),
            ],
        ], 200);
    }

    /**
     * POST /api/v1/deliveries/{id}/return/confirm
     *
     * Business confirms the merchandise was received back (RETURN_IN_PROGRESS
     * → RETURNED).
     */
    public function confirmReturn(string $id): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();
        $business = $user->businesses()->first();

        $delivery = Delivery::findOrFail($id);

        if ($delivery->business_id !== $business->id) {
            throw new AuthorizationException('Unauthorized.');
        }

        if ($delivery->status !== DeliveryStatus::RETURN_IN_PROGRESS) {
            throw ValidationException::withMessages([
                'delivery' => 'Devolução não está em andamento.',
            ]);
        }

        $delivery = DB::transaction(function () use ($delivery, $user): Delivery {
            DeliveryStateMachine::validateTransition($delivery->status, DeliveryStatus::RETURNED);

            $delivery->update(['status' => DeliveryStatus::RETURNED->value]);

            $delivery->returns()->where('status', 'IN_PROGRESS')->update([
                'status' => 'COMPLETED',
                'merchant_confirmed_at' => now(),
            ]);

            $this->recordEvent($delivery, 'DELIVERY_RETURNED', 'business', $user->id);

            return $delivery;
        });

        return response()->json([
            'data' => [
                'delivery' => $delivery,
                'message' => 'Devolução confirmada com sucesso.',
            ],
        ], 200);
    }

    /**
     * POST /api/v1/deliveries/{id}/cancel
     *
     * Cancels a delivery in DRAFT, OPEN or NEGOTIATING state. Backend records
     * the cancellation with audit trail (ADR-008).
     */
    public function cancel(CancelDeliveryRequest $request, string $id): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();
        $business = $user->businesses()->first();

        $delivery = Delivery::findOrFail($id);

        if ($delivery->business_id !== $business->id) {
            throw new AuthorizationException('Unauthorized.');
        }

        if (! in_array($delivery->status, [DeliveryStatus::DRAFT, DeliveryStatus::OPEN, DeliveryStatus::NEGOTIATING], true)) {
            throw ValidationException::withMessages([
                'delivery' => 'Entrega não pode ser cancelada neste estado.',
            ]);
        }

        $delivery = DB::transaction(function () use ($delivery, $request, $user): Delivery {
            DeliveryStateMachine::validateTransition($delivery->status, DeliveryStatus::CANCELLED);

            $delivery->cancellation()->create([
                'cancelled_by_type' => 'business',
                'cancelled_by_id' => $user->id,
                'reason' => (string) $request->input('reason'),
                'description' => $request->input('description'),
            ]);

            $delivery->update([
                'status' => DeliveryStatus::CANCELLED->value,
                'cancelled_at' => now(),
            ]);

            $this->recordEvent($delivery, 'DELIVERY_CANCELLED', 'business', $user->id, null, [
                'reason' => $request->input('reason'),
            ]);

            return $delivery;
        });

        return response()->json([
            'data' => [
                'delivery' => $delivery,
                'message' => 'Entrega cancelada com sucesso.',
            ],
        ], 200);
    }

    /**
     * Record an audit trail event for a delivery (ADR-008).
     *
     * @param array<string, mixed> $metadata
     */
    private function recordEvent(
        Delivery $delivery,
        string $eventType,
        string $actorType,
        ?string $actorId,
        ?string $idempotencyKey = null,
        array $metadata = []
    ): void {
        $delivery->events()->create([
            'event_type' => $eventType,
            'actor_type' => $actorType,
            'actor_id' => $actorId,
            'source' => 'API',
            'idempotency_key' => $idempotencyKey,
            'metadata' => $metadata,
            'occurred_at' => now(),
        ]);
    }

    /**
     * Verify that the user is the owning business or an assigned driver.
     */
    private function authorizeAccess(User $user, Delivery $delivery): void
    {
        if ($user->hasRole('admin')) {
            // Admin pode inspecionar qualquer entrega (auditoria/ofertas).
            return;
        }

        if ($user->hasRole('business')) {
            if ($delivery->business_id !== $user->businesses()->first()?->id) {
                throw new AuthorizationException('Unauthorized.');
            }

            return;
        }

        if ($user->hasRole('driver')) {
            $driver = $user->drivers()->first();

            if (! $driver || ! $delivery->assignments()->where('driver_id', $driver->id)->exists()) {
                throw new AuthorizationException('Unauthorized.');
            }

            return;
        }

        throw new AuthorizationException('Unauthorized.');
    }

    /**
     * Human-readable message for an action.
     */
    private function getActionMessage(string $action): string
    {
        return match ($action) {
            'arrive-pickup' => 'chegada ao ponto de coleta',
            'pickup' => 'coletada',
            'arrive-destination' => 'chegada ao destino',
            'complete' => 'entregue',
            'fail' => 'falha registrada',
            'return-start' => 'devolução iniciada',
            'return-confirm' => 'devolução confirmada',
            default => 'atualizada',
        };
    }





}
