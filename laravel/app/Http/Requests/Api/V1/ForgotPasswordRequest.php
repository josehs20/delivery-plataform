<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class ForgotPasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'email' => ['required', 'email', 'max:255', 'exists:users'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.required' => 'Email é obrigatório.',
            'email.email' => 'Email inválido.',
            'email.exists' => 'Este email não está registrado.',
        ];
    }
}
