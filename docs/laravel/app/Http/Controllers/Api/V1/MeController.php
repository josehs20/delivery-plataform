<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class MeController
{
    public function show(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()]);
    }
}
