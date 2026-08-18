<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('driver_documents', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('driver_id')->constrained()->cascadeOnDelete();
            $table->string('document_type');
            $table->string('document_number')->nullable();
            $table->date('expires_at')->nullable();
            $table->string('object_key');
            $table->string('verification_status')->default('PENDING');
            $table->foreignUuid('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('verified_at')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->timestampsTz();
            $table->index(['driver_id', 'document_type']);
            $table->index('expires_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('driver_documents');
    }
};
