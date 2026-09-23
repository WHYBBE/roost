import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../l10n/app_localizations.dart';
import '../settings/app_settings.dart';
import '../settings/lock_session.dart';

/// PIN 数字键盘：圆点显示已输入位数 + 3x4 键盘 + 确认按钮。
/// [resetToken] 变化时清空已输入（父级在出错后递增以重置）
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onSubmit,
    required this.confirmLabel,
    this.errorText,
    this.hint,
    this.resetToken = 0,
  });

  final ValueChanged<String> onSubmit;
  final String confirmLabel;
  final String? errorText;
  final String? hint;
  final int resetToken;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  @override
  void didUpdateWidget(PinPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) _pin = '';
  }

  void _tap(String d) {
    if (_pin.length >= 8) return;
    setState(() => _pin += d);
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.hint != null)
          Text(
            widget.hint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        const SizedBox(height: 12),
        // 已输入圆点
        SizedBox(
          height: 16,
          child: Center(
            child: Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < _pin.length; i++)
                  Container(
                    width: 9,
                    height: 9,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'DEL'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final key in row)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: key == ''
                      ? const SizedBox(width: 64, height: 52)
                      : key == 'DEL'
                          ? SizedBox(
                              width: 64,
                              height: 52,
                              child: IconButton(
                                icon: const Icon(Icons.backspace_outlined),
                                onPressed: _backspace,
                              ),
                            )
                          : InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _tap(key),
                              child: Container(
                                width: 64,
                                height: 52,
                                alignment: Alignment.center,
                                child: Text(
                                  key,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ),
                ),
            ],
          ),
        const SizedBox(height: 4),
        FilledButton(
          onPressed: _pin.length >= 4 ? () => widget.onSubmit(_pin) : null,
          child: Text(widget.confirmLabel),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

/// 九宫格图案：拖动连线，至少 4 个点；松手后若不足触发 [onShort]，
/// 够数则回调 [onComplete]（点序以逗号连接作为密码原文）
class PatternLock extends StatefulWidget {
  const PatternLock({
    super.key,
    required this.onComplete,
    required this.onShort,
    this.errorText,
    this.size = 240,
  });

  final ValueChanged<List<int>> onComplete;
  final VoidCallback onShort;
  final String? errorText;
  final double size;

  @override
  State<PatternLock> createState() => _PatternLockState();
}

class _PatternLockState extends State<PatternLock> {
  final _path = <int>[];
  Offset? _pointer;

  Offset _center(int i, double size) => Offset(
        (i % 3 + 0.5) * size / 3,
        (i ~/ 3 + 0.5) * size / 3,
      );

  int? _hit(Offset local) {
    for (var i = 0; i < 9; i++) {
      if ((local - _center(i, widget.size)).distance <= 26) return i;
    }
    return null;
  }

  /// 加入点；若路径跨过中间点（同行/列/对角隔点）先自动补上
  void _addHit(int i) {
    if (_path.isEmpty || _path.last == i) {
      if (!_path.contains(i)) _path.add(i);
      return;
    }
    final last = _path.last;
    final mid = Offset.lerp(_center(last, widget.size),
        _center(i, widget.size), 0.5)!;
    for (var j = 0; j < 9; j++) {
      if (j == last || j == i || _path.contains(j)) continue;
      if ((mid - _center(j, widget.size)).distance <= 8) {
        _path.add(j);
        break;
      }
    }
    if (!_path.contains(i)) _path.add(i);
  }

  void _onPan(DragUpdateDetails d) {
    setState(() {
      final hit = _hit(d.localPosition);
      if (hit != null) _addHit(hit);
      _pointer = d.localPosition;
    });
  }

  void _onStart(DragStartDetails d) => _onPan(DragUpdateDetails(
        globalPosition: d.globalPosition,
        localPosition: d.localPosition,
      ));

  void _onEnd() {
    if (_path.length >= 4) {
      widget.onComplete(List<int>.of(_path));
    } else if (_path.isNotEmpty) {
      widget.onShort();
    }
    setState(() {
      _path.clear();
      _pointer = null;
    });
  }

  void _cancel() {
    setState(() {
      _path.clear();
      _pointer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onStart,
          onPanUpdate: _onPan,
          onPanEnd: (_) => _onEnd(),
          onPanCancel: _cancel,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _PatternPainter(
              path: List<int>.unmodifiable(_path),
              pointer: _pointer,
              active: scheme.primary,
              idle: scheme.outlineVariant,
              size: widget.size,
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.path,
    required this.pointer,
    required this.active,
    required this.idle,
    required this.size,
  });

  final List<int> path;
  final Offset? pointer;
  final Color active;
  final Color idle;
  final double size;

  Offset center(int i) => Offset(
        (i % 3 + 0.5) * size / 3,
        (i ~/ 3 + 0.5) * size / 3,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = active
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // 路径连线
    for (var i = 0; i + 1 < path.length; i++) {
      canvas.drawLine(center(path[i]), center(path[i + 1]), linePaint);
    }
    // 最后一点到指针
    if (path.isNotEmpty && pointer != null) {
      canvas.drawLine(center(path.last), pointer!, linePaint);
    }
    // 九个点
    for (var i = 0; i < 9; i++) {
      final selected = path.contains(i);
      final c = center(i);
      canvas.drawCircle(
        c,
        selected ? 10 : 7,
        Paint()
          ..color = selected ? active : idle
          ..style = PaintingStyle.fill,
      );
      if (!selected) {
        canvas.drawCircle(
          c,
          10,
          Paint()
            ..color = idle
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) => true;
}

/// 查看私密内容前的解锁验证：
/// 会话已解锁或未配置锁时直接放行；验证通过后解锁整个会话
Future<bool> showLockVerify(BuildContext context) async {
  if (!LockSession.instance.needsUnlock) return true;
  final l = AppLocalizations.of(context)!;
  final method = AppSettings.instance.lockMethod;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      String error = '';
      int pinToken = 0;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.lockVerifyTitle),
          content: SingleChildScrollView(
            child: method == LockMethod.pin
                ? PinPad(
                    resetToken: pinToken,
                    errorText: error.isEmpty ? null : error,
                    confirmLabel: l.confirm,
                    onSubmit: (pin) {
                      if (AppSettings.instance.matchesLockSecret(pin)) {
                        LockSession.instance.unlock();
                        Navigator.pop(dialogContext, true);
                      } else {
                        setState(() {
                          error = l.lockWrong;
                          pinToken++;
                        });
                      }
                    },
                  )
                : PatternLock(
                    errorText: error.isEmpty ? null : error,
                    onComplete: (path) {
                      if (AppSettings.instance
                          .matchesLockSecret(path.join(','))) {
                        LockSession.instance.unlock();
                        Navigator.pop(dialogContext, true);
                      } else {
                        setState(() => error = l.lockWrong);
                      }
                    },
                    onShort: () => setState(() => error = l.lockPatternShort),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.cancel),
            ),
          ],
        ),
      );
    },
  );
  return ok == true;
}

