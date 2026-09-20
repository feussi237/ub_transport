import 'api_models.dart';

/// A bus/agency trip offering shown in the search results list. Wraps the
/// live [ApiTrip] returned by the backend; display-only fields the API
/// doesn't provide yet (ratings, formatted times) are derived here.
class BusTrip {
  final int id;
  final String agencyName;
  final String travelClass; // e.g. "VIP", "standard", "express"
  final DateTime departureAt;
  final String origin;
  final String destination;
  final int? seatsRemaining;
  final int priceFcfa;

  const BusTrip({
    required this.id,
    required this.agencyName,
    required this.travelClass,
    required this.departureAt,
    required this.origin,
    required this.destination,
    required this.seatsRemaining,
    required this.priceFcfa,
  });

  factory BusTrip.fromApi(ApiTrip trip) => BusTrip(
        id: trip.id,
        agencyName: trip.agencyName,
        travelClass: trip.busCategory,
        departureAt: trip.departureAt,
        origin: trip.originCity,
        destination: trip.destinationCity,
        seatsRemaining: trip.availableSeatsCount,
        priceFcfa: trip.price.round(),
      );

  String get departureTime => _formatTime(departureAt);
}

String _formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

/// Status of an individual bus seat.
enum SeatStatus { available, selected, booked, locked }

/// A single seat on the trip's seat map, keyed by the backend's trip_seat id
/// (not a display index — real buses don't necessarily number seats 1..N).
class BusSeat {
  final int tripSeatId;
  final String label; // e.g. "12A"
  final String seatType; // standard | vip
  SeatStatus status;

  BusSeat({required this.tripSeatId, required this.label, this.seatType = 'standard', this.status = SeatStatus.available});

  factory BusSeat.fromApi(ApiTripSeat seat) => BusSeat(
        tripSeatId: seat.id,
        label: seat.seatNumber,
        seatType: seat.seatType,
        status: switch (seat.status) {
          'booked' => SeatStatus.booked,
          'locked' => SeatStatus.locked,
          _ => SeatStatus.available,
        },
      );
}

/// A passenger travelling on a booked seat. Names/ages are collected for the
/// manifest shown on the ticket; the backend only needs the trip_seat id to
/// create the booking itself (a booking always belongs to the signed-in user).
class Passenger {
  final int tripSeatId;
  final String seatLabel;
  String fullName;
  int? age;
  String gender; // "Female" | "Male"

  Passenger({
    required this.tripSeatId,
    required this.seatLabel,
    this.fullName = '',
    this.age,
    this.gender = 'Female',
  });
}

/// A popular / featured route shown on the home screen.
class PopularRoute {
  final String imageUrl;
  final String origin;
  final String destination;
  final String duration;
  final int priceFcfa;

  const PopularRoute({
    required this.imageUrl,
    required this.origin,
    required this.destination,
    required this.duration,
    required this.priceFcfa,
  });
}

/// Simple currency formatter for FCFA amounts, e.g. 8000 -> "8 000 FCFA".
String formatFcfa(int amount) {
  final s = amount.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final posFromEnd = s.length - i;
    buffer.write(s[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) {
      buffer.write(' ');
    }
  }
  return '${buffer.toString()} FCFA';
}
