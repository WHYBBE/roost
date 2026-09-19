/// 音频附件平台能力：录音临时路径、读取录音、按需播放、缓存清理。
/// 原生走临时文件；Web 直接用字节流播放（录音读取暂不支持）。
library;

export 'attachment_io_web.dart' if (dart.library.io) 'attachment_io_native.dart';
