import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'biometric_service.dart';

/// AuthService — локальна авторизація з можливістю зберігати:
/// - email (secure storage)
/// - password hash (secure storage)
/// - optionally: plain password (secure storage) — only if user opts in
/// Token зберігається у BiometricService (flutter_secure_storage підкапоті).
class AuthService with ChangeNotifier {
  String? _token;
  final BiometricService _biometricService = BiometricService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _emailKey = 'auth_email';
  static const _passwordHashKey = 'auth_password_hash';
  static const _plainPasswordKey = 'auth_password_plain'; // лише якщо користувач погодився

  bool get isAuthenticated => _token != null;
  String? get token => _token;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Register: зберігає email та hash пароля.
  /// Якщо savePlainPassword==true — також зберігає plain password у secure storage (опціонально).
  Future<String?> register(String email, String password, {bool savePlainPassword = false}) async {
    try {
      final existingEmail = await _secureStorage.read(key: _emailKey);
      if (existingEmail != null && existingEmail == email) {
        if (kDebugMode) print('[AuthService] register failed: user exists');
        return null;
      }

      final passwordHash = _hashPassword(password);
      await _secureStorage.write(key: _emailKey, value: email);
      await _secureStorage.write(key: _passwordHashKey, value: passwordHash);

      if (savePlainPassword) {
        await _secureStorage.write(key: _plainPasswordKey, value: password);
      } else {
        // переконаємось, що plain password не лишився з попередніх записів
        await _secureStorage.delete(key: _plainPasswordKey);
      }

      // Генеруємо demo token і зберігаємо через BiometricService (щоб біометрія працювала)
      final demoToken = 'local_demo_token_${DateTime.now().millisecondsSinceEpoch}_$email';
      _token = demoToken;
      await _biometricService.storeToken(demoToken);

      if (kDebugMode) print('[AuthService] registered user=$email tokenSaved savePlain=$savePlainPassword');
      notifyListeners();
      return demoToken;
    } catch (e, st) {
      if (kDebugMode) print('[AuthService] register error: $e\n$st');
      return null;
    }
  }

  /// Login перевіряє збережені credentials (локально).
  Future<bool> login(String email, String password) async {
    try {
      final storedEmail = await _secureStorage.read(key: _emailKey);
      final storedHash = await _secureStorage.read(key: _passwordHashKey);

      if (storedEmail == null || storedHash == null) {
        if (kDebugMode) print('[AuthService] login failed: no stored credentials');
        return false;
      }

      if (storedEmail != email) {
        if (kDebugMode) print('[AuthService] login failed: email mismatch');
        return false;
      }

      final enteredHash = _hashPassword(password);
      if (enteredHash != storedHash) {
        if (kDebugMode) print('[AuthService] login failed: password mismatch');
        return false;
      }

      // Успіх — відновлюємо token (якщо є) або генеруємо і зберігаємо
      final token = await _biometricService.readToken();
      if (token != null && token.isNotEmpty) {
        _token = token;
      } else {
        final demoToken = 'local_demo_token_${DateTime.now().millisecondsSinceEpoch}_$email';
        _token = demoToken;
        await _biometricService.storeToken(demoToken);
      }

      if (kDebugMode) print('[AuthService] login success for $email');
      notifyListeners();
      return true;
    } catch (e, st) {
      if (kDebugMode) print('[AuthService] login error: $e\n$st');
      return false;
    }
  }

  Future<void> tryAutoLogin() async {
    try {
      final token = await _biometricService.readToken();
      if (token != null && token.isNotEmpty) {
        _token = token;
        if (kDebugMode) print('[AuthService] tryAutoLogin succeeded token present');
        notifyListeners();
      } else {
        if (kDebugMode) print('[AuthService] tryAutoLogin: no token found');
      }
    } catch (e, st) {
      if (kDebugMode) print('[AuthService] tryAutoLogin error: $e\n$st');
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

  /// Повертає plain password якщо його зберегли (nullable).
  Future<String?> readSavedPlainPassword() async {
    try {
      final pass = await _secureStorage.read(key: _plainPasswordKey);
      return pass;
    } catch (e, st) {
      if (kDebugMode) print('[AuthService] readSavedPlainPassword error: $e\n$st');
      return null;
    }
  }

  Future<void> deleteSavedPlainPassword() async {
    try {
      await _secureStorage.delete(key: _plainPasswordKey);
    } catch (_) {}
  }

  Future<void> logout({bool clearCredentials = false}) async {
    _token = null;
    try {
      await _biometricService.deleteToken();
      if (clearCredentials) {
        await _secureStorage.delete(key: _emailKey);
        await _secureStorage.delete(key: _passwordHashKey);
        await _secureStorage.delete(key: _plainPasswordKey);
      }
    } catch (_) {}
    notifyListeners();
  }
}