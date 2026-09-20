import '../models/api_models.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final ApiClient _client = ApiClient.instance;

  Future<List<ApiNotification>> list() async {
    final json = await _client.get('/notifications');
    final data = json['data'] as List<dynamic>;
    return data.map((e) => ApiNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(int notificationId) async {
    await _client.post('/notifications/$notificationId/read');
  }

  Future<void> markAllRead() async {
    await _client.post('/notifications/read-all');
  }
}
