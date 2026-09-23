import '../models/dashboard_models.dart';
import 'api_client.dart';

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final ApiClient _client = ApiClient.instance;

  Future<List<DashboardAgency>> listAgencies({String? status}) async {
    final json = await _client.get('/admin/agencies', query: {if (status != null) 'status': status});
    final data = json['data'] as List<dynamic>;
    return data.map((e) => DashboardAgency.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> approveAgency(int agencyId) => _client.post('/admin/agencies/$agencyId/approve');

  Future<void> suspendAgency(int agencyId, String reason) =>
      _client.post('/admin/agencies/$agencyId/suspend', {'reason': reason});

  Future<void> updateCommission(int agencyId, double rate) =>
      _client.patch('/admin/agencies/$agencyId/commission', {'commission_rate': rate});

  Future<List<DashboardUser>> listUsers({String? role}) async {
    final json = await _client.get('/admin/users', query: {if (role != null) 'role': role});
    final data = json['data'] as List<dynamic>;
    return data.map((e) => DashboardUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> lockUser(int userId, String reason) => _client.post('/admin/users/$userId/lock', {'reason': reason});

  Future<void> unlockUser(int userId) => _client.post('/admin/users/$userId/unlock');

  Future<List<DashboardBooking>> listBookings({String? status}) async {
    final json = await _client.get('/admin/bookings', query: {if (status != null) 'status': status});
    final data = json['data'] as List<dynamic>;
    return data.map((e) => DashboardBooking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> suspendBooking(int bookingId, String reason) =>
      _client.post('/admin/bookings/$bookingId/suspend', {'reason': reason});

  Future<List<DashboardTrip>> listTrips({String? status}) async {
    final json = await _client.get('/admin/trips', query: {if (status != null) 'status': status});
    final data = json['data'] as List<dynamic>;
    return data.map((e) => DashboardTrip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateTripStatus(int tripId, String status) => _client.patch('/admin/trips/$tripId', {'status': status});

  Future<List<AdminPayment>> listPayments({String? status}) async {
    final json = await _client.get('/admin/payments', query: {if (status != null) 'status': status});
    final data = json['data'] as List<dynamic>;
    return data.map((e) => AdminPayment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refundPayment(int paymentId, String reason) =>
      _client.post('/admin/payments/$paymentId/refund', {'reason': reason});

  Future<SystemSettings> getSettings() async {
    final json = await _client.get('/admin/settings');
    return SystemSettings.fromJson(json as Map<String, dynamic>);
  }

  Future<SystemSettings> updateSettings(Map<String, dynamic> changes) async {
    final json = await _client.patch('/admin/settings', changes);
    return SystemSettings.fromJson(json as Map<String, dynamic>);
  }

  Future<PlatformReport> getReports() async {
    final json = await _client.get('/admin/reports');
    return PlatformReport.fromJson(json as Map<String, dynamic>);
  }
}
