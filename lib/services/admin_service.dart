import '../models/dashboard_models.dart';
import 'api_client.dart';

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final ApiClient _client = ApiClient.instance;

  Future<List<DashboardAgency>> listAgencies({String? status}) async {
    final json = await _client.get('/admin/agencies', query: {'status': ?status});
    final data = json['data'] as List<dynamic>;
    return data.map((e) => DashboardAgency.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> approveAgency(int agencyId) => _client.post('/admin/agencies/$agencyId/approve');

  Future<void> suspendAgency(int agencyId, String reason) =>
      _client.post('/admin/agencies/$agencyId/suspend', {'reason': reason});

  Future<void> updateCommission(int agencyId, double rate) =>
      _client.patch('/admin/agencies/$agencyId/commission', {'commission_rate': rate});

  Future<List<DashboardUser>> listUsers({String? role}) async {
    final json = await _client.get('/admin/users', query: {'role': ?role});
    final data = json['data'] as List<dynamic>;
    return data.map((e) => DashboardUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> lockUser(int userId, String reason) => _client.post('/admin/users/$userId/lock', {'reason': reason});

  Future<void> unlockUser(int userId) => _client.post('/admin/users/$userId/unlock');
}
