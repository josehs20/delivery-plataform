<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

/**
 * Implements ADR-005: retryable critical operations must be idempotent.
 *
 * The client supplies an idempotency key through the X-Idempotency-Key header
 * or the JSON body field "idempotency_key". The first successful response is
 * cached; subsequent retries with the same key return the already-processed
 * result without repeating side effects.
 */
final class IdempotencyKeyMiddleware
{
    private const CACHE_TTL_SECONDS = 86400; // 24 hours

    public function handle(Request $request, Closure $next): Response
    {
        $key = $this->resolveKey($request);

        if ($key === null || $key === '') {
            return response()->json([
                'errors' => [
                    'message' => 'A chave de idempotência é obrigatória (header X-Idempotency-Key ou campo idempotency_key).',
                ],
            ], 422);
        }

        $cacheKey = $this->cacheKey($request, $key);

        if (Cache::has($cacheKey)) {
            /** @var array<string, mixed> $cached */
            $cached = Cache::get($cacheKey);

            return response()->json($cached, 200);
        }

        $response = $next($request);

        if ($response->isSuccessful()) {
            $payload = json_decode($response->getContent() ?: 'null', true);

            Cache::put($cacheKey, $payload, now()->addSeconds(self::CACHE_TTL_SECONDS));
        }

        return $response;
    }

    private function resolveKey(Request $request): ?string
    {
        $header = $request->header('X-Idempotency-Key');

        if (is_string($header) && $header !== '') {
            return $header;
        }

        $body = $request->input('idempotency_key');

        if (is_string($body) && $body !== '') {
            return $body;
        }

        // The offline sync batch is identified by its sync_token (ADR-002).
        $syncToken = $request->input('sync_token');

        if (is_string($syncToken) && $syncToken !== '') {
            return $syncToken;
        }

        return null;
    }

    private function cacheKey(Request $request, string $key): string
    {
        $actor = (string) ($request->user()?->id ?? $request->ip() ?? 'anonymous');

        return sprintf('idempotency:%s:%s', $actor, $key);
    }
}
