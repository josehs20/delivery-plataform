<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('business_users', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('business_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('user_id')->constrained()->cascadeOnDelete();
            $table->string('role')->default('OWNER');
            $table->string('status')->default('ACTIVE');
            $table->timestampsTz();
            $table->unique(['business_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('business_users');
    }
};
