<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trips', function (Blueprint $table) {
            $table->id();
            $table->foreignId('agency_id')->constrained()->cascadeOnDelete();
            $table->foreignId('bus_id')->constrained()->restrictOnDelete();
            $table->string('origin_city');
            $table->string('destination_city');
            $table->dateTime('departure_at');
            $table->dateTime('arrival_at_estimate')->nullable();
            $table->decimal('price', 10, 2);
            $table->enum('status', ['scheduled', 'delayed', 'cancelled', 'completed'])->default('scheduled');
            $table->timestamps();

            $table->index(['origin_city', 'destination_city', 'departure_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trips');
    }
};
