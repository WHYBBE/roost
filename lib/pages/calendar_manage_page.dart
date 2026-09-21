import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/tag_presets.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';

/// 创建种类：创建前先选中，字段随种类显隐。
/// 节假日为单一类型（内置 放假/补班 两个状态）；生日下的事件默认每年循环；
/// 其余预设只是快捷填充；自定义拥有全部字段（含状态预设）
enum _CreateKind { holiday, birthday, checkIn, cycle, travel, custom }

/// 类型对话框里的一个状态编辑条目
/// （id 非空 = 编辑已有状态行，保存时原位更新以保留事件引用）
class _StatusDraft {
  final int? id;
  final TextEditingController name;
  final TextEditingController glyph;
  int color;

  _StatusDraft({
    this.id,
    required String name,
    String glyph = '',
    this.color = 0xFF9E9E9E,
  })  : name = TextEditingController(text: name),
        glyph = TextEditingController(text: glyph);

  void dispose() {
    name.dispose();
    glyph.dispose();
  }
}

/// 节假日类型内置的两个状态颜色（休·红 / 班·蓝）
const _holidayStatusColors = [0xFFCF4B3F, 0xFF3F7DCF];

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

  /// 新建/编辑类型（existing 为 null 即新建）。
  /// 状态随类型一起编辑：新建时先收集草稿，保存时一并种入；
  /// 编辑时直接对已有状态行增删改
  Future<void> _showTypeDialog(
    BuildContext context, {
    EventType? existing,
  }) async {
    final l = AppLocalizations.of(context)!;
    final name = TextEditingController(text: existing?.name ?? '');
    final glyph = TextEditingController(text: existing?.glyph ?? '');
    var color = existing?.color ?? tagColorChoices.first;
    var counter = existing?.counter ?? false;
    // 编辑时种类不可变；新建时先选种类
    var createKind = _CreateKind.custom;
    // 状态编辑行（新建为空；编辑时预填已有状态，保存时按 id 增删改）
    final drafts = <_StatusDraft>[];
    final existingStatuses = <EventStatus>[];
    if (existing != null) {
      existingStatuses.addAll(await appDb.statusesFor(existing.id));
      if (!context.mounted) return;
      drafts.addAll([
        for (final s in existingStatuses)
          _StatusDraft(
            id: s.id,
            name: s.name,
            glyph: s.glyph,
            color: s.color,
          ),
      ]);
    }

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
      // 预设状态：节假日内置 放假/补班（锁定）；其余种类默认无
      drafts.clear();
      if (kind == _CreateKind.holiday) {
        drafts.add(_StatusDraft(
            name: l.statusRest, color: _holidayStatusColors[0]));
        drafts.add(_StatusDraft(
            name: l.statusMakeup, color: _holidayStatusColors[1]));
      }
    }

    /// 状态编辑条目：名称 + 单字符角标 + 颜色 + 删除
    Widget statusRow(_StatusDraft d, VoidCallback onChanged) => Row(
          children: [
            Expanded(
              child: TextField(
                controller: d.name,
                decoration: InputDecoration(
                    isDense: true, labelText: l.statusNameHint),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: TextField(
                controller: d.glyph,
                decoration: InputDecoration(
                    isDense: true, labelText: l.statusGlyphHint),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 8),
            // 颜色：循环切换预设色
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                final idx = tagColorChoices.indexOf(d.color);
                d.color = tagColorChoices[(idx + 1) % tagColorChoices.length];
                onChanged();
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(d.color),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: () {
                if (drafts.remove(d)) onChanged();
              },
            ),
          ],
        );

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // 状态区：编辑时非计数器类型可见；新建时除生日/打卡等预设外可见
          final showStatuses = existing != null
              ? !existing.counter
              : createKind == _CreateKind.holiday ||
                  createKind == _CreateKind.custom;
          // 节假日状态内置固定（放假/补班）：只展示不可改
          final holidayLock = (existing?.kind == EventTypeKind.holiday ||
                  existing?.kind == EventTypeKind.makeup) ||
              (existing == null && createKind == _CreateKind.holiday);
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
                  // ---------- 状态预设 ----------
                  if (showStatuses) ...[
                    const SizedBox(height: 12),
                    Text(l.statusPresetTitle,
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    // 节假日锁定：只读芯片展示内置状态
                    if (holidayLock)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Wrap(
                          spacing: 6,
                          children: [
                            for (final d in drafts)
                              Chip(
                                avatar: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(d.color),
                                  ),
                                ),
                                label: Text(
                                  '${d.name.text}${d.glyph.text.isEmpty ? '' : ' · ${d.glyph.text}'}',
                                ),
                              ),
                          ],
                        ),
                      )
                    else ...[
                      for (final d in drafts)
                        statusRow(d, () => setState(() {})),
                      TextButton.icon(
                        onPressed: () => setState(() => drafts.add(
                            _StatusDraft(
                                name: '', color: tagColorChoices.first))),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.addStatus),
                      ),
                    ],
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
    // 节假日状态内置固定，编辑类型本身时不动状态行
    final touchStatuses = !(existing != null &&
        (existing.kind == EventTypeKind.holiday ||
            existing.kind == EventTypeKind.makeup));

    if (existing == null) {
      // 节假日：单一类型（内置 放假/补班 状态）
      final isHoliday = createKind == _CreateKind.holiday;
      await appDb.createEventType(
        name: trimmed,
        color: isHoliday ? 0xFFCF4B3F : color,
        glyph: glyphText.isEmpty ? null : glyphText,
        counter: counter,
        kind: switch (createKind) {
          _CreateKind.holiday => EventTypeKind.holiday,
          _CreateKind.birthday => EventTypeKind.birthday,
          _ => EventTypeKind.custom,
        },
        statuses: [
          for (final d in drafts)
            if (d.name.text.trim().isNotEmpty)
              EventStatusesCompanion.insert(
                typeId: 0,
                name: d.name.text.trim(),
                color: d.color,
                glyph: Value(d.glyph.text.trim()),
              ),
        ],
      );
    } else {
      await appDb.updateEventType(
        existing.id,
        name: trimmed,
        color: color,
        glyph: glyphText.isEmpty ? null : glyphText,
        counter: counter,
        kind: existing.kind,
      );
      if (touchStatuses) {
        // 状态按 id 增删改：已有行原位更新，保住事件实例的 statusId
        final keepIds = <int>{};
        for (final d in drafts) {
          final n = d.name.text.trim();
          if (n.isEmpty) continue;
          if (d.id != null) {
            await appDb.updateEventStatus(
              d.id!,
              name: n,
              color: d.color,
              glyph: d.glyph.text.trim(),
            );
            keepIds.add(d.id!);
          } else {
            final sid = await appDb.createEventStatus(
              typeId: existing.id,
              name: n,
              color: d.color,
              glyph: d.glyph.text.trim(),
            );
            keepIds.add(sid);
          }
        }
        // 被移除的状态行：其上事件实例 statusId 外键置空
        for (final s in existingStatuses) {
          if (!keepIds.contains(s.id)) {
            await appDb.deleteEventStatus(s.id);
          }
        }
      }
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

  /// 新建/编辑事件实例（existing 为 null 即新建）。
  /// 类型有状态预设时（如节假日的 放假/补班、任务的 已完成/未完成）可选择
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
    final statuses = await appDb.statusesFor(type.id);
    if (!context.mounted) return;
    // 默认选中第一个状态（如节假日默认放假）；编辑时保留原状态
    int? selStatus = existing?.statusId ??
        (statuses.isEmpty ? null : statuses.first.id);

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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                // 状态：类型的状态预设（无状态 = 无标记）
                if (statuses.isNotEmpty) ...[
                  Text(l.statusLabel,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 0,
                    children: [
                      ChoiceChip(
                        label: Text(l.markNone),
                        selected: selStatus == null,
                        onSelected: (_) =>
                            setState(() => selStatus = null),
                      ),
                      for (final s in statuses)
                        ChoiceChip(
                          avatar: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(s.color),
                            ),
                          ),
                          label: Text(
                            s.glyph.isEmpty
                                ? s.name
                                : '${s.glyph} ${s.name}',
                          ),
                          selected: selStatus == s.id,
                          onSelected: (_) =>
                              setState(() => selStatus = s.id),
                        ),
                    ],
                  ),
                ],
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
    if (existing == null) {
      await appDb.insertEvent(
        typeId: type.id,
        title: titleText,
        startDate: AppDatabase.formatDay(start),
        endDate: endDateStr,
        annual: annual,
        statusId: selStatus,
      );
    } else {
      await appDb.updateEvent(
        existing.id,
        title: titleText,
        startDate: AppDatabase.formatDay(start),
        endDate: endDateStr,
        annual: annual,
        statusId: selStatus,
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

    /// 类型卡片副标题
    String typeSubtitle(
      EventType type,
      List<EventStatus> statuses,
      int eventCount,
      int total,
    ) {
      if (type.counter) return l.totalCount(total);
      final label = switch (type.kind) {
        EventTypeKind.holiday ||
        EventTypeKind.makeup =>
          statuses.isEmpty
              ? '${l.restLabel} / ${l.workLabel}'
              : statuses.map((s) => s.name).join(' / '),
        EventTypeKind.birthday => l.annualRecur,
        _ => statuses.isEmpty
            ? l.markNone
            : statuses.map((s) => s.name).join(' / '),
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
          return StreamBuilder<List<EventStatus>>(
            stream: appDb.watchEventStatuses(),
            builder: (context, stSnap) {
              final statusById = {
                for (final s in stSnap.data ?? const <EventStatus>[]) s.id: s,
              };
              final statusesByType = <int, List<EventStatus>>{};
              for (final s in stSnap.data ?? const <EventStatus>[]) {
                statusesByType
                    .putIfAbsent(s.typeId, () => [])
                    .add(s);
              }
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

                  /// 类型卡片展开区：普通类型展示全部事件（可编辑），计数器展示计次
                  List<Widget> typeChildren(EventType type) {
                    if (type.counter) {
                      return [
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
                                  onPressed: () => appDb.decrementCounter(
                                    typeId: type.id,
                                    date: e.startDate,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 20),
                                  onPressed: () => appDb.incrementCounter(
                                    typeId: type.id,
                                    date: e.startDate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ];
                    }
                    return [
                      // 该类型的全部事件（点按编辑）
                      for (final e in byType[type.id] ??
                          const <CalendarEvent>[])
                        ListTile(
                          dense: true,
                          leading: typeIcon(type, size: 24),
                          title: Text(e.title ?? type.name),
                          subtitle: Text(
                            [
                              _eventRange(e, locale),
                              if (e.statusId != null)
                                statusById[e.statusId]?.name ?? '',
                            ].where((s) => s.isNotEmpty).join(' · '),
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
                        ),
                      if ((byType[type.id] ?? const []).isEmpty)
                        ListTile(
                          dense: true,
                          enabled: false,
                          title: Text(l.emptyEvents),
                        ),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.add),
                        title: Text(l.addEvent),
                        onTap: () =>
                            _showEventDialog(context, type: type),
                      ),
                    ];
                  }

                  Widget typeCard(EventType type) {
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        leading: typeIcon(type),
                        title: Text(type.name),
                        subtitle: Text(
                          typeSubtitle(
                            type,
                            statusesByType[type.id] ?? const [],
                            byType[type.id]?.length ?? 0,
                            totals[type.id] ?? 0,
                          ),
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
                        children: typeChildren(type),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ---------- 类型定义：点开即该类型的全部事件 ----------
                      Row(
                        children: [
                          Text(
                            l.eventTypesSection,
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.eventsCount(types.length),
                            style:
                                Theme.of(context).textTheme.labelSmall,
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
                      for (final type in types) typeCard(type),
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
}
