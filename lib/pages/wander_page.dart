import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../l10n/app_localizations.dart';
import '../settings/app_settings.dart';
import '../ui/entry_widgets.dart';
import '../ui/tag_view.dart';
import '../ui/vault_switcher.dart';
import 'insights_page.dart';

class WanderPage extends StatefulWidget {
  const WanderPage({super.key});

  @override
  State<WanderPage> createState() => _WanderPageState();
}

class _WanderPageState extends State<WanderPage> {
  List<ThoughtEntry>? _onThisDay;
  List<ThoughtEntry>? _random;
  bool _showAllOnThisDay = false;
  bool _showAllWeek = false;
  bool _showAllMonth = false;

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
      body: StreamBuilder<List<ThoughtEntry>>(
        stream: appDb.watchAllEntries(),
        builder: (context, snap) {
          final all = snap.data ?? const <ThoughtEntry>[];
          return StreamBuilder<Map<int, List<TagWithCategory>>>(
            stream: appDb.watchAllThoughtTags(),
            builder: (context, tagSnap) {
              final tagMap =
                  tagSnap.data ?? const <int, List<TagWithCategory>>{};
              if (onThisDay == null || random == null) {
                return const Center(child: CircularProgressIndicator());
              }
              // 回顾周期：本周按设置的每周起始日；本月为自然月
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final firstWeekday =
                  AppSettings.instance.weekStart == WeekStart.monday
                      ? DateTime.monday
                      : DateTime.sunday;
              final weekStart = today.subtract(
                  Duration(days: (today.weekday - firstWeekday + 7) % 7));
              final weekEnd = weekStart.add(const Duration(days: 7));
              final monthStart = DateTime(now.year, now.month, 1);
              final monthEnd = DateTime(now.year, now.month + 1, 1);
              final weekFmt = DateFormat.MMMd(locale);

              final weekRecap = _recapSection(
                context,
                icon: Icons.calendar_view_week_outlined,
                title: l.thisWeekTitle,
                periodLabel:
                    '${weekFmt.format(weekStart)} – ${weekFmt.format(weekEnd.subtract(const Duration(days: 1)))}',
                entries: _inRange(all, weekStart, weekEnd),
                tagMap: tagMap,
                locale: locale,
                expanded: _showAllWeek,
                onToggle: () =>
                    setState(() => _showAllWeek = !_showAllWeek),
              );
              final monthRecap = _recapSection(
                context,
                icon: Icons.calendar_month_outlined,
                title: l.thisMonthTitle,
                periodLabel: DateFormat.yMMMM(locale).format(monthStart),
                entries: _inRange(all, monthStart, monthEnd),
                tagMap: tagMap,
                locale: locale,
                expanded: _showAllMonth,
                onToggle: () =>
                    setState(() => _showAllMonth = !_showAllMonth),
              );
              final onThisDayWidget =
                  _onThisDaySection(context, onThisDay, locale);
              final randomWidget = _randomSection(context, random, locale);

              return Center(
                child: SizedBox(
                  width: twoColumn ? 1000.0 : contentWidth,
                  child: twoColumn
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    weekRecap,
                                    const SizedBox(height: 24),
                                    monthRecap,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  children: [
                                    onThisDayWidget,
                                    const SizedBox(height: 24),
                                    randomWidget,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          children: [
                            weekRecap,
                            const SizedBox(height: 24),
                            monthRecap,
                            const SizedBox(height: 24),
                            onThisDayWidget,
                            const SizedBox(height: 24),
                            randomWidget,
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 周期内的活跃思绪（[start, end)），最近在前
  List<ThoughtEntry> _inRange(
      List<ThoughtEntry> all, DateTime start, DateTime end) {
    final startDay = AppDatabase.formatDay(start);
    final endDay = AppDatabase.formatDay(end);
    return all
        .where((e) => e.day.compareTo(startDay) >= 0 && e.day.compareTo(endDay) < 0)
        .toList(growable: false);
  }

  // ---------- 周/月回顾 ----------

  Widget _recapSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String periodLabel,
    required List<ThoughtEntry> entries,
    required Map<int, List<TagWithCategory>> tagMap,
    required String locale,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    // 小结统计：条数、字数、活跃天数、心情分布、普通标签
    final activeDays = <String>{};
    var words = 0;
    final byMood = <int, int>{};
    final moodById = <int, Tag>{};
    final tagCounts = <String, int>{};
    for (final e in entries) {
      activeDays.add(e.day);
      words += countWords(e.content);
      for (final t in tagMap[e.id] ?? const <TagWithCategory>[]) {
        if (t.isBuiltin) {
          byMood[t.tag.id] = (byMood[t.tag.id] ?? 0) + 1;
          moodById[t.tag.id] = t.tag;
        } else if (t.isNormal) {
          tagCounts[t.tag.name] = (tagCounts[t.tag.name] ?? 0) + 1;
        }
      }
    }
    final moodIds = byMood.keys.toList()
      ..sort((a, b) => byMood[b]!.compareTo(byMood[a]!));
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = expanded ? entries : entries.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                periodLabel,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Text(l.recapEmpty, style: Theme.of(context).textTheme.bodyMedium)
        else ...[
          Text(
            '${l.entriesCount(entries.length)} · '
            '${l.wordCount(words)} · '
            '${l.daysValue(activeDays.length)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (moodIds.isNotEmpty || topTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in moodIds.take(5))
                  _recapChip(context, '${moodById[id]!.name} ${byMood[id]}',
                      moodById[id]!.uiColor),
                for (final t in topTags.take(6))
                  _recapChip(context, '#${t.key} ${t.value}', null),
              ],
            ),
          ],
          const SizedBox(height: 8),
          for (final e in visible)
            EntryCard(
              entry: e,
              onTap: () => showEntryEditor(context, existing: e),
              onLongPress: () => showEntryActions(context, e),
            ),
          if (entries.length > visible.length)
            TextButton(
              onPressed: onToggle,
              child: Text(l.showAll),
            )
          else if (expanded && entries.length > 5)
            TextButton(
              onPressed: onToggle,
              child: Text(l.collapse),
            ),
        ],
      ],
    );
  }

  Widget _recapChip(BuildContext context, String label, Color? color) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
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
                onLongPress: () => showEntryActions(context, e),
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
                  onLongPress: () => showEntryActions(context, e),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
