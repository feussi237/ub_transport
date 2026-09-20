/// Models backing the admin and agency web dashboards. Kept separate from
/// api_models.dart since these shapes are only ever used by staff/admin
/// accounts, never by the passenger-facing screens.
library;

class DashboardAgency {
  final int id;
  final String name;
  final String status; // pending | verified | suspended
  final String? registrationNo;
  final String? contactPhone;
  final String? contactEmail;
  final double commissionRate;

  DashboardAgency({
    required this.id,
    required this.name,
    required this.status,
    this.registrationNo,
    this.contactPhone,
    this.contactEmail,
    required this.commissionRate,
  });

  factory DashboardAgency.fromJson(Map<String, dynamic> json) => DashboardAgency(
        id: json['id'] as int,
        name: json['name'] as String,
        status: json['status'] as String,
        registrationNo: json['registration_no'] as String?,
        contactPhone: json['contact_phone'] as String?,
        contactEmail: json['contact_email'] as String?,
        commissionRate: double.parse((json['commission_rate'] ?? 0).toString()),
      );
}

class DashboardUser {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isLocked;

  DashboardUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isLocked,
  });

  factory DashboardUser.fromJson(Map<String, dynamic> json) => DashboardUser(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        role: (json['role'] as Map<String, dynamic>?)?['name'] as String? ?? '?',
        isLocked: json['is_locked'] as bool? ?? false,
      );
}

class DashboardSeat {
  final int id;
  final String seatNumber;
  final String seatType;

  DashboardSeat({required this.id, required this.seatNumber, required this.seatType});

  factory DashboardSeat.fromJson(Map<String, dynamic> json) => DashboardSeat(
        id: json['id'] as int,
        seatNumber: json['seat_number'] as String,
        seatType: json['seat_type'] as String,
      );
}

class DashboardBus {
  final int id;
  final String plateNumber;
  final String category;
  final int seatCount;
  final List<DashboardSeat> seats;

  DashboardBus({
    required this.id,
    required this.plateNumber,
    required this.category,
    required this.seatCount,
    this.seats = const [],
  });

  factory DashboardBus.fromJson(Map<String, dynamic> json) => DashboardBus(
        id: json['id'] as int,
        plateNumber: json['plate_number'] as String,
        category: json['category'] as String,
        seatCount: json['seat_count'] as int,
        seats: (json['seats'] as List<dynamic>? ?? [])
            .map((e) => DashboardSeat.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DashboardTrip {
  final int id;
  final String originCity;
  final String destinationCity;
  final DateTime departureAt;
  final double price;
  final String status;

  DashboardTrip({
    required this.id,
    required this.originCity,
    required this.destinationCity,
    required this.departureAt,
    required this.price,
    required this.status,
  });

  factory DashboardTrip.fromJson(Map<String, dynamic> json) => DashboardTrip(
        id: json['id'] as int,
        originCity: json['origin_city'] as String,
        destinationCity: json['destination_city'] as String,
        departureAt: DateTime.parse(json['departure_at'] as String),
        price: double.parse(json['price'].toString()),
        status: json['status'] as String,
      );
}

/// One row of an agency's booking ledger — who booked what seat on which trip.
class DashboardBooking {
  final int id;
  final String passengerName;
  final String passengerPhone;
  final String originCity;
  final String destinationCity;
  final DateTime departureAt;
  final String seatNumber;
  final String status;
  final String? ticketBoardingStatus;

  DashboardBooking({
    required this.id,
    required this.passengerName,
    required this.passengerPhone,
    required this.originCity,
    required this.destinationCity,
    required this.departureAt,
    required this.seatNumber,
    required this.status,
    this.ticketBoardingStatus,
  });

  factory DashboardBooking.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>;
    final user = json['user'] as Map<String, dynamic>;
    final ticket = json['ticket'] as Map<String, dynamic>?;
    return DashboardBooking(
      id: json['id'] as int,
      passengerName: user['name'] as String,
      passengerPhone: user['phone'] as String,
      originCity: trip['origin_city'] as String,
      destinationCity: trip['destination_city'] as String,
      departureAt: DateTime.parse(trip['departure_at'] as String),
      seatNumber: (json['trip_seat'] as Map<String, dynamic>)['seat']['seat_number'] as String,
      status: json['status'] as String,
      ticketBoardingStatus: ticket?['boarding_status'] as String?,
    );
  }
}
