import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/tag_presets.dart';

import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';
import '../ui/tag_view.dart';
import '../ui/vault_switcher.dart';

/// 标签管理：高级标签组（内置"心情"+ 自定义组）+ 普通标签胶囊墙
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
            onPressed: () => showTagEditor(context),
          ),
        ],
      ),
      body: StreamBuilder<List<TagCategory>>(
        stream: appDb.watchTagCategories(),
        builder: (context, catSnap) {
          final categories = catSnap.data ?? const <TagCategory>[];
          return StreamBuilder<List<TagWithCount>>(
            stream: appDb.watchTagsWithCount(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data ?? const <TagWithCount>[];
              final normal = all.where((e) => e.category == null).toList();
              // 各组选项数量
              final optionCounts = <int, int>{};
              for (final t in all) {
                final cid = t.category?.id;
                if (cid != null) {
                  optionCounts[cid] = (optionCounts[cid] ?? 0) + 1;
                }
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    l.advancedTagsSection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.advancedTagsHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        for (final c in categories)
                          ListTile(
                            leading: CategoryIcon(
                              category: c,
                              size: 24,
                              color: scheme.primary,
                              fallback: Icons.label_outline,
                            ),
                            title: Text(c.name),
                            subtitle: Text(
                              '${c.multi ? l.categoryMulti : l.categorySingle}'
                              ' · ${l.optionCount(optionCounts[c.id] ?? 0)}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryPage(categoryId: c.id),
                              ),
                            ),
                          ),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: Text(l.addTagCategory),
                          onTap: () => showCategoryEditor(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.normalTagsSection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.tagHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
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
          );
        },
      ),
    );
  }
}

/// 单个高级标签组：管理其选项（新建/编辑/删除）与组设置
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.categoryId});

  final int categoryId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<TagCategory>>(
      stream: appDb.watchTagCategories(),
      builder: (context, catSnap) {
        final category = (catSnap.data ?? const <TagCategory>[])
            .where((c) => c.id == categoryId)
            .firstOrNull;
        if (category == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const SizedBox.shrink(),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryIcon(
                  category: category,
                  size: 18,
                  color: scheme.primary,
                  fallback: Icons.label_outline,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    category.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category.multi ? l.categoryMulti : l.categorySingle,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: l.addOption,
                onPressed: () =>
                    showTagEditor(context, categoryId: categoryId),
              ),
              PopupMenuButton<String>(
                onSelected: (action) => switch (action) {
                  'edit' => showCategoryEditor(context, existing: category),
                  'delete' => _deleteCategory(context, category),
                  _ => null,
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(l.editTagCategory),
                  ),
                  if (!category.builtin)
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        l.deleteTagCategory,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: StreamBuilder<List<TagWithCount>>(
            stream: appDb.watchTagsWithCount(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final options = (snap.data ?? const <TagWithCount>[])
                  .where((t) => t.category?.id == categoryId)
                  .toList();
              if (options.isEmpty) {
                return Center(
                  child: Text(
                    l.optionsEmpty,
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
                          for (final item in options)
                            _TagPill(item: item, advancedStyle: true),
                        ],
                      ),
                    ),
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

Future<void> _deleteCategory(
    BuildContext context, TagCategory category) async {
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.deleteTagCategory),
      content: Text(l.deleteTagCategoryBody(category.name)),
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
    await appDb.deleteTagCategory(category.id);
    if (context.mounted) Navigator.pop(context);
  }
}

/// 标签/选项胶囊：高级样式（有底色）与普通样式（#名称）
class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.item,
    this.advancedStyle = false,
    this.interactive = true,
    this.showCount = true,
  });

  final TagWithCount item;
  final bool advancedStyle;

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
              if (advancedStyle) {
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
          color: advancedStyle
              ? c.withValues(alpha: 0.15)
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                advancedStyle ? c.withValues(alpha: 0.4) : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tag.hasIcon) ...[
              TagIcon(
                tag: tag,
                size: 16,
                color: advancedStyle ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              advancedStyle ? tag.name : '#${tag.name}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: advancedStyle ? c : scheme.onSurface,
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

/// 编辑标签/选项；tag 为 null 时新建（categoryId 非空即高级标签组的选项）
Future<void> showTagEditor(
  BuildContext context, {
  Tag? tag,
  int? categoryId,
}) async {
  final l = AppLocalizations.of(context)!;
  final isCreate = tag == null;
  final effectiveCategoryId = tag?.categoryId ?? categoryId;
  final advancedStyle = effectiveCategoryId != null;
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
              ? (advancedStyle ? l.addOption : l.addTag)
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
                    categoryId: effectiveCategoryId,
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
                advancedStyle: advancedStyle,
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
                      onPressed: () => FocusScope.of(context).unfocus(),
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
              if (isCreate &&
                  await appDb.tagByName(name, categoryId: effectiveCategoryId) !=
                      null) {
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
      categoryId: effectiveCategoryId,
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

/// 新建/编辑高级标签组（名称 + 单选/多选 + 颜色 + 图标）
Future<void> showCategoryEditor(
  BuildContext context, {
  TagCategory? existing,
}) async {
  final l = AppLocalizations.of(context)!;
  final isCreate = existing == null;
  final nameController = TextEditingController(text: existing?.name ?? '');
  final glyphController =
      TextEditingController(text: existing?.displayGlyph ?? '');
  final hasGlyph = (existing?.glyph?.isNotEmpty ?? false);
  int? icon = existing?.icon;
  int? color = existing?.color;
  var multi = existing?.multi ?? false;
  String? nameError;
  var tab = hasGlyph ? 1 : 0;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(isCreate ? l.addTagCategory : l.editTagCategory),
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
              const SizedBox(height: 12),
              // 单选 / 多选
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(l.categorySingle)),
                  ButtonSegment(value: true, label: Text(l.categoryMulti)),
                ],
                selected: {multi},
                onSelectionChanged: (s) => setState(() => multi = s.first),
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
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                setState(() => nameError = l.tagNameEmpty);
                return;
              }
              if (_glyphError(glyphController.text, l) != null) return;
              Navigator.pop(context, true);
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
  final newName = nameController.text.trim();
  final finalGlyph = _validatedGlyph(glyphController.text);
  nameController.dispose();
  glyphController.dispose();
  if (ok != true || !context.mounted) return;
  final effectiveIcon = finalGlyph == null ? icon : null;
  if (isCreate) {
    await appDb.createTagCategory(
      name: newName,
      multi: multi,
      color: color,
      icon: effectiveIcon,
      glyph: finalGlyph,
    );
  } else {
    await appDb.updateTagCategory(
      existing.id,
      name: newName,
      multi: multi,
      color: color,
      icon: effectiveIcon,
      glyph: finalGlyph,
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
        final advancedStyle = current.category != null;
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
                    advancedStyle
                        ? current.tag.name
                        : '#${current.tag.name}',
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
