<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class CancelDeliveryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->hasRole('business');
    }

    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', 'in:NO_LONGER_NEEDED,WRONG_ADDRESS,CUSTOMER_REQUEST,OPERATIONAL_ISSUE'],
            'description' => ['sometimes', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'reason.required' => 'Motivo de cancelamento é obrigatório.',
            'reason.in' => 'Motivo de cancelamento inválido.',
            'description.max' => 'Descrição não pode exceder 500 caracteres.',
        ];
    }
}
