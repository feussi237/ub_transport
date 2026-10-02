<?php

namespace App\Services\Payments;

use App\Models\Payment;
use Illuminate\Support\Str;

/**
 * Stands in for a real Mobile Money provider when PAYMENT_SIMULATION_MODE
 * is on (the default) or when the selected provider has no credentials
 * configured — lets the booking flow be demoed/graded end to end without a
 * live MTN/Orange merchant account. Confirms the charge immediately.
 */
class SimulationGateway implements PaymentGateway
{
    public function requestToPay(Payment $payment, string $phoneNumber): array
    {
        return [
            'status' => 'success',
            'provider_reference' => 'SIM-'.Str::upper(Str::random(10)),
            'redirect_url' => null,
            'message' => null,
        ];
    }

    public function checkStatus(Payment $payment): array
    {
        // initiate() already resolved this synchronously, so a status
        // check under simulation just reflects whatever is on the record.
        return ['status' => $payment->status, 'message' => null];
    }
}
