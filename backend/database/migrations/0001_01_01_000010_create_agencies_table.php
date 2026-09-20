<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('agencies', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('registration_no')->unique();
            $table->enum('status', ['pending', 'verified', 'suspended'])->default('pending');
            $table->string('contact_phone');
            $table->string('contact_email')->nullable();
            $table->string('address')->nullable();
            $table->decimal('commission_rate', 5, 2)->default(10.00);
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('agencies');
    }
};
