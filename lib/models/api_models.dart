/// DTOs mirroring the Laravel API's JSON shapes (see backend/app/Http/Controllers/Api).
library;

class ApiUser {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role; // admin | agency_staff | passenger
  final String? agencyContactPhone;
  final String? agencyContactEmail;

  ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.agencyContactPhone,
    this.agencyContactEmail,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    final agency = (json['agency_staff'] as Map<String, dynamic>?)?['agency'] as Map<String, dynamic>?;
    return ApiUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: (json['role'] as Map<String, dynamic>?)?['name'] as String? ?? 'passenger',
      agencyContactPhone: agency?['contact_phone'] as String?,
      agencyContactEmail: agency?['contact_email'] as String?,
    );
  }
}

class ApiTripSeat {
  final int id;
  final String seatNumber;
  final String seatType;
  final String status; // available | locked | booked

  ApiTripSeat({required this.id, required this.seatNumber, required this.seatType, required this.status});

  factory ApiTripSeat.fromJson(Map<String, dynamic> json) => ApiTripSeat(
        id: json['id'] as int,
        seatNumber: (json['seat'] as Map<String, dynamic>)['seat_number'] as String,
        seatType: (json['seat'] as Map<String, dynamic>)['seat_type'] as String,
        status: json['status'] as String,
      );
}

class ApiTrip {
  final int id;
  final int agencyId;
  final String agencyName;
  final String busCategory;
  final String originCity;
  final String destinationCity;
  final DateTime departureAt;
  final double price;
  final String status; // scheduled | delayed | cancelled | completed
  final int? availableSeatsCount;
  final List<ApiTripSeat> seats;

  ApiTrip({
    required this.id,
    required this.agencyId,
    required this.agencyName,
    required this.busCategory,
    required this.originCity,
    required this.destinationCity,
    required this.departureAt,
    required this.price,
    this.status = 'scheduled',
    this.availableSeatsCount,
    this.seats = const [],
  });

