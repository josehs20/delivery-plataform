<?php

namespace Tests;

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Support\Facades\DB;

abstract class TestCase extends BaseTestCase
{
    /**
     * Força a suíte a usar o banco de testes (delivery_platform_test), nunca o
     * banco de desenvolvimento.
     *
     * O container injeta DB_DATABASE=delivery_platform e o `artisan test` já
     * resolveu a config com esse valor antes de o phpunit.xml aplicar o <env>;
     * por isso o override é feito aqui, logo após a criação do app e ANTES do
     * RefreshDatabase executar o migrate:fresh (que apagaria o banco de dev).
     */
    public function createApplication(): Application
    {
        $app = parent::createApplication();

        config(['database.connections.mysql.database' => env('DB_DATABASE_TEST', 'delivery_platform_test')]);
        DB::purge('mysql');

        return $app;
    }
}
