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
  const EntryCard({super.key, required this.entry, this.onTap, this.onLongPress});

  final ThoughtEntry entry;
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
            ],
          ),
        ),
      ),
    );
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

  await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? l.newThought : l.editThought),
        content: Column(
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              if (existing == null) {
                await appDb.insertThought(
                  content: text,
                  mood: mood,
                  day: AppDatabase.today(),
                );
              } else {
                await appDb.updateThought(existing.id, text, mood);
              }
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
  if (saved && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.saved)));
  }
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
