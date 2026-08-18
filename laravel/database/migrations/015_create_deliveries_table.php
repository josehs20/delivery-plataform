<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('deliveries', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('business_id')->constrained()->restrictOnDelete();
            $table->foreignUuid('current_driver_id')->nullable()->constrained('drivers')->nullOnDelete();
            $table->string('status')->default('DRAFT')->index();
            $table->string('pricing_mode')->default('CALCULATED');
            $table->string('currency', 3)->default('BRL');
            $table->decimal('suggested_amount', 14, 2)->nullable();
            $table->decimal('merchant_offered_amount', 14, 2)->nullable();
            $table->decimal('accepted_amount', 14, 2)->nullable();
            $table->json('origin_snapshot');
            $table->json('destination_snapshot');
            $table->string('recipient_name');
            $table->string('recipient_phone');
            $table->text('recipient_reference')->nullable();
            $table->timestampTz('pickup_deadline')->nullable();
            $table->timestampTz('published_at')->nullable();
            $table->timestampTz('accepted_at')->nullable();
            $table->timestampTz('picked_up_at')->nullable();
            $table->timestampTz('delivered_at')->nullable();
            $table->timestampTz('cancelled_at')->nullable();
            $table->timestampsTz();

            $table->index(['business_id', 'created_at']);
            $table->index(['status', 'created_at']);
            $table->index(['current_driver_id', 'status']);
            $table->index(['pickup_deadline', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('deliveries');
    }
};
