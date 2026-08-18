<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class CreateDeliveryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null && $this->user()->hasRole('business');
    }

    public function rules(): array
    {
        return [
            'origin' => ['required', 'array'],
            'origin.address' => ['required', 'string', 'max:500'],
            'origin.latitude' => ['required', 'numeric', 'between:-90,90'],
            'origin.longitude' => ['required', 'numeric', 'between:-180,180'],
            'origin.reference' => ['sometimes', 'string', 'max:255'],

            'destination' => ['required', 'array'],
            'destination.address' => ['required', 'string', 'max:500'],
            'destination.latitude' => ['required', 'numeric', 'between:-90,90'],
            'destination.longitude' => ['required', 'numeric', 'between:-180,180'],
            'destination.reference' => ['sometimes', 'string', 'max:255'],

            'recipient' => ['required', 'array'],
            'recipient.name' => ['required', 'string', 'max:255'],
            'recipient.phone' => ['required', 'string', 'max:20'],

            'items' => ['required', 'array', 'min:1'],
            'items.*.name' => ['required', 'string', 'max:255'],
            'items.*.category' => ['required', 'string', 'in:GENERAL,FRAGILE,FROZEN,HAZMAT,HAZMAT_RESTRICTED'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'items.*.approximate_weight' => ['required', 'numeric', 'min:0.1'],
            'items.*.notes' => ['sometimes', 'string', 'max:500'],

            'pricing' => ['required', 'array'],
            'pricing.mode' => ['required', 'string', 'in:CALCULATED,MANUAL'],
            'pricing.manual_value' => ['required_if:pricing.mode,MANUAL', 'numeric', 'min:0'],

            'pickup_deadline' => ['required', 'date_format:Y-m-d\TH:i:s\Z', 'after:now'],
        ];
    }

    public function messages(): array
    {
        return [
            'origin.required' => 'Origem é obrigatória.',
            'origin.array' => 'Origem deve ser um objeto.',
            'origin.address.required' => 'Endereço de origem é obrigatório.',
            'origin.latitude.required' => 'Latitude de origem é obrigatória.',
            'origin.longitude.required' => 'Longitude de origem é obrigatória.',
            'origin.latitude.between' => 'Latitude deve estar entre -90 e 90.',
            'origin.longitude.between' => 'Longitude deve estar entre -180 e 180.',

            'destination.required' => 'Destino é obrigatório.',
            'destination.array' => 'Destino deve ser um objeto.',
            'destination.address.required' => 'Endereço de destino é obrigatório.',
            'destination.latitude.required' => 'Latitude de destino é obrigatória.',
            'destination.longitude.required' => 'Longitude de destino é obrigatória.',
            'destination.latitude.between' => 'Latitude deve estar entre -90 e 90.',
            'destination.longitude.between' => 'Longitude deve estar entre -180 e 180.',

            'recipient.required' => 'Informações do destinatário são obrigatórias.',
            'recipient.name.required' => 'Nome do destinatário é obrigatório.',
            'recipient.phone.required' => 'Telefone do destinatário é obrigatório.',

            'items.required' => 'Pelo menos um item é obrigatório.',
            'items.min' => 'Deve haver no mínimo 1 item.',
            'items.*.name.required' => 'Nome do item é obrigatório.',
            'items.*.category.required' => 'Categoria do item é obrigatória.',
            'items.*.category.in' => 'Categoria de item inválida.',
            'items.*.quantity.required' => 'Quantidade é obrigatória.',
            'items.*.quantity.min' => 'Quantidade deve ser no mínimo 1.',
            'items.*.approximate_weight.required' => 'Peso aproximado é obrigatório.',
            'items.*.approximate_weight.min' => 'Peso deve ser no mínimo 0.1 kg.',

            'pricing.required' => 'Informações de preço são obrigatórias.',
            'pricing.mode.required' => 'Modo de preço é obrigatório.',
            'pricing.mode.in' => 'Modo de preço inválido.',
            'pricing.manual_value.required_if' => 'Valor manual é obrigatório quando modo é MANUAL.',

            'pickup_deadline.required' => 'Prazo de coleta é obrigatório.',
            'pickup_deadline.date_format' => 'Prazo deve estar no formato ISO 8601.',
            'pickup_deadline.after' => 'Prazo deve ser no futuro.',
        ];
    }
}
