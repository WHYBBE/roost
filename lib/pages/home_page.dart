import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _query = '';
  Mood? _mood;

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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: MoodChips(
                      selected: _mood,
                      onSelected: (m) => setState(() => _mood = m),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ThoughtEntry>>(
                  stream: appDb.watchSearch(_query, mood: _mood),
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
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            for (final e in dayEntries)
                              EntryCard(
                                entry: e,
                                onTap: () => showEntryEditor(context, existing: e),
                                onLongPress: () => confirmDelete(context, e),
                              ),
                          ],
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
