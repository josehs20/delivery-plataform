<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('driver_vehicles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('driver_id')->constrained()->cascadeOnDelete();
            $table->string('vehicle_type')->default('MOTORCYCLE');
            $table->string('brand')->nullable();
            $table->string('model')->nullable();
            $table->unsignedSmallInteger('year')->nullable();
            $table->string('color')->nullable();
            $table->string('plate')->unique();
            $table->string('status')->default('ACTIVE');
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('driver_vehicles');
    }
};
