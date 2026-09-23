<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Payment;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function index(Request $request)
    {
        $query = Payment::with(['booking.trip.agency', 'booking.user:id,name,phone']);

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        return $query->latest()->paginate(30);
    }

    /** Marks a payment refunded — the mobile money reversal itself happens outside this system. */
    public function refund(Request $request, Payment $payment)
    {
        if ($payment->status !== Payment::STATUS_SUCCESS) {
            return response()->json(['message' => 'Only a successful payment can be refunded.'], 409);
        }

        $data = $request->validate(['reason' => ['required', 'string']]);

        $payment->update(['status' => Payment::STATUS_REFUNDED]);

        AuditLog::record($request->user(), 'payment.refunded', $payment, $data['reason']);

        return $payment->fresh();
    }
}
