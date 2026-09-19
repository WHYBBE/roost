import 'package:flutter/foundation.dart';

import 'app_database.dart';

/// 数据库实例持有者：数据损坏清理后可整体替换实例并通知 UI 重建
class DataStore extends ChangeNotifier {
  DataStore._();
  static final DataStore instance = DataStore._();

  AppDatabase? _db;
  int _epoch = 0;
  bool corrupted = false;

  /// 数据库代数：每替换一次实例自增，UI 以此整体重建
  int get epoch => _epoch;

  AppDatabase get db {
    _db ??= AppDatabase();
    return _db!;
  }

  /// 标记数据异常状态并通知 UI（进入/退出清理引导）
  void setCorrupted(bool value) {
    if (corrupted == value) return;
    corrupted = value;
    notifyListeners();
  }

  /// 关闭旧实例并替换为新实例（旧实例上的流会失效，UI 需整体重建）
  Future<void> reopen() async {
    final old = _db;
    _db = null;
    _epoch++;
    try {
      await old?.close();
    } catch (_) {}
    notifyListeners();
  }
}

AppDatabase get appDb => DataStore.instance.db;
