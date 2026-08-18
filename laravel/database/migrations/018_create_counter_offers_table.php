<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('counter_offers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('delivery_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('driver_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('previous_counter_offer_id')->nullable()->constrained('counter_offers')->nullOnDelete();
            $table->decimal('amount', 14, 2);
            $table->string('currency', 3)->default('BRL');
            $table->string('status')->default('PENDING');
            $table->text('message')->nullable();
            $table->timestampTz('valid_until')->nullable();
            $table->timestampTz('responded_at')->nullable();
            $table->timestampsTz();

            $table->index(['delivery_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('counter_offers');
    }
};
