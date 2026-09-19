import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/tag_presets.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';
import '../ui/tag_view.dart';

/// 标签管理：心情管理入口 + 普通标签胶囊墙（非列表），点按查看、长按操作
class TagsPage extends StatelessWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
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
  const _TagPill({required this.item, this.moodStyle = false});

  final TagWithCount item;
  final bool moodStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tag = item.tag;
    final c = tag.uiColor ?? scheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        if (moodStyle) {
          showTagEditor(context, tag: tag);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TagDetailPage(tagWithCount: item)),
          );
        }
      },
      onLongPress: () => _showTagActions(context, item),
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
            if (tag.iconData != null) ...[
              Icon(
                tag.iconData,
                size: 16,
                color: moodStyle ? c : scheme.onSurfaceVariant,
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
            const SizedBox(width: 6),
            Text(
              '${item.count}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
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
Future<void> showTagEditor(
  BuildContext context, {
  Tag? tag,
  TagKind kind = TagKind.normal,
}) async {
  final l = AppLocalizations.of(context)!;
  final isCreate = tag == null;
  final nameController = TextEditingController(text: tag?.name ?? '');
  int? icon = tag?.icon;
  int? color = tag?.color;
  String? nameError;

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
              const SizedBox(height: 12),
              Text(l.tagIcon, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _iconOption(
                      context,
                      iconData: null,
                      label: l.noIcon,
                      selected: icon == null,
                      onTap: () => setState(() => icon = null),
                    ),
                    for (final candidate in tagIconChoices)
                      _iconOption(
                        context,
                        iconData: candidate,
                        selected: icon == candidate.codePoint,
                        tint: color,
                        onTap: () => setState(() => icon = candidate.codePoint),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(l.tagColor, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
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
              ),
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
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
  final newName = nameController.text.trim();
  nameController.dispose();
  if (ok != true || !context.mounted) return;
  if (isCreate) {
    await appDb.getOrCreateTag(
      newName,
      kind: kind,
      icon: icon,
      color: color,
    );
  } else {
    if (newName.isNotEmpty && newName != tag.name) {
      await appDb.renameTag(tag.id, newName);
    }
    await appDb.setTagAppearance(tag.id, icon: icon, color: color);
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

    return Scaffold(
      appBar: AppBar(
        title: Text('#${tagWithCount.tag.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showTagEditor(context, tag: tagWithCount.tag),
          ),
        ],
      ),
      body: StreamBuilder<List<ThoughtEntry>>(
        stream: appDb.watchEntriesWithTag(tagWithCount.tag.id),
        builder: (context, snap) {
          final entries = snap.data ?? const <ThoughtEntry>[];
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (entries.isEmpty) {
            return Center(child: Text(l.emptyDay));
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 2),
                        child: Text(
                          DateFormat.yMMMd(locale).format(e.dayDate),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      EntryCard(
                        entry: e,
                        onTap: () => showEntryEditor(context, existing: e),
                        onLongPress: () => confirmDelete(context, e),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
