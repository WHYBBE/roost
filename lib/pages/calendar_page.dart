import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';
import '../ui/mood.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _year = DateTime.now().year;
  String? _selectedDay;

  static const _cellSize = 14.0;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navCalendar),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _year--),
          ),
          Text('$_year', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _year++),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<ThoughtEntry>>(
        stream: appDb.watchAllEntries(),
        builder: (context, snap) {
          final entries = snap.data ?? const <ThoughtEntry>[];
          final counts = <String, int>{};
          for (final e in entries) {
            counts[e.day] = (counts[e.day] ?? 0) + 1;
          }
          final streak = _computeStreak(counts);
          final selectedEntries =
              _selectedDay == null ? null : entries.where((e) => e.day == _selectedDay).toList();

          return Center(
            child: SizedBox(
              width: 900,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Text(l.streak(streak),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: 16),
                      Text(l.totalEntries(counts.values.fold(0, (a, b) => a + b)),
                          style: Theme.of(context).textTheme.bodySmall),
                      const Spacer(),
                      _legend(context, l),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _heatmap(context, counts, locale),
                  const SizedBox(height: 24),
                  if (_selectedDay != null) ...[
                    Text(
                      DateFormat.yMMMMd(locale)
                          .format(DateTime.parse(_selectedDay!)),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (selectedEntries!.isEmpty)
                      Text(l.emptyDay)
                    else
                      ...selectedEntries.map(
                        (e) => EntryCard(
                          entry: e,
                          onTap: () => showEntryEditor(context, existing: e),
                          onLongPress: () => confirmDelete(context, e),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heatmap(BuildContext context, Map<String, int> counts, String locale) {
    final now = DateTime.now();
    final jan1 = DateTime(_year, 1, 1);
    final daysInYear =
        DateTime(_year + 1, 1, 1).difference(jan1).inDays;

    // 列 = 周，行 = 星期几（周一在上，与 GitHub 一致）
    final weeks = <List<DateTime?>>[];
    final leadingBlanks = (jan1.weekday - 1);
    if (leadingBlanks > 0) {
      weeks.add(List<DateTime?>.filled(leadingBlanks, null));
    }
    var week = weeks.removeLast();
    for (var i = 0; i < daysInYear; i++) {
      final d = DateTime(_year, 1, 1 + i);
      if (d.weekday == 1 && week.isNotEmpty) {
        weeks.add(week);
        week = <DateTime?>[];
      }
      week.add(d);
    }
    if (week.isNotEmpty) weeks.add(week);

    final futureDates = weeks
        .expand((w) => w)
        .whereType<DateTime>()
        .where((d) => d.isAfter(now))
        .toSet();

    return SizedBox(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: weeks.length * (_cellSize + _gap) + 24,
          height: 7 * (_cellSize + _gap) + 20,
          child: Stack(
            children: [
              for (var w = 0; w < weeks.length; w++)
                for (var d = 0; d < weeks[w].length; d++)
                  if (weeks[w][d] != null)
                    _cell(
                      context,
                      date: weeks[w][d]!,
                      count: counts[AppDatabase.formatDay(weeks[w][d]!)] ?? 0,
                      isFuture: futureDates.contains(weeks[w][d]),
                      locale: locale,
                      left: w * (_cellSize + _gap) + 20,
                      top: (weeks[w][d]!.weekday - 1) * (_cellSize + _gap),
                    ),
              for (var m = 0; m < 12; m++)
                ..._monthLabels(context, weeks, m),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _monthLabels(BuildContext context, List<List<DateTime?>> weeks, int month) {
    for (var w = 0; w < weeks.length; w++) {
      final days = weeks[w].whereType<DateTime>().toList();
      if (days.isNotEmpty && days.first.month == month) {
        final label = DateFormat.M().format(DateTime(_year, month, 1));
        return [
          Positioned(
            left: w * (_cellSize + _gap) + 20,
            top: 0,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ];
      }
    }
    return [];
  }

  Widget _cell(
    BuildContext context, {
    required DateTime date,
    required int count,
    required bool isFuture,
    required String locale,
    required double left,
    required double top,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final level = heatLevel(count);
    Color color;
    if (isFuture) {
      color = scheme.surfaceContainerHighest.withValues(alpha: 0.3);
    } else {
      color = switch (level) {
        0 => scheme.surfaceContainerHighest,
        1 => scheme.primary.withValues(alpha: 0.25),
        2 => scheme.primary.withValues(alpha: 0.45),
        3 => scheme.primary.withValues(alpha: 0.7),
        _ => scheme.primary,
      };
    }
    final isToday = AppDatabase.formatDay(date) == AppDatabase.today();

    return Positioned(
      left: left,
      top: top + 16,
      child: Tooltip(
        message:
            '${DateFormat.yMd(locale).format(date)} · ${l.entriesCount(count)}',
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: () => setState(() => _selectedDay = AppDatabase.formatDay(date)),
          child: Container(
            width: _cellSize,
            height: _cellSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: isToday
                  ? Border.all(color: scheme.onSurface, width: 1.2)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, AppLocalizations l) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.less, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 4),
        for (final level in [0, 1, 2, 3, 4])
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: switch (level) {
                0 => scheme.surfaceContainerHighest,
                1 => scheme.primary.withValues(alpha: 0.25),
                2 => scheme.primary.withValues(alpha: 0.45),
                3 => scheme.primary.withValues(alpha: 0.7),
                _ => scheme.primary,
              },
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        const SizedBox(width: 4),
        Text(l.more, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  int _computeStreak(Map<String, int> counts) {
    var streak = 0;
    var d = DateTime.now();
    // 今天没写不影响连击
    if (counts[AppDatabase.formatDay(d)] == null) d = d.subtract(const Duration(days: 1));
    while (counts[AppDatabase.formatDay(d)] != null) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
