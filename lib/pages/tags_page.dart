import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/tag_presets.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';
import '../ui/tag_view.dart';
import '../ui/vault_switcher.dart';

/// 标签管理：心情管理入口 + 普通标签胶囊墙（非列表），点按查看、长按操作
class TagsPage extends StatelessWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: appBarVaultSwitcher(context),
        title: Text(l.navTags),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l.addTag,
            onPressed: () => showTagEditor(context, kind: TagKind.normal),
          ),
        ],
      ),
      body: StreamBuilder<List<TagWithCount>>(
        stream: appDb.watchTagsWithCount(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? const <TagWithCount>[];
          final moodCount =
              all.where((e) => e.tag.tagKind == TagKind.mood).length;
          final normal =
              all.where((e) => e.tag.tagKind == TagKind.normal).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: Icon(Icons.mood_outlined, color: scheme.primary),
                  title: Text(l.moodManagement),
                  subtitle:
                      moodCount > 0 ? Text(l.moodCount(moodCount)) : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MoodPage()),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (normal.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    l.tagsEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in normal) _TagPill(item: item),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 心情管理：独立界面，复用标签胶囊与编辑器
class MoodPage extends StatelessWidget {
  const MoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.moodManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l.addMood,
            onPressed: () => showTagEditor(context, kind: TagKind.mood),
          ),
        ],
      ),
      body: StreamBuilder<List<TagWithCount>>(
        stream: appDb.watchTagsWithCount(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final moods = (snap.data ?? const <TagWithCount>[])
              .where((e) => e.tag.tagKind == TagKind.mood)
              .toList();
          if (moods.isEmpty) {
            return Center(
              child: Text(
                l.moodsEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in moods) _TagPill(item: m, moodStyle: true),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 标签胶囊：普通样式（非列表行）；点按进入详情/编辑，长按弹出操作
class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.item,
    this.moodStyle = false,
    this.interactive = true,
    this.showCount = true,
  });

  final TagWithCount item;
  final bool moodStyle;

  /// 预览模式：无点按/长按行为
  final bool interactive;

  /// 是否显示使用数量
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tag = item.tag;
    final c = tag.uiColor ?? scheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: !interactive
          ? null
          : () {
              if (moodStyle) {
                showTagEditor(context, tag: tag);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TagDetailPage(tagWithCount: item)),
                );
              }
            },
      onLongPress: interactive ? () => _showTagActions(context, item) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: moodStyle ? c.withValues(alpha: 0.15) : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: moodStyle ? c.withValues(alpha: 0.4) : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tag.hasIcon) ...[
              TagIcon(
                tag: tag,
                size: 16,
                color: moodStyle ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              moodStyle ? tag.name : '#${tag.name}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: moodStyle ? c : scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (showCount) ...[
              const SizedBox(width: 6),
              Text(
                '${item.count}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 预览名称：空时回落到占位文案
String _previewName(String raw, AppLocalizations l) {
  final name = raw.trim();
  return name.isEmpty ? l.tagName : name;
}

/// 字符图标校验错误：非空时必须恰好一个字位（单码点字符或多码点 emoji 序列）
String? _glyphError(String raw, AppLocalizations l) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  if (s.characters.length > 1) return l.glyphOnlyOne;
  return null;
}

/// 通过校验的字符图标；无效（多个字位）返回 null
String? _validatedGlyph(String raw) {
  final s = raw.trim();
  if (s.isEmpty || s.characters.length > 1) return null;
  return s;
}

/// 长按操作：查看思绪 / 编辑 / 删除
Future<void> _showTagActions(BuildContext context, TagWithCount item) async {
  final l = AppLocalizations.of(context)!;
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: Text(l.viewEntries),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TagDetailPage(tagWithCount: item),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l.tagEditorTitle),
            onTap: () {
              Navigator.pop(sheetContext);
              showTagEditor(context, tag: item.tag);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l.deleteTag),
            onTap: () {
              Navigator.pop(sheetContext);
              _deleteDialog(context, item);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _deleteDialog(BuildContext context, TagWithCount item) async {
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.deleteTag),
      content: Text(l.deleteTagBody(item.count)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.delete),
        ),
      ],
    ),
  );
  if (ok == true) {
    await appDb.deleteTag(item.tag.id);
  }
}