/// 设置密码（PIN / 图案），两步确认一致后保存并解锁会话
Future<bool> showLockSetup(BuildContext context, LockMethod method) async {
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      String? firstPin;
      List<int>? firstPath;
      var confirming = false;
      String error = '';
      int pinToken = 0;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(method == LockMethod.pin
              ? l.lockSetPin
              : l.lockSetPattern),
          content: SingleChildScrollView(
            child: method == LockMethod.pin
                ? PinPad(
                    key: ValueKey(confirming),
                    resetToken: pinToken,
                    hint: confirming ? l.lockConfirmHint : l.lockEnterPinHint,
                    errorText: error.isEmpty ? null : error,
                    confirmLabel: l.confirm,
                    onSubmit: (pin) async {
                      if (!confirming) {
                        setState(() {
                          firstPin = pin;
                          confirming = true;
                        });
                      } else if (pin == firstPin) {
                        await AppSettings.instance.setLockSecret(
                            LockMethod.pin, pin);
                        LockSession.instance.unlock();
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } else {
                        setState(() {
                          confirming = false;
                          error = l.lockMismatch;
                          pinToken++;
                        });
                      }
                    },
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        confirming ? l.lockConfirmHint : l.lockPatternHint,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                      ),
                      PatternLock(
                        errorText: error.isEmpty ? null : error,
                        onComplete: (path) async {
                          if (!confirming) {
                            setState(() {
                              firstPath = path;
                              confirming = true;
                              error = '';
                            });
                          } else if (listEquals(path, firstPath)) {
                            await AppSettings.instance.setLockSecret(
                                LockMethod.pattern, path.join(','));
                            LockSession.instance.unlock();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } else {
                            setState(() {
                              confirming = false;
                              error = l.lockMismatch;
                            });
                          }
                        },
                        onShort: () =>
                            setState(() => error = l.lockPatternShort),
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.cancel),
            ),
          ],
        ),
      );
    },
  );
  return ok == true;
}

/// 选择解锁方式（PIN / 图案）
Future<LockMethod?> showLockMethodPicker(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return showModalBottomSheet<LockMethod>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l.lockChooseMethod,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dialpad),
            title: Text(l.lockPin),
            onTap: () => Navigator.pop(context, LockMethod.pin),
          ),
          ListTile(
            leading: const Icon(Icons.pattern),
            title: Text(l.lockPattern),
            onTap: () => Navigator.pop(context, LockMethod.pattern),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// 私密内容点按门：私密思绪需先解锁，通过后执行 [open]
Future<void> openEntryGuarded(
  BuildContext context,
  ThoughtEntry entry,
  VoidCallback open,
) async {
  if (entry.locked) {
    final ok = await showLockVerify(context);
    if (!ok) return;
  }
  open();
}

/// 列表中是否遮挡内容（私密且未解锁）
bool isEntryMasked(ThoughtEntry entry) =>
    entry.locked && LockSession.instance.needsUnlock;

/// 事件标题是否应遮罩：事件关联的思绪为私密，且会话未解锁。
/// （编辑器创建的事件标题就是思绪内容，关联私密思绪时不能直接显示）
bool isEventTitleMasked(CalendarEvent event, Set<int> lockedThoughtIds) =>
    event.thoughtId != null &&
    lockedThoughtIds.contains(event.thoughtId) &&
    LockSession.instance.needsUnlock;

/// 事件的显示标题：私密关联时以类型名代替原标题
String eventDisplayTitle(
  CalendarEvent event,
  String typeName,
  Set<int> lockedThoughtIds,
) =>
    isEventTitleMasked(event, lockedThoughtIds)
        ? typeName
        : (event.title ?? typeName);
