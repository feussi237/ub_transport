import '../models/api_models.dart';
import 'api_client.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final ApiClient _client = ApiClient.instance;

  Future<List<ApiReview>> listForAgency(int agencyId) async {
    final json = await _client.get('/agencies/$agencyId/reviews');
    final data = json['data'] as List<dynamic>;
    return data.map((e) => ApiReview.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Only succeeds if the passenger actually completed a trip with this
  /// agency — the backend rejects anything else with a 403.
  Future<ApiReview> submit({
    required int agencyId,
    required int tripId,
    required int rating,
    String? comment,
  }) async {
    final json = await _client.post('/agencies/$agencyId/reviews', {
      'trip_id': tripId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    return ApiReview.fromJson(json as Map<String, dynamic>);
  }
}
