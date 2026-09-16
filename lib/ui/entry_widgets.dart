import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import 'mood.dart';

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

  /// 标签名列表；为 null 时自动加载该思绪的标签
  final List<String>? tags;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = entry.createdAtLocal;
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
                  Icon(entry.mood.icon, size: 18, color: entry.mood.color(context)),
                  const SizedBox(width: 6),
                  Text(
                    entry.mood.label(context),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                        ),
                  ),
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
              if (tags == null)
                _TagChipsLoader(entryId: entry.id)
              else if (tags!.isNotEmpty)
                TagChips(names: tags!),
            ],
          ),
        ),
      ),
    );
  }
}

class TagChips extends StatelessWidget {
  const TagChips({super.key, required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final name in names)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '#$name',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
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
  List<String>? _tags;

  @override
  void initState() {
    super.initState();
    appDb.tagNamesFor(widget.entryId).then((tags) {
      if (mounted) setState(() => _tags = tags);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tags = _tags;
    if (tags == null || tags.isEmpty) return const SizedBox.shrink();
    return TagChips(names: tags);
  }
}

class MoodChips extends StatelessWidget {
  const MoodChips({super.key, required this.selected, required this.onSelected});

  final Mood? selected;
  final ValueChanged<Mood?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final m in Mood.values)
          FilterChip(
            label: Text(m.label(context)),
            selected: selected == m,
            avatar: Icon(m.icon, size: 16, color: m.color(context)),
            onSelected: (v) => onSelected(v ? m : null),
          ),
      ],
    );
  }
}

Future<void> showEntryEditor(
  BuildContext context, {
  ThoughtEntry? existing,
  String? initialText,
  Mood? initialMood,
}) async {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: existing?.content ?? initialText ?? '');
  var mood = existing?.mood ?? initialMood ?? Mood.calm;
  var saved = false;
  final tags = existing == null
      ? <String>[]
      : List<String>.of(await appDb.tagNamesFor(existing.id));
  if (!context.mounted) return;
  final tagController = TextEditingController();

  await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
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
              Text(l.moodLabel, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in Mood.values)
                    ChoiceChip(
                      label: Text(m.label(context)),
                      selected: mood == m,
                      avatar: Icon(m.icon, size: 16, color: m.color(context)),
                      onSelected: (_) => setState(() => mood = m),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(l.tagHint, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              if (tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final name in tags)
                        InputChip(
                          label: Text('#$name'),
                          visualDensity: VisualDensity.compact,
                          onDeleted: () => setState(() => tags.remove(name)),
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
                        tagController, tags, () => setState(() {})),
                  ),
                ),
                onSubmitted: (_) => _addTagsFromField(
                    tagController, tags, () => setState(() {})),
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
              _addTagsFromField(tagController, tags, () {});
              final text = controller.text.trim();
              if (text.isEmpty) return;
              var thoughtId = existing?.id;
              if (existing == null) {
                thoughtId = await appDb.insertThought(
                  content: text,
                  mood: mood,
                  day: AppDatabase.today(),
                );
              } else {
                await appDb.updateThought(existing.id, text, mood);
              }
              await appDb.setThoughtTags(thoughtId!, tags);
              saved = true;
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text(l.save),
          ),
        ],
      ),
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
  List<String> tags,
  VoidCallback onChanged,
) {
  final parts =
      controller.text.split(RegExp(r'[\s,，]+')).where((p) => p.trim().isNotEmpty);
  for (final part in parts) {
    final name = part.trim();
    if (!tags.contains(name)) tags.add(name);
  }
  controller.clear();
  onChanged();
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
