import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';
import '../ui/tag_view.dart';
import '../ui/vault_switcher.dart';

/// 字数统计：CJK 逐字计数，拉丁/数字按词计数（跳过空白与标点）
int countWords(String text) {
  var count = 0;
  var inWord = false;
  for (final r in text.runes) {
    final isCjk = (r >= 0x2E80 && r <= 0x9FFF) ||
        (r >= 0x3040 && r <= 0x30FF) ||
        (r >= 0xAC00 && r <= 0xD7AF) ||
        (r >= 0xF900 && r <= 0xFAFF) ||
        (r >= 0x20000 && r <= 0x2FA1F);
    if (isCjk) {
      count++;
      inWord = false;
    } else if (_isWordChar(r)) {
      if (!inWord) {
        count++;
        inWord = true;
      }
    } else {
      inWord = false;
    }
  }
  return count;
}

bool _isWordChar(int r) =>
    (r >= 0x30 && r <= 0x39) || // 0-9
    (r >= 0x41 && r <= 0x5A) || // A-Z
    (r >= 0x61 && r <= 0x7A) || // a-z
    (r >= 0xC0 && r <= 0x24F); // 拉丁扩展字母

/// 独立洞察页（PC 端作为导航 tab；手机端从日历页点击进入）
class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key, this.initialYear});

  final int? initialYear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        // 作为 tab 时展示保险库切换；路由推入（手机）时保留返回键
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? null
            : appBarVaultSwitcher(context),
        title: Text(l.insightsTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: InsightsView(initialYear: initialYear),
          ),
        ),
      ),
    );
  }
}

/// 洞察内容：概览 / 月度趋势 / 心情 / 标签 / 写作时段 / 日历
class InsightsView extends StatefulWidget {
  const InsightsView({super.key, this.initialYear});

  /// 初始年份（如从日历页进入时带上当前浏览年）
  final int? initialYear;

