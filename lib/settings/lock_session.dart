import 'package:flutter/foundation.dart';

import '../settings/app_settings.dart';

/// 应用锁会话：解锁状态只在应用进程内有效
/// （冷启动需重新解锁；切换保险库不影响会话）
class LockSession extends ChangeNotifier {
  LockSession._();

  static final LockSession instance = LockSession._();

  bool _unlocked = false;

  /// 当前会话是否已解锁（未配置锁时恒为 true）
  bool get unlocked => !AppSettings.instance.lockConfigured || _unlocked;

  /// 是否需要显示解锁门
  bool get needsUnlock => AppSettings.instance.lockConfigured && !_unlocked;

  void unlock() {
    if (!_unlocked) {
      _unlocked = true;
      notifyListeners();
    }
  }

  /// 重新上锁（设置里的"立即上锁"入口）
  void lock() {
    if (AppSettings.instance.lockConfigured && _unlocked) {
      _unlocked = false;
      notifyListeners();
    }
  }

  /// 关闭应用锁时清会话
  void reset() {
    _unlocked = false;
    notifyListeners();
  }
}
