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

  Future<ApiPayment> initiatePayment(int bookingId, {String provider = 'mtn_momo'}) async {
    final json = await _client.post('/bookings/$bookingId/pay', {'provider': provider});
    return ApiPayment.fromJson(json as Map<String, dynamic>);
  }

  /// There is no live MTN MoMo / Orange Money integration yet — production
  /// payment confirmation is meant to arrive at POST /payments/webhook from
  /// the provider itself (see PaymentController::handleWebhook on the
  /// backend). Until that integration exists, the app calls the same public
  /// webhook endpoint directly to simulate a successful charge, so the rest
  /// of the booking flow (ticket issuance, seat becoming "booked") can be
  /// exercised end to end. Remove this the moment a real gateway is wired up.
  Future<void> simulateProviderConfirmation(String transactionRef) async {
    await _client.post('/payments/webhook', {
      'transaction_ref': transactionRef,
      'status': 'success',
    });
  }

  Future<ApiTicket> getTicket(int bookingId) async {
    final json = await _client.get('/bookings/$bookingId');
    return ApiTicket.fromJson(json['ticket'] as Map<String, dynamic>);
  }

  Future<void> cancel(int bookingId, {String? reason}) async {
    await _client.post('/bookings/$bookingId/cancel', {if (reason != null) 'reason': reason});
  }
}
