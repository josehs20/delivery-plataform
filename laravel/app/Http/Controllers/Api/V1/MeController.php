<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\UpdateProfileRequest;
use App\Models\Driver;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;

class MeController extends Controller
{
    /**
     * GET /api/v1/me
     *
     * Returns the authenticated user's identity, roles, permissions and
     * role-specific context.
     */
    public function show(): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();

        return response()->json([
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'roles' => $user->getRoleNames(),
                    'is_blocked' => $user->is_blocked,
                    'email_verified_at' => $user->email_verified_at?->toIso8601String(),
                    'phone_verified_at' => $user->phone_verified_at?->toIso8601String(),
                ],
                'permissions' => $user->getAllPermissions()->pluck('name'),
                'context' => $this->buildAuthContext($user),
            ],
        ], 200);
    }

    /**
     * PATCH /api/v1/me
     *
     * Updates profile fields. A valid current_password is required when the
     * password is changed. Roles and permissions are never accepted from the
     * client.
     */
    public function update(UpdateProfileRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = auth()->user();

        if ($request->filled('password')) {
            if (! Hash::check((string) $request->input('current_password'), (string) $user->password_hash)) {
                return response()->json([
                    'errors' => [
                        'current_password' => 'Senha atual incorreta.',
                    ],
                ], 422);
            }

            $user->password = Hash::make((string) $request->input('password'));
        }

        if ($request->filled('name')) {
            $user->name = (string) $request->input('name');
        }

        if ($request->filled('email') && (string) $request->input('email') !== (string) $user->email) {
            $user->email = (string) $request->input('email');
            $user->email_verified_at = null; // Require re-verification.
        }

        if ($request->filled('phone') && (string) $request->input('phone') !== (string) $user->phone) {
            $user->phone = (string) $request->input('phone');
            $user->phone_verified_at = null; // Require re-verification.
        }

        $user->save();

        return response()->json([
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'roles' => $user->getRoleNames(),
                    'email_verified_at' => $user->email_verified_at?->toIso8601String(),
                    'phone_verified_at' => $user->phone_verified_at?->toIso8601String(),
                ],
                'message' => 'Perfil atualizado com sucesso.',
            ],
        ], 200);
    }

    /**
     * Build the role-specific authorization context.
     *
     * @return array<string, mixed>
     */
    private function buildAuthContext(User $user): array
    {
        $context = [];

        if ($user->hasRole('business')) {
            $business = $user->businesses()->first();

            if ($business) {
                $context['business'] = [
                    'id' => $business->id,
                    'legal_name' => $business->legal_name,
                    'trade_name' => $business->trade_name,
                    'document_number' => $business->document_number,
                    'status' => $business->status,
                ];
            }
        }

        if ($user->hasRole('driver')) {
            /** @var Driver|null $driver */
            $driver = $user->drivers()->first();

            if ($driver) {
                $context['driver'] = [
                    'id' => $driver->id,
                    'approval_status' => $driver->approval_status,
                    'operational_status' => $driver->operational_status,
                    'vehicle_count' => $driver->vehicles()->count(),
                    'active_deliveries' => $driver->deliveries()
                        ->whereIn('status', [
                            'DRIVER_ACCEPTED',
                            'GOING_TO_PICKUP',
                            'AT_PICKUP',
                            'PICKED_UP',
                            'IN_TRANSIT',
                            'AT_DESTINATION',
                        ])
                        ->count(),
                ];
            }
        }

        return $context;
    }
}
