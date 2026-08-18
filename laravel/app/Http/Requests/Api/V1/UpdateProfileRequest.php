<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = (string) $this->user()->id ?? null;

        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'phone' => ['sometimes', 'required', 'string', 'max:20', 'unique:users,phone,' . $userId],
            'email' => ['sometimes', 'required', 'email', 'max:255', 'unique:users,email,' . $userId],
            'current_password' => ['required_with:password', 'string'],
            'password' => ['sometimes', 'required', 'string', 'min:8', 'confirmed'],
            'password_confirmation' => ['required_with:password', 'string', 'min:8'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.string' => 'Nome deve ser texto.',
            'phone.unique' => 'Este telefone já está registrado.',
            'email.email' => 'Email inválido.',
            'email.unique' => 'Este email já está registrado.',
            'current_password.required_with' => 'Senha atual é obrigatória ao alterar senha.',
            'password.min' => 'Senha deve ter no mínimo 8 caracteres.',
            'password.confirmed' => 'Confirmação de senha não corresponde.',
        ];
    }
}
