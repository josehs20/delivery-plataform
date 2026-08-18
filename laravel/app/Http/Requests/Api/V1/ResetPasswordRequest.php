<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class ResetPasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'token' => ['required', 'string'],
            'email' => ['required', 'email', 'max:255', 'exists:users'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'password_confirmation' => ['required', 'string', 'min:8'],
        ];
    }

    public function messages(): array
    {
        return [
            'token.required' => 'Token de recuperação é obrigatório.',
            'email.required' => 'Email é obrigatório.',
            'email.email' => 'Email inválido.',
            'email.exists' => 'Este email não está registrado.',
            'password.required' => 'Senha é obrigatória.',
            'password.min' => 'Senha deve ter no mínimo 8 caracteres.',
            'password.confirmed' => 'Confirmação de senha não corresponde.',
        ];
    }
}
