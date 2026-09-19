import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../data/attachment_io.dart';
import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';

/// 单个附件大小上限（20 MB）
const kMaxAttachmentBytes = 20 * 1024 * 1024;

/// 录音码率（64 kbps ≈ 7.5 KB/s，20MB 可录约 40 分钟）
const _recordBitRate = 64000;

String formatDuration(int ms) {
  final s = (ms / 1000).round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// 根据文件类型/扩展名推断图片 MIME
String guessImageMime(String? mimeType, String fileName) {
  final m = mimeType ?? '';
  if (m.startsWith('image/')) return m;
  switch (fileName.toLowerCase().split('.').last) {
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'bmp':
      return 'image/bmp';
    default:
      return 'image/jpeg';
  }
}

/// 全局唯一播放器：同一时刻只播一条附件音频，避免叠音
class AttachmentAudioHost extends ChangeNotifier {
  AttachmentAudioHost._() {
    _player.onPlayerStateChanged.listen((state) {
      _state = state;
      notifyListeners();
    });
  }
  static final AttachmentAudioHost instance = AttachmentAudioHost._();

  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  String? activeKey;
  bool loading = false;
  List<int>? _currentBytes;
  String _currentMime = 'audio/mp4';

  bool get playing => _state == PlayerState.playing;

  /// 播放/暂停已入库附件
  Future<void> toggleAttachment(Attachment a) =>
      _toggle('att-${a.id}', () => appDb.attachmentData(a.id), a.mime);

  /// 播放/暂停尚未入库的音频（编辑器预览）
  Future<void> toggleBytes(String key, Uint8List bytes, String mime) =>
      _toggle(key, () async => bytes, mime);

  Future<void> _toggle(
    String key,
    Future<List<int>?> Function() load,
    String mime,
  ) async {
    if (activeKey == key) {
      switch (_state) {
        case PlayerState.playing:
          await _player.pause();
          return;
        case PlayerState.paused:
          await _player.resume();
          return;
        case PlayerState.completed:
          await _replayCurrent();
          return;
        case PlayerState.stopped:
        case PlayerState.disposed:
          break;
      }
    }
    activeKey = key;
    loading = true;
    notifyListeners();
    try {
      final bytes = await load();
      if (bytes == null || bytes.isEmpty) {
        throw StateError('empty attachment');
      }
      _currentBytes = bytes;
      _currentMime = mime;
      await _player.stop();
      await startAttachmentPlayback(_player, key, bytes, mime);
    } catch (_) {
      activeKey = null;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _replayCurrent() async {
    try {
      final bytes = _currentBytes;
      if (bytes == null || bytes.isEmpty) return;
      await startAttachmentPlayback(
          _player, activeKey ?? 'replay', bytes, _currentMime);
    } catch (_) {}
  }
}

/// 思绪卡片附件区：图片缩略图 + 音频播放 chip
class AttachmentStrip extends StatelessWidget {
  const AttachmentStrip({super.key, required this.thoughtId});

  final int thoughtId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Attachment>>(
      stream: appDb.watchAttachmentsFor(thoughtId),
      builder: (context, snap) {
        final atts = snap.data;
        if (atts == null || atts.isEmpty) return const SizedBox.shrink();
        final images =
            atts.where((a) => a.kind == AttachmentKind.image).toList();
        final audios =
            atts.where((a) => a.kind == AttachmentKind.audio).toList();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in images)
                AttachmentImageThumb(
                  attachment: a,
                  onTap: () => showAttachmentImages(
                    context,
                    images,
                    initialIndex: images.indexOf(a),
                  ),
                ),
              for (final a in audios) AudioChip(attachment: a),
            ],
          ),
        );
      },
    );
  }
}

/// 附件图片缩略图：懒加载字节；可选点击查看与移除
class AttachmentImageThumb extends StatefulWidget {
  const AttachmentImageThumb({
    super.key,
    required this.attachment,
    this.size = 80,
    this.onTap,
    this.onRemove,
  });

