<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('sync_operations', function (Blueprint $table) { $table->uuid('id')->primary(); $table->string('client_id'); $table->string('device_id'); $table->string('operation_id'); $table->string('entity_type'); $table->uuid('entity_id'); $table->string('operation_type'); $table->json('payload')->nullable(); $table->timestampTz('client_created_at'); $table->timestampTz('received_at')->nullable(); $table->timestampTz('processed_at')->nullable(); $table->string('status')->default('PENDING'); $table->unsignedInteger('retry_count')->default(0); $table->string('error_code')->nullable(); $table->text('error_message')->nullable(); $table->timestampsTz(); $table->unique(['client_id','operation_id']); });
    }

    public function down(): void
    {
        Schema::dropIfExists('sync_operations');
    }
};
