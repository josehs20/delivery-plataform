<?php

declare(strict_types=1);

namespace App\Http\Requests\Api\V1;

use App\Rules\Ulid;
use Illuminate\Foundation\Http\FormRequest;

class ListDeliveriesRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Permissions will be checked in the controller/service layer
    }

    public function rules(): array
    {
        // Rules for filtering and pagination, if any, would go here.
        // Based on OpenAPI and DeliveryAPI docs, no specific filtering rules mentioned for listing.
        // Commonly, parameters like 'status', 'driver_id', 'business_id', 'sort_by', 'sort_order', 'page', 'limit' might be expected.
        return [
            'status' => ['nullable', 'string', 'in:DRAFT,OPEN,NEGOTIATING,ASSIGNED,DRIVER_ACCEPTED,GOING_TO_PICKUP,AT_PICKUP,PICKED_UP,IN_TRANSIT,AT_DESTINATION,DELIVERED,DELIVERY_FAILED,RETURN_REQUIRED,RETURN_IN_PROGRESS,RETURNED,CANCELLED'],
            'driver_id' => ['nullable', new Ulid()],
            'business_id' => ['nullable', new Ulid()],
            'sort_by' => ['nullable', 'string', 'in:created_at,updated_at,suggested_amount'],
            'sort_order' => ['nullable', 'string', 'in:asc,desc'],
            'page' => ['nullable', 'integer', 'min:1'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:100'],
        ];
    }
}
