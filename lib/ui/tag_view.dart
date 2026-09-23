import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/tag_presets.dart';


/// Material Icons 私用区判断（与 app_database 的 isEmojiCodepoint 同规则）
bool _isEmojiCodepoint(int codePoint) =>
    codePoint < 0xE000 || codePoint > 0xF8FF;

/// 外观解析（标签与高级标签组共用同一组外观列）
IconData? resolveIconData(int? icon, String? glyph) {
  if (glyph != null && glyph.isNotEmpty) return null;
  if (icon == null || _isEmojiCodepoint(icon)) return null;
  for (final candidate in tagIconChoices) {
    if (candidate.codePoint == icon) return candidate;
  }
  return null;
}

String? resolveDisplayGlyph(int? icon, String? glyph) {
  if (glyph != null && glyph.isNotEmpty) return glyph;
  if (icon != null && _isEmojiCodepoint(icon)) {
    return String.fromCharCodes([icon]);
  }
  return null;
}

bool hasAppearanceIcon(int? icon, String? glyph) =>
    icon != null || (glyph != null && glyph.isNotEmpty);

extension TagX on Tag {
  /// 自定义图标；null = 无图标。从候选集中查表保证 const 引用（图标可被 tree-shake）。
  /// emoji/glyph 走 displayGlyph 文本渲染，此处返回 null。
  IconData? get iconData => resolveIconData(icon, glyph);

  /// 是否 emoji 图标（旧数据：emoji 单码点存于 icon 列）
  bool get isEmojiIcon {
    final codePoint = icon;
    return codePoint != null && _isEmojiCodepoint(codePoint);
  }

  /// 是否设置了任何图标（glyph/emoji/Material 任一）
  bool get hasIcon => hasAppearanceIcon(icon, glyph);

  /// 字符图标（glyph 列优先，兼容旧 icon 列中的单码点 emoji）
  String? get displayGlyph => resolveDisplayGlyph(icon, glyph);

  /// 自定义颜色；null = 使用主题默认
  Color? get uiColor => color == null ? null : Color(color!);
}

extension TagCategoryX on TagCategory {
  IconData? get iconData => resolveIconData(icon, glyph);

  bool get hasIcon => hasAppearanceIcon(icon, glyph);

  String? get displayGlyph => resolveDisplayGlyph(icon, glyph);

  Color? get uiColor => color == null ? null : Color(color!);
}

/// 统一标签图标渲染：glyph/emoji 以文本渲染原色（不受 color 影响），
/// Material 图标按 uiColor ?? color 着色，无图标时显示 fallback（或缺省）。
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
  Widget build(BuildContext context) => _AppearanceIcon(
        glyph: tag.displayGlyph,
        data: tag.iconData,
        tint: tag.uiColor,
        size: size,
        color: color,
        fallback: fallback,
      );
}

/// 高级标签组图标渲染（与 TagIcon 同规则）
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 16,
    this.color,
    this.fallback,
  });

  final TagCategory category;
  final double size;
  final Color? color;
  final IconData? fallback;

  @override
  Widget build(BuildContext context) => _AppearanceIcon(
        glyph: category.displayGlyph,
        data: category.iconData,
        tint: category.uiColor,
        size: size,
        color: color,
        fallback: fallback,
      );
}

class _AppearanceIcon extends StatelessWidget {
  const _AppearanceIcon({
    required this.glyph,
    required this.data,
    required this.tint,
    required this.size,
    required this.color,
    required this.fallback,
  });

  final String? glyph;
  final IconData? data;
  final Color? tint;
  final double size;
  final Color? color;
  final IconData? fallback;

  @override
  Widget build(BuildContext context) {
    if (glyph != null) {
      return Text(
        glyph!,
        style: TextStyle(fontSize: size * 1.05, height: 1.1),
      );
    }
    final iconData = data ?? fallback;
    if (iconData == null) return const SizedBox.shrink();
    return Icon(
      iconData,
      size: size,
      color: tint ?? color ?? Theme.of(context).colorScheme.primary,
    );
  }
}

/// 高级标签值胶囊：组图标（或值图标）+ 值名，按组/值颜色着色。
/// 用于卡片下方展示"天气·晴 / 食物·拉面"等
class AdvancedTagChips extends StatelessWidget {
  const AdvancedTagChips({super.key, required this.items, this.showCategoryName = false});

  final List<TagWithCategory> items;

  /// 是否在值名前带上组名（多组并排时更清晰）
  final bool showCategoryName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final item in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (item.tag.uiColor ?? item.category?.uiColor ??
                        scheme.primary)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.tag.hasIcon || (item.category?.hasIcon ?? false)) ...[
                    item.tag.hasIcon
                        ? TagIcon(tag: item.tag, size: 12)
                        : CategoryIcon(category: item.category!, size: 12),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    showCategoryName && item.category != null
                        ? '${item.category!.name} · ${item.tag.name}'
                        : item.tag.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: item.tag.uiColor ??
                              item.category?.uiColor ??
                              scheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
