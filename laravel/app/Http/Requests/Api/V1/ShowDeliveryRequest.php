<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class ShowDeliveryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Permissions will be checked in the controller/service layer
    }

    public function rules(): array
    {
        // The delivery ID is expected as a route parameter, not in the request body.
        // The route definition will handle its validation (e.g., uuid format).
        return []; 
    }
}
