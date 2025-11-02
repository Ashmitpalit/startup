import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { en, hi }

class LanguageProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_language_code';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  AppLanguage get language =>
      _locale.languageCode == 'hi' ? AppLanguage.hi : AppLanguage.en;

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    final newLocale = language == AppLanguage.hi
        ? const Locale('hi')
        : const Locale('en');
    if (newLocale == _locale) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _locale.languageCode);
  }
}

