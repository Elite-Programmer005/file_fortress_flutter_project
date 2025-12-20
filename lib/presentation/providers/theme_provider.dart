import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider extends ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final theme = await _secureStorage.read(key: 'theme_mode');
    if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await _secureStorage.write(key: 'theme_mode', value: 'light');
    } else {
      _themeMode = ThemeMode.dark;
      await _secureStorage.write(key: 'theme_mode', value: 'dark');
    }
    notifyListeners();
  }
}
