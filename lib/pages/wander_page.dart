import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';
import '../ui/vault_switcher.dart';

class WanderPage extends StatefulWidget {
  const WanderPage({super.key});

  @override
  State<WanderPage> createState() => _WanderPageState();
}

class _WanderPageState extends State<WanderPage> {
  List<ThoughtEntry>? _onThisDay;
  List<ThoughtEntry>? _random;
  bool _showAllOnThisDay = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final results = await Future.wait([
      appDb.onThisDay(month: now.month, day: now.day),
      appDb.randomThoughts(limit: 5),
    ]);
    if (!mounted) return;
    setState(() {
      _onThisDay = results[0];
      _random = results[1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final width = MediaQuery.sizeOf(context).width;
    final twoColumn = width >= 900;
    final contentWidth = width > 1200 ? 720.0 : double.infinity;

    final onThisDay = _onThisDay;
    final random = _random;

    return Scaffold(
      appBar: AppBar(
        leading: appBarVaultSwitcher(context),
        title: Text(l.wanderTitle),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() => _random = null);
          final list = await appDb.randomThoughts(limit: 5);
          if (mounted) setState(() => _random = list);
        },
        tooltip: l.shuffle,
        child: const Icon(Icons.shuffle),
      ),
      body: onThisDay == null || random == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SizedBox(
                width: twoColumn ? 1000.0 : contentWidth,
                child: twoColumn
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _onThisDaySection(context, onThisDay, locale),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _randomSection(context, random, locale),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        children: [
                          _onThisDaySection(context, onThisDay, locale),
                          const SizedBox(height: 24),
                          _randomSection(context, random, locale),
                        ],
                      ),
              ),
            ),
    );
  }

  Widget _onThisDaySection(
      BuildContext context, List<ThoughtEntry> entries, String locale) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    // 按年份分组（最近的年份在前）
    final byYear = <int, List<ThoughtEntry>>{};
    for (final e in entries) {
      byYear.putIfAbsent(e.year, () => []).add(e);
    }
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
    final visibleYears = _showAllOnThisDay ? years : years.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              l.onThisDayHeader,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat.MMMd(locale).format(now),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (years.isEmpty)
          Text(l.noMemories, style: Theme.of(context).textTheme.bodyMedium)
        else
          for (final year in visibleYears) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                l.onThisDay(now.year - year),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...byYear[year]!.map(
              (e) => EntryCard(
                entry: e,
                onTap: () => showEntryEditor(context, existing: e),
                onLongPress: () => confirmDelete(context, e),
              ),
            ),
          ],
        if (years.length > visibleYears.length)
          TextButton(
            onPressed: () => setState(() => _showAllOnThisDay = true),
            child: Text(l.showAll),
          ),
      ],
    );
  }

  Widget _randomSection(
      BuildContext context, List<ThoughtEntry> entries, String locale) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.explore, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(l.randomHeader, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Text(l.noMemories, style: Theme.of(context).textTheme.bodyMedium)
        else
          ...entries.map(
            (e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMd(locale).format(e.dayDate),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                EntryCard(
                  entry: e,
                  onTap: () => showEntryEditor(context, existing: e),
                  onLongPress: () => confirmDelete(context, e),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
