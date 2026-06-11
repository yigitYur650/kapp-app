// lib/features/auth/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthProvider(this._repo);

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _userId;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get userId => _userId;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repo.login(email: email, password: password);
      _userId = res['user_id'] as String?;
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    _status = AuthStatus.unauthenticated;
    _userId = null;
    notifyListeners();
  }
}
