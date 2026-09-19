import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';
import 'attachment_io.dart';
import 'data_io.dart';
import 'tag_presets.dart';

/// 保险库元信息：[file] 为原生库文件名 / Web IndexedDB 库名
class VaultMeta {
  final String id;
  final String name;
  final String file;

  const VaultMeta({required this.id, required this.name, required this.file});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'file': file};

  factory VaultMeta.fromJson(Map<String, dynamic> json) => VaultMeta(
        id: json['id'] as String,
        name: json['name'] as String,
        file: json['file'] as String,
      );
}

/// 数据库实例持有者，同时管理保险库注册表：
/// 每个 vault 一个独立库文件（思绪/标签完全隔离），应用级设置存 SharedPreferences
class DataStore extends ChangeNotifier {
  DataStore._({AppDatabase Function(String name)? openDb})
      : _openDb = openDb ?? ((name) => AppDatabase(name: name));

  static final DataStore instance = DataStore._();

  @visibleForTesting
  DataStore.forTest({required AppDatabase Function(String name) open})
      : _openDb = open;

  final AppDatabase Function(String name) _openDb;

  static const _vaultsKey = 'vaults';
  static const _activeKey = 'activeVault';

  static final _random = Random();

  AppDatabase? _db;
  int _epoch = 0;
  bool corrupted = false;
  bool ready = false;
  List<VaultMeta> vaults = const [];
  String? _activeId;

  /// 数据库代数：每替换一次实例自增，UI 以此整体重建
  int get epoch => _epoch;

  VaultMeta? get currentVault {
    for (final v in vaults) {
      if (v.id == _activeId) return v;
    }
    return null;
  }

  AppDatabase get db {
    _db ??= _openDb(currentVault?.file ?? 'roost');
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

  /// 启动引导：读取注册表，无保险库时创建默认库（沿用默认文件名，既有数据自然保留）
  Future<void> init() async {
    if (ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      vaults = _decodeVaults(prefs.getString(_vaultsKey));
      if (vaults.isEmpty) {
        final first = VaultMeta(
          id: _newId(),
          name: seedUseChinese ? '思栖' : 'Roost',
          file: 'roost',
        );
        vaults = [first];
        await prefs.setString(
            _vaultsKey, jsonEncode([first.toJson()]));
      }
      _activeId = prefs.getString(_activeKey);
      if (currentVault == null) _activeId = vaults.first.id;
      await _openActive();
      await prefs.setString(_activeKey, _activeId!);
      ready = true;
    } catch (_) {
      ready = true;
      setCorrupted(true);
    }
    notifyListeners();
  }

  /// 当前库健康检查（quick_check + 业务表可读），异常时进入清理引导
  Future<void> checkHealth() async {
    if (corrupted || !ready) return;
    try {
      if (!await db.isHealthy()) setCorrupted(true);
    } catch (_) {
      setCorrupted(true);
    }
  }

  /// 新建保险库并切换过去（新库自动播种预设心情）
  Future<void> createVault(String name) async {
    final id = _newId();
    final meta = VaultMeta(
      id: id,
      name: name.trim().isEmpty ? _defaultVaultName() : name.trim(),
      file: 'roost-$id',
    );
    vaults = [...vaults, meta];
    _activeId = id;
    await _openActive();
    await _persist();
    notifyListeners();
  }

  /// 切换到指定保险库
  Future<void> switchVault(String id) async {
    if (id == _activeId || !vaults.any((v) => v.id == id)) return;
    _activeId = id;
    await _openActive();
    await _persist();
    notifyListeners();
  }

  /// 重命名保险库
  Future<void> renameVault(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    vaults = [
      for (final v in vaults)
        if (v.id == id) VaultMeta(id: v.id, name: trimmed, file: v.file) else v
    ];
    await _persist();
    notifyListeners();
  }

  /// 删除保险库（至少保留一个，UI 负责拦截）；若删除的是当前库则切换到第一个
  Future<void> deleteVault(String id) async {
    if (vaults.length <= 1) return;
    final meta = vaults.firstWhere((v) => v.id == id);
    vaults = vaults.where((v) => v.id != id).toList();
    if (id == _activeId) {
      _activeId = vaults.first.id;
      await _openActive();
    }
    await _persist();
    await _removeVaultData(meta.file);
    notifyListeners();
  }

  Future<void> _openActive() async {
    final old = _db;
    _db = _openDb(currentVault!.file);
    _epoch++;
    try {
      await old?.close();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _vaultsKey, jsonEncode([for (final v in vaults) v.toJson()]));
    await prefs.setString(_activeKey, _activeId!);
  }

  /// 清除保险库数据：原生删库文件；Web 无文件系统，改为清空业务表
  Future<void> _removeVaultData(String file) async {
    try {
      if (kIsWeb) {
        final target = _openDb(file);
        await target.resetAllData();
        await target.close();
      } else {
        await deleteDataFiles(file);
        // 播放缓存以附件 id 为键，跨库可能撞号，顺手全清
        await clearAttachmentCache();
      }
    } catch (_) {}
  }

  static String _defaultVaultName() => seedUseChinese ? '思栖' : 'Roost';

  static List<VaultMeta> _decodeVaults(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final item in list)
          VaultMeta.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  static String _newId() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$time-${_random.nextInt(0x7fffffff).toRadixString(36)}';
  }
}

AppDatabase get appDb => DataStore.instance.db;
