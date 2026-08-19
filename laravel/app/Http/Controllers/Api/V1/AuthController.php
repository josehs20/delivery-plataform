<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ForgotPasswordRequest;
use App\Http\Requests\Api\V1\LoginRequest;
use App\Http\Requests\Api\V1\RefreshTokenRequest;
use App\Http\Requests\Api\V1\RegisterRequest;
use App\Http\Requests\Api\V1\ResetPasswordRequest;
use App\Models\Business;
use App\Models\Driver;
use App\Models\DriverVehicle;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * POST /api/v1/auth/login
     *
     * Authenticates a user by email or phone + password and returns a
     * Sanctum bearer token.
     *
     * Per docs/api/30-auth-api.md: role is never trusted from the client;
     * blocked users cannot authenticate.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $identifier = (string) $request->input('identifier');

        $user = User::where('email', $identifier)
            ->orWhere('phone', $identifier)
            ->first();

        if (! $user || ! Hash::check((string) $request->input('password'), (string) $user->password_hash)) {
            throw ValidationException::withMessages([
                'identifier' => 'Credenciais inválidas.',
            ]);
        }

        if ($user->is_blocked) {
            throw ValidationException::withMessages([
                'identifier' => 'Usuário bloqueado. Contate o suporte.',
            ]);
        }

        $user->forceFill(['last_login_at' => now()])->save();

        $token = $user->createToken('api-token');

        return response()->json([
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'roles' => $user->getRoleNames(),
                ],
                'token' => $token->plainTextToken,
                'token_type' => 'Bearer',
                'expires_in' => config('sanctum.expiration', 60 * 24),
            ],
        ], 200);
    }

    /**
     * POST /api/v1/auth/register
     *
     * Registers a business or driver account. Role-specific records are
     * created inside the same transaction.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $role = (string) $request->input('role');

        $user = DB::transaction(function () use ($request, $role): User {
            $user = User::create([
                'name' => (string) $request->input('name'),
                'email' => $request->input('email'),
                'phone' => $request->input('phone'),
                'password_hash' => Hash::make((string) $request->input('password')),
                'status' => 'ACTIVE',
            ]);

            $user->assignRole($role);

            if ($role === 'business') {
                $business = Business::create([
                    'legal_name' => (string) $request->input('business_name'),
                    'trade_name' => (string) $request->input('business_name'),
                    'document_number' => (string) $request->input('business_cnpj'),
                    'status' => 'PENDING',
                ]);

                $business->users()->create([
                    'user_id' => $user->id,
                    'role' => 'OWNER',
                    'status' => 'ACTIVE',
                ]);
            } elseif ($role === 'driver') {
                $driver = Driver::create([
                    'user_id' => $user->id,
                    'national_document' => (string) $request->input('national_document'),
                    'approval_status' => 'PENDING',
                    'operational_status' => 'OFFLINE',
                ]);

                DriverVehicle::create([
                    'driver_id' => $driver->id,
                    'vehicle_type' => strtoupper((string) $request->input('vehicle_type', 'MOTORCYCLE')),
                    'plate' => (string) $request->input('vehicle_plate'),
                    'status' => 'ACTIVE',
                ]);
            }

            return $user;
        });

        $token = $user->createToken('api-token');

        return response()->json([
            'data' => [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'phone' => $user->phone,
                    'roles' => $user->getRoleNames(),
                ],
                'token' => $token->plainTextToken,
                'token_type' => 'Bearer',
                'message' => 'Conta criada com sucesso. Aguarde verificação.',
            ],
        ], 201);
    }

    /**
     * POST /api/v1/auth/logout
     *
     * Revokes the current bearer token.
     */
    public function logout(): JsonResponse
    {
        $user = auth()->user();

        if ($user) {
            $user->currentAccessToken()?->delete();
        }

        return response()->json([
            'data' => [
                'message' => 'Successfully logged out',
            ],
        ], 200);
    }

    /**
     * POST /api/v1/auth/refresh
     *
     * With Sanctum, tokens are long-lived. This endpoint issues a fresh token
     * when a valid token is presented; otherwise the caller must authenticate
     * again.
     */
    public function refresh(RefreshTokenRequest $request): JsonResponse
    {
        $user = auth()->user();

        if (! $user) {
            throw ValidationException::withMessages([
                'refresh_token' => 'Token inválido ou expirado.',
            ]);
        }

        $token = $user->createToken('api-token');

        return response()->json([
            'data' => [
                'token' => $token->plainTextToken,
                'token_type' => 'Bearer',
                'expires_in' => config('sanctum.expiration', 60 * 24),
            ],
        ], 200);
    }

    /**
     * POST /api/v1/auth/forgot-password
     *
     * Requests a password reset link. The response never reveals whether the
     * email is registered (account enumeration protection).
     */
    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $user = User::where('email', (string) $request->input('email'))->first();

        if ($user) {
            Password::createToken($user);
            // TODO: dispatch password reset email via notification channel.
        }

        return response()->json([
            'data' => [
                'message' => 'Se este email está registrado, você receberá um link de recuperação.',
            ],
        ], 200);
    }

    /**
     * POST /api/v1/auth/reset-password
     *
     * Resets the password using a valid reset token.
     */
    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $response = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user, string $password): void {
                $user->forceFill([
                    'password_hash' => Hash::make($password),
                ])->save();
            }
        );

        if ($response === Password::PASSWORD_RESET) {
            return response()->json([
                'data' => [
                    'message' => 'Senha redefinida com sucesso.',
                ],
            ], 200);
        }

        throw ValidationException::withMessages([
            'token' => 'Token de recuperação inválido ou expirado.',
        ]);
    }
}
