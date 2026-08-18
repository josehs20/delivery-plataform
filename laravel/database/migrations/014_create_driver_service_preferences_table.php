<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('driver_service_preferences', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('driver_id')->unique()->constrained()->cascadeOnDelete();
            $table->json('accepts_categories')->nullable();
            $table->json('excluded_categories')->nullable();
            $table->decimal('max_distance_km', 10, 2)->nullable();
            $table->unsignedInteger('max_concurrent_deliveries')->default(1);
            $table->boolean('enabled')->default(true)->index();
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('driver_service_preferences');
    }
};