  final Attachment attachment;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  State<AttachmentImageThumb> createState() => _AttachmentImageThumbState();
}

class _AttachmentImageThumbState extends State<AttachmentImageThumb> {
  List<int>? _bytes;
  int? _loadedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _loadedId = widget.attachment.id;
    appDb.attachmentData(widget.attachment.id).then((bytes) {
      if (mounted && _loadedId == widget.attachment.id) {
        setState(() => _bytes = bytes);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AttachmentImageThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.id != widget.attachment.id) _load();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final scheme = Theme.of(context).colorScheme;
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: _bytes == null
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Image.memory(
                Uint8List.fromList(_bytes!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth:
                    (size * MediaQuery.devicePixelRatioOf(context)).round(),
              ),
      ),
    );
    return Stack(
      children: [
        if (widget.onTap != null)
          GestureDetector(onTap: widget.onTap, child: thumb)
        else
          thumb,
        if (widget.onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// 编辑器中新增（尚未入库）的图片缩略图，可点击放大预览
class PendingImageThumb extends StatelessWidget {
  const PendingImageThumb({
    super.key,
    required this.bytes,
    this.onTap,
    required this.onRemove,
  });

  final Uint8List bytes;
  final VoidCallback? onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        color: scheme.surfaceContainerHighest,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          cacheWidth:
              (80 * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      ),
    );
    return Stack(
      children: [
        if (onTap != null) GestureDetector(onTap: onTap, child: thumb) else thumb,
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// 已入库音频的播放 chip；可选删除按钮
class AudioChip extends StatelessWidget {
  const AudioChip({super.key, required this.attachment, this.onDeleted});

  final Attachment attachment;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: AttachmentAudioHost.instance,
      builder: (context, _) {
        final host = AttachmentAudioHost.instance;
        final active = host.activeKey == 'att-${attachment.id}';
        final playing = active && host.playing;
        return Container(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
          decoration: BoxDecoration(
            color: active
                ? scheme.secondaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active && host.loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => host.toggleAttachment(attachment),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(
                      playing
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 22,
                      color: scheme.primary,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                formatDuration(attachment.durationMs ?? 0),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDeleted,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 编辑器中新增（尚未入库）的音频 chip：可试听，可移除
class PendingAudioChip extends StatelessWidget {
  const PendingAudioChip({
    super.key,
    required this.bytes,
    required this.mime,
    required this.playKey,
    required this.durationMs,
    required this.onRemove,
  });

  final Uint8List bytes;
  final String mime;
  final String playKey;
  final int durationMs;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: AttachmentAudioHost.instance,
      builder: (context, _) {
        final host = AttachmentAudioHost.instance;
        final active = host.activeKey == playKey;
        final playing = active && host.playing;
        return Container(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
          decoration: BoxDecoration(
            color: active
                ? scheme.secondaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active && host.loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => host.toggleBytes(playKey, bytes, mime),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(
                      playing
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 22,
                      color: scheme.primary,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                formatDuration(durationMs),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(width: 4),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 查看器图片来源：已入库附件按 id 懒加载，未入库直接给字节
class ImageViewerItem {
  const ImageViewerItem.attachment(this.attachmentId) : bytes = null;
  const ImageViewerItem.bytes(this.bytes) : attachmentId = null;

  final int? attachmentId;
  final Uint8List? bytes;
}

/// 全屏图片查看器：左右翻页（桌面鼠标用箭头按钮翻页）
Future<void> showImageViewer(
  BuildContext context,
  List<ImageViewerItem> items, {
  int initialIndex = 0,
}) async {
  if (items.isEmpty) return;
  final controller = PageController(
    initialPage: initialIndex.clamp(0, items.length - 1),
  );
  try {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              PageView(
                controller: controller,
                children: [for (final item in items) _ViewerPage(item: item)],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              if (items.length > 1) ...[
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: Colors.white70, size: 36),
                      onPressed: () {
                        final page = controller.page?.round() ?? 0;
                        if (page > 0) {
                          controller.previousPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.ease,
                          );
                        }
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right,
                          color: Colors.white70, size: 36),
                      onPressed: () {
                        final page = controller.page?.round() ?? 0;
                        if (page < items.length - 1) {
                          controller.nextPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.ease,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  } finally {
    controller.dispose();
  }
}

/// 已入库图片列表的便捷入口
Future<void> showAttachmentImages(
  BuildContext context,
  List<Attachment> images, {
  int initialIndex = 0,
}) {
  return showImageViewer(
    context,
    [for (final a in images) ImageViewerItem.attachment(a.id)],
    initialIndex: initialIndex,
  );
}

class _ViewerPage extends StatefulWidget {
  const _ViewerPage({required this.item});

  final ImageViewerItem item;

  @override
  State<_ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<_ViewerPage> {
  List<int>? _bytes;

  @override
  void initState() {
    super.initState();
    final direct = widget.item.bytes;
    if (direct != null) {
      _bytes = direct;
    } else {
      appDb.attachmentData(widget.item.attachmentId!).then((bytes) {
        if (mounted) setState(() => _bytes = bytes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 4,
      child: Center(
        child: _bytes == null
            ? const CircularProgressIndicator(color: Colors.white70)
            : Image.memory(
                Uint8List.fromList(_bytes!),
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}

/// 录音结果（尚未入库）
class PendingRecording {
  const PendingRecording({required this.bytes, required this.durationMs});

  final Uint8List bytes;
  final int durationMs;
}

/// 录音对话框：点按开始 → 计时 → 停止并返回；取消即丢弃
Future<PendingRecording?> showAudioRecorder(BuildContext context) {
  return showDialog<PendingRecording>(
    context: context,
    builder: (_) => const _RecordDialog(),
  );
}

class _RecordDialog extends StatefulWidget {
  const _RecordDialog();

  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  final _recorder = AudioRecorder();
  Timer? _timer;
  bool _recording = false;
  bool _busy = false;
  int _seconds = 0;
  String? _path;

  @override
  void dispose() {
    _timer?.cancel();
    // 关闭对话框时仍在录音：先停再释放（不等待）
    if (_recording) {
      _recorder.stop().whenComplete(() => _recorder.dispose());
    } else {
      _recorder.dispose();
    }
    super.dispose();
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context)!.micPermissionDenied),
          ));
        }
        return;
      }
      _path = await createRecordingPath();
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: _recordBitRate,
          sampleRate: 44100,
        ),
        path: _path!,
      );
      _seconds = 0;
      setState(() => _recording = true);
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() => _seconds++),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.opFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    if (_busy || !_recording) return;
    setState(() => _busy = true);
    _timer?.cancel();
    try {
      final stopped = await _recorder.stop();
      final bytes = await readRecording(stopped ?? _path!);
      if (!mounted) return;
      Navigator.pop(
        context,
        PendingRecording(
          bytes: Uint8List.fromList(bytes),
          durationMs: _seconds * 1000,
        ),
      );
    } catch (_) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.opFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l.recordAudio),
      content: SizedBox(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            IconButton(
              onPressed: _busy ? null : (_recording ? _stop : _start),
              icon: Icon(_recording ? Icons.stop : Icons.mic, size: 32),
              style: IconButton.styleFrom(
                backgroundColor: _recording
                    ? scheme.errorContainer
                    : scheme.secondaryContainer,
                foregroundColor:
                    _recording ? scheme.error : scheme.primary,
                fixedSize: const Size(72, 72),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _recording
                  ? '${l.recording}  ${formatDuration(_seconds * 1000)}'
                  : _busy
                      ? '…'
                      : l.recordHint,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
      ],
    );
  }
}
