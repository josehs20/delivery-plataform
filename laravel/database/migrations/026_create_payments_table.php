<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) { $table->uuid('id')->primary(); $table->foreignUuid('delivery_id')->constrained()->restrictOnDelete(); $table->string('payer_type'); $table->uuid('payer_id'); $table->string('provider'); $table->string('provider_payment_reference')->nullable()->index(); $table->decimal('amount',14,2); $table->string('currency',3)->default('BRL'); $table->string('status')->default('PENDING')->index(); $table->timestampTz('authorized_at')->nullable(); $table->timestampTz('captured_at')->nullable(); $table->timestampTz('failed_at')->nullable(); $table->timestampsTz(); });
    }

    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
