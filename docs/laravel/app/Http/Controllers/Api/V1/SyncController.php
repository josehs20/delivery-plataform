<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class SyncController
{
    public function batch(Request $request): JsonResponse
    {
        return response()->json(['data' => []]);
    }
}
