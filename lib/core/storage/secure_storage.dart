import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyTenantId = 'tenant_id';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserName = 'user_name';
  static const _keyUserRole = 'user_role';
  static const _keyBaseUrl = 'base_url';
  static const _keyBiometricEnabled = 'biometric_enabled';

  final FlutterSecureStorage _storage;

  SecureStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  Future<void> saveToken(String token) => _storage.write(key: _keyToken, value: token);
  Future<String?> getToken() => _storage.read(key: _keyToken);
  Future<void> deleteToken() => _storage.delete(key: _keyToken);

  Future<void> saveRefreshToken(String token) => _storage.write(key: _keyRefreshToken, value: token);
  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);
  Future<void> deleteRefreshToken() => _storage.delete(key: _keyRefreshToken);

  Future<void> saveTenantId(String id) => _storage.write(key: _keyTenantId, value: id);
  Future<String?> getTenantId() => _storage.read(key: _keyTenantId);
  Future<void> deleteTenantId() => _storage.delete(key: _keyTenantId);

  Future<void> saveUserId(String id) => _storage.write(key: _keyUserId, value: id);
  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  Future<void> saveUserEmail(String email) => _storage.write(key: _keyUserEmail, value: email);
  Future<String?> getUserEmail() => _storage.read(key: _keyUserEmail);

  Future<void> saveUserName(String name) => _storage.write(key: _keyUserName, value: name);
  Future<String?> getUserName() => _storage.read(key: _keyUserName);

  Future<void> saveUserRole(String role) => _storage.write(key: _keyUserRole, value: role);
  Future<String?> getUserRole() => _storage.read(key: _keyUserRole);

  Future<void> saveBaseUrl(String url) => _storage.write(key: _keyBaseUrl, value: url);
  Future<String?> getBaseUrl() => _storage.read(key: _keyBaseUrl);

  Future<void> setBiometricEnabled(bool enabled) => _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
