import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

const _jsonType = XTypeGroup(label: 'JSON', extensions: ['json']);

/// 打开 JSON 文件并读取文本（取消返回 null）
Future<String?> pickAndReadJson() async {
  final file = await openFile(acceptedTypeGroups: [_jsonType]);
  if (file == null) return null;
  return File(file.path).readAsString();
}

/// 保存文本为 JSON 文件（取消返回 false）
Future<bool> saveJsonToFile(String content) async {
  final location = await getSaveLocation(
    suggestedName:
        'roost-${DateTime.now().toIso8601String().substring(0, 10)}.json',
    acceptedTypeGroups: [_jsonType],
  );
  if (location == null) return false;
  await File(location.path).writeAsString(content);
  return true;
}

/// 删除指定库的本地数据库文件（尽力而为；用于删除 vault 或无法修复的损坏数据）
Future<bool> deleteDataFiles(String dbName) async {
  var deleted = false;
  final dirs = <Directory?>[
    await _safe(() => getApplicationDocumentsDirectory()),
    await _safe(() => getApplicationSupportDirectory()),
  ];
  for (final dir in dirs) {
    if (dir == null) continue;
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      try {
        final f = File('${dir.path}/$dbName.sqlite$suffix');
        if (await f.exists()) {
          await f.delete();
          deleted = true;
        }
      } catch (_) {}
    }
  }
  return deleted;
}

Future<Directory?> _safe(Future<Directory?> Function() fn) async {
  try {
    return await fn();
  } catch (_) {
    return null;
  }
}
