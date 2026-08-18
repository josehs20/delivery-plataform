<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('delivery_events', function (Blueprint $table) { $table->uuid('id')->primary(); $table->foreignUuid('delivery_id')->constrained()->cascadeOnDelete(); $table->string('event_type'); $table->string('actor_type')->nullable(); $table->uuid('actor_id')->nullable(); $table->string('source')->nullable(); $table->string('idempotency_key')->nullable(); $table->json('metadata')->nullable(); $table->timestampTz('occurred_at'); $table->timestampsTz(); $table->index(['delivery_id','occurred_at']); $table->unique(['source','idempotency_key']); });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_events');
    }
};
