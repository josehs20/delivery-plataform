<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'identifier' => ['required', 'string', 'max:255'],
            'password' => ['required', 'string', 'min:8'],
        ];
    }

    public function messages(): array
    {
        return [
            'identifier.required' => 'Email ou telefone é obrigatório.',
            'identifier.string' => 'Email ou telefone deve ser texto.',
            'identifier.max' => 'Email ou telefone não pode exceder 255 caracteres.',
            'password.required' => 'Senha é obrigatória.',
            'password.string' => 'Senha deve ser texto.',
            'password.min' => 'Senha deve ter no mínimo 8 caracteres.',
        ];
    }
}
