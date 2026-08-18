<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Pricing configuration
    |--------------------------------------------------------------------------
    |
    | Baseline pricing used when the backend calculates the suggested amount
    | (docs/domain/06-pricing-and-negotiation.md). Values are configurable so
    | the business rules can evolve without code changes.
    |
    */

    'pricing' => [
        'base_fee' => (float) env('DELIVERY_BASE_FEE', 10.00),
        'per_km' => (float) env('DELIVERY_PER_KM', 1.50),
        'currency' => env('DELIVERY_CURRENCY', 'BRL'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Dispatch configuration
    |--------------------------------------------------------------------------
    |
    | ADR-006: geospatial dispatch by proximity to the pickup location.
    |
    */

    'dispatch' => [
        'default_radius_km' => (float) env('DELIVERY_DISPATCH_RADIUS_KM', 50.0),
        'offer_window_minutes' => (int) env('DELIVERY_OFFER_WINDOW_MINUTES', 15),
        'location_age_minutes' => (int) env('DELIVERY_LOCATION_AGE_MINUTES', 30),
        'operational_statuses' => ['AVAILABLE', 'ONLINE'],
    ],

];
