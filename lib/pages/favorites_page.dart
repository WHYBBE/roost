import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';

/// 收藏视图：汇总所有星标思绪（仅活跃：未归档、未回收），按天分组
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.favoritesTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: StreamBuilder<List<ThoughtEntry>>(
            stream: appDb.watchStarredEntries(),
            builder: (context, snap) {
              final entries = snap.data ?? const <ThoughtEntry>[];
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (entries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l.emptyFavoritesHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              // 按天分组
              final groups = <String, List<ThoughtEntry>>{};
              for (final e in entries) {
                groups.putIfAbsent(e.day, () => []).add(e);
              }
              final days = groups.keys.toList();
              return StreamBuilder<Map<int, List<TagWithCategory>>>(
                stream: appDb.watchAllThoughtTags(),
                builder: (context, tagSnap) {
                  final tagMap =
                      tagSnap.data ?? const <int, List<TagWithCategory>>{};
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: days.length,
                    itemBuilder: (context, i) {
                      final day = days[i];
                      final dayEntries = groups[day]!;
                      final date = DateTime.parse(day);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: Text(
                              DateFormat.yMMMd(
                                      Localizations.localeOf(context).toString())
                                  .format(date),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                          for (final e in dayEntries)
                            EntryCard(
                              entry: e,
                              tags: tagMap[e.id],
                              onTap: () =>
                                  showEntryEditor(context, existing: e),
                              onLongPress: () => showEntryActions(context, e),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