  @override
  State<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<InsightsView> {
  late int _year = widget.initialYear ?? DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ThoughtEntry>>(
      stream: appDb.watchAllEntries(),
      builder: (context, snap) {
        final entries = snap.data ?? const <ThoughtEntry>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _yearSwitcher(context),
            _overview(context, entries),
            const SizedBox(height: 20),
            _monthlyTrend(context, entries),
            const SizedBox(height: 20),
            _moodSection(context, entries),
            const SizedBox(height: 20),
            _tagsSection(context),
            const SizedBox(height: 20),
            _writingTime(context, entries),
            const SizedBox(height: 20),
            _calendarSection(context, entries),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ---------- 年份切换（仅独立页） ----------

  Widget _yearSwitcher(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _year--),
          ),
          Text('$_year',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: scheme.primary)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _year++),
          ),
        ],
      ),
    );
  }

  // ---------- 概览 ----------

  Widget _overview(BuildContext context, List<ThoughtEntry> entries) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final countsByDay = <String, int>{};
    var words = 0;
    for (final e in entries) {
      countsByDay[e.day] = (countsByDay[e.day] ?? 0) + 1;
      words += countWords(e.content);
    }
    final streak = _currentStreak(countsByDay);
    final longest = _longestStreak(countsByDay);
    final nf = NumberFormat.decimalPattern(locale);
    return _section(
      context,
      l.insightsOverview,
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _statTile(context, l.totalThoughts, nf.format(entries.length),
              Icons.article_outlined),
          _statTile(context, l.totalWords, nf.format(words),
              Icons.text_fields_outlined),
          _statTile(context, l.activeDays, nf.format(countsByDay.length),
              Icons.event_available_outlined),
          _statTile(context, l.currentStreak, l.daysValue(streak),
              Icons.local_fire_department_outlined),
          _statTile(context, l.longestStreakLabel, l.daysValue(longest),
              Icons.emoji_events_outlined),
        ],
      ),
    );
  }

  int _currentStreak(Map<String, int> counts) {
    var streak = 0;
    var d = DateTime.now();
    if (counts[AppDatabase.formatDay(d)] == null) {
      d = d.subtract(const Duration(days: 1));
    }
    while (counts[AppDatabase.formatDay(d)] != null) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _longestStreak(Map<String, int> counts) {
    final days = counts.keys.toList()..sort();
    var best = 0;
    var cur = 0;
    DateTime? prev;
    for (final d in days) {
      final date = DateTime.parse(d);
      cur = (prev != null && date.difference(prev).inDays == 1) ? cur + 1 : 1;
      best = max(best, cur);
      prev = date;
    }
    return best;
  }

  // ---------- 月度趋势 ----------

  Widget _monthlyTrend(BuildContext context, List<ThoughtEntry> entries) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final counts = List<int>.filled(12, 0);
    final words = List<int>.filled(12, 0);
    for (final e in entries) {
      if (e.year != _year) continue;
      final m = int.parse(e.day.substring(5, 7)) - 1;
      counts[m]++;
      words[m] += countWords(e.content);
    }
    final maxCount = max(1, counts.fold(0, max));
    final maxWords = max(1, words.fold(0, max));
    final hasData = counts.any((c) => c > 0);
    final monthFmt = DateFormat.MMM(Localizations.localeOf(context).toString());

    return _section(
      context,
      l.insightsMonthly,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图例
          Row(
            children: [
              _legendDot(scheme.primary, l.seriesThoughts, context),
              const SizedBox(width: 16),
              _legendDot(scheme.tertiary, l.seriesWords, context),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasData)
            _empty(context)
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var m = 0; m < 12; m++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _bar(scheme.primary,
                                    counts[m] / maxCount, 6),
                                const SizedBox(width: 2),
                                _bar(scheme.tertiary,
                                    words[m] / maxWords, 6),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            monthFmt.format(DateTime(_year, m + 1)),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(Color color, double fraction, double width) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: width,
        height: (fraction.clamp(0.0, 1.0)) * 96,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ---------- 心情 ----------

  Widget _moodSection(BuildContext context, List<ThoughtEntry> entries) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final yearEntries =
        entries.where((e) => e.year == _year).toList(growable: false);
    return StreamBuilder<Map<int, List<Tag>>>(
      stream: appDb.watchAllThoughtTags(),
      builder: (context, snap) {
        final tagMap = snap.data ?? const <int, List<Tag>>{};
        // 心情分布与月度堆叠
        final byMood = <int, int>{};
        final moodById = <int, Tag>{};
        final byMonthMood = List.generate(12, (_) => <int, int>{});
        for (final e in yearEntries) {
          final mood = (tagMap[e.id] ?? const <Tag>[])
              .where((t) => t.tagKind == TagKind.mood)
              .firstOrNull;
          if (mood == null) continue;
          byMood[mood.id] = (byMood[mood.id] ?? 0) + 1;
          moodById[mood.id] = mood;
          final m = int.parse(e.day.substring(5, 7)) - 1;
          byMonthMood[m][mood.id] = (byMonthMood[m][mood.id] ?? 0) + 1;
        }
        if (byMood.isEmpty) {
          return _section(context, l.insightsMood, _empty(context));
        }
        final moodIds = byMood.keys.toList()
          ..sort((a, b) => byMood[b]!.compareTo(byMood[a]!));
        final topMoods = moodIds.take(4).toList();
        final maxMood = byMood[moodIds.first]!;
        final maxMonthTotal = max(
          1,
          byMonthMood
              .map((m) => m.values.fold<int>(0, (a, b) => a + b))
              .fold<int>(0, (a, b) => a > b ? a : b),
        ).toDouble();
        Color moodColor(Tag t) => t.uiColor ?? scheme.primary;

        return _section(
          context,
          l.insightsMood,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.moodDistribution,
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              for (final id in moodIds)
                _hBar(
                  context,
                  color: moodColor(moodById[id]!),
                  fraction: byMood[id]! / maxMood,
                  label: moodById[id]!.name,
                  trailing: '${byMood[id]}',
                ),
              const SizedBox(height: 12),
              // 月度堆叠（Top 心情）
              SizedBox(
                height: 90,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var m = 0; m < 12; m++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _stackedMonth(
                                byMonthMood[m],
                                topMoods,
                                moodById,
                                moodColor,
                                maxMonthTotal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${m + 1}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 单月心情堆叠柱（自底向上按 Top 心情排列，高度按全年最大月份归一化）
  Widget _stackedMonth(
    Map<int, int> monthMoods,
    List<int> topMoods,
    Map<int, Tag> moodById,
    Color Function(Tag) colorOf,
    double maxMonthTotal,
  ) {
    final total = monthMoods.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final segments = <Widget>[];
    for (final id in topMoods) {
      final v = monthMoods[id] ?? 0;
      if (v == 0) continue;
      segments.add(Expanded(
        flex: v,
        child: Container(color: colorOf(moodById[id]!)),
      ));
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 10,
        height: 70.0 * (total / maxMonthTotal),
        child: Column(children: segments),
      ),
    );
  }

  // ---------- 标签 Top ----------

  Widget _tagsSection(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<TagWithCount>>(
      stream: appDb.watchTagsWithCount(),
      builder: (context, snap) {
        final tags = (snap.data ?? const <TagWithCount>[])
            .where((t) => t.tag.tagKind == TagKind.normal && t.count > 0)
            .take(10)
            .toList();
        if (tags.isEmpty) {
          return _section(context, l.insightsTags, _empty(context));
        }
        final maxCount = tags.first.count;
        return _section(
          context,
          l.insightsTags,
          Column(
            children: [
              for (final t in tags)
                _hBar(
                  context,
                  color: t.tag.uiColor ?? scheme.primary,
                  fraction: t.count / maxCount,
                  label: '#${t.tag.name}',
                  trailing: '${t.count}',
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------- 写作时段 ----------

  Widget _writingTime(BuildContext context, List<ThoughtEntry> entries) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final byHour = List<int>.filled(24, 0);
    final byWeekday = List<int>.filled(7, 0); // 0=周一 … 6=周日
    for (final e in entries) {
      final time = e.createdAtLocal;
      byHour[time.hour]++;
      byWeekday[time.weekday - 1]++;
    }
    final locale = Localizations.localeOf(context).toString();
    final narrow = DateFormat.E(locale).dateSymbols.NARROWWEEKDAYS;
    final maxHour = max(1, byHour.fold(0, max));
    final maxWeekday = max(1, byWeekday.fold(0, max));

    Widget miniChart(List<int> values, int maxValue,
        List<String> labels, Color color) {
      return SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 6,
                          height: max(2, (values[i] / maxValue) * 64),
                          decoration: BoxDecoration(
                            color: values[i] == 0
                                ? scheme.surfaceContainerHighest
                                : color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      labels[i],
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    final hourLabels = [
      for (var h = 0; h < 24; h++) h % 6 == 0 ? '$h' : '',
    ];
    // 周一起始：[1..6,0] 映射 NARROWWEEKDAYS（0=周日）
    final weekdayLabels = [
      for (var w = 1; w <= 7; w++) narrow[w % 7],
    ];

    return _section(
      context,
      l.insightsWritingTime,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          miniChart(byHour, maxHour, hourLabels, scheme.primary),
          const SizedBox(height: 12),
          miniChart(byWeekday, maxWeekday, weekdayLabels, scheme.secondary),
        ],
      ),
    );
  }

  // ---------- 日历洞察 ----------

  Widget _calendarSection(BuildContext context, List<ThoughtEntry> entries) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<CalendarEvent>>(
      stream: appDb.watchEvents(),
      builder: (context, evSnap) {
        final events = evSnap.data ?? const <CalendarEvent>[];
        return StreamBuilder<List<EventType>>(
          stream: appDb.watchEventTypes(),
          builder: (context, typeSnap) {
            final types = typeSnap.data ?? const <EventType>[];
            final typeById = {for (final t in types) t.id: t};
            // 计数器累计（总量 + 天数）
            final counterTotals = <int, (int days, int total)>{};
            // 普通类型事件数分布
            final byType = <int, int>{};
            for (final e in events) {
              final t = typeById[e.typeId];
              if (t == null) continue;
              if (t.counter) {
                final cur = counterTotals[t.id] ?? (0, 0);
                counterTotals[t.id] = (cur.$1 + 1, cur.$2 + e.count);
              } else {
                byType[t.id] = (byType[t.id] ?? 0) + 1;
              }
            }
            final specialDays =
                entries.where((e) => e.annualDate != null).length;
            final typeIds = byType.keys.toList()
              ..sort((a, b) => byType[b]!.compareTo(byType[a]!));
            final maxType = typeIds.isEmpty ? 1 : byType[typeIds.first]!;

            return _section(
              context,
              l.insightsCalendar,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statTile(context, l.eventTotal, '${events.length}',
                          Icons.event_outlined),
                      _statTile(context, l.specialDaysTitle, '$specialDays',
                          Icons.celebration_outlined),
                    ],
                  ),
                  if (counterTotals.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(l.counterLabel,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    for (final entry in counterTotals.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(typeById[entry.key]?.name ?? '')),
                            Text(
                              '${l.totalCount(entry.value.$2)} · '
                              '${l.daysValue(entry.value.$1)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (typeIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(l.eventTypeDistribution,
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    for (final id in typeIds)
                      _hBar(
                        context,
                        color: Color(typeById[id]!.color),
                        fraction: byType[id]! / maxType,
                        label: typeById[id]!.name,
                        trailing: '${byType[id]}',
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------- 通用小部件 ----------

  Widget _section(BuildContext context, String title, Widget child) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _statTile(
      BuildContext context, String label, String value, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 130,
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _hBar(
    BuildContext context, {
    required Color color,
    required double fraction,
    required String label,
    required String trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 10,
                color: scheme.surfaceContainerHighest,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(color: color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              trailing,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          AppLocalizations.of(context)!.insightsEmpty,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
}
