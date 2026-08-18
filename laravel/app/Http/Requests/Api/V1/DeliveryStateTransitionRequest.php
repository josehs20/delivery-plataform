<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class DeliveryStateTransitionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->hasRole('driver');
    }

    public function rules(): array
    {
        return [
            'idempotency_key' => ['required', 'string', 'max:255'],
            'proof' => ['sometimes', 'required', 'array'],
            'proof.type' => ['required_with:proof', 'string', 'in:PHOTO,SIGNATURE,LOCATION,CUSTOMER_CONFIRMATION'],
            'proof.data' => ['required_with:proof', 'string'],
            'reason' => ['sometimes', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'idempotency_key.required' => 'Chave de idempotência é obrigatória.',
            'proof.type.required_with' => 'Tipo de prova é obrigatório.',
            'proof.type.in' => 'Tipo de prova inválido.',
            'proof.data.required_with' => 'Dados de prova são obrigatórios.',
            'reason.max' => 'Motivo não pode exceder 500 caracteres.',
        ];
    }
}
