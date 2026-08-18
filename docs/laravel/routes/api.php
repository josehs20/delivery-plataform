<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::post('/auth/login', [\App\Http\Controllers\Api\V1\AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/me', [\App\Http\Controllers\Api\V1\MeController::class, 'show']);
        Route::post('/deliveries', [\App\Http\Controllers\Api\V1\DeliveryController::class, 'store']);
        Route::get('/deliveries', [\App\Http\Controllers\Api\V1\DeliveryController::class, 'index']);
        Route::get('/deliveries/{delivery}', [\App\Http\Controllers\Api\V1\DeliveryController::class, 'show']);
        Route::post('/deliveries/{delivery}/publish', [\App\Http\Controllers\Api\V1\DeliveryController::class, 'publish']);
        Route::post('/deliveries/{delivery}/cancel', [\App\Http\Controllers\Api\V1\DeliveryController::class, 'cancel']);
        Route::post('/deliveries/{delivery}/accept', [\App\Http\Controllers\Api\V1\DeliveryController::class, 'accept']);
        Route::post('/deliveries/{delivery}/counter-offers', [\App\Http\Controllers\Api\V1\CounterOfferController::class, 'store']);
        Route::post('/counter-offers/{counterOffer}/accept', [\App\Http\Controllers\Api\V1\CounterOfferController::class, 'accept']);
        Route::post('/counter-offers/{counterOffer}/reject', [\App\Http\Controllers\Api\V1\CounterOfferController::class, 'reject']);
        Route::post('/deliveries/{delivery}/arrive-pickup', [\App\Http\Controllers\Api\V1\DeliveryController::class, 'arrivePickup']);
        Route::post('/deliveries/{delivery}/pickup', [\App\Http\Controllers\Api\V1\DeliveryController::class, 'pickup']);
        Route::post('/deliveries/{delivery}/arrive-destination', [\App\Http\Controllers\Api\V1\DeliveryController::class, 'arriveDestination']);
        Route::post('/deliveries/{delivery}/complete', [\App\Http\Controllers\Api\V1\DeliveryController::class, 'complete']);
        Route::post('/deliveries/{delivery}/fail', [\App\Http\Controllers\Api\V1\DeliveryController::class, 'fail']);
        Route::post('/driver/location', [\App\Http\Controllers\Api\V1\LocationController::class, 'store']);
        Route::post('/driver/location/batch', [\App\Http\Controllers\Api\V1\LocationController::class, 'batch']);
        Route::post('/sync/batch', [\App\Http\Controllers\Api\V1\SyncController::class, 'batch']);
    });
});
