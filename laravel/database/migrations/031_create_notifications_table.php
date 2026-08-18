<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) { $table->uuid('id')->primary(); $table->foreignUuid('user_id')->constrained()->cascadeOnDelete(); $table->string('type'); $table->string('title'); $table->text('body'); $table->json('data')->nullable(); $table->string('channel')->default('PUSH'); $table->string('status')->default('PENDING'); $table->timestampTz('sent_at')->nullable(); $table->timestampTz('read_at')->nullable(); $table->timestampsTz(); });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
