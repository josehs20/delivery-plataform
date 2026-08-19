<?php

use App\Http\Controllers\Api\V1\AdminController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\DeliveryController;
use App\Http\Controllers\Api\V1\MeController;
use App\Http\Controllers\Api\V1\SyncController;
use App\Http\Requests\Api\V1\DeliveryStateTransitionRequest;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| API v1 routes for Delivery Platform.
| All routes are prefixed with /api/v1
|
| Authentication: Sanctum tokens (Bearer <token>)
| Idempotency: Use X-Idempotency-Key header for retryable operations
| Rate Limiting: Applied via middleware (see middleware configuration)
|
| Per docs/api/29-api-overview.md:
| - All endpoints require authentication except auth endpoints
| - Use stable response envelopes defined by OpenAPI spec
| - Consistent error shapes per docs/api/42-api-errors-idempotency-concurrency.md
|
| Per ADR-005: Idempotency key prevents duplicate effects from retries.
| Per ADR-004: Transactional consistency for concurrent operations.
|
*/

// The `api` prefix is added automatically by the framework for routes/api.php,
// so the group only declares the version prefix.
Route::prefix('v1')->middleware('api')->group(function () {
    // ================================================================
    // Authentication Endpoints
    // ================================================================
    // Per docs/api/30-auth-api.md: No authentication required
    // Per docs/api/43-api-security.md: Rate limiting on auth endpoints
    Route::prefix('auth')->middleware('throttle:5,1')->group(function () {
        Route::post('login', [AuthController::class, 'login'])
            ->name('auth.login');

        Route::post('register', [AuthController::class, 'register'])
            ->name('auth.register');

        Route::post('refresh', [AuthController::class, 'refresh'])
            ->name('auth.refresh');

        Route::post('forgot-password', [AuthController::class, 'forgotPassword'])
            ->name('auth.forgot-password');

        Route::post('reset-password', [AuthController::class, 'resetPassword'])
            ->name('auth.reset-password');
    });

    // ================================================================
    // Protected Routes (Authentication Required)
    // ================================================================
    Route::middleware('auth:sanctum')->group(function () {
        // ================================================================
        // Authentication — Logout (protected: requires a valid token)
        // ================================================================
        // Revokes the current Sanctum token (docs/api/30-auth-api.md).
        Route::post('auth/logout', [AuthController::class, 'logout'])
            ->name('auth.logout');

        // ================================================================
        // Profile Endpoints
        // ================================================================
        // Per docs/api/30-auth-api.md: GET /api/v1/me returns user identity
        Route::prefix('me')->group(function () {
            Route::get('/', [MeController::class, 'show'])
                ->name('me.show');

            Route::patch('/', [MeController::class, 'update'])
                ->name('me.update');
        });

        // ================================================================
        // Delivery Management Endpoints
        // ================================================================
        // Per docs/api/34-delivery-api.md: Full CRUD and state transitions
        // Per ADR-004: Transactional operations for concurrent safety
        Route::prefix('deliveries')->group(function () {
            // List and create
            Route::get('/', [DeliveryController::class, 'index'])
                ->name('deliveries.index');

            Route::post('/', [DeliveryController::class, 'store'])
                ->middleware('can:create-delivery')
                ->name('deliveries.store');

            // Single delivery details
            Route::get('{id}', [DeliveryController::class, 'show'])
                ->name('deliveries.show');

            // Update delivery (only in DRAFT state)
            Route::put('{id}', [DeliveryController::class, 'update'])
                ->middleware('can:update-delivery')
                ->name('deliveries.update');

            // Publish delivery (DRAFT -> OPEN) + dispatch
            Route::post('{id}/publish', [DeliveryController::class, 'publish'])
                ->middleware('can:update-delivery')
                ->name('deliveries.publish');

            // Delivery state transitions
            // Per docs/api/34-delivery-api.md: Each endpoint validates state machine
            // Per ADR-005: Idempotency key in X-Idempotency-Key header
            Route::group(['prefix' => '{id}'], function () {
                // Driver acceptance of delivery
                Route::post('accept', [DeliveryController::class, 'accept'])
                    ->middleware(['can:accept-delivery', 'idempotency-key'])
                    ->name('deliveries.accept');

                // Driver state transitions
                Route::post('arrive-pickup', fn (DeliveryStateTransitionRequest $request, string $id) => app(DeliveryController::class)->transitionState($request, $id, 'arrive-pickup')
                )->middleware(['can:transition-delivery', 'idempotency-key'])
                    ->name('deliveries.arrive-pickup');

                Route::post('pickup', fn (DeliveryStateTransitionRequest $request, string $id) => app(DeliveryController::class)->transitionState($request, $id, 'pickup')
                )->middleware(['can:transition-delivery', 'idempotency-key'])
                    ->name('deliveries.pickup');

                Route::post('arrive-destination', fn (DeliveryStateTransitionRequest $request, string $id) => app(DeliveryController::class)->transitionState($request, $id, 'arrive-destination')
                )->middleware(['can:transition-delivery', 'idempotency-key'])
                    ->name('deliveries.arrive-destination');

                Route::post('complete', fn (DeliveryStateTransitionRequest $request, string $id) => app(DeliveryController::class)->transitionState($request, $id, 'complete')
                )->middleware(['can:transition-delivery', 'idempotency-key'])
                    ->name('deliveries.complete');

                Route::post('fail', fn (DeliveryStateTransitionRequest $request, string $id) => app(DeliveryController::class)->transitionState($request, $id, 'fail')
                )->middleware(['can:transition-delivery', 'idempotency-key'])
                    ->name('deliveries.fail');

                // Return flow (driver starts, business confirms)
                Route::post('return/start', fn (DeliveryStateTransitionRequest $request, string $id) => app(DeliveryController::class)->transitionState($request, $id, 'return-start')
                )->middleware(['can:transition-delivery', 'idempotency-key'])
                    ->name('deliveries.return.start');

                Route::post('return/confirm', [DeliveryController::class, 'confirmReturn'])
                    ->middleware('can:update-delivery')
                    ->name('deliveries.return.confirm');

                // Cancellation (business only)
                Route::post('cancel', [DeliveryController::class, 'cancel'])
                    ->middleware('can:cancel-delivery')
                    ->name('deliveries.cancel');
            });
        });

        // ================================================================
        // Offline Synchronization Endpoint
        // ================================================================
        // Per docs/domain/11-offline-and-synchronization.md
        // Per ADR-002: Offline-first capability with sync queue
        // Per ADR-005: Idempotency keys prevent duplicate operations
        Route::post('sync', [SyncController::class, 'sync'])
            ->middleware('idempotency-key')
            ->name('sync.operations');

        // ================================================================
        // Admin Panel (docs/docs/api/41-admin-api.md)
        // ================================================================
        // Protected by auth:sanctum + can:access-admin (role 'admin').
        Route::prefix('admin')->middleware('can:access-admin')->group(function () {
            // Dashboard metrics (cards do painel administrativo).
            Route::get('metrics', [AdminController::class, 'metrics'])
                ->name('admin.metrics');

            // Motoboys — aprovação cadastral.
            Route::get('drivers/pending', [AdminController::class, 'pendingDrivers'])
                ->name('admin.drivers.pending');
            Route::post('drivers/{driver}/approve', [AdminController::class, 'approveDriver'])
                ->name('admin.drivers.approve');
            Route::post('drivers/{driver}/reject', [AdminController::class, 'rejectDriver'])
                ->name('admin.drivers.reject');
            Route::post('drivers/{driver}/suspend', [AdminController::class, 'suspendDriver'])
                ->name('admin.drivers.suspend');

            // Torre de controle de entregas.
            Route::get('deliveries', [AdminController::class, 'deliveries'])
                ->name('admin.deliveries');
            Route::post('deliveries/{delivery}/assign', [AdminController::class, 'assignDelivery'])
                ->name('admin.deliveries.assign');
            Route::post('deliveries/{delivery}/cancel', [AdminController::class, 'cancelDelivery'])
                ->name('admin.deliveries.cancel');

            // Financeiro, reembolsos e repasses.
            Route::get('payments', [AdminController::class, 'payments'])
                ->name('admin.payments');
            Route::get('refunds', [AdminController::class, 'listRefunds'])
                ->name('admin.refunds');
            Route::post('refunds', [AdminController::class, 'createRefund'])
                ->name('admin.refunds.store');
            Route::get('payouts', [AdminController::class, 'payouts'])
                ->name('admin.payouts');

            // Auditoria.
            Route::get('audit-logs', [AdminController::class, 'auditLogs'])
                ->name('admin.audit-logs');
        });
    });
});

/*
|--------------------------------------------------------------------------
| Health Check & Fallback Routes
|--------------------------------------------------------------------------
*/

// Health check endpoint (unauthenticated)
Route::get('health', fn () => response()->json(['status' => 'ok']))
    ->name('health');

// API documentation endpoint (OpenAPI contract)
Route::get('docs', function () {
    $candidates = [
        storage_path('app/openapi.yaml'),
        base_path('../docs/docs/openapi/openapi.yaml'),
        base_path('../docs/openapi/openapi.yaml'),
    ];

    foreach ($candidates as $path) {
        if (is_file($path)) {
            return response()->file($path);
        }
    }

    return response()->json([
        'errors' => [
            'message' => 'Documentação OpenAPI não disponível.',
        ],
    ], 404);
})->name('api.docs');

// Catch-all for undefined routes
Route::fallback(function () {
    return response()->json([
        'errors' => [
            'message' => 'Endpoint não encontrado.',
        ],
    ], 404);
});
