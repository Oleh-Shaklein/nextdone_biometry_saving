import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  String? _userId;
  bool _isAuthenticated = false;

  String? get userId => _userId;
  bool get isAuthenticated => _isAuthenticated;

  // Імітація логіну
  Future<bool> login(String email, String password) async {
    // TODO: замінити на реальну логіку (API, Firebase тощо)
    await Future.delayed(const Duration(seconds: 1));
    if (email == 'test@test.com' && password == 'password') {
      _userId = 'user123';
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Імітація реєстрації
  Future<bool> register(String email, String password) async {
    // TODO: замінити на реальну логіку (API, Firebase тощо)
    await Future.delayed(const Duration(seconds: 1));
    if (email.isNotEmpty && password.length >= 6) {
      _userId = 'user123';
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Вихід
  Future<void> logout() async {
    _userId = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}