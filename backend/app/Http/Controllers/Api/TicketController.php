<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ResolvesAgency;
use App\Http\Controllers\Controller;
use App\Models\Ticket;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\HttpException;

class TicketController extends Controller
{
    use ResolvesAgency;

    /** Agency staff scans a passenger's QR code at boarding. */
    public function validateBoarding(Request $request)
    {
        $data = $request->validate(['qr_code' => ['required', 'string']]);

        $ticket = Ticket::with('booking.trip', 'booking.user')
            ->where('qr_code', $data['qr_code'])
            ->firstOrFail();

        $agency = $this->currentAgency($request);

        if ($ticket->booking->trip->agency_id !== $agency->id) {
            throw new HttpException(403, 'This ticket is for a different agency.');
        }

        if ($ticket->boarding_status === Ticket::BOARDING_BOARDED) {
            throw new HttpException(409, 'This ticket has already been used to board.');
        }

        $ticket->update(['boarding_status' => Ticket::BOARDING_BOARDED, 'boarded_at' => now()]);

        return response()->json([
            'passenger' => $ticket->booking->user->only(['id', 'name']),
            'trip' => $ticket->booking->trip->only(['origin_city', 'destination_city', 'departure_at']),
            'boarded_at' => $ticket->boarded_at,
        ]);
    }
}
