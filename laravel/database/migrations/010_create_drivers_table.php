<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('drivers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->string('national_document')->unique();
            $table->string('approval_status')->default('PENDING')->index();
            $table->string('operational_status')->default('OFFLINE')->index();
            $table->timestampTz('last_online_at')->nullable();
            $table->timestampTz('approved_at')->nullable();
            $table->timestampsTz();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('drivers');
    }
};
