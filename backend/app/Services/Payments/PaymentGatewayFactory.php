<?php

namespace App\Services\Payments;

class PaymentGatewayFactory
{
    /**
     * Resolves to the real gateway for $provider only when simulation mode
     * is off AND that provider's credentials are actually configured —
     * otherwise falls back to the simulation gateway so the booking flow
     * never breaks for lack of a live merchant account.
     */
    public static function for(string $provider): PaymentGateway
    {
        if (config('services.payment_simulation_mode', true)) {
            return new SimulationGateway;
        }

        return match ($provider) {
            'mtn_momo' => self::isConfigured('mtn_momo') ? new MtnMomoGateway : new SimulationGateway,
            'orange_money' => self::isConfigured('orange_money') ? new OrangeMoneyGateway : new SimulationGateway,
            default => new SimulationGateway,
        };
    }

    private static function isConfigured(string $provider): bool
    {
        $required = $provider === 'mtn_momo'
            ? ['subscription_key', 'api_user', 'api_key']
            : ['client_id', 'client_secret', 'merchant_key'];

        foreach ($required as $key) {
            if (blank(config("services.{$provider}.{$key}"))) {
                return false;
            }
        }

        return true;
    }
}
