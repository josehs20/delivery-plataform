<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class CounterOfferController
{
    public function store(string $delivery, Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }

    public function accept(string $counterOffer, Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }

    public function reject(string $counterOffer, Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }
}
