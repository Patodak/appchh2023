import 'package:flutter/material.dart';

enum CustomThemeMode { light, dark, pink }

class ThemeNotifier extends ChangeNotifier {
  CustomThemeMode _customThemeMode = CustomThemeMode.light;

  CustomThemeMode get customThemeMode => _customThemeMode;

  ThemeMode get themeMode {
    switch (_customThemeMode) {
      case CustomThemeMode.light:
        return ThemeMode.light;
      case CustomThemeMode.dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  void toggleTheme() {
    _customThemeMode = CustomThemeMode.values[
        (_customThemeMode.index + 1) % CustomThemeMode.values.length];
    notifyListeners();
  }
}

