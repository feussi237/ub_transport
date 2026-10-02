<?php

namespace App\Services\Payments;

use App\Models\Payment;

interface PaymentGateway
{
    /**
     * Starts the charge. For a push-based provider (MTN MoMo) this prompts
     * the payer's phone directly and returns status 'pending' until they
     * approve. For a redirect-based provider (Orange Money web payment) it
     * returns 'pending' plus a 'redirect_url' the client must open.
     *
     * @return array{status: string, provider_reference: ?string, redirect_url: ?string, message: ?string}
     */
    public function requestToPay(Payment $payment, string $phoneNumber): array;

    /**
     * Polls the provider for the current status of an already-initiated
     * payment. Called by the status-check endpoint since webhook delivery
     * can't be relied on in a local/sandbox environment.
     *
     * @return array{status: string, message: ?string}
     */
    public function checkStatus(Payment $payment): array;
}
