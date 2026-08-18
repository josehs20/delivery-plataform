<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('payment_transactions', function (Blueprint $table) { $table->uuid('id')->primary(); $table->foreignUuid('payment_id')->constrained()->restrictOnDelete(); $table->string('transaction_type'); $table->string('provider'); $table->string('provider_reference'); $table->decimal('amount',14,2); $table->string('status'); $table->json('payload_snapshot')->nullable(); $table->timestampTz('occurred_at'); $table->timestampsTz(); $table->unique(['provider','provider_reference','transaction_type'], 'paytxn_provider_ref_type_unique'); });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_transactions');
    }
};
