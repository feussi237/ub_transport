import '../models/api_models.dart';
import 'api_client.dart';

/// Holds the signed-in passenger for the lifetime of the app and talks to
/// the /auth/* endpoints. A real dependency-injection setup isn't worth it
/// for a single-role mobile client, so this is a simple singleton.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final ApiClient _client = ApiClient.instance;
  ApiUser? currentUser;

  /// Restores the persisted token (if any) and fetches the profile it
  /// belongs to. Called once at startup to decide Login vs Home.
  Future<bool> tryRestoreSession() async {
    await _client.loadToken();
    if (!_client.isAuthenticated) return false;

    try {
      final json = await _client.get('/me');
      currentUser = ApiUser.fromJson(json as Map<String, dynamic>);
      return true;
    } on ApiException {
      await _client.setToken(null);
      return false;
    }
  }

  Future<void> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final json = await _client.post('/auth/register/passenger', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    await _client.setToken(json['token'] as String);
    currentUser = ApiUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<void> login({required String email, required String password}) async {
    final json = await _client.post('/auth/login', {'email': email, 'password': password});
    await _client.setToken(json['token'] as String);
    currentUser = ApiUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  /// Edits the signed-in user's own name/email/phone/password. Any field
  /// left null is left untouched server-side.
  Future<void> updateProfile({String? name, String? email, String? phone, String? password}) async {
    final json = await _client.patch('/me', {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (password != null) 'password': password,
    });
    currentUser = ApiUser.fromJson(json as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } on ApiException {
      // Token may already be invalid; clearing it locally is enough either way.
    }
    await _client.setToken(null);
    currentUser = null;
  }
}
