import '../models/api_models.dart';
import 'api_client.dart';

class BookingService {
  BookingService._();
  static final BookingService instance = BookingService._();

  final ApiClient _client = ApiClient.instance;

  /// The signed-in passenger's booking history, most recent first — trip,
  /// ticket and payment status all come embedded so the list screen needs
  /// no follow-up requests.
  Future<List<ApiBooking>> list() async {
    final json = await _client.get('/bookings');
    final data = json['data'] as List<dynamic>;
    return data.map((e) => ApiBooking.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Locks one seat and creates a pending booking for it. The backend row-locks
  /// the seat inside a transaction, so a 409 here means someone else just took it.
  Future<ApiBooking> book(int tripSeatId) async {
    final json = await _client.post('/bookings', {'trip_seat_id': tripSeatId});
    return ApiBooking.fromJson(json as Map<String, dynamic>);
  }

  /// Starts the Mobile Money charge. Resolves instantly to 'success' when
  /// the backend is in simulation mode (the default — see
  /// PAYMENT_SIMULATION_MODE on the backend); against a real MTN MoMo
  /// (direct phone prompt) or Orange Money (returns [ApiPayment.redirectUrl]
  /// to open) integration it comes back 'pending' and the caller should
  /// poll [checkPaymentStatus] until it resolves.
  Future<ApiPayment> initiatePayment(int bookingId, {String provider = 'mtn_momo'}) async {
    final json = await _client.post('/bookings/$bookingId/pay', {'provider': provider});
    return ApiPayment.fromJson(json as Map<String, dynamic>);
  }

  /// Polls the booking's current status, reconciling against the payment
  /// provider if still pending. Returns the booking's status string
  /// ('pending' | 'confirmed' | 'cancelled') — 'confirmed' means payment
  /// succeeded and the ticket is ready.
  Future<ApiBooking> checkPaymentStatus(int bookingId) async {
    final json = await _client.get('/bookings/$bookingId/payment-status');
    return ApiBooking.fromJson(json as Map<String, dynamic>);
  }

  Future<ApiTicket> getTicket(int bookingId) async {
    final json = await _client.get('/bookings/$bookingId');
    return ApiTicket.fromJson(json['ticket'] as Map<String, dynamic>);
  }

  Future<void> cancel(int bookingId, {String? reason}) async {
    await _client.post('/bookings/$bookingId/cancel', {'reason': ?reason});
  }
}
