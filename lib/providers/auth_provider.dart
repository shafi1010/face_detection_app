import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _error;

  AuthProvider({required AuthService authService})
      : _authService = authService;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String? get error => _error;
  String? get tenantId => _user?.tenantId;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> tryAutoLogin() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      try {
        await _authService.refreshToken();
        final name = await _authService.getUserName();
        final email = await _authService.getUserEmail();
        final role = await _authService.getUserRole();
        final tenantId = await _authService.getTenantId();
        final userId = await _authService.getUserId();

        _user = User(
          id: userId ?? '',
          email: email ?? '',
          name: name ?? '',
          role: role ?? 'viewer',
          tenantId: tenantId ?? '',
          createdAt: DateTime.now(),
        );
        _status = AuthStatus.authenticated;
      } catch (_) {
        await _authService.clearSession();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _user = response.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
