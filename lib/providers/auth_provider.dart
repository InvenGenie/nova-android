import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(username, password);
      if (data['success'] == true) {
        final token = data['token'] ?? data['access_token'] ?? data['session_id'];
        await _api.setToken(token);
        final userFields = data['user'] ?? data;
        try {
          final sessionData = await _api.getSession();
          if (sessionData['success'] == true) {
            _user = User.fromJson({...sessionData, 'token': token});
          } else {
            _user = User.fromJson({...userFields, 'username': username, 'token': token});
          }
        } catch (_) {
          _user = User.fromJson({...userFields, 'username': username, 'token': token});
        }
        _loading = false;
        notifyListeners();
        return true;
      }
      _error = data['message'] ?? 'Login failed';
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Connection error: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreSession() async {
    await _api.init();
    if (_api.token == null) return false;

    try {
      final data = await _api.getSession();
      if (data['success'] == true) {
        _user = User.fromJson(data);
        notifyListeners();
        return true;
      }
    } catch (_) {}

    await _api.setToken(null);
    return false;
  }

  Future<void> logout() async {
    _user = null;
    await _api.setToken(null);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
