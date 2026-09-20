import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/tag_presets.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import '../ui/entry_widgets.dart';

/// 类型预设：名称 + 默认标记/字符
class _TypePreset {
  final String Function(AppLocalizations l) name;
  final CalendarMark mark;
  final String? glyph;
  final bool counter;
  const _TypePreset(this.name, {this.mark = CalendarMark.none, this.glyph, this.counter = false});
}

/// 日历统一管理：完全自定义的事件类型（分组承载），
/// 国家节假日/调休、生日、月经周期、旅行等都是类型的特例；
/// 计数器类型可每日 +1 计次；带 annualDate 的思绪（特殊日子）也在此管理
class CalendarManagePage extends StatelessWidget {
  const CalendarManagePage({super.key});

  static const _presets = [
    _TypePreset(
        _presetHoliday, mark: CalendarMark.rest, glyph: '休'),
    _TypePreset(
        _presetMakeup, mark: CalendarMark.work, glyph: '班'),
    _TypePreset(_presetBirthday, glyph: '🎂'),
    _TypePreset(_presetPeriod, glyph: '🩸'),
    _TypePreset(_presetTravel, glyph: '✈️'),
    _TypePreset(_presetCheckIn, counter: true, glyph: '✅'),
  ];

  static String _presetHoliday(AppLocalizations l) => l.presetHoliday;
  static String _presetMakeup(AppLocalizations l) => l.presetMakeup;
  static String _presetBirthday(AppLocalizations l) => l.presetBirthday;
  static String _presetPeriod(AppLocalizations l) => l.presetPeriod;
  static String _presetTravel(AppLocalizations l) => l.presetTravel;
  static String _presetCheckIn(AppLocalizations l) => l.presetCheckIn;

  // ---------- 类型对话框 ----------

  /// 新建/编辑类型（existing 为 null 即新建）
  Future<void> _showTypeDialog(
    BuildContext context, {
    EventType? existing,
  }) async {
    final l = AppLocalizations.of(context)!;
    final name = TextEditingController(text: existing?.name ?? '');
    final glyph = TextEditingController(text: existing?.glyph ?? '');
    var color = existing?.color ?? tagColorChoices.first;
    var mark = existing?.mark ?? CalendarMark.none;
    var counter = existing?.counter ?? false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? l.addEventType : l.editType),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (existing == null) ...[
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final preset in _presets)
                        ActionChip(
                          label: Text(preset.name(l)),
                          onPressed: () => setState(() {
                            name.text = preset.name(l);
                            mark = preset.mark;
                            counter = preset.counter;
                            glyph.text = preset.glyph ?? '';
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(labelText: l.typeNameHint),
                ),
                const SizedBox(height: 12),
                // 颜色
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in tagColorChoices)
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => color = c),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(c),
                            border: Border.all(
                              width: color == c ? 3 : 1,
                              color: color == c
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<CalendarMark>(
                  segments: [
                    ButtonSegment(
                        value: CalendarMark.none, label: Text(l.markNone)),
                    ButtonSegment(
                        value: CalendarMark.rest, label: Text(l.restLabel)),
                    ButtonSegment(
                        value: CalendarMark.work, label: Text(l.workLabel)),
                  ],
                  selected: {mark},
                  onSelectionChanged: (s) => setState(() => mark = s.first),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.counterType),
                  subtitle: Text(
                    l.counterHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: counter,
                  onChanged: (v) => setState(() => counter = v),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: glyph,
                  decoration:
                      InputDecoration(labelText: l.cornerGlyphHint),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.confirm),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final trimmed = name.text.trim();
    if (trimmed.isEmpty) return;
    final glyphText = glyph.text.trim();
    if (existing == null) {
      await appDb.createEventType(
        name: trimmed,
        color: color,
        glyph: glyphText.isEmpty ? null : glyphText,
        mark: mark,
        counter: counter,
      );
    } else {
      await appDb.updateEventType(
        existing.id,
        name: trimmed,
        color: color,
        glyph: glyphText.isEmpty ? null : glyphText,
        mark: mark,
        counter: counter,
      );
    }
  }

