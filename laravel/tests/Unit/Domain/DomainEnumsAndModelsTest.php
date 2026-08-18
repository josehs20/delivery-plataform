<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Delivery\Enums\DeliveryStatus;
use App\Domain\Delivery\Enums\OfferStatus;
use App\Domain\Delivery\Enums\PaymentStatus;
use App\Models\Delivery;
use App\Models\Payment;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

class DomainEnumsAndModelsTest extends TestCase
{
    #[Test]
    public function it_has_expected_domain_enums(): void
    {
        $this->assertSame('DRAFT', DeliveryStatus::DRAFT->value);
        $this->assertSame('PENDING', OfferStatus::PENDING->value);
        $this->assertSame('CAPTURED', PaymentStatus::CAPTURED->value);
    }

    #[Test]
    public function it_registers_core_domain_models(): void
    {
        $this->assertTrue(class_exists(Delivery::class));
        $this->assertTrue(class_exists(Payment::class));
    }
}
