<?php

use App\Http\Controllers\Api\Admin\AgencyController as AdminAgencyController;
use App\Http\Controllers\Api\Admin\UserController as AdminUserController;
use App\Http\Controllers\Api\AgencyController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\BusController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\TicketController;
use App\Http\Controllers\Api\TripController;
use App\Models\Role;
use Illuminate\Support\Facades\Route;

// --- Public -----------------------------------------------------------
Route::post('/auth/register/passenger', [AuthController::class, 'registerPassenger']);
Route::post('/auth/register/agency', [AuthController::class, 'registerAgency']);
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/payments/webhook', [PaymentController::class, 'handleWebhook']);

Route::get('/trips', [TripController::class, 'index']);
Route::get('/trips/{trip}', [TripController::class, 'show']);
Route::get('/agencies/{agency}', [AgencyController::class, 'show']);
Route::get('/agencies/{agency}/reviews', [ReviewController::class, 'index']);

// --- Authenticated (any role) -----------------------------------------
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    Route::get('/messages', [MessageController::class, 'index']);
    Route::post('/messages', [MessageController::class, 'store']);

    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::post('/notifications/{notification}/read', [NotificationController::class, 'markRead']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllRead']);
});

// --- Passenger ----------------------------------------------------------
Route::middleware(['auth:sanctum', 'role:'.Role::PASSENGER])->group(function () {
    Route::get('/bookings', [BookingController::class, 'index']);
    Route::post('/bookings', [BookingController::class, 'store']);
    Route::get('/bookings/{booking}', [BookingController::class, 'show']);
    Route::post('/bookings/{booking}/cancel', [BookingController::class, 'cancel']);
    Route::post('/bookings/{booking}/pay', [PaymentController::class, 'initiate']);

    Route::post('/agencies/{agency}/reviews', [ReviewController::class, 'store']);
});

// --- Agency staff ---------------------------------------------------------
Route::middleware(['auth:sanctum', 'role:'.Role::AGENCY_STAFF])->prefix('agency')->group(function () {
    Route::get('/buses', [BusController::class, 'index']);
    Route::post('/buses', [BusController::class, 'store']);
    Route::get('/buses/{bus}', [BusController::class, 'show']);

    Route::post('/trips', [TripController::class, 'store']);
    Route::get('/trips', [TripController::class, 'agencyIndex']);
    Route::patch('/trips/{trip}', [TripController::class, 'update']);

    Route::get('/bookings', [BookingController::class, 'agencyBookings']);

    Route::post('/tickets/validate', [TicketController::class, 'validateBoarding']);
});

// --- Admin ---------------------------------------------------------------
Route::middleware(['auth:sanctum', 'role:'.Role::ADMIN])->prefix('admin')->group(function () {
    Route::get('/agencies', [AdminAgencyController::class, 'index']);
    Route::post('/agencies/{agency}/approve', [AdminAgencyController::class, 'approve']);
    Route::post('/agencies/{agency}/suspend', [AdminAgencyController::class, 'suspend']);
    Route::patch('/agencies/{agency}/commission', [AdminAgencyController::class, 'updateCommission']);

    Route::get('/users', [AdminUserController::class, 'index']);
    Route::post('/users/{user}/lock', [AdminUserController::class, 'lock']);
    Route::post('/users/{user}/unlock', [AdminUserController::class, 'unlock']);
});