/// 编辑标签；tag 为 null 时进入新建模式（kind 决定新建种类）
/// 布局：名称 → 颜色（有用则用）→ 单色图标 / Emoji（Tab 切换）
Future<void> showTagEditor(
  BuildContext context, {
  Tag? tag,
  TagKind kind = TagKind.normal,
}) async {
  final l = AppLocalizations.of(context)!;
  final isCreate = tag == null;
  final nameController = TextEditingController(text: tag?.name ?? '');
  // 字符图标（emoji/任意字符）以输入框内容为单一数据源
  final glyphController =
      TextEditingController(text: tag?.displayGlyph ?? '');
  final hasGlyph = (tag?.glyph?.isNotEmpty ?? false) ||
      (tag?.isEmojiIcon ?? false);
  int? icon = tag?.icon;
  int? color = tag?.color;
  String? nameError;
  var tab = hasGlyph ? 1 : 0;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(
          isCreate
              ? (kind == TagKind.mood ? l.addMood : l.addTag)
              : l.tagEditorTitle,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: isCreate,
                decoration: InputDecoration(
                  labelText: l.tagName,
                  border: const OutlineInputBorder(),
                  errorText: nameError,
                ),
              ),
              const SizedBox(height: 10),
              // 实时预览：名称 + 图标 + 颜色组合效果
              _TagPill(
                item: TagWithCount(
                  tag: Tag(
                    id: tag?.id ?? -1,
                    kind: tag?.kind ?? kind.value,
                    name: _previewName(nameController.text, l),
                    icon: _validatedGlyph(glyphController.text) == null
                        ? icon
                        : null,
                    glyph: _validatedGlyph(glyphController.text),
                    color: color,
                    createdAt: tag?.createdAt ?? DateTime.now(),
                  ),
                  count: 0,
                ),
                moodStyle:
                    TagKind.fromValue(tag?.kind ?? kind.value) == TagKind.mood,
                interactive: false,
                showCount: false,
              ),
              const SizedBox(height: 12),
              Text(l.tagColor, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _colorOption(
                    context,
                    label: l.defaultColor,
                    selected: color == null,
                    onTap: () => setState(() => color = null),
                  ),
                  for (final candidate in tagColorChoices)
                    _colorOption(
                      context,
                      argb: candidate,
                      selected: color == candidate,
                      onTap: () => setState(() => color = candidate),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 0, label: Text(l.tagIcon)),
                  ButtonSegment(value: 1, label: Text(l.tagEmoji)),
                ],
                selected: {tab},
                onSelectionChanged: (s) => setState(() => tab = s.first),
              ),
              const SizedBox(height: 12),
              if (tab == 0)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _iconOption(
                      context,
                      iconData: null,
                      label: l.noIcon,
                      selected: icon == null &&
                          glyphController.text.trim().isEmpty,
                      onTap: () => setState(() {
                        icon = null;
                        glyphController.clear();
                      }),
                    ),
                    for (final candidate in tagIconChoices)
                      _iconOption(
                        context,
                        iconData: candidate,
                        selected: icon == candidate.codePoint &&
                            glyphController.text.trim().isEmpty,
                        tint: color,
                        onTap: () => setState(() {
                          icon = candidate.codePoint;
                          glyphController.clear();
                        }),
                      ),
                  ],
                )
              else ...[
                TextField(
                  controller: glyphController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l.glyphHint,
                    border: const OutlineInputBorder(),
                    errorText: _glyphError(glyphController.text, l),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check, size: 20),
                      tooltip: l.save,
                      onPressed: () =>
                          FocusScope.of(context).unfocus(),
                    ),
                  ),
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final candidate in tagEmojiChoices)
                      _emojiOption(
                        context,
                        emoji: candidate,
                        selected: glyphController.text == candidate,
                        onTap: () =>
                            setState(() => glyphController.text = candidate),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                setState(() => nameError = l.tagNameEmpty);
                return;
              }
              if (isCreate && await appDb.tagByName(name) != null) {
                setState(() => nameError = l.tagExists);
                return;
              }
              // 字符图标非法（多个字位）时阻止保存，错误已实时显示在输入框
              if (_glyphError(glyphController.text, l) != null) return;
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
  final newName = nameController.text.trim();
  // 字符图标：恰好一个字位（单字符或单个多码点 emoji），保存前已校验
  final finalGlyph = _validatedGlyph(glyphController.text);
  nameController.dispose();
  glyphController.dispose();
  if (ok != true || !context.mounted) return;
  // glyph 与 icon 互斥，glyph 优先
  final effectiveIcon = finalGlyph == null ? icon : null;
  if (isCreate) {
    await appDb.getOrCreateTag(
      newName,
      kind: kind,
      icon: effectiveIcon,
      glyph: finalGlyph,
      color: color,
    );
  } else {
    if (newName.isNotEmpty && newName != tag.name) {
      await appDb.renameTag(tag.id, newName);
    }
    await appDb.setTagAppearance(
      tag.id,
      icon: effectiveIcon,
      glyph: finalGlyph,
      color: color,
    );
  }
}

