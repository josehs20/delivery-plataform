<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class AdminCancelDeliveryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->hasRole('admin');
    }

    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', 'max:500'],
            'refund_type' => ['sometimes', 'string', 'in:NONE,FULL,PARTIAL'],
            'description' => ['sometimes', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'reason.required' => 'Informe o motivo do cancelamento administrativo.',
            'refund_type.in' => 'Tipo de reembolso inválido.',
        ];
    }
}
