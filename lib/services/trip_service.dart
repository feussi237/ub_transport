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

  /// Same-route search result plus, when nothing exact matched, a handful of
  /// other trips running that same day so the passenger isn't left empty-handed.
  Future<TripSearchResult> searchWithAlternatives({
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
    final alternatives = json['same_day_alternatives'] as List<dynamic>?;
    return TripSearchResult(
      trips: data.map((e) => ApiTrip.fromJson(e as Map<String, dynamic>)).toList(),
      sameDayAlternatives: (alternatives ?? []).map((e) => ApiTrip.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Trips across every route, soonest first — used for the home screen's
  /// "Popular Routes" strip and the "See All" browse screen. Client-side
  /// filters out anything already departed since the backend doesn't scope
  /// an unfiltered listing to the future.
  Future<List<ApiTrip>> browseUpcoming() async {
    final json = await _client.get('/trips');
    final data = json['data'] as List<dynamic>;
    final trips = data.map((e) => ApiTrip.fromJson(e as Map<String, dynamic>)).toList();
    trips.retainWhere((t) => t.departureAt.isAfter(DateTime.now()) && t.status == 'scheduled');
    return trips;
  }

  /// Trip detail including the live per-seat availability map.
  Future<ApiTrip> getTrip(int id) async {
    final json = await _client.get('/trips/$id');
    return ApiTrip.fromJson(json as Map<String, dynamic>);
  }
}

class TripSearchResult {
  final List<ApiTrip> trips;
  final List<ApiTrip> sameDayAlternatives;

  TripSearchResult({required this.trips, required this.sameDayAlternatives});
}
