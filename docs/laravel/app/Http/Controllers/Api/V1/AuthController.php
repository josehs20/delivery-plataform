<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class AuthController
{
    public function login(Request $request): JsonResponse
    {
        return response()->json(['error' => ['code' => 'NOT_IMPLEMENTED']], 501);
    }
}
