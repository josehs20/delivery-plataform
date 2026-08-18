<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('businesses', function (Blueprint $table) { $table->uuid('id')->primary(); $table->string('legal_name'); $table->string('trade_name'); $table->string('document_number')->unique(); $table->string('status')->default('PENDING')->index(); $table->timestampsTz(); });
    }

    public function down(): void
    {
        Schema::dropIfExists('businesses');
    }
};
