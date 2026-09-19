import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Web 端 record 包会忽略路径，但录音结果无法在 Dart 侧读取，暂不支持录音入库
Future<String> createRecordingPath() async =>
    'roost-rec-${DateTime.now().millisecondsSinceEpoch}.webm';

Future<List<int>> readRecording(String path) =>
    throw UnsupportedError('web: 录音读取暂不支持');

/// Web 直接按字节流播放，无需落盘
Future<void> startAttachmentPlayback(
  AudioPlayer player,
  String cacheKey,
  List<int> bytes,
  String mime,
) async {
  await player.play(BytesSource(Uint8List.fromList(bytes), mimeType: mime));
}

Future<void> clearAttachmentCache() async {}
