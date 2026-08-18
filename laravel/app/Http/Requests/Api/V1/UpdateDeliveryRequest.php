<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class UpdateDeliveryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->hasRole('business');
    }

    public function rules(): array
    {
        return [
            'origin' => ['sometimes', 'required', 'array'],
            'origin.address' => ['required_with:origin', 'string', 'max:500'],
            'origin.latitude' => ['required_with:origin', 'numeric', 'between:-90,90'],
            'origin.longitude' => ['required_with:origin', 'numeric', 'between:-180,180'],
            'origin.reference' => ['sometimes', 'string', 'max:255'],

            'destination' => ['sometimes', 'required', 'array'],
            'destination.address' => ['required_with:destination', 'string', 'max:500'],
            'destination.latitude' => ['required_with:destination', 'numeric', 'between:-90,90'],
            'destination.longitude' => ['required_with:destination', 'numeric', 'between:-180,180'],
            'destination.reference' => ['sometimes', 'string', 'max:255'],

            'recipient' => ['sometimes', 'required', 'array'],
            'recipient.name' => ['required_with:recipient', 'string', 'max:255'],
            'recipient.phone' => ['required_with:recipient', 'string', 'max:20'],

            'items' => ['sometimes', 'required', 'array', 'min:1'],
            'items.*.name' => ['required_with:items', 'string', 'max:255'],
            'items.*.category' => ['required_with:items', 'string', 'in:GENERAL,FRAGILE,FROZEN,HAZMAT,HAZMAT_RESTRICTED'],
            'items.*.quantity' => ['required_with:items', 'integer', 'min:1'],
            'items.*.approximate_weight' => ['required_with:items', 'numeric', 'min:0.1'],
            'items.*.notes' => ['sometimes', 'string', 'max:500'],

            'pricing' => ['sometimes', 'required', 'array'],
            'pricing.mode' => ['required_with:pricing', 'string', 'in:CALCULATED,MANUAL'],
            'pricing.manual_value' => ['required_if:pricing.mode,MANUAL', 'numeric', 'min:0'],

            'pickup_deadline' => ['sometimes', 'required', 'date_format:Y-m-d\TH:i:s\Z', 'after:now'],
        ];
    }

    public function messages(): array
    {
        return [
            'origin.address.required_with' => 'Endereço de origem é obrigatório.',
            'origin.latitude.required_with' => 'Latitude de origem é obrigatória.',
            'origin.longitude.required_with' => 'Longitude de origem é obrigatória.',
            'origin.latitude.between' => 'Latitude deve estar entre -90 e 90.',
            'origin.longitude.between' => 'Longitude deve estar entre -180 e 180.',

            'destination.address.required_with' => 'Endereço de destino é obrigatório.',
            'destination.latitude.required_with' => 'Latitude de destino é obrigatória.',
            'destination.longitude.required_with' => 'Longitude de destino é obrigatória.',
            'destination.latitude.between' => 'Latitude deve estar entre -90 e 90.',
            'destination.longitude.between' => 'Longitude deve estar entre -180 e 180.',

            'recipient.name.required_with' => 'Nome do destinatário é obrigatório.',
            'recipient.phone.required_with' => 'Telefone do destinatário é obrigatório.',

            'items.min' => 'Deve haver no mínimo 1 item.',
            'items.*.name.required_with' => 'Nome do item é obrigatório.',
            'items.*.category.required_with' => 'Categoria do item é obrigatória.',
            'items.*.category.in' => 'Categoria de item inválida.',
            'items.*.quantity.required_with' => 'Quantidade é obrigatória.',
            'items.*.quantity.min' => 'Quantidade deve ser no mínimo 1.',
            'items.*.approximate_weight.required_with' => 'Peso aproximado é obrigatório.',
            'items.*.approximate_weight.min' => 'Peso deve ser no mínimo 0.1 kg.',

            'pricing.mode.required_with' => 'Modo de preço é obrigatório.',
            'pricing.mode.in' => 'Modo de preço inválido.',
            'pricing.manual_value.required_if' => 'Valor manual é obrigatório quando modo é MANUAL.',

            'pickup_deadline.date_format' => 'Prazo deve estar no formato ISO 8601.',
            'pickup_deadline.after' => 'Prazo deve ser no futuro.',
        ];
    }
}
