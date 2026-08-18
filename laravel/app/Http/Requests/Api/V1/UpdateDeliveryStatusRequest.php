<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use Illuminate\Foundation\Http\FormRequest;

class UpdateDeliveryStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Permissions will be checked in the controller/service layer
    }

    public function rules(): array
    {
        // The delivery ID is expected as a route parameter.
        // The status update should be in the request body.
        return [
            'status' => ['required', 'string', 'in:PICKUP_IN_PROGRESS,PICKED_UP,IN_TRANSIT,DELIVERED,FAILED,RETURNED'], // Example statuses, adjust based on Delivery Lifecycle
        ];
    }
}
