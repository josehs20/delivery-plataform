<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class LocationController
{
    public function store(Request $request): JsonResponse
    {
        return response()->json(['data' => ['status' => 'ACCEPTED']], 202);
    }

    public function batch(Request $request): JsonResponse
    {
        return response()->json(['data' => ['status' => 'ACCEPTED']], 202);
    }
}
