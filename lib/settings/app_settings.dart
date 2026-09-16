import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSetting { system, light, dark }

enum LanguageSetting { system, zh, en }

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();

  AppSettings._();

  ThemeSetting theme = ThemeSetting.system;
  LanguageSetting language = LanguageSetting.system;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getInt('theme') ?? ThemeSetting.system.index;
    theme = (t >= 0 && t < ThemeSetting.values.length)
        ? ThemeSetting.values[t]
        : ThemeSetting.system;
    final lang = prefs.getInt('language') ?? LanguageSetting.system.index;
    language = (lang >= 0 && lang < LanguageSetting.values.length)
        ? LanguageSetting.values[lang]
        : LanguageSetting.system;
    notifyListeners();
  }

  Future<void> setTheme(ThemeSetting value) async {
    theme = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme', value.index);
  }

  Future<void> setLanguage(LanguageSetting value) async {
    language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('language', value.index);
  }
}
