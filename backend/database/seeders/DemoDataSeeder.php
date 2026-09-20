<?php

namespace Database\Seeders;

use App\Models\Agency;
use App\Models\AgencyStaff;
use App\Models\Booking;
use App\Models\Bus;
use App\Models\Message;
use App\Models\Payment;
use App\Models\Review;
use App\Models\Role;
use App\Models\Seat;
use App\Models\Ticket;
use App\Models\Trip;
use App\Models\TripSeat;
use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/**
 * Populates enough realistic data (two verified agencies, buses with seat
 * maps, past and upcoming trips, a demo passenger with a completed booking,
 * a review, a message thread and a few notifications) to exercise every
 * screen of the app without having to click through the whole booking flow
 * by hand first. Safe to re-run: everything is keyed on a unique field.
 */
class DemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $agencyRole = Role::where('name', Role::AGENCY_STAFF)->firstOrFail();
        $passengerRole = Role::where('name', Role::PASSENGER)->firstOrFail();

        // --- Agencies + staff --------------------------------------------------
        $agencies = [
            ['name' => 'Guaranty Express', 'reg' => 'REG-GE-001', 'phone' => '+237670000001'],
            ['name' => 'Vatican Voyages', 'reg' => 'REG-VV-002', 'phone' => '+237670000002'],
        ];

        $createdAgencies = [];
        foreach ($agencies as $a) {
            $agency = Agency::firstOrCreate(
                ['registration_no' => $a['reg']],
                [
                    'name' => $a['name'],
                    'status' => Agency::STATUS_VERIFIED,
                    'contact_phone' => $a['phone'],
                    'contact_email' => Str::slug($a['name']).'@ubtransport.cm',
                    'commission_rate' => 10,
                    'verified_at' => now(),
                ]
            );

            $staffUser = User::firstOrCreate(
                ['email' => Str::slug($a['name']).'.staff@ubtransport.cm'],
                [
                    'role_id' => $agencyRole->id,
                    'name' => $a['name'].' Staff',
                    'phone' => $a['phone'],
                    'password' => 'password',
                ]
            );

            AgencyStaff::firstOrCreate(['user_id' => $staffUser->id], [
                'agency_id' => $agency->id,
                'position' => 'manager',
            ]);

            $bus = Bus::firstOrCreate(
                ['plate_number' => 'CE-'.Str::upper(Str::random(3)).'-'.$agency->id],
                ['agency_id' => $agency->id, 'category' => 'vip', 'seat_count' => 10]
            );

            if ($bus->seats()->count() === 0) {
                foreach (range(1, 10) as $n) {
                    Seat::create([
                        'bus_id' => $bus->id,
                        'seat_number' => (string) $n,
                        'seat_type' => $n <= 4 ? 'vip' : 'standard',
                    ]);
                }
            }

            $createdAgencies[] = ['agency' => $agency, 'staff' => $staffUser, 'bus' => $bus->fresh('seats')];
        }

        // --- Demo passenger ------------------------------------------------------
        $passenger = User::firstOrCreate(
            ['email' => 'passenger.demo@ubtransport.cm'],
            [
                'role_id' => $passengerRole->id,
                'name' => 'Demo Passenger',
                'phone' => '+237690000000',
                'password' => 'password',
            ]
        );

        // --- Upcoming trips (one per agency, searchable/bookable) ---------------
        $routes = [
            ['origin' => 'Douala', 'destination' => 'Yaoundé', 'price' => 6000],
            ['origin' => 'Yaoundé', 'destination' => 'Bamenda', 'price' => 9000],
        ];

        foreach ($createdAgencies as $i => $entry) {
            $route = $routes[$i % count($routes)];

            $trip = Trip::firstOrCreate(
                [
                    'agency_id' => $entry['agency']->id,
                    'origin_city' => $route['origin'],
                    'destination_city' => $route['destination'],
                    'departure_at' => now()->addDays(2)->setTime(8, 0),
                ],
                [
                    'bus_id' => $entry['bus']->id,
                    'arrival_at_estimate' => now()->addDays(2)->setTime(12, 0),
                    'price' => $route['price'],
                    'status' => Trip::STATUS_SCHEDULED,
                ]
            );

            if ($trip->tripSeats()->count() === 0) {
                foreach ($entry['bus']->seats as $seat) {
                    TripSeat::create(['trip_id' => $trip->id, 'seat_id' => $seat->id]);
                }
            }
        }

        // --- One completed trip with a confirmed booking, so the demo passenger
        // can immediately see a ticket, leave a review and message the agency. --
        $completedAgency = $createdAgencies[0];
        $completedTrip = Trip::firstOrCreate(
            [
                'agency_id' => $completedAgency['agency']->id,
                'origin_city' => 'Douala',
                'destination_city' => 'Yaoundé',
                'departure_at' => now()->subDays(5)->setTime(8, 0),
            ],
            [
                'bus_id' => $completedAgency['bus']->id,
                'arrival_at_estimate' => now()->subDays(5)->setTime(12, 0),
                'price' => 6000,
                'status' => Trip::STATUS_COMPLETED,
            ]
        );

        if ($completedTrip->tripSeats()->count() === 0) {
            foreach ($completedAgency['bus']->seats as $seat) {
                TripSeat::create(['trip_id' => $completedTrip->id, 'seat_id' => $seat->id]);
            }
        }

        $tripSeat = $completedTrip->tripSeats()->first();

        $booking = Booking::firstOrCreate(
            ['user_id' => $passenger->id, 'trip_id' => $completedTrip->id],
            ['trip_seat_id' => $tripSeat->id, 'status' => Booking::STATUS_CONFIRMED]
        );

        if ($tripSeat->status !== TripSeat::STATUS_BOOKED) {
            $tripSeat->update(['status' => TripSeat::STATUS_BOOKED]);
        }

        Payment::firstOrCreate(
            ['booking_id' => $booking->id],
            ['provider' => 'mtn_momo', 'amount' => 6000, 'status' => Payment::STATUS_SUCCESS, 'transaction_ref' => (string) Str::uuid(), 'paid_at' => now()->subDays(5)]
        );

        Ticket::firstOrCreate(
            ['booking_id' => $booking->id],
            ['qr_code' => (string) Str::uuid(), 'boarding_status' => Ticket::BOARDING_BOARDED, 'boarded_at' => now()->subDays(5)->addHours(4)]
        );

        Review::firstOrCreate(
            ['user_id' => $passenger->id, 'trip_id' => $completedTrip->id],
            ['agency_id' => $completedAgency['agency']->id, 'rating' => 5, 'comment' => 'Voyage confortable, bus à l\'heure.']
        );

        Message::firstOrCreate(
            ['sender_id' => $passenger->id, 'receiver_id' => $completedAgency['staff']->id, 'trip_id' => $completedTrip->id],
            ['body' => 'Bonjour, à quelle heure exactement le bus part-il ?']
        );
        Message::firstOrCreate(
            ['sender_id' => $completedAgency['staff']->id, 'receiver_id' => $passenger->id, 'trip_id' => $completedTrip->id],
            ['body' => 'Bonjour, le départ est prévu à 8h00 précises, merci d\'arriver 20 min avant.']
        );

        UserNotification::firstOrCreate(
            ['user_id' => $passenger->id, 'type' => UserNotification::TYPE_BOOKING, 'title' => 'Réservation confirmée'],
            ['channel' => UserNotification::CHANNEL_PUSH, 'body' => 'Votre billet Douala → Yaoundé est confirmé.', 'is_read' => true, 'sent_at' => now()->subDays(5)]
        );
        UserNotification::firstOrCreate(
            ['user_id' => $passenger->id, 'type' => UserNotification::TYPE_REMINDER, 'title' => 'Départ dans 2 jours'],
            ['channel' => UserNotification::CHANNEL_PUSH, 'body' => 'N\'oubliez pas votre prochain trajet !', 'is_read' => false, 'sent_at' => now()]
        );
    }
}
