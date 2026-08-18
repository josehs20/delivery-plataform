<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class DeliveryController
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(['data' => [], 'meta' => ['not_implemented' => true]]);
    }

    public function store(Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }

    public function show(string $delivery): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }

    public function publish(string $delivery, Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }

    public function cancel(string $delivery, Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }

    public function accept(string $delivery, Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }

    public function arrivePickup(string $delivery, Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }

    public function pickup(string $delivery, Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }

    public function arriveDestination(string $delivery, Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }

    public function complete(string $delivery, Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }

    public function fail(string $delivery, Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }
}
