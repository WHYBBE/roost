import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';

/// 标签页：标签列表 + 使用数量，支持重命名 / 删除 / 查看标签下的思绪
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
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        Icons.sell_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text('#${item.tag.name}'),
                      subtitle: Text(l.entriesCount(item.count)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TagDetailPage(tagWithCount: item),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'rename') {
                            _renameDialog(context, item);
                          } else if (action == 'delete') {
                            _deleteDialog(context, item);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(l.renameTag),
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

  Future<void> _renameDialog(BuildContext context, TagWithCount item) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: item.tag.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.renameTag),
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
    if (newName != null && context.mounted) {
      await appDb.renameTag(item.tag.id, newName);
    }
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

/// 某个标签下的全部思绪
class TagDetailPage extends StatelessWidget {
  const TagDetailPage({super.key, required this.tagWithCount});

  final TagWithCount tagWithCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(title: Text('#${tagWithCount.tag.name}')),
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
