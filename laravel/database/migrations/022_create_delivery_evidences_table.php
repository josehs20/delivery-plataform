<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('delivery_evidences', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('delivery_id')->constrained()->cascadeOnDelete();
            $table->string('evidence_type');
            $table->string('object_key');
            $table->timestampTz('captured_at')->nullable();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->string('captured_by_type')->nullable();
            $table->uuid('captured_by_id')->nullable();
            $table->json('metadata')->nullable();
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_evidences');
    }
};
