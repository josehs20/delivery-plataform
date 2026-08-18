<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('delivery_assignments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('delivery_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('driver_id')->constrained()->restrictOnDelete();
            $table->string('source_type');
            $table->uuid('source_reference_id')->nullable();
            $table->decimal('agreed_amount', 14, 2);
            $table->string('status')->default('ACTIVE');
            $table->timestampTz('assigned_at');
            $table->timestampTz('accepted_at')->nullable();
            $table->timestampTz('released_at')->nullable();
            $table->timestampsTz();

            $table->index(['delivery_id', 'status']);
            $table->index(['driver_id', 'status']);

            // MySQL does not support partial unique indexes. A generated
            // column that equals the row id only when status = 'ACTIVE'
            // reproduces the "one active assignment per delivery" database
            // invariant required by ADR-004.
            $table->string('active_guard')
                ->virtualAs("IF(status = 'ACTIVE', id, NULL)")
                ->nullable()
                ->unique();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('delivery_assignments');
    }
};
