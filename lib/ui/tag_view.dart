import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/tag_presets.dart';
import '../data/thoughts_table.dart';

extension TagX on Tag {
  /// 标签种类（kind 列存 int，此处转换）
  TagKind get tagKind => TagKind.fromValue(kind);

  /// 自定义图标；null = 无图标。从候选集中查表保证 const 引用（图标可被 tree-shake）。
  /// emoji/glyph 走 displayGlyph 文本渲染，此处返回 null。
  IconData? get iconData {
    final codePoint = icon;
    if (glyph != null && glyph!.isNotEmpty) return null;
    if (codePoint == null || isEmojiCodepoint(codePoint)) return null;
    for (final candidate in tagIconChoices) {
      if (candidate.codePoint == codePoint) return candidate;
    }
    return null;
  }

  /// 是否 emoji 图标（旧数据：emoji 单码点存于 icon 列）
  bool get isEmojiIcon {
    final codePoint = icon;
    return codePoint != null && isEmojiCodepoint(codePoint);
  }

  /// 是否设置了任何图标（glyph/emoji/Material 任一）
  bool get hasIcon =>
      icon != null || (glyph != null && glyph!.isNotEmpty);

  /// 字符图标（glyph 列优先，兼容旧 icon 列中的单码点 emoji）
  String? get displayGlyph {
    final g = glyph;
    if (g != null && g.isNotEmpty) return g;
    final codePoint = icon;
    if (codePoint != null && isEmojiCodepoint(codePoint)) {
      return String.fromCharCodes([codePoint]);
    }
    return null;
  }

  /// 自定义颜色；null = 使用主题默认
  Color? get uiColor => color == null ? null : Color(color!);
}

/// 统一标签图标渲染：glyph/emoji 以文本渲染原色（不受 color 影响），
/// Material 图标按 tag.uiColor ?? color 着色，无图标时显示 fallback（或缺省）。
class TagIcon extends StatelessWidget {
  const TagIcon({
    super.key,
    required this.tag,
    this.size = 16,
    this.color,
    this.fallback,
  });

  final Tag tag;
  final double size;

  /// Material 图标无自定义颜色时的兜底色
  final Color? color;

  /// 无图标时的兜底图标（不传则不渲染）
  final IconData? fallback;

  @override
  Widget build(BuildContext context) {
    final glyph = tag.displayGlyph;
    if (glyph != null) {
      return Text(
        glyph,
        style: TextStyle(fontSize: size * 1.05, height: 1.1),
      );
    }
    final data = tag.iconData ?? fallback;
    if (data == null) return const SizedBox.shrink();
    return Icon(
      data,
      size: size,
      color: tag.uiColor ?? color ?? Theme.of(context).colorScheme.primary,
    );
  }
}
