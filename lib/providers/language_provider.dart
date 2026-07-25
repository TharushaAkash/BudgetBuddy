import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'en';
  String _aiLanguageCode = 'en';
  bool _useAiScanner = false;

  String get languageCode => _languageCode;
  String get aiLanguageCode => _aiLanguageCode;
  bool get useAiScanner => _useAiScanner;
  bool get isSinhala => _languageCode == 'si';

  LanguageProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString('language_code') ?? 'en';
    _aiLanguageCode = prefs.getString('ai_language_code') ?? 'en';
    _useAiScanner = prefs.getBool('use_ai_scanner') ?? false;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    notifyListeners();
  }

  Future<void> setAiLanguage(String code) async {
    if (_aiLanguageCode == code) return;
    _aiLanguageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_language_code', code);
    notifyListeners();
  }

  Future<void> setUseAiScanner(bool value) async {
    if (_useAiScanner == value) return;
    _useAiScanner = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_ai_scanner', value);
    notifyListeners();
  }
}
