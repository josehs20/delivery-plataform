<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('driver_payouts', function (Blueprint $table) { $table->uuid('id')->primary(); $table->foreignUuid('driver_id')->constrained()->restrictOnDelete(); $table->foreignUuid('delivery_id')->constrained()->restrictOnDelete(); $table->decimal('gross_amount',14,2); $table->decimal('platform_fee',14,2)->default(0); $table->decimal('other_fees',14,2)->default(0); $table->decimal('net_amount',14,2); $table->string('status')->default('PENDING'); $table->timestampTz('available_at')->nullable(); $table->timestampTz('paid_at')->nullable(); $table->string('provider_reference')->nullable()->index(); $table->timestampsTz(); $table->unique('delivery_id'); });
    }

    public function down(): void
    {
        Schema::dropIfExists('driver_payouts');
    }
};
