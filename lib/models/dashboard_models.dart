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
  final int? agencyId;
  final String? agencyName;
  final String originCity;
  final String destinationCity;
  final DateTime departureAt;
  final double price;
  final String status;

  DashboardTrip({
    required this.id,
    this.agencyId,
    this.agencyName,
    required this.originCity,
    required this.destinationCity,
    required this.departureAt,
    required this.price,
    required this.status,
  });

  factory DashboardTrip.fromJson(Map<String, dynamic> json) {
    final agency = json['agency'] as Map<String, dynamic>?;
    return DashboardTrip(
      id: json['id'] as int,
      agencyId: agency?['id'] as int?,
      agencyName: agency?['name'] as String?,
      originCity: json['origin_city'] as String,
      destinationCity: json['destination_city'] as String,
      departureAt: DateTime.parse(json['departure_at'] as String),
      price: double.parse(json['price'].toString()),
      status: json['status'] as String,
    );
  }
}

/// One row of an agency's booking ledger — who booked what seat on which trip.
class DashboardBooking {
  final int id;
  final String passengerName;
  final String passengerPhone;
  final String? agencyName;
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
    this.agencyName,
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
    final agency = trip['agency'] as Map<String, dynamic>?;
    return DashboardBooking(
      id: json['id'] as int,
      passengerName: user['name'] as String,
      passengerPhone: user['phone'] as String,
      agencyName: agency?['name'] as String?,
      originCity: trip['origin_city'] as String,
      destinationCity: trip['destination_city'] as String,
      departureAt: DateTime.parse(trip['departure_at'] as String),
      seatNumber: (json['trip_seat'] as Map<String, dynamic>)['seat']['seat_number'] as String,
      status: json['status'] as String,
      ticketBoardingStatus: ticket?['boarding_status'] as String?,
    );
  }
}

/// The agency dashboard's overview numbers, from GET /agency/stats.
class AgencyStats {
  final int tripsTotal;
  final int tripsUpcoming;
  final int bookingsTotal;
  final int bookingsConfirmed;
  final double revenueTotal;
  final double? averageRating;
  final int reviewsCount;
  final int unreadMessagesCount;

  AgencyStats({
    required this.tripsTotal,
    required this.tripsUpcoming,
    required this.bookingsTotal,
    required this.bookingsConfirmed,
    required this.revenueTotal,
    this.averageRating,
    required this.reviewsCount,
    required this.unreadMessagesCount,
  });

  factory AgencyStats.fromJson(Map<String, dynamic> json) => AgencyStats(
        tripsTotal: json['trips_total'] as int,
        tripsUpcoming: json['trips_upcoming'] as int,
        bookingsTotal: json['bookings_total'] as int,
        bookingsConfirmed: json['bookings_confirmed'] as int,
        revenueTotal: double.parse(json['revenue_total'].toString()),
        averageRating: json['average_rating'] != null ? double.parse(json['average_rating'].toString()) : null,
        reviewsCount: json['reviews_count'] as int,
        unreadMessagesCount: json['unread_messages_count'] as int,
      );
}

/// One row of the agency's chat inbox — a passenger and their latest message.
class AgencyConversation {
  final int passengerId;
  final String passengerName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  AgencyConversation({
    required this.passengerId,
    required this.passengerName,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory AgencyConversation.fromJson(Map<String, dynamic> json) => AgencyConversation(
        passengerId: json['passenger_id'] as int,
        passengerName: json['passenger_name'] as String? ?? 'Passenger',
        lastMessage: json['last_message'] as String?,
        lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at'] as String) : null,
        unreadCount: json['unread_count'] as int? ?? 0,
      );
}

/// One row of the admin payments ledger, from GET /admin/payments.
class AdminPayment {
  final int id;
  final String provider;
  final double amount;
  final String status; // pending | success | failed | refunded
  final String passengerName;
  final String? agencyName;
  final String originCity;
  final String destinationCity;
  final DateTime? paidAt;

  AdminPayment({
    required this.id,
    required this.provider,
    required this.amount,
    required this.status,
    required this.passengerName,
    this.agencyName,
    required this.originCity,
    required this.destinationCity,
    this.paidAt,
  });

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map<String, dynamic>;
    final trip = booking['trip'] as Map<String, dynamic>;
    final agency = trip['agency'] as Map<String, dynamic>?;
    final user = booking['user'] as Map<String, dynamic>;
    return AdminPayment(
      id: json['id'] as int,
      provider: json['provider'] as String,
      amount: double.parse(json['amount'].toString()),
      status: json['status'] as String,
      passengerName: user['name'] as String,
      agencyName: agency?['name'] as String?,
      originCity: trip['origin_city'] as String,
      destinationCity: trip['destination_city'] as String,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
    );
  }
}

/// Platform-wide configuration, from GET/PATCH /admin/settings.
class SystemSettings {
  final double defaultCommissionRate;
  final int seatLockMinutes;
  final String supportPhone;
  final String supportEmail;
  final bool maintenanceMode;

