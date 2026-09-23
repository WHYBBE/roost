import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSetting { system, light, dark }

enum LanguageSetting { system, zh, en }

/// 每周起始日：日历与热力图共用
enum WeekStart { sunday, monday }

/// 应用锁方式：无 / PIN 码 / 九宫格图案
enum LockMethod { none, pin, pattern }

/// 默认主题种子色（与首次发布一致）
const int defaultSeedColor = 0xFF5C7C6D;

/// 密码哈希：sha256(盐:密码)，本地校验用
String hashSecret(String salt, String secret) =>
    sha256.convert(utf8.encode('$salt:$secret')).toString();

String _randomSalt() {
  final rnd = Random.secure();
  return List.generate(8, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0'))
      .join();
}

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._();

  AppSettings._();

  ThemeSetting theme = ThemeSetting.system;
  LanguageSetting language = LanguageSetting.system;
  int seedColor = defaultSeedColor;
  WeekStart weekStart = WeekStart.sunday;
  // 应用锁：方式 + 盐 + 哈希（不存明文）
  LockMethod lockMethod = LockMethod.none;
  String lockSalt = '';
  String lockHash = '';

  /// 是否已配置应用锁
  bool get lockConfigured =>
      lockMethod != LockMethod.none && lockHash.isNotEmpty;

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
    final lm = prefs.getInt('lockMethod') ?? LockMethod.none.index;
    lockMethod = (lm >= 0 && lm < LockMethod.values.length)
        ? LockMethod.values[lm]
        : LockMethod.none;
    lockSalt = prefs.getString('lockSalt') ?? '';
    lockHash = prefs.getString('lockHash') ?? '';
    notifyListeners();
  }

  /// 设置密码（PIN 或图案序列），生成新盐并哈希
  Future<void> setLockSecret(LockMethod method, String secret) async {
    lockMethod = method;
    lockSalt = _randomSalt();
    lockHash = hashSecret(lockSalt, secret);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lockMethod', method.index);
    await prefs.setString('lockSalt', lockSalt);
    await prefs.setString('lockHash', lockHash);
  }

  /// 关闭应用锁（清除方式与哈希）
  Future<void> clearLock() async {
    lockMethod = LockMethod.none;
    lockSalt = '';
    lockHash = '';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lockMethod', LockMethod.none.index);
    await prefs.remove('lockSalt');
    await prefs.remove('lockHash');
  }

  /// 校验密码
  bool matchesLockSecret(String secret) =>
      lockConfigured && lockHash == hashSecret(lockSalt, secret);

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
