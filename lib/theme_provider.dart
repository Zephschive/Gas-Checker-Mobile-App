import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  // Dark Theme
  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardColor: const Color(0xFF2D4A43),
    dialogBackgroundColor: const Color(0xFF2A2A2A),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: Colors.white, fontSize: 14),
    ),
  );

  // Light Theme
  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Soft white, not too bright
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8F9FA),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF2D3436),
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Color(0xFF2D3436)),
    ),
    cardColor: const Color(0xFFFFFFFF),
    dialogBackgroundColor: const Color(0xFFFFFFFF),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2D3436)),
      bodyMedium: TextStyle(color: Color(0xFF636E72)),
      titleLarge: TextStyle(color: Color(0xFF2D3436), fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Color(0xFF2D3436), fontSize: 20, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: Color(0xFF636E72), fontSize: 14),
    ),
  );

  // Custom colors for components that need specific theming
  Color get cardBackgroundColor => _isDarkMode ? const Color(0xFF2D4A43) : const Color(0xFFFFFFFF);
  Color get secondaryCardColor => _isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA);
  Color get accentColor => _isDarkMode ? const Color(0xFFF2FD7D) : const Color(0xFF1E3A8A); // Yellow for dark, dark blue for light
  Color get textPrimaryColor => _isDarkMode ? Colors.white : const Color(0xFF2D3436);
  Color get textSecondaryColor => _isDarkMode ? Colors.white.withOpacity(0.6) : const Color(0xFF636E72);
  Color get progressBackgroundColor => _isDarkMode ? const Color(0xFF2D4A43) : const Color(0xFFE9ECEF);
  Color get progressBarColor => _isDarkMode ? const Color(0xFFF2FD7D) : const Color(0xFF1E3A8A); // Yellow for dark, dark blue for light
  Color get buttonBackgroundColor => _isDarkMode ? const Color(0xFFF2FD7D) : const Color(0xFF1E3A8A); // Yellow for dark, dark blue for light

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true; // Default to dark mode
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  void setDarkMode(bool isDark) {
    if (_isDarkMode != isDark) {
      toggleTheme();
    }
  }
}
