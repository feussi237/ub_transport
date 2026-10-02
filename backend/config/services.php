<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    /*
    | AI Assistant — any OpenAI-compatible chat-completions endpoint
    | (OpenAI itself, or a compatible provider). Leave AI_API_KEY empty
    | to keep the assistant disabled without breaking the rest of the app.
    */
    'ai' => [
        'key' => env('AI_API_KEY'),
        'base_url' => env('AI_API_BASE_URL', 'https://api.openai.com/v1'),
        'model' => env('AI_MODEL', 'gpt-4o-mini'),
    ],

    /*
    | Mobile Money payment gateways. PAYMENT_SIMULATION_MODE defaults to
    | true so the booking flow works end to end without a live merchant
    | account; set it to false once real credentials are filled in below
    | for the provider(s) you want to go live with. A provider with blank
    | credentials is used in simulation even if the flag is false.
    */
    'payment_simulation_mode' => env('PAYMENT_SIMULATION_MODE', true),

    'mtn_momo' => [
        'base_url' => env('MTN_MOMO_BASE_URL', 'https://sandbox.momodeveloper.mtn.com'),
        'subscription_key' => env('MTN_MOMO_SUBSCRIPTION_KEY'),
        'api_user' => env('MTN_MOMO_API_USER'),
        'api_key' => env('MTN_MOMO_API_KEY'),
        'target_environment' => env('MTN_MOMO_TARGET_ENVIRONMENT', 'sandbox'),
        'currency' => env('MTN_MOMO_CURRENCY', 'XAF'),
    ],

    'orange_money' => [
        'base_url' => env('ORANGE_MONEY_BASE_URL', 'https://api.orange.com'),
        'client_id' => env('ORANGE_MONEY_CLIENT_ID'),
        'client_secret' => env('ORANGE_MONEY_CLIENT_SECRET'),
        'merchant_key' => env('ORANGE_MONEY_MERCHANT_KEY'),
        'return_url' => env('ORANGE_MONEY_RETURN_URL'),
        'cancel_url' => env('ORANGE_MONEY_CANCEL_URL'),
        'notif_url' => env('ORANGE_MONEY_NOTIF_URL'),
        'currency' => env('ORANGE_MONEY_CURRENCY', 'XAF'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

];
