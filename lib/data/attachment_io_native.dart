import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// 录音临时文件路径（AAC-LC → m4a 容器）。
/// path_provider 不保证目录存在，而 AVCaptureFileOutput.startRecording
/// 在父目录缺失时会静默失败，这里显式创建
Future<String> createRecordingPath() async {
  final dir = await getTemporaryDirectory();
  await dir.create(recursive: true);
  return '${dir.path}/roost-rec-${DateTime.now().millisecondsSinceEpoch}.m4a';
}

/// 读取录音文件内容。AVCaptureFileOutput.stopRecording 是异步收尾，
/// 停止后文件可能尚未写完，这里轮询等待生成
Future<List<int>> readRecording(String path) async {
  for (var i = 0; i < 20; i++) {
    final file = File(path);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) return bytes;
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('录音文件未生成: $path');
}

/// 播放前把 blob 落到缓存目录（同一附件复用同一文件）
Future<String> _materialize(String cacheKey, List<int> bytes, String mime) async {
  final dir = await getTemporaryDirectory();
  final cache = Directory('${dir.path}/roost-attachments');
  await cache.create(recursive: true);
  final file = File('${cache.path}/$cacheKey.${_extForMime(mime)}');
  if (!await file.exists() || await file.length() != bytes.length) {
    await file.writeAsBytes(bytes, flush: true);
  }
  return file.path;
}

String _extForMime(String mime) {
  switch (mime) {
    case 'audio/mpeg':
      return 'mp3';
    case 'audio/ogg':
    case 'audio/opus':
      return 'ogg';
    case 'audio/wav':
    case 'audio/x-wav':
      return 'wav';
    default:
      return 'm4a';
  }
}

/// 播放附件音频（原生：临时文件）
Future<void> startAttachmentPlayback(
  AudioPlayer player,
  String cacheKey,
  List<int> bytes,
  String mime,
) async {
  final path = await _materialize(cacheKey, bytes, mime);
  await player.play(DeviceFileSource(path));
}

/// 清空附件播放缓存（删除 vault 时调用）
Future<void> clearAttachmentCache() async {
  try {
    final dir = await getTemporaryDirectory();
    final cache = Directory('${dir.path}/roost-attachments');
    if (await cache.exists()) await cache.delete(recursive: true);
  } catch (_) {}
}
