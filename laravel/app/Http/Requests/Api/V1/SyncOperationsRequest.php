<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class SyncOperationsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        return [
            'operations' => ['required', 'array', 'min:1'],
            'operations.*.id' => ['required', 'string', 'max:255'],
            'operations.*.idempotency_key' => ['required', 'string', 'max:255'],
            'operations.*.entity' => ['required', 'string', 'in:delivery,location,proof,event'],
            'operations.*.operation' => ['required', 'string', 'in:CREATE,UPDATE,DELETE'],
            'operations.*.payload' => ['required', 'array'],
            'operations.*.priority' => ['sometimes', 'integer', 'in:1,2,3,4,5'],
            'operations.*.created_at' => ['required', 'date'],
            'sync_token' => ['sometimes', 'string', 'max:255'],
        ];
    }

    public function messages(): array
    {
        return [
            'operations.required' => 'Operações são obrigatórias.',
            'operations.min' => 'Deve haver no mínimo 1 operação.',
            'operations.*.id.required' => 'ID da operação é obrigatório.',
            'operations.*.idempotency_key.required' => 'Chave de idempotência é obrigatória.',
            'operations.*.entity.required' => 'Entidade é obrigatória.',
            'operations.*.entity.in' => 'Entidade inválida.',
            'operations.*.operation.required' => 'Operação é obrigatória.',
            'operations.*.operation.in' => 'Operação inválida.',
            'operations.*.payload.required' => 'Payload é obrigatório.',
            'operations.*.priority.in' => 'Prioridade deve estar entre 1 e 5.',
            'operations.*.created_at.required' => 'Data de criação é obrigatória.',
            'operations.*.created_at.date_format' => 'Data deve estar no formato ISO 8601.',
        ];
    }
}
