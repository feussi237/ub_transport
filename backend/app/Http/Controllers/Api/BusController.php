<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Concerns\ResolvesAgency;
use App\Http\Controllers\Controller;
use App\Models\Bus;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpKernel\Exception\HttpException;

class BusController extends Controller
{
    use ResolvesAgency;

    public function index(Request $request)
    {
        return $this->currentAgency($request)->buses()->with('seats')->get();
    }

    /**
     * Register a bus and its seat map in one call: seat_layout is a flat list of
     * seat numbers (e.g. ["1A","1B","2A","2B"]) so the agency can lay out rows itself.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'plate_number' => ['required', 'string', 'unique:buses,plate_number'],
            'category' => ['required', Rule::in(['standard', 'vip', 'express'])],
            'seat_layout' => ['required', 'array', 'min:1'],
            'seat_layout.*.seat_number' => ['required', 'string'],
            'seat_layout.*.seat_type' => ['required', Rule::in(['standard', 'vip'])],
        ]);

        $agency = $this->currentAgency($request);

        $bus = DB::transaction(function () use ($agency, $data) {
            $bus = $agency->buses()->create([
                'plate_number' => $data['plate_number'],
                'category' => $data['category'],
                'seat_count' => count($data['seat_layout']),
            ]);

            $bus->seats()->createMany($data['seat_layout']);

            return $bus;
        });

        return response()->json($bus->load('seats'), 201);
    }

    public function show(Request $request, Bus $bus)
    {
        $this->authorizeAgencyBus($request, $bus);

        return $bus->load('seats');
    }

    /** Agency edits its own bus's plate number/category. Seats are managed at creation time only. */
    public function update(Request $request, Bus $bus)
    {
        $this->authorizeAgencyBus($request, $bus);

        $data = $request->validate([
            'plate_number' => ['sometimes', 'string', Rule::unique('buses', 'plate_number')->ignore($bus->id)],
            'category' => ['sometimes', Rule::in(['standard', 'vip', 'express'])],
        ]);

        $bus->update($data);

        return $bus->load('seats');
    }

    private function authorizeAgencyBus(Request $request, Bus $bus): void
    {
        if ($bus->agency_id !== $this->currentAgency($request)->id) {
            throw new HttpException(403, 'This bus does not belong to your agency.');
        }
    }
}
