<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            // The gateway's own transaction id, when it differs from our transaction_ref
            // (e.g. Orange Money's pay_token). Used to reconcile status checks/callbacks.
            $table->string('provider_reference')->nullable()->after('transaction_ref');
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropColumn('provider_reference');
        });
    }
};
