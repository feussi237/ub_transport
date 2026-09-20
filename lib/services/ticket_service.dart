import 'api_client.dart';

class BoardingValidationResult {
  final String passengerName;
  final String originCity;
  final String destinationCity;
  final DateTime departureAt;

  BoardingValidationResult({
    required this.passengerName,
    required this.originCity,
    required this.destinationCity,
    required this.departureAt,
  });

  factory BoardingValidationResult.fromJson(Map<String, dynamic> json) => BoardingValidationResult(
        passengerName: (json['passenger'] as Map<String, dynamic>)['name'] as String,
        originCity: (json['trip'] as Map<String, dynamic>)['origin_city'] as String,
        destinationCity: (json['trip'] as Map<String, dynamic>)['destination_city'] as String,
        departureAt: DateTime.parse((json['trip'] as Map<String, dynamic>)['departure_at'] as String),
      );
}

class TicketService {
  TicketService._();
  static final TicketService instance = TicketService._();

  final ApiClient _client = ApiClient.instance;

  /// Scans/validates a ticket at boarding. Throws [ApiException] if the QR
  /// code is unknown, belongs to a different agency, or was already used.
  Future<BoardingValidationResult> validateBoarding(String qrCode) async {
    final json = await _client.post('/agency/tickets/validate', {'qr_code': qrCode});
    return BoardingValidationResult.fromJson(json as Map<String, dynamic>);
  }
}
