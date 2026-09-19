import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/tag_presets.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import 'tag_view.dart';

extension EntryX on ThoughtEntry {
  DateTime get createdAtLocal => DateTime.fromMillisecondsSinceEpoch(createdAt);
  DateTime get dayDate => DateTime.parse(day);
  String get monthDay => day.substring(5);
  int get year => int.parse(day.substring(0, 4));
}

class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    this.tags,
    this.onTap,
    this.onLongPress,
  });

  final ThoughtEntry entry;

  /// 标签列表（含心情标签）；为 null 时自动加载
  final List<Tag>? tags;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = entry.createdAtLocal;
    final mood = tags
        ?.where((t) => t.tagKind == TagKind.mood)
        .fold<Tag?>(null, (prev, t) => prev ?? t);
    final normalTags =
        tags?.where((t) => t.tagKind == TagKind.normal).toList() ?? const [];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (mood != null) ...[
                    Icon(
                      mood.iconData ?? Icons.mood,
                      size: 18,
                      color: mood.uiColor ?? scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mood.name,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: mood.uiColor ?? scheme.primary,
                          ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectionArea(
                child: Text(
                  entry.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (normalTags.isNotEmpty) TagChips(tags: normalTags),
            ],
          ),
        ),
      ),
    );
  }
}

class TagChips extends StatelessWidget {
  const TagChips({super.key, required this.tags});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final tag in tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tag.uiColor?.withValues(alpha: 0.18) ??
                    scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tag.iconData != null) ...[
                    Icon(
                      tag.iconData,
                      size: 12,
                      color: tag.uiColor ?? scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '#${tag.name}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tag.uiColor ?? scheme.onSecondaryContainer,
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

class _TagChipsLoader extends StatefulWidget {
  const _TagChipsLoader({required this.entryId});

  final int entryId;

  @override
  State<_TagChipsLoader> createState() => _TagChipsLoaderState();
}

class _TagChipsLoaderState extends State<_TagChipsLoader> {
  List<Tag>? _tags;

  @override
  void initState() {
    super.initState();
    appDb.tagsFor(widget.entryId).then((tags) {
      if (mounted) setState(() => _tags = tags);
    });
  }

  @override
  Widget build(BuildContext context) {
    final normal = _tags?.where((t) => t.tagKind == TagKind.normal).toList();
    if (normal == null || normal.isEmpty) return const SizedBox.shrink();
    return TagChips(tags: normal);
  }
}

Future<void> showEntryEditor(
  BuildContext context, {
  ThoughtEntry? existing,
  String? initialText,
}) async {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: existing?.content ?? initialText ?? '');
  var saved = false;
  final allTags = existing == null
      ? <Tag>[]
      : List<Tag>.of(await appDb.tagsFor(existing.id));
  if (!context.mounted) return;
  final moodTags = await appDb.moodTags();
  if (!context.mounted) return;
  // 该思绪的心情标签若已被删除，仍保留在选项里供本次保存
  for (final t in allTags) {
    if (t.tagKind == TagKind.mood && !moodTags.any((m) => m.id == t.id)) {
      moodTags.add(t);
    }
  }
  final tagController = TextEditingController();

  await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
      var mood = allTags
          .where((t) => t.tagKind == TagKind.mood)
          .fold<Tag?>(null, (prev, t) => prev ?? t);
      final normalTags =
          allTags.where((t) => t.tagKind == TagKind.normal).toList();

        return AlertDialog(
          title: Text(existing == null ? l.newThought : l.editThought),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: controller,
                  autofocus: existing == null,
                  maxLines: 6,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: l.thoughtHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // 心情：特殊标签，单选；可即时新建心情标签
                Row(
                  children: [
                    Text(l.moodLabel, style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    Tooltip(
                      message: l.createMoodTag,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final name = await _promptText(
                            context,
                            title: l.createMoodTag,
                          );
                          if (name == null || name.trim().isEmpty) return;
                          final tag = await appDb.getOrCreateTag(
                            name,
                            kind: TagKind.mood,
                            icon: moodPresets.first.icon.codePoint,
                            color: moodPresets.first.color,
                          );
                          allTags.removeWhere((t) => t.id == tag.id);
                          allTags.add(tag);
                          setState(() {});
                        },
                        child: const Icon(Icons.add, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final m in moodTags)
                      ChoiceChip(
                        label: Text(m.name),
                        selected: mood?.id == m.id,
                        avatar: Icon(
                          m.iconData ?? Icons.mood,
                          size: 16,
                          color: m.uiColor,
                        ),
                        onSelected: (sel) {
                          allTags.removeWhere((t) => t.tagKind == TagKind.mood);
                          if (sel) allTags.add(m);
                          setState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l.tagHint, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                if (normalTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final t in normalTags)
                          InputChip(
                            label: Text('#${t.name}'),
                            visualDensity: VisualDensity.compact,
                            onDeleted: () =>
                                setState(() => allTags.remove(t)),
                          ),
                      ],
                    ),
                  ),
                TextField(
                  controller: tagController,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: l.tagAdd,
                      onPressed: () => _addTagsFromField(
                          tagController, allTags, () => setState(() {})),
                    ),
                  ),
                  onSubmitted: (_) => _addTagsFromField(
                      tagController, allTags, () => setState(() {})),
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
                _addTagsFromField(tagController, allTags, () {});
                final text = controller.text.trim();
                if (text.isEmpty) return;
                var thoughtId = existing?.id;
                if (existing == null) {
                  thoughtId = await appDb.insertThought(
                    content: text,
                    day: AppDatabase.today(),
                  );
                } else {
                  await appDb.updateThought(existing.id, text);
                }
                await appDb.setThoughtTags(
                  thoughtId!,
                  allTags.map((t) => t.name).toList(),
                );
                saved = true;
                if (context.mounted) Navigator.pop(context, true);
              },
              child: Text(l.save),
            ),
          ],
        );
      },
    ),
  );
  controller.dispose();
  tagController.dispose();
  if (saved && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.saved)));
  }
}

void _addTagsFromField(
  TextEditingController controller,
  List<Tag> tags,
  VoidCallback onChanged,
) {
  final parts =
      controller.text.split(RegExp(r'[\s,，]+')).where((p) => p.trim().isNotEmpty);
  for (final part in parts) {
    final name = part.trim();
    if (!tags.any((t) => t.name == name)) {
      tags.add(Tag(
        id: -1,
        name: name,
        kind: TagKind.normal.value,
        icon: null,
        color: null,
        createdAt: DateTime.now(),
      ));
    }
  }
  controller.clear();
  onChanged();
}

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  String? initial,
}) async {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initial ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(l.save),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<void> confirmDelete(BuildContext context, ThoughtEntry entry) async {
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.confirmDeleteTitle),
      content: Text(l.confirmDeleteBody),
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
    await appDb.deleteThought(entry.id);
  }
}
