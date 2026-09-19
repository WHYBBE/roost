import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/tag_presets.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';
import '../ui/tag_view.dart';

/// 标签页：标签列表（含心情标签）+ 使用数量，支持编辑外观 / 删除
class TagsPage extends StatelessWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.navTags)),
      body: StreamBuilder<List<TagWithCount>>(
        stream: appDb.watchTagsWithCount(),
        builder: (context, snap) {
          final tags = snap.data ?? const <TagWithCount>[];
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (tags.isEmpty) {
            return Center(
              child: Text(
                l.tagsEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: tags.length,
                itemBuilder: (context, i) {
                  final item = tags[i];
                  final isMood = item.tag.tagKind == TagKind.mood;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        item.tag.iconData ?? Icons.sell_outlined,
                        color: item.tag.uiColor ??
                            Theme.of(context).colorScheme.primary,
                      ),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: Text(item.tag.name)),
                          if (isMood) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l.kindMood,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(l.entriesCount(item.count)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TagDetailPage(tagWithCount: item),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'edit') {
                            showTagEditor(context, item.tag);
                          } else if (action == 'delete') {
                            _deleteDialog(context, item);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(l.tagEditorTitle),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l.deleteTag),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
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
}

/// 编辑标签：名称 + 图标 + 颜色（图标/颜色可留空 = 无图标/默认色）
Future<void> showTagEditor(BuildContext context, Tag tag) async {
  final l = AppLocalizations.of(context)!;
  final nameController = TextEditingController(text: tag.name);
  int? icon = tag.icon;
  int? color = tag.color;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l.tagEditorTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l.tagName,
                  border: const OutlineInputBorder(),
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
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
  final newName = nameController.text.trim();
  nameController.dispose();
  if (ok == true && context.mounted) {
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
            onPressed: () => showTagEditor(context, tagWithCount.tag),
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
