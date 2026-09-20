import '../models/api_models.dart';
import '../models/dashboard_models.dart';
import 'api_client.dart';

class MessageService {
  MessageService._();
  static final MessageService instance = MessageService._();

  final ApiClient _client = ApiClient.instance;

  /// The full thread with [otherUserId], optionally scoped to one trip so a
  /// passenger's conversations about different trips with the same agency
  /// don't get mixed together.
  Future<List<ApiMessage>> thread(int otherUserId, {int? tripId}) async {
    final json = await _client.get('/messages', query: {
      'with': '$otherUserId',
      if (tripId != null) 'trip_id': '$tripId',
    });
    final data = json as List<dynamic>;
    return data.map((e) => ApiMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ApiMessage> send({required int receiverId, required String body, int? tripId}) async {
    final json = await _client.post('/messages', {
      'receiver_id': receiverId,
      'body': body,
      if (tripId != null) 'trip_id': tripId,
    });
    return ApiMessage.fromJson(json as Map<String, dynamic>);
  }

  /// The agency dashboard's chat inbox: one row per passenger who has
  /// messaged the agency, most recently active first.
  Future<List<AgencyConversation>> agencyConversations() async {
    final json = await _client.get('/agency/conversations');
    final data = json as List<dynamic>;
    return data.map((e) => AgencyConversation.fromJson(e as Map<String, dynamic>)).toList();
  }
}
