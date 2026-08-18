<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) { $table->uuid('id')->primary(); $table->string('actor_type')->nullable(); $table->uuid('actor_id')->nullable(); $table->string('action'); $table->string('entity_type'); $table->uuid('entity_id')->nullable(); $table->json('before_snapshot')->nullable(); $table->json('after_snapshot')->nullable(); $table->json('metadata')->nullable(); $table->ipAddress('ip_address')->nullable(); $table->text('user_agent')->nullable(); $table->timestampTz('occurred_at'); $table->timestampsTz(); });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
    }
};
