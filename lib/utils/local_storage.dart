import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() => _instance;

  LocalStorageService._internal();

  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(key, value);
    if (kDebugMode) {
      print('[LocalStorage] saveString key=$key length=${value.length} ok=$ok');
    }
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(key);
    if (kDebugMode) {
      print('[LocalStorage] getString key=$key result=${val == null ? "null" : "len:${val.length}"}');
    }
    return val;
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.remove(key);
    if (kDebugMode) {
      print('[LocalStorage] remove key=$key ok=$ok');
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.clear();
    if (kDebugMode) {
      print('[LocalStorage] clear ok=$ok');
    }
  }
}
