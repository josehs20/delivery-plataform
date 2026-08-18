<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('commissions', function (Blueprint $table) { $table->uuid('id')->primary(); $table->foreignUuid('delivery_id')->constrained()->restrictOnDelete(); $table->string('commission_type'); $table->decimal('rate',10,4)->nullable(); $table->decimal('fixed_amount',14,2)->nullable(); $table->decimal('calculated_amount',14,2); $table->string('currency',3)->default('BRL'); $table->json('snapshot')->nullable(); $table->timestampsTz(); $table->unique('delivery_id'); });
    }

    public function down(): void
    {
        Schema::dropIfExists('commissions');
    }
};
