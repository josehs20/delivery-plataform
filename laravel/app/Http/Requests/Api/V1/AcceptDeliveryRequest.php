<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use App\Rules\Ulid;
use Illuminate\Foundation\Http\FormRequest;

class AcceptDeliveryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->hasRole('driver');
    }

    public function rules(): array
    {
        return [
            'idempotency_key' => ['required', 'string', 'max:255'],
            'offer_id' => ['required', 'string', new Ulid()],
        ];
    }

    public function messages(): array
    {
        return [
            'idempotency_key.required' => 'Chave de idempotência é obrigatória.',
            'offer_id.required' => 'ID da oferta é obrigatório.',
        ];
    }
}
