<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Motivo da rejeição cadastral de um motorista (fluxo de aprovação do admin,
     * docs/docs/api/41-admin-api.md). Persistido para a tela do motoboy e auditoria.
     */
    public function up(): void
    {
        Schema::table('drivers', function (Blueprint $table) {
            $table->text('rejection_reason')->nullable()->after('approved_at');
        });
    }

    public function down(): void
    {
        Schema::table('drivers', function (Blueprint $table) {
            $table->dropColumn('rejection_reason');
        });
    }
};
