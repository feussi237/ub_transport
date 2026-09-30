import 'api_client.dart';

class AiChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;

  AiChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class AssistantService {
  AssistantService._();
  static final AssistantService instance = AssistantService._();

  final ApiClient _client = ApiClient.instance;

  /// Sends [message] plus the prior [history] (oldest first, capped to the
  /// last ~10 turns server-side) and returns the assistant's reply. The
  /// backend executes any database lookups the model needs (trip search,
  /// the caller's own bookings, agency ratings) before answering.
  Future<String> ask(String message, List<AiChatMessage> history) async {
    final json = await _client.post('/assistant/ask', {
      'message': message,
      'history': history.map((m) => m.toJson()).toList(),
    });
    return json['reply'] as String;
  }
}
