<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('delivery_items', function (Blueprint $table) { $table->uuid('id')->primary(); $table->foreignUuid('delivery_id')->constrained()->cascadeOnDelete(); $table->string('name'); $table->text('description')->nullable(); $table->string('category')->nullable(); $table->unsignedInteger('quantity'); $table->decimal('approximate_weight',10,2)->nullable(); $table->json('dimensions')->nullable(); $table->string('special_handling')->nullable(); $table->text('notes')->nullable(); $table->timestampsTz(); });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_items');
    }
};
