import '../models/api_models.dart';
import 'api_client.dart';

class AgencyService {
  AgencyService._();
  static final AgencyService instance = AgencyService._();

  final ApiClient _client = ApiClient.instance;

  Future<ApiAgency> getAgency(int agencyId) async {
    final json = await _client.get('/agencies/$agencyId');
    return ApiAgency.fromJson(json as Map<String, dynamic>);
  }
}
