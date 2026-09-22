import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';

/// 归档与回收站：
/// - 归档 ≠ 删除，归档的思绪一直保留在归档标签页，可随时取消归档
/// - 回收站中的思绪保留 7 天，超期在启动时自动永久清除，也可手动清空
class ArchiveTrashPage extends StatelessWidget {
  const ArchiveTrashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.archiveTrashTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.archiveTab),
              Tab(text: l.trashTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ArchiveList(), _TrashList()],
        ),
      ),
    );
  }
}

/// 归档列表：取消归档 / 删除
class _ArchiveList extends StatelessWidget {
  const _ArchiveList();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StreamBuilder<List<ThoughtEntry>>(
      stream: appDb.watchArchivedEntries(),
      builder: (context, snap) {
        final entries = snap.data ?? const <ThoughtEntry>[];
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l.emptyArchiveHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                l.archiveHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final e in entries)
                    _EntryManagementCard(
                      entry: e,
                      subtitle: DateFormat.yMMMd(
                              Localizations.localeOf(context).toString())
                          .format(e.dayDate),
                      actions: [
                        _actionIcon(
                          context,
                          icon: Icons.unarchive_outlined,
                          tooltip: l.unarchive,
                          onPressed: () => appDb.unarchiveThought(e.id),
                        ),
                        _actionIcon(
                          context,
                          icon: Icons.delete_outline,
                          tooltip: l.moveToTrash,
                          onPressed: () => trashEntry(context, e),
                        ),
                      ],
                      onTap: () => showEntryEditor(context, existing: e),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 回收站列表：恢复 / 永久删除（顶部可清空）
class _TrashList extends StatelessWidget {
  const _TrashList();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    return StreamBuilder<List<ThoughtEntry>>(
      stream: appDb.watchTrashedEntries(),
      builder: (context, snap) {
        final entries = snap.data ?? const <ThoughtEntry>[];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.trashRetentionHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (entries.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _emptyTrash(context),
                      icon: Icon(Icons.delete_sweep_outlined,
                          size: 18, color: scheme.error),
                      label: Text(
                        l.emptyTrash,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Text(
                        l.emptyTrashHint,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final e in entries)
                          _EntryManagementCard(
                            entry: e,
                            subtitle: DateFormat.yMMMd(locale)
                                .format(e.dayDate),
                            actions: [
                              _actionIcon(
                                context,
                                icon: Icons.restore,
                                tooltip: l.restore,
                                onPressed: () => appDb.restoreThought(e.id),
                              ),
                              _actionIcon(
                                context,
                                icon: Icons.delete_forever,
                                tooltip: l.deleteForever,
                                onPressed: () => confirmDelete(context, e),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _emptyTrash(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.emptyTrash),
        content: Text(l.emptyTrashBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.emptyTrash),
          ),
        ],
      ),
    );
    if (ok == true) await appDb.emptyTrash();
  }
}

Widget _actionIcon(
  BuildContext context, {
  required IconData icon,
  required String tooltip,
  required VoidCallback onPressed,
}) {
  return IconButton(
    icon: Icon(icon, size: 20),
    tooltip: tooltip,
    onPressed: onPressed,
  );
}

/// 管理用的紧凑条目卡：内容截断 + 日期 + 动作按钮
class _EntryManagementCard extends StatelessWidget {
  const _EntryManagementCard({
    required this.entry,
    required this.subtitle,
    required this.actions,
    this.onTap,
  });

  final ThoughtEntry entry;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Text(
          entry.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
        onTap: onTap,
      ),
    );
  }
}
