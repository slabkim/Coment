import 'package:flutter/material.dart';
import '../data/services/shared_prefs_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  ThemeMode get themeMode => _mode;
  
  bool get isDarkMode {
    if (_mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _mode == ThemeMode.dark;
  }

  Future<void> load() async {
    final sp = SharedPrefsService(namespace: 'coment');
    final list = await sp.getStringList(_key);
    if (list.isNotEmpty) {
      _mode = ThemeMode.values.firstWhere(
        (m) => m.toString() == list.first,
        orElse: () => ThemeMode.system,
      );
    }
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final sp = SharedPrefsService(namespace: 'coment');
    await sp.setStringList(_key, [mode.toString()]);
  }
}