  Future<void> _deleteType(BuildContext context, EventType type) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteType),
        content: Text(l.deleteTypeBody(type.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.deleteType),
          ),
        ],
      ),
    );
    if (ok == true) await appDb.deleteEventType(type.id);
  }

  // ---------- 事件对话框 ----------

  /// 新建/编辑事件（existing 为 null 即新建）
  Future<void> _showEventDialog(
    BuildContext context, {
    required EventType type,
    CalendarEvent? existing,
    String? initialDate,
  }) async {
    final l = AppLocalizations.of(context)!;
    final title = TextEditingController(text: existing?.title ?? '');
    var start = DateTime.parse(existing?.startDate ??
        initialDate ??
        AppDatabase.today());
    DateTime? end = existing?.endDate == null
        ? null
        : DateTime.parse(existing!.endDate!);
    var annual = existing?.annual ?? false;
    var asThought = false;

    Future<void> pick({required bool isStart}) async {
      final d = await showDatePicker(
        context: context,
        initialDate: isStart ? start : (end ?? start),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
      );
      if (d == null) return;
      if (isStart) start = d;
      if (!isStart) end = d;
    }

    String fmt(DateTime d) =>
        DateFormat.yMMMd(Localizations.localeOf(context).toString())
            .format(d);

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? l.addEvent : l.editEvent),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration:
                      InputDecoration(labelText: l.eventTitleHint),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l.startDateLabel),
                  trailing: Text(fmt(start)),
                  onTap: () => pick(isStart: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(l.endDateLabel),
                  trailing: end == null
                      ? const Icon(Icons.close, size: 16)
                      : Text(fmt(end!)),
                  onTap: () => pick(isStart: false),
                  onLongPress: end == null
                      ? null
                      : () => setState(() => end = null),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.annualRecur),
                  value: annual,
                  onChanged: (v) => setState(() => annual = v),
                ),
                if (existing == null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.recordAsThought),
                    value: asThought,
                    onChanged: (v) => setState(() => asThought = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.confirm),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final endDateStr = (end != null && !end!.isBefore(start))
        ? AppDatabase.formatDay(end!)
        : null;
    if (existing == null) {
      int? thoughtId;
      // 联动思绪：事件同时落为一条思绪（万物皆思绪，可选）
      if (asThought) {
        thoughtId = await appDb.insertThought(
          content: title.text.trim().isEmpty ? type.name : title.text.trim(),
          day: AppDatabase.formatDay(start),
        );
      }
      await appDb.insertEvent(
        typeId: type.id,
        title: title.text.trim().isEmpty ? null : title.text.trim(),
        startDate: AppDatabase.formatDay(start),
        endDate: endDateStr,
        annual: annual,
        thoughtId: thoughtId,
      );
    } else {
      await appDb.updateEvent(
        existing.id,
        title: title.text.trim().isEmpty ? null : title.text.trim(),
        startDate: AppDatabase.formatDay(start),
        endDate: endDateStr,
        annual: annual,
      );
    }
  }

  // ---------- 特殊日子（思绪） ----------

  Future<void> _addAnnualThought(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    var picked = DateTime.now();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.addSpecialDay),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration:
                    InputDecoration(labelText: l.specialDayNameHint),
                onSubmitted: (_) => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(l.specialDayDate),
                trailing: Text(DateFormat.yMMMd(
                        Localizations.localeOf(context).toString())
                    .format(picked)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: picked,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => picked = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.confirm),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    await appDb.insertThought(
      content: name,
      day: AppDatabase.today(),
      annualDate:
          '${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
    );
  }

  String _formatDate(String md, String locale) {
    final m = int.parse(md.substring(0, 2));
    final d = int.parse(md.substring(3, 5));
    return DateFormat.MMMd(locale).format(DateTime(2024, m, d));
  }

  // ---------- 页面 ----------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme;

    Widget typeIcon(EventType type, {double size = 40}) {
      final glyph = type.glyph;
      if (glyph != null && glyph.isNotEmpty) {
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(type.color).withValues(alpha: 0.15),
          ),
          child: Text(
            glyph,
            style: TextStyle(
              fontSize: size * 0.4,
              color: Color(type.color),
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(type.color),
        ),
      );
    }

    String markLabel(CalendarMark mark) => switch (mark) {
          CalendarMark.rest => l.restLabel,
          CalendarMark.work => l.workLabel,
          CalendarMark.none => l.markNone,
        };

    return Scaffold(
      appBar: AppBar(title: Text(l.calendarManageTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTypeDialog(context),
        tooltip: l.addEventType,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<EventType>>(
        stream: appDb.watchEventTypes(),
        builder: (context, typeSnap) {
          final types = typeSnap.data ?? const <EventType>[];
          return StreamBuilder<List<CalendarEvent>>(
            stream: appDb.watchEvents(),
            builder: (context, evSnap) {
              final events = evSnap.data ?? const <CalendarEvent>[];
              final byType = <int, List<CalendarEvent>>{};
              for (final e in events) {
                byType.putIfAbsent(e.typeId, () => []).add(e);
              }
              // 计数器类型累计
              final totals = <int, int>{};
              for (final e in events) {
                totals[e.typeId] = (totals[e.typeId] ?? 0) + e.count;
              }
              return StreamBuilder<List<ThoughtEntry>>(
                stream: appDb.watchAnnualEvents(),
                builder: (context, thSnap) {
                  final annualThoughts =
                      thSnap.data ?? const <ThoughtEntry>[];
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 特殊日子（思绪）：万物皆思绪
                      Text(
                        l.specialThoughtsSection,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.specialDaysHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            if (annualThoughts.isEmpty)
                              ListTile(
                                enabled: false,
                                title: Text(l.specialDayEmpty),
                              ),
                            for (final t in annualThoughts)
                              ListTile(
                                leading: const Icon(Icons.celebration_outlined,
                                    color: Color(0xFFCF9F3F)),
                                title: Text(t.content),
                                subtitle:
                                    Text(_formatDate(t.annualDate!, locale)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => confirmDelete(context, t),
                                ),
                                onTap: () =>
                                    showEntryEditor(context, existing: t),
                              ),
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: Text(l.addSpecialDay),
                              onTap: () => _addAnnualThought(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 事件类型：完全自定义，分组承载
                      Row(
                        children: [
                          Text(
                            l.eventTypesSection,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.eventsCount(events.length),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (types.isEmpty)
                        Card(
                          child: ListTile(
                            enabled: false,
                            title: Text(l.emptyTypes),
                          ),
                        ),
                      for (final type in types)
                        Card(
                          child: ExpansionTile(
                            leading: typeIcon(type),
                            title: Text(type.name),
                            subtitle: Text(
                              type.counter
                                  ? l.totalCount(totals[type.id] ?? 0)
                                  : '${(byType[type.id] ?? const []).length} · ${markLabel(type.mark)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: scheme.onSurfaceVariant),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) => switch (action) {
                                'edit' =>
                                  _showTypeDialog(context, existing: type),
                                'delete' => _deleteType(context, type),
                                _ => null,
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(l.editType),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    l.deleteType,
                                    style: TextStyle(color: scheme.error),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              if (type.counter) ...[
                                // 计数器：今天 +1
                                ListTile(
                                  dense: true,
                                  leading: Icon(Icons.add_circle_outline,
                                      color: scheme.primary),
                                  title: Text(l.addOne),
                                  onTap: () => appDb.incrementCounter(
                                    typeId: type.id,
                                    date: AppDatabase.today(),
                                  ),
                                ),
                                // 按日计次列表（新日期在前）
                                for (final e
                                    in (byType[type.id] ??
                                            const <CalendarEvent>[])
                                        .reversed)
                                  ListTile(
                                    dense: true,
                                    leading: typeIcon(type, size: 24),
                                    title: Text(
                                      '${DateFormat.MMMd(locale).format(DateTime.parse(e.startDate))}'
                                      '${e.count > 1 ? ' ×${e.count}' : ''}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 20),
                                          onPressed: () =>
                                              appDb.decrementCounter(
                                            typeId: type.id,
                                            date: e.startDate,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 20),
                                          onPressed: () =>
                                              appDb.incrementCounter(
                                            typeId: type.id,
                                            date: e.startDate,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ] else ...[
                                for (final e in byType[type.id] ?? const [])
                                  ListTile(
                                    dense: true,
                                    leading: typeIcon(type, size: 24),
                                    title: Text(e.title ?? type.name),
                                    subtitle:
                                        Text(_eventRange(e, locale)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (e.thoughtId != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 4),
                                            child: Icon(
                                              Icons.link,
                                              size: 16,
                                              color: scheme.primary,
                                            ),
                                          ),
                                        if (e.annual)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 4),
                                            child: Icon(
                                              Icons.repeat,
                                              size: 16,
                                              color:
                                                  scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20),
                                          onPressed: () =>
                                              appDb.deleteEvent(e.id),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _showEventDialog(
                                      context,
                                      type: type,
                                      existing: e,
                                    ),
                                  ),
                                ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.add),
                                  title: Text(l.addEvent),
                                  onTap: () => _showEventDialog(
                                    context,
                                    type: type,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _eventRange(CalendarEvent e, String locale) {
    final start = DateTime.parse(e.startDate);
    final fmt = DateFormat.yMMMd(locale);
    if (e.endDate == null) return fmt.format(start);
    final end = DateTime.parse(e.endDate!);
    return '${fmt.format(start)} ~ ${fmt.format(end)}';
  }
}
