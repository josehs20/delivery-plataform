<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use App\Rules\Ulid;
use Illuminate\Foundation\Http\FormRequest;

class AdminAssignDeliveryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->hasRole('admin');
    }

    public function rules(): array
    {
        return [
            'driver_id' => ['required', new Ulid],
        ];
    }

    public function messages(): array
    {
        return [
            'driver_id.required' => 'Informe o motorista a ser atribuído.',
        ];
    }
}
