import 'package:flutter/foundation.dart';
import 'biometric_service.dart';

class AuthService with ChangeNotifier {
  String? _token;
  // user info fields...
  final BiometricService _biometricService = BiometricService();

  bool get isAuthenticated => _token != null;

  // Email/password login (replace with your backend implementation)
  Future<bool> login(String email, String password) async {
    // TODO: call your backend and obtain token on success.
    await Future.delayed(const Duration(milliseconds: 300));
    // If you get a token from backend, set _token and return true.
    return false;
  }

  // Register user and return a token on success (or null on failure).
  // Change this to call your backend registration API and return the issued token.
  Future<String?> register(String email, String password) async {
    // TODO: call backend and return real token
    await Future.delayed(const Duration(milliseconds: 300));
    // For development/demo return a fake token so UI flows work.
    final demoToken = 'demo_token_for_$email';
    _token = demoToken;
    notifyListeners();
    return demoToken;
  }

  // Try auto-login at startup by reading stored biometric token.
  Future<void> tryAutoLogin() async {
    try {
      final token = await _biometricService.readToken();
      if (token != null) {
        await loginWithToken(token);
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('tryAutoLogin error: $e\n$st');
      }
    }
  }

  Future<bool> loginWithToken(String token) async {
    _token = token;
    notifyListeners();
    return true;
  }

  Future<void> enableBiometricsForCurrentUser(String token) async {
    _token = token;
    await _biometricService.storeToken(token);
    notifyListeners();
  }

  Future<bool> loginWithBiometrics() async {
    final can = await _biometricService.canCheckBiometrics();
    if (!can) return false;
    final ok = await _biometricService.authenticate();
    if (!ok) return false;
    final token = await _biometricService.readToken();
    if (token == null) return false;
    return await loginWithToken(token);
  }

  Future<void> logout() async {
    _token = null;
    notifyListeners();
  }
}