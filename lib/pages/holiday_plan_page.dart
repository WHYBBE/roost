import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import '../settings/app_settings.dart';

/// 国家放假安排管理：周六日默认休息，法定假日（休）与调休补班（班）手动录入。
/// 12 个月份卡片，点按任意日期弹出设置面板。
class HolidayPlanPage extends StatefulWidget {
  const HolidayPlanPage({super.key});

  @override
  State<HolidayPlanPage> createState() => _HolidayPlanPageState();
}

class _HolidayPlanPageState extends State<HolidayPlanPage> {
  int _year = DateTime.now().year;
  static const _cardWidth = 272.0;

  bool _isWeekend(DateTime d) => d.weekday >= DateTime.saturday;

  Future<void> _editDay(
      BuildContext context, DateTime date, Map<String, DayFlag> flags) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dayStr = AppDatabase.formatDay(date);
    final weekend = _isWeekend(date);
    final current = flags[dayStr] ?? (weekend ? DayFlag.rest : null);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child:
                  Text(DateFormat.yMMMMd(locale).format(date),
                      style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: Text(l.restLabel),
              trailing:
                  current == DayFlag.rest ? const Icon(Icons.check) : null,
              onTap: () {
                appDb.setCalendarFlag(dayStr, DayFlag.rest);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: Text(l.workLabel),
              trailing:
                  current == DayFlag.work ? const Icon(Icons.check) : null,
              onTap: () {
                appDb.setCalendarFlag(dayStr, DayFlag.work);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: Text(l.clearFlag),
              subtitle: weekend ? Text(l.defaultRestLabel) : null,
              onTap: () {
                appDb.setCalendarFlag(dayStr, null);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _monthCard(BuildContext context, int month,
      Map<String, DayFlag> flags, AppLocalizations l, String locale) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final narrowWeekdays = DateFormat.E(locale).dateSymbols.NARROWWEEKDAYS;
    // 每周起始日与日历页一致（设置可调，默认周日）
    final firstWeekday =
        AppSettings.instance.weekStart == WeekStart.monday
            ? DateTime.monday
            : DateTime.sunday;
    int rowIndex(int weekday) => (weekday - firstWeekday + 7) % 7;
    final first = DateTime(_year, month, 1);
    final daysInMonth = DateTime(_year, month + 1, 1).difference(first).inDays;
    final leading = rowIndex(first.weekday);

    Widget cell(DateTime date) {
      final dayStr = AppDatabase.formatDay(date);
      final explicit = flags[dayStr];
      final flag = explicit ?? (_isWeekend(date) ? DayFlag.rest : null);
      final Color bg;
      final Color fg;
      final String glyph;
      if (flag == DayFlag.rest) {
        glyph = l.glyphRest;
        // 显式法定假日更醒目；周末默认休为弱化红（与日历页角标一致）
        if (explicit != null) {
          bg = scheme.error.withValues(alpha: 0.16);
          fg = scheme.error;
        } else {
          bg = scheme.error.withValues(alpha: 0.05);
          fg = scheme.error.withValues(alpha: 0.45);
        }
      } else if (flag == DayFlag.work) {
        glyph = l.glyphWork;
        bg = scheme.primary.withValues(alpha: 0.14);
        fg = scheme.primary;
      } else {
        glyph = ' ';
        bg = scheme.surfaceContainerHighest.withValues(alpha: 0.4);
        fg = scheme.onSurface;
      }
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _editDay(context, date, flags),
          child: Container(
            height: 38,
            margin: const EdgeInsets.all(1),
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${date.day}',
                    style: textTheme.labelSmall?.copyWith(color: fg)),
                Text(
                  glyph,
                  style: TextStyle(
                    fontSize: 8,
                    height: 1.2,
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget blank() => const Expanded(
          child: SizedBox(height: 38),
        );

    final cells = <Widget>[
      for (var i = 0; i < leading; i++) blank(),
      for (var d = 0; d < daysInMonth; d++) cell(DateTime(_year, month, 1 + d)),
    ];
    while (cells.length % 7 != 0) {
      cells.add(blank());
    }

    final rows = <Widget>[
      for (var i = 0; i < cells.length; i += 7)
        Row(children: cells.sublist(i, i + 7)),
    ];

    return SizedBox(
      width: _cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(DateFormat.yMMM(locale).format(first),
                  style: textTheme.titleSmall),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Center(
                        child: Text(
                          narrowWeekdays[(firstWeekday + i) % 7],
                          style: textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              ...rows,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(title: Text(l.holidayPlanTitle)),
      body: StreamBuilder<Map<String, DayFlag>>(
        stream: appDb.watchCalendarFlags(),
        builder: (context, snap) {
          final flags = snap.data ?? const <String, DayFlag>{};
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.holidayPlanHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _year--),
                  ),
                  Text('$_year',
                      style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() => _year++),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var m = 1; m <= 12; m++)
                          _monthCard(context, m, flags, l, locale),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
