import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';
import '../ui/heatmap.dart';
import '../ui/mood.dart';
import '../ui/vault_switcher.dart';
import 'holiday_plan_page.dart';
import 'special_days_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  String? _selectedDay;

  static const _topGutter = 20.0;
  static const _leftGutter = 20.0;

  /// 窄屏（手机竖屏）使用按月分页视图，宽屏使用 GitHub 年度热力图
  static const _narrowBreakpoint = 720.0;

  /// 当天生效的休/班：显式标记优先，周六日默认休
  DayFlag? _effectiveFlag(DateTime date, Map<String, DayFlag> flags) {
    final explicit = flags[AppDatabase.formatDay(date)];
    if (explicit != null) return explicit;
    return date.weekday >= DateTime.saturday ? DayFlag.rest : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final narrow = MediaQuery.sizeOf(context).width < _narrowBreakpoint;

    return Scaffold(
      appBar: AppBar(
        leading: appBarVaultSwitcher(context),
        title: Text(l.navCalendar),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: '$_year - 1',
            onPressed: () => setState(() {
              _year--;
              _selectedDay = null;
            }),
          ),
          Text('$_year', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: '$_year + 1',
            onPressed: () => setState(() {
              _year++;
              _selectedDay = null;
            }),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.event_note_outlined),
            tooltip: '${l.specialDaysTitle} / ${l.holidayPlanTitle}',
            onSelected: (key) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => key == 'events'
                    ? const SpecialDaysPage()
                    : const HolidayPlanPage(),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'events',
                child: Row(
                  children: [
                    Icon(Icons.celebration_outlined,
                        size: 20, color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 10),
                    Text(l.specialDaysTitle),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'plan',
                child: Row(
                  children: [
                    Icon(Icons.edit_calendar_outlined,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(l.holidayPlanTitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<ThoughtEntry>>(
        stream: appDb.watchAllEntries(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data ?? const <ThoughtEntry>[];
          return StreamBuilder<List<ThoughtEntry>>(
            stream: appDb.watchAnnualEvents(),
            builder: (context, evSnap) {
              // MM-DD → 特殊日子思绪
              final eventsByMd = <String, List<ThoughtEntry>>{};
              for (final e in evSnap.data ?? const <ThoughtEntry>[]) {
                eventsByMd.putIfAbsent(e.annualDate!, () => []).add(e);
              }
              return StreamBuilder<Map<String, DayFlag>>(
                stream: appDb.watchCalendarFlags(),
                builder: (context, flagSnap) {
                  final flags = flagSnap.data ?? const <String, DayFlag>{};
                  final counts = <String, int>{};
                  for (final e in entries) {
                    counts[e.day] = (counts[e.day] ?? 0) + 1;
                  }
                  final streak = _computeStreak(counts);
                  final longest = _longestStreakInYear(counts);
                  final yearCount = counts.keys
                      .where((d) => d.startsWith('$_year-'))
                      .fold(0, (sum, d) => sum + counts[d]!);
                  final selectedEntries = _selectedDay == null
                      ? null
                      : entries.where((e) => e.day == _selectedDay).toList();
                  final dayEvents = _selectedDay == null
                      ? const <ThoughtEntry>[]
                      : (eventsByMd[_selectedDay!.substring(5)] ??
                          const <ThoughtEntry>[]);

                  return Center(
                    child: SizedBox(
                      width: 900,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(l.yearTotal(_year, yearCount),
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text(l.streak(streak),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      )),
                              Text(l.longestStreak(longest),
                                  style: Theme.of(context).textTheme.bodySmall),
                              _legend(context, l),
                            ],
                          ),
                          const SizedBox(height: 12),
                          narrow
                              ? _monthCard(context, counts, eventsByMd, flags, locale)
                              : _heatmap(context, counts, eventsByMd, flags, locale),
                          const SizedBox(height: 24),
                          if (_selectedDay != null) ...[
                            Text(
                              DateFormat.yMMMMd(locale)
                                  .format(DateTime.parse(_selectedDay!)),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            // 当日特殊日子（每年循环），展示为特殊思绪
                            if (dayEvents.isNotEmpty) ...[
                              Text(
                                l.specialDaysTitle,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary),
                              ),
                              const SizedBox(height: 4),
                              for (final e in dayEvents)
                                Card(
                                  child: ListTile(
                                    leading: Icon(Icons.celebration_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary),
                                    title: Text(e.content),
                                    onTap: () => showEntryEditor(context, existing: e),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => confirmDelete(context, e),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                            ],
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
              );
            },
          );
        },
      ),
    );
  }

  Color _heatColor(BuildContext context, int level, bool isFuture) {
    final scheme = Theme.of(context).colorScheme;
    if (isFuture) {
      return scheme.surfaceContainerHighest.withValues(alpha: 0.3);
    }
    return switch (level) {
      0 => scheme.surfaceContainerHighest,
      1 => scheme.primary.withValues(alpha: 0.25),
      2 => scheme.primary.withValues(alpha: 0.45),
      3 => scheme.primary.withValues(alpha: 0.7),
      _ => scheme.primary,
    };
  }

  /// 窄屏：按月分页的月历视图（无横向滚动）
  Widget _monthCard(
    BuildContext context,
    Map<String, int> counts,
    Map<String, List<ThoughtEntry>> eventsByMd,
    Map<String, DayFlag> flags,
    String locale,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final narrowWeekdays = DateFormat.E(locale).dateSymbols.NARROWWEEKDAYS;
    final first = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 1).difference(first).inDays;
    final leading = first.weekday - 1;
    final today = AppDatabase.today();

    Widget dayCell(DateTime date) {
      final dayStr = AppDatabase.formatDay(date);
      final count = counts[dayStr] ?? 0;
      final level = heatLevel(count);
      final isSelected = _selectedDay == dayStr;
      final isToday = dayStr == today;
      final color = _heatColor(context, level, date.isAfter(DateTime.now()));
      final flag = _effectiveFlag(date, flags);
      final isExplicit = flags[dayStr] != null;
      final hasEvent = eventsByMd.containsKey(dayStr.substring(5));

      Border? border;
      if (isSelected) {
        border = Border.all(color: scheme.primary, width: 2);
      } else if (isToday) {
        border = Border.all(color: scheme.onSurface, width: 1.2);
      }

      final fg = !date.isAfter(DateTime.now()) && level >= 4
          ? scheme.onPrimary
          : scheme.onSurface;

      return Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Material(
              color: color,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(
                  () => _selectedDay = isSelected ? null : dayStr,
                ),
                child: Container(
                  alignment: Alignment.center,
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: border,
                  ),
                  child: Stack(
                    // 撑满整格：角标相对格子定位（否则 Stack 收缩为数字大小而重叠）
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Text(
                          '${date.day}',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: fg),
                        ),
                      ),
                      // 特殊日子：右下角小圆点
                      if (hasEvent)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.tertiary,
                            ),
                          ),
                        ),
                      // 休/班 角标：颜色与图例及热力图圆点一致
                      // （休=红，周末默认休为弱化红；班=主题色）
                      if (flag != null)
                        Positioned(
                          top: 2,
                          right: 3,
                          child: Text(
                            flag == DayFlag.work ? l.glyphWork : l.glyphRest,
                            style: TextStyle(
                              fontSize: 9,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: flag == DayFlag.work
                                  ? scheme.primary
                                  : isExplicit
                                      ? scheme.error
                                      : scheme.error.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget blank() => const Expanded(
          child: AspectRatio(aspectRatio: 1, child: SizedBox()),
        );

    final cells = <Widget>[
      for (var i = 0; i < leading; i++) blank(),
      for (var d = 0; d < daysInMonth; d++) dayCell(DateTime(_year, _month, 1 + d)),
    ];
    while (cells.length % 7 != 0) {
      cells.add(blank());
    }

    final rows = <Widget>[
      for (var i = 0; i < cells.length; i += 7)
        Row(children: cells.sublist(i, i + 7)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _month--;
                    if (_month < 1) {
                      _month = 12;
                      _year--;
                    }
                  }),
                ),
                Text(
                  DateFormat.yMMM(locale).format(first),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _month++;
                    if (_month > 12) {
                      _month = 1;
                      _year++;
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var wd = 1; wd <= 7; wd++)
                  Expanded(
                    child: Center(
                      child: Text(
                        narrowWeekdays[wd % 7],
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            ...rows,
          ],
        ),
      ),
    );
  }

  /// 构建周列：列 = 周，行 = 星期几（周一在上，与 GitHub 一致）
  List<List<DateTime?>> _buildWeeks() => buildWeeksForYear(_year);

  /// 宽屏：GitHub 年度热力图。格子尺寸按视口宽度自适应缩放，
  /// 保证整年（含 12 月）完整显示、无需滚动。
  Widget _heatmap(BuildContext context, Map<String, int> counts,
      Map<String, List<ThoughtEntry>> eventsByMd, Map<String, DayFlag> flags,
      String locale) {
    final now = DateTime.now();
    final today = AppDatabase.today();
    final weeks = _buildWeeks();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, cons) {
          const minCell = 8.0, maxCell = 18.0, gap = 2.0;
          final avail = cons.maxWidth - 24 - _leftGutter - 4;
          final fitted = (avail - (weeks.length - 1) * gap) / weeks.length;
          final fits = fitted >= minCell;
          final cell = fitted.clamp(minCell, maxCell);
          final pitch = cell + gap;
          final contentWidth = _leftGutter + weeks.length * pitch + 4;

          final stack = SizedBox(
            width: fits ? cons.maxWidth - 24 : contentWidth,
            height: _topGutter + 7 * pitch,
            child: Stack(
              children: [
                // 月份标签
                for (var m = 1; m <= 12; m++)
                  ..._monthLabel(context, weeks, m, locale, cell, gap),
                // 星期标签（一 / 三 / 五）
                for (final row in [1, 3, 5])
                  Positioned(
                    left: 0,
                    top: _topGutter + row * pitch,
                    child: SizedBox(
                      width: _leftGutter - 4,
                      height: cell,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _narrowWeekday(locale, row + 1),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontSize: 9,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                  ),
                // 日期格子
                for (var w = 0; w < weeks.length; w++)
                  for (final date in weeks[w])
                    if (date != null)
                      _cell(
                        context,
                        date: date,
                        count: counts[AppDatabase.formatDay(date)] ?? 0,
                        isFuture: date.isAfter(now),
                        isToday: AppDatabase.formatDay(date) == today,
                        // 仅显式标记（法定假日/调休补班）；周末默认休不上点，
                        // 靠列位置已可辨识
                        flag: flags[AppDatabase.formatDay(date)],
                        hasEvent: eventsByMd
                            .containsKey(AppDatabase.formatDay(date).substring(5)),
                        locale: locale,
                        cellSize: cell,
                        left: _leftGutter + w * pitch,
                        top: _topGutter + (date.weekday - 1) * pitch,
                      ),
              ],
            ),
          );

          return Padding(
            padding: const EdgeInsets.all(12),
            child: fits ? stack : SingleChildScrollView(scrollDirection: Axis.horizontal, child: stack),
          );
        },
      ),
    );
  }

  String _narrowWeekday(String locale, int weekday) {
    // weekday: 1=周一 … 7=周日；NARROWWEEKDAYS[0] 为周日
    final symbols = DateFormat.E(locale).dateSymbols;
    return symbols.NARROWWEEKDAYS[weekday % 7];
  }

  List<Widget> _monthLabel(BuildContext context, List<List<DateTime?>> weeks,
      int month, String locale, double cellSize, double gap) {
    // 找到包含该月 1 号的周列
    final first = DateTime(_year, month, 1);
    for (var w = 0; w < weeks.length; w++) {
      if (weeks[w].contains(first)) {
        return [
          Positioned(
            left: _leftGutter + w * (cellSize + gap),
            top: 2,
            child: Text(
              DateFormat.MMM(locale).format(first),
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
    required bool isToday,
    required DayFlag? flag,
    required bool hasEvent,
    required String locale,
    required double cellSize,
    required double left,
    required double top,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final dayStr = AppDatabase.formatDay(date);
    final isSelected = _selectedDay == dayStr;
    final level = heatLevel(count);
    final color = _heatColor(context, level, isFuture);
    // 小点颜色：班 > 显式休 > 特殊日子
    final Color? dotColor = flag == DayFlag.work
        ? scheme.primary
        : flag == DayFlag.rest
            ? scheme.error
            : hasEvent
                ? scheme.tertiary
                : null;
    final flagLabel = flag == null
        ? (hasEvent ? ' · ${l.specialDaysTitle}' : '')
        : flag == DayFlag.work
            ? ' · ${l.workLabel}'
            : ' · ${l.restLabel}';

    Border? border;
    if (isSelected) {
      border = Border.all(color: scheme.primary, width: 2);
    } else if (isToday) {
      border = Border.all(color: scheme.onSurface, width: 1.2);
    }

    return Positioned(
      left: left,
      top: top,
      child: Tooltip(
        message:
            '${DateFormat.yMd(locale).format(date)} · ${l.entriesCount(count)}$flagLabel',
        child: InkWell(
          borderRadius: BorderRadius.circular(3),
          onTap: () => setState(
            () => _selectedDay = isSelected ? null : dayStr,
          ),
          child: Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: border,
            ),
            // 带颜色小点：休（红）/ 班（主题色）/ 特殊日子（tertiary）；
            // 描边保证与热力底色同色系时仍可辨识
            child: dotColor == null
                ? null
                : Center(
                    child: Container(
                      width: cellSize * 0.42,
                      height: cellSize * 0.42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        border: Border.all(color: scheme.surface, width: 1),
                      ),
                    ),
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
        const SizedBox(width: 12),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.error,
            border: Border.all(color: scheme.surface, width: 1),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          l.restLabel,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.error),
        ),
        const SizedBox(width: 8),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary,
            border: Border.all(color: scheme.surface, width: 1),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          l.workLabel,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.primary),
        ),
      ],
    );
  }

  int _computeStreak(Map<String, int> counts) {
    var streak = 0;
    var d = DateTime.now();
    // 今天没写不影响连击
    if (counts[AppDatabase.formatDay(d)] == null) {
      d = d.subtract(const Duration(days: 1));
    }
    while (counts[AppDatabase.formatDay(d)] != null) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _longestStreakInYear(Map<String, int> counts) {
    final days = counts.keys.where((d) => d.startsWith('$_year-')).toList()
      ..sort();
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
}
