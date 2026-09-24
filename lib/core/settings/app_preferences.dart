import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences() { _load(); }

  static const _themeKey = 'app_theme_mode';
  static const _fontScaleKey = 'app_font_scale';
  static const _contrastKey = 'app_high_contrast';
  static const _languageKey = 'app_language';
  static const _hapticsKey = 'app_haptics_enabled';
  static const _reduceMotionKey = 'app_reduce_motion';

  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;
  bool _highContrast = false;
  String _language = 'en';
  bool _hapticsEnabled = true;
  bool _reduceMotion = false;
  bool _ready = false;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  bool get highContrast => _highContrast;
  String get language => _language;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get reduceMotion => _reduceMotion;
  bool get ready => _ready;

  Locale get locale => Locale(_language);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTheme = prefs.getString(_themeKey) ?? 'system';
    _themeMode = switch (rawTheme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _fontScale = (prefs.getDouble(_fontScaleKey) ?? 1.0).clamp(.85, 1.35);
    _highContrast = prefs.getBool(_contrastKey) ?? false;
    _language = prefs.getString(_languageKey) ?? 'en';
    _hapticsEnabled = prefs.getBool(_hapticsKey) ?? true;
    _reduceMotion = prefs.getBool(_reduceMotionKey) ?? false;
    _ready = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, value.name);
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value.clamp(.85, 1.35);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, _fontScale);
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_contrastKey, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, value);
  }

  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceMotionKey, value);
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
  }
}
