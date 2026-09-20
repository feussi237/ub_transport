import '../models/api_models.dart';
import 'api_client.dart';

class TripService {
  TripService._();
  static final TripService instance = TripService._();

  final ApiClient _client = ApiClient.instance;

  Future<List<ApiTrip>> search({
    required String originCity,
    required String destinationCity,
    DateTime? date,
  }) async {
    final json = await _client.get('/trips', query: {
      'origin_city': originCity,
      'destination_city': destinationCity,
      if (date != null) 'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    });
    final data = json['data'] as List<dynamic>;
    return data.map((e) => ApiTrip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Trip detail including the live per-seat availability map.
  Future<ApiTrip> getTrip(int id) async {
    final json = await _client.get('/trips/$id');
    return ApiTrip.fromJson(json as Map<String, dynamic>);
  }
}
