import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkTheme = false;
  double _fontSize = 14.0;

  bool get isDarkTheme => _isDarkTheme;
  double get fontSize => _fontSize;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 14.0;
    notifyListeners();
  }

  ThemeData get themeData {
    return _isDarkTheme ? _darkTheme : _lightTheme;
  }

  ThemeData get _lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      useMaterial3: true,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: _fontSize + 2),
        bodyMedium: TextStyle(fontSize: _fontSize),
        bodySmall: TextStyle(fontSize: _fontSize - 2),
        headlineSmall: TextStyle(fontSize: _fontSize + 6, fontWeight: FontWeight.bold),
      ),
    );
  }

  ThemeData get _darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: _fontSize + 2, color: Colors.white),
        bodyMedium: TextStyle(fontSize: _fontSize, color: Colors.white),
        bodySmall: TextStyle(fontSize: _fontSize - 2, color: Colors.white70),
        headlineSmall: TextStyle(fontSize: _fontSize + 6, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Future<void> toggleTheme() async {
    _isDarkTheme = !_isDarkTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', _isDarkTheme);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
    notifyListeners();
  }
}