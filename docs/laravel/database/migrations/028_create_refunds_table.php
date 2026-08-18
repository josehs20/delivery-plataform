<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('refunds', function (Blueprint $table) { $table->uuid('id')->primary(); $table->foreignUuid('payment_id')->constrained()->restrictOnDelete(); $table->decimal('amount',14,2); $table->string('reason'); $table->string('provider_reference')->nullable()->index(); $table->string('status')->default('PENDING'); $table->timestampTz('requested_at')->nullable(); $table->timestampTz('completed_at')->nullable(); $table->timestampsTz(); });
    }

    public function down(): void
    {
        Schema::dropIfExists('refunds');
    }
};