  factory ApiTrip.fromJson(Map<String, dynamic> json) {
    final agency = json['agency'] as Map<String, dynamic>;
    return ApiTrip(
      id: json['id'] as int,
      agencyId: agency['id'] as int,
      agencyName: agency['name'] as String,
      busCategory: (json['bus'] as Map<String, dynamic>)['category'] as String,
      originCity: json['origin_city'] as String,
      destinationCity: json['destination_city'] as String,
      departureAt: DateTime.parse(json['departure_at'] as String),
      price: double.parse(json['price'].toString()),
      status: json['status'] as String? ?? 'scheduled',
      availableSeatsCount: json['available_seats_count'] as int?,
      seats: (json['trip_seats'] as List<dynamic>? ?? [])
          .map((e) => ApiTripSeat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ApiBooking {
  final int id;
  final int tripId;
  final int tripSeatId;
  final String seatNumber;
  final String status; // pending | confirmed | cancelled

  // Present once /bookings (list) or /bookings/{id} (detail) is fetched —
  // /bookings/store only returns the seat/trip pair, not ticket/payments yet.
  final int? agencyId;
  final String? agencyName;
  final String? originCity;
  final String? destinationCity;
  final DateTime? departureAt;
  final double? price;
  final String? tripStatus; // scheduled | delayed | cancelled | completed
  final ApiTicket? ticket;
  final String? lastPaymentStatus; // pending | success | failed | refunded

  ApiBooking({
    required this.id,
    required this.tripId,
    required this.tripSeatId,
    required this.seatNumber,
    required this.status,
    this.agencyId,
    this.agencyName,
    this.originCity,
    this.destinationCity,
    this.departureAt,
    this.price,
    this.tripStatus,
    this.ticket,
    this.lastPaymentStatus,
  });

  bool get isCompleted => tripStatus == 'completed';

  factory ApiBooking.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>?;
    final agency = trip?['agency'] as Map<String, dynamic>?;
    final ticketJson = json['ticket'] as Map<String, dynamic>?;
    final payments = json['payments'] as List<dynamic>?;
    final lastPayment = payments != null && payments.isNotEmpty
        ? payments.last as Map<String, dynamic>
        : null;

    return ApiBooking(
      id: json['id'] as int,
      tripId: json['trip_id'] as int? ?? trip?['id'] as int? ?? 0,
      tripSeatId: json['trip_seat_id'] as int,
      seatNumber: (json['trip_seat'] as Map<String, dynamic>)['seat']['seat_number'] as String,
      status: json['status'] as String,
      agencyId: agency?['id'] as int?,
      agencyName: agency?['name'] as String?,
      originCity: trip?['origin_city'] as String?,
      destinationCity: trip?['destination_city'] as String?,
      departureAt: trip?['departure_at'] != null ? DateTime.parse(trip!['departure_at'] as String) : null,
      price: trip?['price'] != null ? double.parse(trip!['price'].toString()) : null,
      tripStatus: trip?['status'] as String?,
      ticket: ticketJson != null ? ApiTicket.fromJson(ticketJson) : null,
      lastPaymentStatus: lastPayment?['status'] as String?,
    );
  }
}

class ApiPayment {
  final int id;
  final int bookingId;
  final String transactionRef;
  final String status;

  ApiPayment({required this.id, required this.bookingId, required this.transactionRef, required this.status});

  factory ApiPayment.fromJson(Map<String, dynamic> json) => ApiPayment(
        id: json['id'] as int,
        bookingId: json['booking_id'] as int,
        transactionRef: json['transaction_ref'] as String,
        status: json['status'] as String,
      );
}

class ApiTicket {
  final String qrCode;
  final String boardingStatus; // unused | boarded

  ApiTicket({required this.qrCode, this.boardingStatus = 'unused'});

  factory ApiTicket.fromJson(Map<String, dynamic> json) => ApiTicket(
        qrCode: json['qr_code'] as String,
        boardingStatus: json['boarding_status'] as String? ?? 'unused',
      );
}

/// Public agency profile — used on the reviews screen and to resolve who a
/// passenger's message should be addressed to for a given trip.
class ApiAgency {
  final int id;
  final String name;
  final String status;
  final String? contactPhone;
  final String? contactEmail;
  final int reviewsCount;
  final double? averageRating;
  final int? contactUserId;

  ApiAgency({
    required this.id,
    required this.name,
    required this.status,
    this.contactPhone,
    this.contactEmail,
    this.reviewsCount = 0,
    this.averageRating,
    this.contactUserId,
  });

  factory ApiAgency.fromJson(Map<String, dynamic> json) => ApiAgency(
        id: json['id'] as int,
        name: json['name'] as String,
        status: json['status'] as String,
        contactPhone: json['contact_phone'] as String?,
        contactEmail: json['contact_email'] as String?,
        reviewsCount: json['reviews_count'] as int? ?? 0,
        averageRating: json['average_rating'] != null ? double.parse(json['average_rating'].toString()) : null,
        contactUserId: json['contact_user_id'] as int?,
      );
}

class ApiReview {
  final int id;
  final String authorName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ApiReview({
    required this.id,
    required this.authorName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ApiReview.fromJson(Map<String, dynamic> json) => ApiReview(
        id: json['id'] as int,
        authorName: (json['user'] as Map<String, dynamic>?)?['name'] as String? ?? 'Passenger',
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ApiMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String body;
  final DateTime createdAt;

  ApiMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.createdAt,
  });

  factory ApiMessage.fromJson(Map<String, dynamic> json) => ApiMessage(
        id: json['id'] as int,
        senderId: json['sender_id'] as int,
        receiverId: json['receiver_id'] as int,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ApiNotification {
  final int id;
  final String type; // booking | delay | cancellation | reminder
  final String title;
  final String body;
  final bool isRead;
  final DateTime sentAt;

  ApiNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.sentAt,
  });

  factory ApiNotification.fromJson(Map<String, dynamic> json) => ApiNotification(
        id: json['id'] as int,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        isRead: json['is_read'] as bool,
        sentAt: DateTime.parse(json['sent_at'] as String),
      );
}
