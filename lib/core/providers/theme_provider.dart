import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isLight => _themeMode == ThemeMode.light;
  bool get isInitialized => _isInitialized;

  // Initialize theme from SharedPreferences
  Future<void> initializeTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final savedTheme = _prefs.getString('themeMode');
    
    if (savedTheme != null) {
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  // Toggle between light and dark mode
  void toggle() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    _saveThemePreference();
    notifyListeners();
  }

  // Set to dark mode
  void setDark() {
    _themeMode = ThemeMode.dark;
    _saveThemePreference();
    notifyListeners();
  }

  // Set to light mode
  void setLight() {
    _themeMode = ThemeMode.light;
    _saveThemePreference();
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  void _saveThemePreference() {
    final themeString = isDark ? 'dark' : 'light';
    _prefs.setString('themeMode', themeString);
  }
}
