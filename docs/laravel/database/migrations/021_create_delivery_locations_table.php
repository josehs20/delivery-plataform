<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('delivery_locations', function (Blueprint $table) { $table->uuid('id')->primary(); $table->foreignUuid('delivery_id')->constrained()->cascadeOnDelete(); $table->foreignUuid('driver_id')->constrained()->cascadeOnDelete(); $table->decimal('latitude',10,7); $table->decimal('longitude',10,7); $table->decimal('accuracy',10,2)->nullable(); $table->decimal('speed',10,2)->nullable(); $table->decimal('heading',10,2)->nullable(); $table->timestampTz('recorded_at'); $table->timestampTz('received_at'); $table->string('source')->nullable(); $table->index(['delivery_id','recorded_at']); $table->index(['driver_id','recorded_at']); });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_locations');
    }
};
