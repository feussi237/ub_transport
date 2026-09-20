import '../models/dashboard_models.dart';
import 'api_client.dart';

class AgencyDashboardService {
  AgencyDashboardService._();
  static final AgencyDashboardService instance = AgencyDashboardService._();

  final ApiClient _client = ApiClient.instance;

  Future<List<DashboardBus>> listBuses() async {
    final json = await _client.get('/agency/buses');
    final data = json as List<dynamic>;
    return data.map((e) => DashboardBus.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DashboardBus> createBus({
    required String plateNumber,
    required String category,
    required List<Map<String, String>> seatLayout,
  }) async {
    final json = await _client.post('/agency/buses', {
      'plate_number': plateNumber,
      'category': category,
      'seat_layout': seatLayout,
    });
    return DashboardBus.fromJson(json as Map<String, dynamic>);
  }

  Future<List<DashboardTrip>> listTrips() async {
    final json = await _client.get('/agency/trips');
    final data = json['data'] as List<dynamic>;
    return data.map((e) => DashboardTrip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createTrip({
    required int busId,
    required String originCity,
    required String destinationCity,
    required DateTime departureAt,
    required double price,
  }) =>
      _client.post('/agency/trips', {
        'bus_id': busId,
        'origin_city': originCity,
        'destination_city': destinationCity,
        'departure_at': departureAt.toIso8601String(),
        'price': price,
      });

  Future<void> updateTripStatus(int tripId, String status) =>
      _client.patch('/agency/trips/$tripId', {'status': status});

  Future<List<DashboardBooking>> listBookings() async {
    final json = await _client.get('/agency/bookings');
    final data = json['data'] as List<dynamic>;
    return data.map((e) => DashboardBooking.fromJson(e as Map<String, dynamic>)).toList();
  }
}
