import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {

  static const String _themeKey = "theme_mode";

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // func change theme
  void updateTheme(String appearance) {
    final normalized = appearance.trim().toLowerCase();

    if (normalized == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (normalized == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    _saveThemeToPrefs(
      _themeMode == ThemeMode.dark
          ? 'Dark'
          : _themeMode == ThemeMode.light
              ? 'Light'
              : 'System',
    );
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs(String appearance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, appearance);
  }

  // load theme when user open app
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final appearance = (prefs.getString(_themeKey) ?? 'Light').trim().toLowerCase();

    if (appearance == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (appearance == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}