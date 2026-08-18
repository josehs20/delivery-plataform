<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('delivery_returns', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('delivery_id')->constrained()->cascadeOnDelete();
            $table->string('initiated_by_type');
            $table->uuid('initiated_by_id');
            $table->string('status')->default('REQUIRED');
            $table->timestampTz('pickup_confirmed_at')->nullable();
            $table->timestampTz('returned_at')->nullable();
            $table->foreignUuid('return_evidence_id')->nullable()->constrained('delivery_evidences')->nullOnDelete();
            $table->timestampTz('merchant_confirmed_at')->nullable();
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_returns');
    }
};
