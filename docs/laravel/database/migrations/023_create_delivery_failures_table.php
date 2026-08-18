<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('delivery_failures', function (Blueprint $table) { $table->uuid('id')->primary(); $table->foreignUuid('delivery_id')->constrained()->cascadeOnDelete(); $table->string('reason'); $table->text('description')->nullable(); $table->string('reported_by_type'); $table->uuid('reported_by_id'); $table->boolean('requires_return')->default(false); $table->string('resolution_status')->default('PENDING'); $table->timestampsTz(); });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_failures');
    }
};
