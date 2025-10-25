import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tasker_0001/utils/local_storage.dart';

enum AppTheme { light, dark }
enum AppLocale { en, uk }

class Settings extends ChangeNotifier {
  static const _keyTheme = 'settings_theme';
  static const _keyLocale = 'settings_locale';

  AppTheme theme;
  AppLocale locale;

  Settings({
    this.theme = AppTheme.light,
    this.locale = AppLocale.uk,
  });

  /// Load settings from SharedPreferences (LocalStorageService).
  Future<void> load() async {
    final storage = LocalStorageService();
    try {
      final themeStr = await storage.getString(_keyTheme);
      final localeStr = await storage.getString(_keyLocale);

      if (themeStr != null) {
        theme = themeStr == 'dark' ? AppTheme.dark : AppTheme.light;
      }
      if (localeStr != null) {
        locale = localeStr == 'en' ? AppLocale.en : AppLocale.uk;
      }

      if (kDebugMode) {
        print('[Settings] loaded theme=$theme locale=$locale');
      }
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) print('[Settings] load error: $e\n$st');
    }
  }

  Future<void> _save() async {
    final storage = LocalStorageService();
    try {
      await storage.saveString(_keyTheme, theme == AppTheme.dark ? 'dark' : 'light');
      await storage.saveString(_keyLocale, locale == AppLocale.en ? 'en' : 'uk');
      if (kDebugMode) print('[Settings] saved theme=$theme locale=$locale');
    } catch (e, st) {
      if (kDebugMode) print('[Settings] save error: $e\n$st');
    }
  }

  void setTheme(AppTheme value) {
    theme = value;
    notifyListeners();
    _save();
  }

  void setLocale(AppLocale value) {
    locale = value;
    notifyListeners();
    _save();
  }
}