  SystemSettings({
    required this.defaultCommissionRate,
    required this.seatLockMinutes,
    required this.supportPhone,
    required this.supportEmail,
    required this.maintenanceMode,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) => SystemSettings(
        defaultCommissionRate: double.parse(json['default_commission_rate'].toString()),
        seatLockMinutes: int.parse(json['seat_lock_minutes'].toString()),
        supportPhone: json['support_phone'] as String,
        supportEmail: json['support_email'] as String,
        maintenanceMode: json['maintenance_mode'].toString() == 'true',
      );
}

/// One entry of GET /admin/reports's revenue-by-month breakdown.
class MonthlyRevenue {
  final String month; // "2026-09"
  final double total;

  MonthlyRevenue({required this.month, required this.total});

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) =>
      MonthlyRevenue(month: json['month'] as String, total: double.parse(json['total'].toString()));
}

/// One row of GET /admin/reports's top-agencies leaderboard.
class TopAgency {
  final int id;
  final String name;
  final int bookingsCount;

  TopAgency({required this.id, required this.name, required this.bookingsCount});

  factory TopAgency.fromJson(Map<String, dynamic> json) => TopAgency(
        id: json['id'] as int,
        name: json['name'] as String,
        bookingsCount: int.parse(json['bookings_count'].toString()),
      );
}

/// Platform-wide analytics, from GET /admin/reports.
class PlatformReport {
  final int agenciesTotal;
  final int agenciesVerified;
  final int agenciesPending;
  final int usersTotal;
  final int passengersTotal;
  final int tripsTotal;
  final int bookingsTotal;
  final int bookingsConfirmed;
  final int bookingsCancelled;
  final double revenueTotal;
  final List<MonthlyRevenue> revenueByMonth;
  final List<TopAgency> topAgencies;

  PlatformReport({
    required this.agenciesTotal,
    required this.agenciesVerified,
    required this.agenciesPending,
    required this.usersTotal,
    required this.passengersTotal,
    required this.tripsTotal,
    required this.bookingsTotal,
    required this.bookingsConfirmed,
    required this.bookingsCancelled,
    required this.revenueTotal,
    required this.revenueByMonth,
    required this.topAgencies,
  });

  factory PlatformReport.fromJson(Map<String, dynamic> json) => PlatformReport(
        agenciesTotal: json['agencies_total'] as int,
        agenciesVerified: json['agencies_verified'] as int,
        agenciesPending: json['agencies_pending'] as int,
        usersTotal: json['users_total'] as int,
        passengersTotal: json['passengers_total'] as int,
        tripsTotal: json['trips_total'] as int,
        bookingsTotal: json['bookings_total'] as int,
        bookingsConfirmed: json['bookings_confirmed'] as int,
        bookingsCancelled: json['bookings_cancelled'] as int,
        revenueTotal: double.parse(json['revenue_total'].toString()),
        revenueByMonth: (json['revenue_by_month'] as List<dynamic>)
            .map((e) => MonthlyRevenue.fromJson(e as Map<String, dynamic>))
            .toList(),
        topAgencies:
            (json['top_agencies'] as List<dynamic>).map((e) => TopAgency.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
