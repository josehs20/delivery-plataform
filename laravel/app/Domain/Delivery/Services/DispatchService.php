<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Services;

use App\Domain\Delivery\Enums\OfferStatus;
use App\Models\Delivery;
use App\Models\DeliveryLocation;
use App\Models\DeliveryOffer;
use App\Models\Driver;
use Carbon\Carbon;
use Illuminate\Database\Query\JoinClause;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * DispatchService
 *
 * Implements ADR-006: geospatial dispatch by proximity to the pickup location.
 *
 * Uses a plain SQL Haversine distance (MySQL-compatible, no spatial extension)
 * over the driver's latest recorded position.
 */
final class DispatchService
{
    /**
     * Find nearby eligible drivers.
     *
     * Criteria:
     * - approved (approval_status = APPROVED);
     * - operational (operational_status in the configured set);
     * - recent location (recorded within the last N minutes);
     * - within the configured radius.
     *
     * Results are ordered by proximity (nearest first).
     *
     * @return Collection<int, Driver>
     */
    public function findNearbyDrivers(
        float $pickupLatitude,
        float $pickupLongitude,
        ?float $radiusKm = null,
        int $locationAgeMinutes = 30
    ): Collection {
        $radiusKm ??= (float) config('delivery.dispatch.default_radius_km', 50.0);
        $cutoffTime = Carbon::now()->subMinutes($locationAgeMinutes);
        $operationalStatuses = config('delivery.dispatch.operational_statuses', ['AVAILABLE', 'ONLINE']);

        $distanceExpr = $this->haversineExpression($pickupLatitude, $pickupLongitude);

        $latestLocations = DeliveryLocation::query()
            ->select('driver_id', 'latitude', 'longitude', 'recorded_at')
            ->whereRaw('recorded_at = (SELECT MAX(recorded_at) FROM delivery_locations dl2 WHERE dl2.driver_id = delivery_locations.driver_id)')
            ->where('recorded_at', '>=', $cutoffTime);

        $rows = DB::table('drivers')
            ->joinSub($latestLocations, 'delivery_locations', function (JoinClause $join): void {
                $join->on('drivers.id', '=', 'delivery_locations.driver_id');
            })
            ->select(
                'drivers.*',
                'delivery_locations.latitude',
                'delivery_locations.longitude',
                DB::raw($distanceExpr.' as distance_km')
            )
            ->where('drivers.approval_status', '=', 'APPROVED')
            ->whereIn('drivers.operational_status', $operationalStatuses)
            ->whereRaw($distanceExpr.' <= ?', [$radiusKm])
            ->orderBy('distance_km', 'asc')
            ->get();

        return $rows->map(function (object $row): Driver {
            $driver = (new Driver())->newFromBuilder((array) $row);
            $driver->distance_km = (float) $row->distance_km;

            return $driver;
        })->values();
    }

    /**
     * Create delivery offers for all nearby eligible drivers.
     *
     * @throws \Throwable
     *
     * @return Collection<int, DeliveryOffer>
     */
    public function createOffersForDelivery(
        Delivery $delivery,
        ?float $radiusKm = null,
        ?int $offerWindowMinutes = null
    ): Collection {
        $radiusKm ??= (float) config('delivery.dispatch.default_radius_km', 50.0);
        $offerWindowMinutes ??= (int) config('delivery.dispatch.offer_window_minutes', 15);

        $origin = $delivery->origin_snapshot;
        $pickupLatitude = (float) ($origin['latitude'] ?? 0);
        $pickupLongitude = (float) ($origin['longitude'] ?? 0);

        if ($pickupLatitude === 0.0 || $pickupLongitude === 0.0) {
            return collect([]);
        }

        $nearbyDrivers = $this->findNearbyDrivers($pickupLatitude, $pickupLongitude, $radiusKm);

        if ($nearbyDrivers->isEmpty()) {
            return collect([]);
        }

        return DB::transaction(function () use ($delivery, $nearbyDrivers, $offerWindowMinutes): Collection {
            $offers = [];
            $expiresAt = Carbon::now()->addMinutes($offerWindowMinutes);

            foreach ($nearbyDrivers as $driver) {
                $offer = DeliveryOffer::create([
                    'delivery_id' => $delivery->id,
                    'driver_id' => $driver->id,
                    'status' => OfferStatus::PENDING->value,
                    'offered_amount' => $delivery->merchant_offered_amount ?? $delivery->suggested_amount,
                    'available_until' => $expiresAt,
                    'sent_at' => now(),
                ]);

                $offers[] = $offer;
            }

            return collect($offers);
        });
    }

    /**
     * Haversine distance (km) SQL expression for MySQL.
     *
     * MySQL converts DECIMAL columns to DOUBLE automatically in math
     * functions, so no explicit cast is required.
     */
    private function haversineExpression(float $latitude, float $longitude): string
    {
        return sprintf(
            '6371.0 * acos(least(1.0, greatest(-1.0, '
            .'cos(radians(%f)) * cos(radians(delivery_locations.latitude)) '
            .'* cos(radians(delivery_locations.longitude - %f)) '
            .' + sin(radians(%f)) * sin(radians(delivery_locations.latitude)))))',
            $latitude,
            $longitude,
            $latitude
        );
    }
}
