import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../l10n/app_localizations.dart';
import '../settings/lock_session.dart';
import '../ui/lock_widgets.dart';
import 'calendar_manage_page.dart';

/// 待办聚合视图：跨类型汇总所有"未完成"的事件。
/// 类型在日历管理里将某状态标记为"完成态"后即参与待办；
/// 列表按开始日期升序，逾期标红，可一键勾完成（撤销可恢复）
class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  Widget _typeIcon(EventType type, {double size = 36}) {
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

  /// 事件截止日（区间事件的最后一天）；早于今天即逾期
  static String _dueOf(CalendarEvent e) => e.endDate ?? e.startDate;

  String _range(CalendarEvent e, String locale) {
    final fmt = DateFormat.yMMMd(locale);
    if (e.endDate == null) return fmt.format(DateTime.parse(e.startDate));
    return '${fmt.format(DateTime.parse(e.startDate))} ~ ${fmt.format(DateTime.parse(e.endDate!))}';
  }

  Future<void> _complete(
    BuildContext context,
    AppLocalizations l,
    TodoItem item,
  ) async {
    final oldStatusId = item.status?.id;
    await appDb.completeTodo(item);
    if (!context.mounted) return;
    final title = item.event.title ?? item.type.name;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.todoCompleted(title)),
      action: SnackBarAction(
        label: l.undo,
        onPressed: () => appDb.setEventStatus(item.event.id, oldStatusId),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final scheme = Theme.of(context).colorScheme;
    final today = AppDatabase.today();

    return Scaffold(
      appBar: AppBar(title: Text(l.todosTitle)),
      body: StreamBuilder<Set<int>>(
        stream: appDb.watchLockedThoughtIds(),
        builder: (context, lockSnap) {
          final lockedIds = lockSnap.data ?? const <int>{};
          return StreamBuilder<List<TodoItem>>(
        stream: appDb.watchTodos(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const <TodoItem>[];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 48, color: scheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    l.todosEmpty,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final item in items)
                Card(
                  child: ListTile(
                    leading: _typeIcon(item.type),
                    title: Row(
                      children: [
                        Flexible(
                          child: ListenableBuilder(
                            listenable: LockSession.instance,
                            builder: (context, _) => Text(
                              eventDisplayTitle(
                                  item.event, item.type.name, lockedIds),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (item.event.annual) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.repeat,
                              size: 14, color: scheme.onSurfaceVariant),
                        ],
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _range(item.event, locale),
                            style: TextStyle(
                              fontSize: 12,
                              color: _dueOf(item.event).compareTo(today) < 0
                                  ? scheme.error
                                  : scheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            item.status?.name ?? l.todoNoStatus,
                            style: TextStyle(
                              fontSize: 12,
                              color: item.status == null
                                  ? scheme.onSurfaceVariant
                                  : Color(item.status!.color),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      color: scheme.primary,
                      tooltip: l.todoComplete,
                      onPressed: () => _complete(context, l, item),
                    ),
                    onTap: () => CalendarManagePage.showEventDialog(
                      context,
                      type: item.type,
                      existing: item.event,
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
