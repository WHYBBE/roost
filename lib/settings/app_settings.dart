import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSetting { system, light, dark }

enum LanguageSetting { system, zh, en }

/// 每周起始日：日历与热力图共用
enum WeekStart { sunday, monday }

/// 默认主题种子色（与首次发布一致）
const int defaultSeedColor = 0xFF5C7C6D;

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();

  AppSettings._();

  ThemeSetting theme = ThemeSetting.system;
  LanguageSetting language = LanguageSetting.system;
  int seedColor = defaultSeedColor;
  WeekStart weekStart = WeekStart.sunday;

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
    seedColor = prefs.getInt('seedColor') ?? defaultSeedColor;
    final ws = prefs.getInt('weekStart') ?? WeekStart.sunday.index;
    weekStart = (ws >= 0 && ws < WeekStart.values.length)
        ? WeekStart.values[ws]
        : WeekStart.sunday;
    notifyListeners();
  }

  Future<void> setSeedColor(int value) async {
    seedColor = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', value);
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

  Future<void> setWeekStart(WeekStart value) async {
    weekStart = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('weekStart', value.index);
  }
}
