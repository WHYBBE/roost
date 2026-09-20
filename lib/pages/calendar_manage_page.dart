import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/tag_presets.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';

/// 创建种类：创建前先选中，字段随种类显隐。
/// 节假日为单一类型（实例可分别标记 休/调休班）；生日下的事件默认每年循环；
/// 其余预设只是快捷填充；自定义拥有全部字段（含休/班标记）
enum _CreateKind { holiday, birthday, checkIn, cycle, travel, custom }

/// 日历统一管理：
/// 上半部分是"实例"（具体的事件，显示在日历上），下半部分仅承载"类型"定义。
/// 节假日、生日、计数器等都是类型的特例；带 annualDate 的思绪继续在日历展示
class CalendarManagePage extends StatelessWidget {
  const CalendarManagePage({super.key});

  static String _kindLabel(_CreateKind kind, AppLocalizations l) =>
      switch (kind) {
        _CreateKind.holiday => l.kindHoliday,
        _CreateKind.birthday => l.presetBirthday,
        _CreateKind.checkIn => l.presetCheckIn,
        _CreateKind.cycle => l.presetPeriod,
        _CreateKind.travel => l.presetTravel,
        _CreateKind.custom => l.kindCustom,
      };

  static String _kindGlyph(_CreateKind kind) => switch (kind) {
        _CreateKind.birthday => '🎂',
        _CreateKind.checkIn => '✅',
        _CreateKind.cycle => '🩸',
        _CreateKind.travel => '✈️',
        _ => '',
      };

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
    // 编辑时种类不可变；新建时先选种类
    var createKind = _CreateKind.custom;

