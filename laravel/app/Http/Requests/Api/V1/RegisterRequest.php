<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users'],
            'phone' => ['required', 'string', 'max:20', 'unique:users'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'password_confirmation' => ['required', 'string', 'min:8'],
            'role' => ['required', 'string', 'in:business,driver'],
            'business_name' => ['required_if:role,business', 'string', 'max:255'],
            'business_cnpj' => ['required_if:role,business', 'string', 'max:20', 'unique:businesses,document_number'],
            'national_document' => ['required_if:role,driver', 'string', 'max:20', 'unique:drivers,national_document'],
            'vehicle_type' => ['required_if:role,driver', 'string', 'in:motorcycle,car,van,truck'],
            'vehicle_plate' => ['required_if:role,driver', 'string', 'max:20', 'unique:driver_vehicles,plate'],
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nome é obrigatório.',
            'email.required' => 'Email é obrigatório.',
            'email.email' => 'Email inválido.',
            'email.unique' => 'Este email já está registrado.',
            'phone.required' => 'Telefone é obrigatório.',
            'phone.unique' => 'Este telefone já está registrado.',
            'password.required' => 'Senha é obrigatória.',
            'password.min' => 'Senha deve ter no mínimo 8 caracteres.',
            'password.confirmed' => 'Confirmação de senha não corresponde.',
            'role.required' => 'Tipo de usuário é obrigatório.',
            'role.in' => 'Tipo de usuário inválido.',
            'business_name.required_if' => 'Nome da empresa é obrigatório para usuários de negócio.',
            'business_cnpj.required_if' => 'CNPJ da empresa é obrigatório para usuários de negócio.',
            'business_cnpj.unique' => 'Este CNPJ já está registrado.',
            'national_document.required_if' => 'Documento nacional é obrigatório para motoristas.',
            'national_document.unique' => 'Este documento já está registrado.',
            'vehicle_type.required_if' => 'Tipo de veículo é obrigatório para motoristas.',
            'vehicle_plate.required_if' => 'Placa do veículo é obrigatória para motoristas.',
            'vehicle_plate.unique' => 'Esta placa já está registrada.',
        ];
    }
}
