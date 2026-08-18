<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('user_sessions', function (Blueprint $table) { $table->uuid('id')->primary(); $table->foreignUuid('user_id')->constrained()->cascadeOnDelete(); $table->string('device_id')->nullable()->index(); $table->string('token_hash'); $table->timestampTz('expires_at')->nullable(); $table->timestampTz('revoked_at')->nullable(); $table->timestampsTz(); $table->unique(['user_id','token_hash']); });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_sessions');
    }
};
