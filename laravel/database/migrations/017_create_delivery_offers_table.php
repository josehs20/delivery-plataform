<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('delivery_offers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('delivery_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('driver_id')->constrained()->cascadeOnDelete();
            $table->string('status')->default('PENDING');
            $table->decimal('offered_amount', 14, 2)->nullable();
            $table->timestampTz('available_until')->nullable();
            $table->timestampTz('sent_at')->nullable();
            $table->timestampTz('responded_at')->nullable();
            $table->timestampsTz();

            $table->index(['delivery_id', 'status']);
            $table->index(['driver_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_offers');
    }
};
