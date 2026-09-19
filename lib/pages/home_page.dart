import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';
import '../ui/tag_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _query = '';
  String? _filterTag;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final contentWidth = width > 1200
        ? 720.0
        : width > 720
            ? 560.0
            : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navHome),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l.newThought,
            onPressed: () => showEntryEditor(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showEntryEditor(context),
        tooltip: l.newThought,
        child: const Icon(Icons.edit_outlined),
      ),
      body: Center(
        child: SizedBox(
          width: contentWidth,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SearchBar(
                  hintText: l.searchHint,
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              // 筛选行：选中的标签 + 心情标签（已被标记过的）
              StreamBuilder<List<TagWithCount>>(
                stream: appDb.watchTagsWithCount(),
                builder: (context, tagSnap) {
                  final tags = tagSnap.data ?? const <TagWithCount>[];
                  final moodTags = tags
                      .where((t) =>
                          t.tag.tagKind == TagKind.mood && t.count > 0)
                      .toList();
                  if (tags.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (_filterTag != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text('#$_filterTag'),
                                  selected: true,
                                  onSelected: (_) =>
                                      setState(() => _filterTag = null),
                                ),
                              ),
                            for (final item in moodTags)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(item.tag.name),
                                  selected: _filterTag == item.tag.name,
                                  avatar: Icon(
                                    item.tag.iconData ?? Icons.mood,
                                    size: 16,
                                    color: item.tag.uiColor,
                                  ),
                                  onSelected: (sel) => setState(() =>
                                      _filterTag =
                                          sel ? item.tag.name : null),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Expanded(
                child: StreamBuilder<List<ThoughtEntry>>(
                  stream: appDb.watchSearch(_query, tagName: _filterTag),
                  builder: (context, snap) {
                    final entries = snap.data ?? const <ThoughtEntry>[];
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (entries.isEmpty) {
                      return Center(
                        child: Text(
                          l.emptyThoughts,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    // 按天分组
                    final groups = <String, List<ThoughtEntry>>{};
                    for (final e in entries) {
                      groups.putIfAbsent(e.day, () => []).add(e);
                    }
                    final days = groups.keys.toList();
                    return StreamBuilder<Map<int, List<Tag>>>(
                      stream: appDb.watchAllThoughtTags(),
                      builder: (context, tagSnap) {
                        final tagMap = tagSnap.data ?? const <int, List<Tag>>{};
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
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
                                  child: Row(
                                    children: [
                                      Text(
                                        DateFormat.yMMMd(
                                                Localizations.localeOf(context)
                                                    .toString())
                                            .format(date),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l.entriesCount(dayEntries.length),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                for (final e in dayEntries)
                                  EntryCard(
                                    entry: e,
                                    tags: tagMap[e.id],
                                    onTap: () =>
                                        showEntryEditor(context, existing: e),
                                    onLongPress: () =>
                                        confirmDelete(context, e),
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
            ],
          ),
        ),
      ),
    );
  }
}
