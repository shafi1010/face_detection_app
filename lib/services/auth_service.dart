import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  AuthService({
    required ApiClient apiClient,
    required SecureStorage storage,
  })  : _apiClient = apiClient,
        _storage = storage {
    _apiClient.getToken = getToken;
    _apiClient.onUnauthorized = _onUnauthorized;
  }

  Future<String?> getToken() => _storage.getToken();

  void _onUnauthorized() {
    clearSession();
  }

  Future<AuthResponse> login(String email, String password) async {
    final response = await _apiClient.post<AuthResponse>(
      '/auth/login',
      body: LoginRequest(email: email, password: password).toJson(),
      fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );
    await _persistAuth(response);
    return response;
  }

  Future<AuthResponse> refreshToken() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null) throw Exception('No refresh token available');

    final response = await _apiClient.post<AuthResponse>(
      '/auth/refresh',
      body: RefreshRequest(refreshToken: refresh).toJson(),
      fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );
    await _persistAuth(response);
    return response;
  }

  Future<void> _persistAuth(AuthResponse response) async {
    await _storage.saveToken(response.token);
    await _storage.saveRefreshToken(response.refreshToken);
    await _storage.saveUserId(response.user.id);
    await _storage.saveUserEmail(response.user.email);
    await _storage.saveUserName(response.user.name);
    await _storage.saveUserRole(response.user.role);
    await _storage.saveTenantId(response.user.tenantId);
  }

  Future<User> getProfile() async {
    return await _apiClient.get<User>(
      '/auth/profile',
      fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post<void>('/auth/logout');
    } catch (_) {}
    await clearSession();
  }

  Future<void> clearSession() async {
    await _storage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getTenantId() => _storage.getTenantId();
  Future<String?> getUserId() => _storage.getUserId();
  Future<String?> getUserName() => _storage.getUserName();
  Future<String?> getUserEmail() => _storage.getUserEmail();
  Future<String?> getUserRole() => _storage.getUserRole();
}
