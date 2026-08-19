<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use App\Rules\Ulid;
use Illuminate\Foundation\Http\FormRequest;

class AdminRefundRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->hasRole('admin');
    }

    public function rules(): array
    {
        return [
            'payment_id' => ['required', new Ulid],
            'amount' => ['required', 'numeric', 'min:0.01'],
            'currency' => ['sometimes', 'string', 'in:BRL'],
            'reason' => ['required', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'payment_id.required' => 'Informe o pagamento a ser reembolsado.',
            'amount.required' => 'Informe o valor do reembolso.',
            'amount.min' => 'O valor do reembolso deve ser maior que zero.',
            'reason.required' => 'Informe o motivo do reembolso.',
        ];
    }
}
