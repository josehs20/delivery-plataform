<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class RefreshTokenRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'refresh_token' => ['required', 'string'],
        ];
    }

    public function messages(): array
    {
        return [
            'refresh_token.required' => 'Token de renovação é obrigatório.',
            'refresh_token.string' => 'Token de renovação deve ser texto.',
        ];
    }
}