Widget _iconOption(
  BuildContext context, {
  required IconData? iconData,
  required bool selected,
  required VoidCallback onTap,
  String? label,
  int? tint,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: scheme.primary, width: 1.5) : null,
        ),
        child: label != null
            ? Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              )
            : Icon(
                iconData,
                size: 20,
                color: tint != null ? Color(tint) : scheme.onSurface,
              ),
      ),
    ),
  );
}

Widget _emojiOption(
  BuildContext context, {
  required String emoji,
  required bool selected,
  required VoidCallback onTap,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: scheme.primary, width: 1.5) : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
    ),
  );
}

Widget _colorOption(
  BuildContext context, {
  required bool selected,
  required VoidCallback onTap,
  String? label,
  int? argb,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: scheme.primary, width: 1.5) : null,
        ),
        child: label != null
            ? Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              )
            : Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Color(argb!),
                  shape: BoxShape.circle,
                ),
              ),
      ),
    ),
  );
}

/// 某个标签下的全部思绪
class TagDetailPage extends StatelessWidget {
  const TagDetailPage({super.key, required this.tagWithCount});

  final TagWithCount tagWithCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme;
    final tagId = tagWithCount.tag.id;

    return StreamBuilder<List<TagWithCount>>(
      // 跟随最新外观（图标/颜色/名称）：编辑保存后再次进入不显示旧结果
      stream: appDb.watchTagsWithCount(),
      builder: (context, tagSnap) {
        TagWithCount current = tagWithCount;
        for (final t in tagSnap.data ?? const <TagWithCount>[]) {
          if (t.tag.id == tagId) {
            current = t;
            break;
          }
        }
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (current.tag.hasIcon) ...[
                  TagIcon(tag: current.tag, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    '#${current.tag.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                // 编辑按钮必须用最新 tag 对象，否则保存后重开会显示旧值
                onPressed: () => showTagEditor(context, tag: current.tag),
              ),
            ],
          ),
          body: StreamBuilder<List<ThoughtEntry>>(
            stream: appDb.watchEntriesWithTag(tagId),
            builder: (context, snap) {
              final entries = snap.data ?? const <ThoughtEntry>[];
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (entries.isEmpty) {
                return Center(child: Text(l.emptyDay));
              }
              final children = <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    l.entriesCount(entries.length),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ];
              // 按日分组：同一天只显示一次日期头
              String? lastDay;
              for (final e in entries) {
                if (e.day != lastDay) {
                  lastDay = e.day;
                  children.add(Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Text(
                      DateFormat.yMMMd(locale).format(e.dayDate),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ));
                }
                children.add(EntryCard(
                  entry: e,
                  onTap: () => showEntryEditor(context, existing: e),
                  onLongPress: () => showEntryActions(context, e),
                ));
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: children,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