    /// 按种类应用预填（仅新建）
    void applyKind(_CreateKind kind) {
      createKind = kind;
      name.text = switch (kind) {
        _CreateKind.holiday =>
          '${DateTime.now().year} ${l.presetHoliday}',
        _CreateKind.birthday => l.presetBirthday,
        _CreateKind.checkIn => l.presetCheckIn,
        _CreateKind.cycle => l.presetPeriod,
        _CreateKind.travel => l.presetTravel,
        _CreateKind.custom => '',
      };
      final g = _kindGlyph(kind);
      glyph.text = kind == _CreateKind.holiday ? '休' : g;
      counter = kind == _CreateKind.checkIn;
      mark = kind == _CreateKind.holiday
          ? CalendarMark.rest
          : CalendarMark.none;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // 休/班标记仅自定义种类可选（节假日类型固定为休，
          // 其下实例可逐条覆盖为班）；编辑时种类锁定
          final showMark = existing?.kind == EventTypeKind.custom ||
              (existing == null && createKind == _CreateKind.custom);
          final showColor = !(existing == null &&
              createKind == _CreateKind.holiday);

          return AlertDialog(
            title: Text(existing == null ? l.addEventType : l.editType),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (existing == null) ...[
                    // 第一步：选中种类
                    Wrap(
                      spacing: 6,
                      runSpacing: 0,
                      children: [
                        for (final kind in _CreateKind.values)
                          ChoiceChip(
                            label: Text(_kindLabel(kind, l)),
                            selected: createKind == kind,
                            onSelected: (_) =>
                                setState(() => applyKind(kind)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: name,
                    autofocus: existing != null,
                    decoration: InputDecoration(
                      labelText: existing == null &&
                              createKind == _CreateKind.holiday
                          ? l.typeNameHint
                          : l.typeNameSimpleHint,
                    ),
                  ),
                  if (showColor) ...[
                    const SizedBox(height: 12),
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
                  ],
                  if (showMark) ...[
                    const SizedBox(height: 12),
                    SegmentedButton<CalendarMark>(
                      segments: [
                        ButtonSegment(
                            value: CalendarMark.none,
                            label: Text(l.markNone)),
                        ButtonSegment(
                            value: CalendarMark.rest,
                            label: Text(l.restLabel)),
                        ButtonSegment(
                            value: CalendarMark.work,
                            label: Text(l.workLabel)),
                      ],
                      selected: {mark},
                      onSelectionChanged: (s) =>
                          setState(() => mark = s.first),
                    ),
                  ],
                  if (existing == null && createKind == _CreateKind.checkIn)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.counterType),
                      value: counter,
                      onChanged: (v) => setState(() => counter = v),
                    ),
                  if (!(existing == null &&
                      createKind == _CreateKind.holiday)) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: glyph,
                      decoration: InputDecoration(
                          labelText: l.cornerGlyphHint),
                    ),
                  ],
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
          );
        },
      ),
    );
    if (ok != true || !context.mounted) return;
    final trimmed = name.text.trim();
    if (trimmed.isEmpty) return;
    final glyphText = glyph.text.trim();

    if (existing == null) {
      // 节假日：单一类型（休标记；实例可逐条覆盖为班/调休）
      await appDb.createEventType(
        name: trimmed,
        color: createKind == _CreateKind.holiday ? 0xFFCF4B3F : color,
        glyph: glyphText.isEmpty ? null : glyphText,
        mark: mark,
        counter: counter,
        kind: switch (createKind) {
          _CreateKind.holiday => EventTypeKind.holiday,
          _CreateKind.birthday => EventTypeKind.birthday,
          _ => EventTypeKind.custom,
        },
      );
    } else {
      await appDb.updateEventType(
        existing.id,
        name: trimmed,
        color: color,
        glyph: glyphText.isEmpty ? null : glyphText,
        mark: existing.kind == EventTypeKind.holiday
            ? CalendarMark.rest
            : existing.kind == EventTypeKind.makeup
                ? CalendarMark.work
                : mark,
        counter: counter,
        kind: existing.kind,
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

  // ---------- 事件（实例） ----------

  /// 从类型列表中选一个，再进入事件对话框
  Future<void> _pickTypeAndAddEvent(
    BuildContext context,
    List<EventType> types,
  ) async {
    final l = AppLocalizations.of(context)!;
    final candidates = types.where((t) => !t.counter).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.noEventTypes)));
      return;
    }
    final picked = await showModalBottomSheet<EventType>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.pickTypeTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            for (final t in candidates)
              ListTile(
                leading: t.glyph == null || t.glyph!.isEmpty
                    ? Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(t.color),
                        ),
                      )
                    : Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(t.color).withValues(alpha: 0.15),
                        ),
                        child: Text(
                          t.glyph!,
                          style:
                              TextStyle(fontSize: 13, color: Color(t.color)),
                        ),
                      ),
                title: Text(t.name),
                onTap: () => Navigator.pop(context, t),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    await _showEventDialog(context, type: picked);
  }

  /// 新建/编辑事件实例（existing 为 null 即新建）。
  /// 节假日类型下可选休/班（班即调休日），其余类型继承类型标记
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
    var annual = existing?.annual ?? (type.kind == EventTypeKind.birthday);
    var instMark = existing?.mark ?? type.mark;

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
                // 节假日类型：实例可分别标记为休（放假日）或班（调休日）
                if (type.kind == EventTypeKind.holiday)
                  SegmentedButton<CalendarMark>(
                    segments: [
                      ButtonSegment(
                          value: CalendarMark.rest,
                          label: Text(l.restLabel)),
                      ButtonSegment(
                          value: CalendarMark.work,
                          label: Text(l.workLabel)),
                    ],
                    selected: {
                      instMark == CalendarMark.work
                          ? CalendarMark.work
                          : CalendarMark.rest
                    },
                    onSelectionChanged: (s) =>
                        setState(() => instMark = s.first),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.annualRecur),
                  value: annual,
                  onChanged: (v) => setState(() => annual = v),
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
    final titleText = title.text.trim().isEmpty ? null : title.text.trim();
    // 仅节假日类型写入实例级标记；其余清除覆盖
    final markOut =
        type.kind == EventTypeKind.holiday ? instMark : null;
    if (existing == null) {
      await appDb.insertEvent(
        typeId: type.id,
        title: titleText,
        startDate: AppDatabase.formatDay(start),
        endDate: endDateStr,
        annual: annual,
        mark: markOut,
      );
    } else {
      await appDb.updateEvent(
        existing.id,
        title: titleText,
        startDate: AppDatabase.formatDay(start),
        endDate: endDateStr,
        annual: annual,
        mark: markOut,
      );
    }
  }

  String _eventRange(CalendarEvent e, String locale) {
    final start = DateTime.parse(e.startDate);
    final fmt = DateFormat.yMMMd(locale);
    if (e.endDate == null) return fmt.format(start);
    final end = DateTime.parse(e.endDate!);
    return '${fmt.format(start)} ~ ${fmt.format(end)}';
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

    /// 类型卡片副标题
    String typeSubtitle(EventType type, int eventCount, int total) {
      if (type.counter) return l.totalCount(total);
      final label = switch (type.kind) {
        EventTypeKind.holiday => '${l.restLabel} / ${l.workLabel}',
        EventTypeKind.birthday => l.annualRecur,
        _ => markLabel(type.mark),
      };
      return '$label · ${l.eventsCount(eventCount)}';
    }

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
          final typeById = {for (final t in types) t.id: t};
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
              // 实例列表：按开始日期升序，排除计数器类型（计数在类型卡片内）
              final instances = [
                for (final e in events)
                  if (!(typeById[e.typeId]?.counter ?? false)) e,
              ]..sort((a, b) => a.startDate.compareTo(b.startDate));

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ---------- 实例 ----------
                  Text(
                    l.dayEventsLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.instancesHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        if (instances.isEmpty)
                          ListTile(
                            enabled: false,
                            title: Text(l.emptyEvents),
                          ),
                        for (final e in instances)
                          Builder(builder: (context) {
                            final type = typeById[e.typeId];
                            if (type == null) {
                              return const SizedBox.shrink();
                            }
                            final subtitle = _eventRange(e, locale);
                            return ListTile(
                              dense: true,
                              leading: typeIcon(type, size: 24),
                              title: Text(e.title ?? type.name),
                              subtitle: Text(
                                type.kind == EventTypeKind.holiday &&
                                        e.mark == CalendarMark.work
                                    ? '$subtitle · ${l.workLabel}'
                                    : subtitle,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (e.thoughtId != null)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.link,
                                        size: 16,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  if (e.annual)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.repeat,
                                        size: 16,
                                        color: scheme.onSurfaceVariant,
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
                            );
                          }),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: Text(l.addEvent),
                          onTap: () =>
                              _pickTypeAndAddEvent(context, types),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ---------- 类型定义 ----------
                  Row(
                    children: [
                      Text(
                        l.eventTypesSection,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.eventsCount(types.length),
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
                    if (type.counter)
                      // 计数器：定义与计次都收在类型卡片内
                      Card(
                        child: ExpansionTile(
                          leading: typeIcon(type),
                          title: Text(type.name),
                          subtitle: Text(
                            typeSubtitle(
                                type, byType[type.id]?.length ?? 0,
                                totals[type.id] ?? 0),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
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
                            for (final e in (byType[type.id] ??
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
                          ],
                        ),
                      )
                    else
                      // 普通类型：仅定义，实例在上方
                      Card(
                        child: ListTile(
                          leading: typeIcon(type),
                          title: Text(type.name),
                          subtitle: Text(
                            typeSubtitle(type, byType[type.id]?.length ?? 0,
                                totals[type.id] ?? 0),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
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
                        ),
                      ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
