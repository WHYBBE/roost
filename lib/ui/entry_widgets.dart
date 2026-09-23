import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import '../pages/templates_page.dart';
import '../settings/lock_session.dart';
import 'attachment_widgets.dart';
import 'lock_widgets.dart';
import 'tag_view.dart';

extension EntryX on ThoughtEntry {
  DateTime get createdAtLocal => DateTime.fromMillisecondsSinceEpoch(createdAt);
  DateTime get dayDate => DateTime.parse(day);
  String get monthDay => day.substring(5);
  int get year => int.parse(day.substring(0, 4));
}

class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    this.tags,
    this.onTap,
    this.onLongPress,
  });

  final ThoughtEntry entry;

  /// 标签列表（含高级标签值）；为 null 时自动加载
  final List<TagWithCategory>? tags;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    // 私密内容的显隐跟随会话解锁状态（解锁后整卡即时刷新）
    return ListenableBuilder(
      listenable: LockSession.instance,
      builder: (context, _) => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final time = entry.createdAtLocal;
    final masked = isEntryMasked(entry);
    final allTags = tags ?? const <TagWithCategory>[];
    // 内置"心情"组：仍以元信息行展示
    final mood = masked
        ? null
        : allTags
            .where((t) => t.isBuiltin)
            .map((t) => t.tag)
            .fold<Tag?>(null, (prev, t) => prev ?? t);
    // 其他高级标签组的值：卡片下方胶囊展示
    final advanced =
        masked ? const <TagWithCategory>[] : allTags.where((t) => !t.isNormal).toList();
    // 普通标签
    final normalTags = masked
        ? const <Tag>[]
        : allTags.where((t) => t.isNormal).map((t) => t.tag).toList();
    // 除内置心情外的高级标签（心情已在元信息行）
    final otherAdvanced =
        advanced.where((t) => !t.isBuiltin).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // 桌面端明确的可点击反馈
        mouseCursor: SystemMouseCursors.click,
        hoverColor: scheme.primary.withValues(alpha: 0.06),
        onTap: onTap == null
            ? null
            : () => openEntryGuarded(context, entry, onTap!),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 元信息行靠左：心情 + 时间连排，避免右上大片空白
              Row(
                children: [
                  if (mood != null) ...[
                    TagIcon(tag: mood, size: 18, color: scheme.primary, fallback: Icons.mood),
                    const SizedBox(width: 6),
                    Text(
                      mood.name,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: mood.uiColor ?? scheme.primary,
                          ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (masked) ...[
                    Icon(Icons.lock_outline,
                        size: 13, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  // 星标/收藏：点按即切换（收藏视图汇总展示）
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    iconSize: 20,
                    tooltip: entry.starred ? l.unstar : l.star,
                    icon: Icon(
                      entry.starred ? Icons.star : Icons.star_border,
                      color: entry.starred
                          ? Colors.amber
                          : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    onPressed: () =>
                        appDb.setThoughtStarred(entry.id, !entry.starred),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 不能用 SelectionArea：会接管点击手势，导致卡片无法点按编辑
              if (masked)
                Text(
                  l.lockedBadge,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        fontStyle: FontStyle.italic,
                      ),
                )
              else ...[
                Text(
                  entry.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                AttachmentStrip(thoughtId: entry.id, thumbSize: 64),
                if (otherAdvanced.isNotEmpty)
                  AdvancedTagChips(
                    items: otherAdvanced,
                    showCategoryName: otherAdvanced
                            .map((t) => t.category?.id)
                            .toSet()
                            .length >
                        1,
                  ),
                if (normalTags.isNotEmpty) TagChips(tags: normalTags),
                // 评论与反应：自动加载，有内容时才显示
                _CommentReactionPreview(entryId: entry.id),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TagChips extends StatelessWidget {
  const TagChips({super.key, required this.tags});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final tag in tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tag.uiColor?.withValues(alpha: 0.18) ??
                    scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tag.hasIcon) ...[
                    TagIcon(
                      tag: tag,
                      size: 12,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '#${tag.name}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tag.uiColor ?? scheme.onSecondaryContainer,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 内置反应 emoji（固定顺序， ReactionKind 同步）
class ReactionBar extends StatelessWidget {
  const ReactionBar({super.key, required this.onPick});

  final ValueChanged<ReactionKind> onPick;

  @override
  Widget build(BuildContext context) {
    // 横排 6 个 emoji
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final kind in ReactionKind.values)
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onPick(kind),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                kind.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
      ],
    );
  }
}

/// 思绪的评论与反应区：StreamBuilder 自动刷新（卡片与编辑器共用）
class CommentReactionSection extends StatefulWidget {
  const CommentReactionSection({super.key, required this.thoughtId});

  final int thoughtId;

  @override
  State<CommentReactionSection> createState() =>
      _CommentReactionSectionState();
}

class _CommentReactionSectionState extends State<CommentReactionSection> {
  final _controller = TextEditingController();
  // 评论输入框默认不显示（点击入口展开）
  bool _showInput = false;
  // 反应选单浮层（悬浮在点击位置）
  OverlayEntry? _pickerOverlay;

  @override
  void dispose() {
    _hideReactionPicker();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 已有反应（点气泡移除）+ 选单中的 6 选 1
        StreamBuilder<List<Reaction>>(
          stream: appDb.watchReactionsFor(widget.thoughtId),
          builder: (context, snap) {
            final reactions = snap.data ?? const <Reaction>[];
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final r in reactions)
                    Tooltip(
                      message: l.deleteReaction,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => appDb.deleteReaction(r.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            r.kind.emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        // 评论列表
        StreamBuilder<List<Comment>>(
          stream: appDb.watchCommentsFor(widget.thoughtId),
          builder: (context, snap) {
            final comments = snap.data ?? const <Comment>[];
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in comments)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.6),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                  bottomLeft: Radius.circular(2),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                c.content,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                          // 删除藏在点按里：点评论弹删除确认
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.close,
                                size: 14, color: scheme.onSurfaceVariant),
                            tooltip: l.deleteComment,
                            onPressed: () => appDb.deleteComment(c.id),
                          ),
                        ],
                      ),
                    ),
                  // 评论输入框：点击入口才显示
                  if (_showInput) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: l.commentHint,
                              border: const OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send,
                              size: 18, color: scheme.primary),
                          tooltip: l.addComment,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        // 弱化的操作行：反应 + / 评论 +（点击展开对应输入）
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: l.addReaction,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  // 选单悬浮在点击位置
                  onTapUp: (d) => _showReactionPickerAt(d.globalPosition),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.add_reaction_outlined,
                        size: 16, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Tooltip(
                message: l.addComment,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() => _showInput = !_showInput),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.chat_bubble_outline,
                        size: 16, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 反应选单：悬浮在点击位置的小浮层（点空白处关闭，选中后关闭）
  void _showReactionPickerAt(Offset globalPosition) {
    _hideReactionPicker();
    final size = MediaQuery.sizeOf(context);
    // 横排 6 个 emoji 的估算尺寸
    const barWidth = 6 * 34.0 + 20;
    const barHeight = 46.0;
    var left = globalPosition.dx - barWidth / 2;
    left = left.clamp(8.0, size.width - barWidth - 8);
    var top = globalPosition.dy - barHeight - 8;
    if (top < 8) top = globalPosition.dy + 24;
    _pickerOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 点空白处关闭
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideReactionPicker,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(999),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ReactionBar(
                  onPick: (kind) {
                    appDb.addReaction(
                        thoughtId: widget.thoughtId, kind: kind);
                    _hideReactionPicker();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_pickerOverlay!);
  }

  void _hideReactionPicker() {
    _pickerOverlay?.remove();
    _pickerOverlay = null;
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    appDb.addComment(thoughtId: widget.thoughtId, content: text);
    _controller.clear();
    setState(() => _showInput = false);
  }
}

/// 卡片上的评论/反应预览：为空时整块隐藏，避免无谓占位
class _CommentReactionPreview extends StatefulWidget {
  const _CommentReactionPreview({required this.entryId});

  final int entryId;

  @override
  State<_CommentReactionPreview> createState() =>
      _CommentReactionPreviewState();
}

class _CommentReactionPreviewState extends State<_CommentReactionPreview> {
  StreamSubscription? _subReactions;
  StreamSubscription? _subComments;
  bool _hasAny = false;

  @override
  void initState() {
    super.initState();
    // 两个流分别监听：任一变化都重新检查是否为空
    _subReactions = appDb.watchReactionsFor(widget.entryId).listen((r) {
      appDb.watchCommentsFor(widget.entryId).first.then((c) {
        if (mounted) setState(() => _hasAny = r.isNotEmpty || c.isNotEmpty);
      });
    });
    _subComments = appDb.watchCommentsFor(widget.entryId).listen((c) {
      appDb.watchReactionsFor(widget.entryId).first.then((r) {
        if (mounted) setState(() => _hasAny = r.isNotEmpty || c.isNotEmpty);
      });
    });
  }

  @override
  void dispose() {
    _subReactions?.cancel();
    _subComments?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();
    return CommentReactionSection(thoughtId: widget.entryId);
  }
}

class _TagChipsLoader extends StatefulWidget {  const _TagChipsLoader({required this.entryId});

  final int entryId;

  @override
  State<_TagChipsLoader> createState() => _TagChipsLoaderState();
}

class _TagChipsLoaderState extends State<_TagChipsLoader> {
  List<TagWithCategory>? _tags;

  @override
  void initState() {
    super.initState();
    appDb.tagsFor(widget.entryId).then((tags) {
      if (mounted) setState(() => _tags = tags);
    });
  }

  @override
  Widget build(BuildContext context) {
    final normal = _tags
        ?.where((t) => t.isNormal)
        .map((t) => t.tag)
        .toList();
    if (normal == null || normal.isEmpty) return const SizedBox.shrink();
    return TagChips(tags: normal);
  }
}

Future<void> showEntryEditor(
  BuildContext context, {
  ThoughtEntry? existing,
  String? initialText,
  // 新建时的记录日（如从日历选中某天补记）；为空则今天
  String? initialDay,
}) async {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: existing?.content ?? initialText ?? '');
  // 记录日：补记/改日期共用；编辑已有思绪时沿用其日期
  var recordDay = existing != null
      ? DateTime.parse(existing.day)
      : (initialDay != null ? DateTime.parse(initialDay) : DateTime.now());
  var saved = false;
  // 已有标签（含所属高级标签组）
  final existingTags = existing == null
      ? <TagWithCategory>[]
      : List<TagWithCategory>.of(await appDb.tagsFor(existing.id));
  if (!context.mounted) return;
  // 高级标签组与各组选项
  final categories = await appDb.watchTagCategories().first;
  if (!context.mounted) return;
  final categoryOptions = <int, List<Tag>>{};
  for (final c in categories) {
    categoryOptions[c.id] = await appDb.categoryTags(c.id);
  }
  if (!context.mounted) return;
  // 普通标签（自由输入，多选）
  final normalTags = existingTags.where((t) => t.isNormal).map((t) => t.tag).toList();
  // 高级标签：本条思绪已添加的组 → 选中的值名称集合
  final appliedCategoryIds = <int>{
    if (existing != null) ...await appDb.thoughtCategoryIds(existing.id),
  };
  final selectedByCategory = <int, Set<String>>{};
  for (final t in existingTags) {
    final cid = t.category?.id;
    if (cid == null) continue;
    appliedCategoryIds.add(cid);
    selectedByCategory.putIfAbsent(cid, () => <String>{}).add(t.tag.name);
  }
  for (final cid in appliedCategoryIds) {
    selectedByCategory.putIfAbsent(cid, () => <String>{});
  }
  final tagController = TextEditingController();
  // 私密开关（编辑已有思绪时沿用其状态）
  var locked = existing?.locked ?? false;
  // 星标/收藏（编辑已有思绪时沿用其状态）
  var starred = existing?.starred ?? false;
  // 附件：kept 为已入库（可移除），pending 为本次新增（未入库）
  final existingAtts = existing == null
      ? const <Attachment>[]
      : List<Attachment>.of(
          await appDb.watchAttachmentsFor(existing.id).first,
        );
  if (!context.mounted) return;
  final kept = List<Attachment>.of(existingAtts);
  final pending = <_PendingAttachment>[];

  // 日历事件关联：类型（计数器除外）+ 已关联事件（编辑模式）
  final calTypes = (await appDb.watchEventTypes().first)
      .where((t) => !t.counter)
      .toList();
  if (!context.mounted) return;
  CalendarEvent? linkedEvent;
  if (existing != null) {
    linkedEvent = (await appDb.watchEvents().first)
        .where((e) => e.thoughtId == existing.id)
        .firstOrNull;
    if (!context.mounted) return;
  }
  // 保存后待创建的关联（新事件）
  int? pendingTypeId;
  bool pendingAnnual = false;
  // 新事件的默认状态（类型状态预设的第一个）
  int? pendingStatusId;
  // 保存后待关联的已有事件（仅限思绪当天的事件）
  int? pendingEventId;
  String? pendingEventTitle;
  // 私密思绪 id：事件标题遮罩（事件标题即所关联思绪的内容）
  final lockedThoughtIds = await appDb.watchLockedThoughtIds().first;
  if (!context.mounted) return;

  await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
      /// 选类型 → 新建事件 或 关联当天已有事件
      Future<void> pickLink() async {
        if (calTypes.isEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.noEventTypes)));
          return;
        }
        final type = await showModalBottomSheet<EventType>(
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
                for (final t in calTypes)
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
                              color:
                                  Color(t.color).withValues(alpha: 0.15),
                            ),
                            child: Text(
                              t.glyph!,
                              style: TextStyle(
                                  fontSize: 13, color: Color(t.color)),
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
        if (type == null || !context.mounted) return;
        // 思绪当天（取编辑器当前选定的记录日）
        final day = AppDatabase.formatDay(recordDay);
        // 当天已被该类型事件覆盖的（含每年循环与区间），仅这些可直接关联
        final year = DateTime.parse(day).year;
        final dayEvents = (await appDb.watchEvents().first)
            .where((e) =>
                e.typeId == type.id &&
                AppDatabase.eventDaysInYear(e, year).contains(day))
            .toList();
        if (!context.mounted) return;
        final picked = await showModalBottomSheet<Object>(
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
                // 新建事件
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(l.newEvent),
                  onTap: () => Navigator.pop(context, 'new'),
                ),
                // 当天已有事件
                if (dayEvents.isEmpty)
                  ListTile(
                    dense: true,
                    enabled: false,
                    title: Text(l.linkExistingHint),
                  ),
                for (final e in dayEvents)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                        eventDisplayTitle(e, type.name, lockedThoughtIds)),
                    subtitle: e.endDate == null
                        ? null
                        : Text('${e.startDate} ~ ${e.endDate}'),
                    onTap: () => Navigator.pop(context, e),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
        if (picked == null || !context.mounted) return;
        if (picked is CalendarEvent) {
          // 关联已有事件
          if (existing != null) {
            await appDb.linkEventToThought(picked.id, existing.id);
            linkedEvent = (await appDb.watchEvents().first)
                .firstWhere((e) => e.id == picked.id);
            setState(() {});
          } else {
            pendingEventId = picked.id;
            pendingEventTitle = picked.title ?? type.name;
            setState(() {});
          }
          return;
        }
        // 新建事件：生日类型默认每年循环；状态默认取类型状态预设的第一个
        final annual = await _promptAnnual(
          context,
          initial: type.kind == EventTypeKind.birthday,
        );
        if (annual == null || !context.mounted) return;
        final typeStatuses = await appDb.statusesFor(type.id);
        if (!context.mounted) return;
        pendingTypeId = type.id;
        pendingAnnual = annual;
        pendingStatusId =
            typeStatuses.isEmpty ? null : typeStatuses.first.id;
        setState(() {});
      }

      // 编辑器内可见的全部图片（已入库 + 待新增），供查看器翻页
      final keptImages =
          kept.where((k) => k.kind == AttachmentKind.image).toList();
      final pendingImages =
          pending.where((p) => p.kind == AttachmentKind.image).toList();
      final imageItems = [
        for (final a in keptImages) ImageViewerItem.attachment(a.id),
        for (final p in pendingImages) ImageViewerItem.bytes(p.bytes),
      ];

        return AlertDialog(
          title: Row(
            children: [
              Text(existing == null ? l.newThought : l.editThought),
              const Spacer(),
              // 星标/收藏：保存时写库
              IconButton(
                icon: Icon(
                  starred ? Icons.star : Icons.star_border,
                  color: starred ? Colors.amber : null,
                ),
                tooltip: starred ? l.unstar : l.star,
                onPressed: () => setState(() => starred = !starred),
              ),
              // 删除藏在标题栏：图标形式，确认后关闭编辑器
              if (existing != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: l.delete,
                  onPressed: () async {
                    final deleted = await trashEntry(context, existing);
                    if (deleted && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: controller,
                  autofocus: existing == null,
                  maxLines: 6,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: l.thoughtHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                // 模板：从预设文本一键插入（如"今日三问"）
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.article_outlined, size: 18),
                    label: Text(l.insertTemplate),
                    onPressed: () => _pickTemplate(
                        context, controller, () => setState(() {})),
                  ),
                ),
                const SizedBox(height: 4),
                // 记录日：可补记为过去某天，或修改已有记录的日期
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(l.recordDay,
                        style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                      label: Text(
                        MaterialLocalizations.of(context)
                            .formatMediumDate(recordDay),
                      ),
                      onPressed: () async {
                        final today = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              recordDay.isAfter(today) ? today : recordDay,
                          firstDate: DateTime(2000),
                          lastDate: today,
                        );
                        if (picked == null || !context.mounted) return;
                        setState(() => recordDay = DateTime(
                            picked.year, picked.month, picked.day));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ---------- 高级标签：按需添加标签组，组内单选/多选 ----------
                Row(
                  children: [
                    Text(l.advancedTagsSection,
                        style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _pickCategory(
                        context,
                        categories: categories,
                        applied: appliedCategoryIds,
                        onPicked: (cid) => setState(() {
                          appliedCategoryIds.add(cid);
                          selectedByCategory.putIfAbsent(cid, () => <String>{});
                        }),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.addTagCategory),
                    ),
                  ],
                ),
                if (appliedCategoryIds.isEmpty)
                  Text(
                    l.advancedTagsEmpty,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                else
                  for (final c in categories
                      .where((c) => appliedCategoryIds.contains(c.id)))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CategoryIcon(
                                category: c,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                                fallback: Icons.label_outline,
                              ),
                              const SizedBox(width: 6),
                              Text(c.name,
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                              const SizedBox(width: 6),
                              Text(
                                c.multi ? l.categoryMulti : l.categorySingle,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.add, size: 18),
                                tooltip: l.addOption,
                                onPressed: () async {
                                  final name = await _promptText(
                                    context,
                                    title: l.addOption,
                                  );
                                  if (name == null || name.trim().isEmpty) {
                                    return;
                                  }
                                  await appDb.getOrCreateTag(
                                    name,
                                    categoryId: c.id,
                                    color: c.color,
                                  );
                                  final options =
                                      await appDb.categoryTags(c.id);
                                  if (!context.mounted) return;
                                  setState(() {
                                    categoryOptions[c.id] = options;
                                    selectedByCategory[c.id]!
                                        .add(name.trim());
                                  });
                                },
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: l.removeTagCategory,
                                onPressed: () => setState(() {
                                  appliedCategoryIds.remove(c.id);
                                  selectedByCategory.remove(c.id);
                                }),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final option
                                  in categoryOptions[c.id] ?? const <Tag>[])
                                c.multi
                                    ? FilterChip(
                                        label: Text(option.name),
                                        selected: selectedByCategory[c.id]!
                                            .contains(option.name),
                                        onSelected: (sel) => setState(() {
                                          if (sel) {
                                            selectedByCategory[c.id]!
                                                .add(option.name);
                                          } else {
                                            selectedByCategory[c.id]!
                                                .remove(option.name);
                                          }
                                        }),
                                      )
                                    : ChoiceChip(
                                        label: Text(option.name),
                                        selected: selectedByCategory[c.id]!
                                            .contains(option.name),
                                        onSelected: (sel) => setState(() {
                                          selectedByCategory[c.id]!.clear();
                                          if (sel) {
                                            selectedByCategory[c.id]!
                                                .add(option.name);
                                          }
                                        }),
                                      ),
                            ],
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 12),
                Text(l.tagHint, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                if (normalTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final t in normalTags)
                          InputChip(
                            label: Text('#${t.name}'),
                            visualDensity: VisualDensity.compact,
                            onDeleted: () =>
                                setState(() => normalTags.remove(t)),
                          ),
                      ],
                    ),
                  ),
                TextField(
                  controller: tagController,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: l.tagAdd,
                      onPressed: () => _addTagsFromField(
                          tagController, normalTags, () => setState(() {})),
                    ),
                  ),
                  onSubmitted: (_) => _addTagsFromField(
                      tagController, normalTags, () => setState(() {})),
                ),
                const SizedBox(height: 12),
                // 私密：上锁的思绪不参与搜索，查看需先解锁
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  secondary: Icon(
                    locked ? Icons.lock : Icons.lock_open_outlined,
                    color: locked ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(l.lockPrivate),
                  value: locked,
                  onChanged: (v) => setState(() => locked = v),
                ),
                const SizedBox(height: 12),
                // 关联到日历：事件以该思绪为载体（万物皆思绪，可选）
                Row(
                  children: [
                    Text(l.calendarLink,
                        style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    if (linkedEvent == null &&
                        pendingTypeId == null &&
                        pendingEventId == null)
                      Tooltip(
                        message: l.addToCalendar,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: pickLink,
                          child: const Icon(Icons.add_link, size: 20),
                        ),
                      ),
                  ],
                ),
                if (linkedEvent != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: InputChip(
                      avatar: const Icon(Icons.link, size: 16),
                      label: Text(
                        linkedEvent!.title ??
                            (calTypes
                                    .where((t) => t.id == linkedEvent!.typeId)
                                    .firstOrNull
                                    ?.name ??
                                l.dayEventsLabel),
                      ),
                      visualDensity: VisualDensity.compact,
                      onDeleted: () async {
                        await appDb.unlinkEventFromThought(existing!.id);
                        linkedEvent = null;
                        setState(() {});
                      },
                    ),
                  )
                else if (pendingEventId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: InputChip(
                      avatar: const Icon(Icons.link, size: 16),
                      label: Text(pendingEventTitle ?? l.dayEventsLabel),
                      visualDensity: VisualDensity.compact,
                      onDeleted: () =>
                          setState(() => pendingEventId = null),
                    ),
                  )
                else if (pendingTypeId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: InputChip(
                      avatar: const Icon(Icons.event_outlined, size: 16),
                      label: Text(
                        '${calTypes.where((t) => t.id == pendingTypeId).firstOrNull?.name ?? ''}'
                        '${pendingAnnual ? ' · ${l.annualRecur}' : ''}',
                      ),
                      visualDensity: VisualDensity.compact,
                      onDeleted: () =>
                          setState(() => pendingTypeId = null),
                    ),
                  ),
                const SizedBox(height: 12),
                // 附件：图片（选择）+ 音频（录音）
                Row(
                  children: [
                    Text(l.attachments,
                        style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    Tooltip(
                      message: l.addImage,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _pickImages(
                            context, pending, () => setState(() {})),
                        child: const Icon(Icons.photo_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Tooltip(
                      message: l.recordAudio,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _recordAudio(
                            context, pending, () => setState(() {})),
                        child: const Icon(Icons.mic_none_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
                if (kept.isNotEmpty || pending.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in kept)
                        if (a.kind == AttachmentKind.image)
                          AttachmentImageThumb(
                            attachment: a,
                            size: 72,
                            onTap: () => showImageViewer(
                              context,
                              imageItems,
                              initialIndex: keptImages.indexOf(a),
                            ),
                            onRemove: () => setState(() => kept.remove(a)),
                          )
                        else
                          AudioChip(
                            attachment: a,
                            onDeleted: () => setState(() => kept.remove(a)),
                          ),
                      for (final p in pending)
                        if (p.kind == AttachmentKind.image)
                          PendingImageThumb(
                            bytes: p.bytes,
                            onTap: () => showImageViewer(
                              context,
                              imageItems,
                              initialIndex:
                                  keptImages.length + pendingImages.indexOf(p),
                            ),
                            onRemove: () => setState(() => pending.remove(p)),
                          )
                        else
                          PendingAudioChip(
                            bytes: p.bytes,
                            mime: p.mime,
                            playKey: p.playKey,
                            durationMs: p.durationMs ?? 0,
                            onRemove: () => setState(() => pending.remove(p)),
                          ),
                    ],
                  ),
                ],
                // 评论与反应：仅已保存的思绪（新思绪保存后再来）
                if (existing != null) ...[
                  const SizedBox(height: 16),
                  Text(l.commentsLabel,
                      style: Theme.of(context).textTheme.labelLarge),
                  CommentReactionSection(thoughtId: existing.id),
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
              onPressed: () async {
                _addTagsFromField(tagController, normalTags, () {});
                final text = controller.text.trim();
                if (text.isEmpty) return;
                final dayStr = AppDatabase.formatDay(recordDay);
                var thoughtId = existing?.id;
                if (existing == null) {
                  thoughtId = await appDb.insertThought(
                    content: text,
                    day: dayStr,
                    locked: locked,
                  );
                } else {
                  await appDb.updateThought(
                    existing.id,
                    text,
                    day: existing.day == dayStr ? null : dayStr,
                  );
                  if (existing.locked != locked) {
                    await appDb.setThoughtLocked(existing.id, locked);
                  }
                }
                if ((existing?.starred ?? false) != starred) {
                  await appDb.setThoughtStarred(thoughtId!, starred);
                }
                // 普通标签：整体替换
                await appDb.setThoughtNormalTags(
                  thoughtId!,
                  normalTags.map((t) => t.name).toList(),
                );
                // 高级标签：移除不再添加的组，写入各组的选中值
                final previousCategories = existing == null
                    ? <int>{}
                    : await appDb.thoughtCategoryIds(thoughtId);
                for (final cid
                    in previousCategories.difference(appliedCategoryIds)) {
                  await appDb.removeThoughtCategory(thoughtId, cid);
                }
                for (final cid in appliedCategoryIds) {
                  await appDb.addThoughtCategory(thoughtId, cid);
                  await appDb.setThoughtCategoryTags(
                    thoughtId,
                    cid,
                    selectedByCategory[cid]?.toList() ?? const [],
                  );
                }
                // 附件：删除被移除的已入库项，追加本次新增
                for (final a in existingAtts) {
                  if (!kept.any((k) => k.id == a.id)) {
                    await appDb.deleteAttachment(a.id);
                  }
                }
                for (final p in pending) {
                  await appDb.insertAttachment(
                    thoughtId: thoughtId,
                    kind: p.kind,
                    mime: p.mime,
                    bytes: p.bytes,
                    durationMs: p.durationMs,
                  );
                }
                // 新建的日历关联：新建事件 或 关联当天已有事件
                if (pendingTypeId != null) {
                  await appDb.insertEvent(
                    typeId: pendingTypeId!,
                    startDate: dayStr,
                    annual: pendingAnnual,
                    title: text,
                    statusId: pendingStatusId,
                    thoughtId: thoughtId,
                  );
                } else if (pendingEventId != null) {
                  await appDb.linkEventToThought(pendingEventId!, thoughtId);
                }
                saved = true;
                if (context.mounted) Navigator.pop(context, true);
              },
              child: Text(l.save),
            ),
          ],
        );
      },
    ),
  );
  controller.dispose();
  tagController.dispose();
  if (saved && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.saved)));
  }
}

/// 询问"每年循环"（返回 null = 取消）
Future<bool?> _promptAnnual(
  BuildContext context, {
  required bool initial,
}) async {
  final l = AppLocalizations.of(context)!;
  var annual = initial;
  return showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l.addToCalendar),
        content: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.annualRecur),
          value: annual,
          onChanged: (v) => setState(() => annual = v),
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
}

void _addTagsFromField(
  TextEditingController controller,
  List<Tag> tags,
  VoidCallback onChanged,
) {  final parts =
      controller.text.split(RegExp(r'[\s,，]+')).where((p) => p.trim().isNotEmpty);
  for (final part in parts) {
    final name = part.trim();
    if (!tags.any((t) => t.name == name)) {
        tags.add(Tag(
          id: -1,
          name: name,
          icon: null,
          glyph: null,
          color: null,
          createdAt: DateTime.now(),
        ));
    }
  }
  controller.clear();
  onChanged();
}

/// 选择模板插入：列出模板，点选即插入文本；底部可进入模板管理
Future<void> _pickTemplate(
  BuildContext context,
  TextEditingController controller,
  VoidCallback onChanged,
) async {
  final l = AppLocalizations.of(context)!;
  final templates = await appDb.watchEntryTemplates().first;
  if (!context.mounted) return;
  final picked = await showModalBottomSheet<Object>(
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
                l.pickTemplate,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          if (templates.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.templatesEmpty,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final t in templates)
                    ListTile(
                      leading: const Icon(Icons.article_outlined),
                      title: Text(t.name),
                      subtitle: Text(
                        t.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.pop(context, t),
                    ),
                ],
              ),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l.manageTemplates),
            onTap: () => Navigator.pop(context, 'manage'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (picked == null || !context.mounted) return;
  if (picked is EntryTemplate) {
    _insertTemplateText(controller, picked.content);
    onChanged();
  } else if (picked == 'manage') {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TemplatesPage()),
    );
  }
}

/// 把模板文本插入到光标处；输入框为空则直接填入
void _insertTemplateText(TextEditingController controller, String content) {
  final text = controller.text;
  if (text.trim().isEmpty) {
    controller.text = content;
    controller.selection = TextSelection.collapsed(offset: content.length);
    return;
  }
  final selection = controller.selection;
  final offset = selection.isValid ? selection.start : text.length;
  final before = text.substring(0, offset);
  final after = text.substring(offset);
  final separator = before.isEmpty || before.endsWith('\n') ? '' : '\n';
  final inserted = '$separator$content';
  controller.text = '$before$inserted$after';
  controller.selection =
      TextSelection.collapsed(offset: before.length + inserted.length);
}

/// 选择要添加到这条思绪的高级标签组（已添加的不再列出）
Future<void> _pickCategory(
  BuildContext context, {
  required List<TagCategory> categories,
  required Set<int> applied,
  required ValueChanged<int> onPicked,
}) async {
  final l = AppLocalizations.of(context)!;
  final available =
      categories.where((c) => !applied.contains(c.id)).toList();
  if (available.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.allTagCategoriesAdded)));
    return;
  }
  final picked = await showModalBottomSheet<TagCategory>(
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
                l.addTagCategory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          for (final c in available)
            ListTile(
              leading: CategoryIcon(
                category: c,
                size: 22,
                fallback: Icons.label_outline,
              ),
              title: Text(c.name),
              subtitle: Text(
                c.multi ? l.categoryMulti : l.categorySingle,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              onTap: () => Navigator.pop(context, c),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (picked == null) return;
  onPicked(picked.id);
}

/// 编辑器中的待新增附件
class _PendingAttachment {
  static int _seq = 0;

  _PendingAttachment({
    required this.bytes,
    required this.mime,
    required this.kind,
    this.durationMs,
  }) : playKey = 'pending-${_seq++}';

  final Uint8List bytes;
  final String mime;
  final AttachmentKind kind;
  final int? durationMs;

  /// 播放器键（未入库附件的试听预览）
  final String playKey;
}

/// 选择图片（可多选）加入 pending；超限提示并跳过
Future<void> _pickImages(
  BuildContext context,
  List<_PendingAttachment> pending,
  VoidCallback onChanged,
) async {
  final l = AppLocalizations.of(context)!;
  try {
    final files = await openFiles(
      acceptedTypeGroups: const [
        // macOS 的 UTType 不支持 'image/*' 通配（会令全部文件变灰），
        // 桌面用扩展名/UTI，Web 用具体 MIME
        XTypeGroup(
          label: 'Images',
          extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'],
          uniformTypeIdentifiers: ['public.image'],
          mimeTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
        ),
      ],
    );
    if (files.isEmpty) return;
    for (final f in files) {
      final bytes = await f.readAsBytes();
      if (bytes.lengthInBytes > kMaxAttachmentBytes) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.attachmentTooLarge)),
          );
        }
        continue;
      }
      pending.add(_PendingAttachment(
        bytes: bytes,
        mime: guessImageMime(f.mimeType, f.name),
        kind: AttachmentKind.image,
      ));
    }
    onChanged();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.opFailed)));
    }
  }
}

/// 录音加入 pending
Future<void> _recordAudio(
  BuildContext context,
  List<_PendingAttachment> pending,
  VoidCallback onChanged,
) async {
  final l = AppLocalizations.of(context)!;
  final rec = await showAudioRecorder(context);
  if (rec == null || !context.mounted) return;
  if (rec.bytes.lengthInBytes > kMaxAttachmentBytes) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.attachmentTooLarge)));
    return;
  }
  pending.add(_PendingAttachment(
    bytes: rec.bytes,
    mime: 'audio/mp4',
    kind: AttachmentKind.audio,
    durationMs: rec.durationMs,
  ));
  onChanged();
}

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  String? initial,
}) async {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initial ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(l.save),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// 长按操作表：归档 / 删除（回收站内的条目则为 恢复 / 永久删除）
Future<void> showEntryActions(BuildContext context, ThoughtEntry entry) async {
  // 私密条目：打开操作表前先解锁
  if (entry.locked) {
    final ok = await showLockVerify(context);
    if (!ok || !context.mounted) return;
  }
  final l = AppLocalizations.of(context)!;
  final scheme = Theme.of(context).colorScheme;
  final isTrashed = entry.deletedAt != null;
  final isArchived = entry.archivedAt != null;
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTrashed) ...[
            ListTile(
              leading: const Icon(Icons.restore),
              title: Text(l.restore),
              onTap: () {
                Navigator.pop(sheetContext);
                appDb.restoreThought(entry.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: scheme.error),
              title: Text(l.deleteForever,
                  style: TextStyle(color: scheme.error)),
              onTap: () {
                Navigator.pop(sheetContext);
                confirmDelete(context, entry);
              },
            ),
          ] else ...[
            ListTile(
              leading: Icon(
                  isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
              title: Text(isArchived ? l.unarchive : l.archive),
              onTap: () {
                Navigator.pop(sheetContext);
                if (isArchived) {
                  appDb.unarchiveThought(entry.id);
                } else {
                  appDb.archiveThought(entry.id);
                }
              },
            ),
            ListTile(
              leading: Icon(
                  entry.starred ? Icons.star : Icons.star_border),
              title: Text(entry.starred ? l.unstar : l.star),
              onTap: () {
                Navigator.pop(sheetContext);
                appDb.setThoughtStarred(entry.id, !entry.starred);
              },
            ),
            ListTile(
              leading: Icon(
                  entry.locked ? Icons.lock_open : Icons.lock_outline),
              title: Text(entry.locked ? l.lockUnlockEntry : l.lockPrivate),
              onTap: () {
                Navigator.pop(sheetContext);
                appDb.setThoughtLocked(entry.id, !entry.locked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l.moveToTrash),
              onTap: () {
                Navigator.pop(sheetContext);
                trashEntry(context, entry);
              },
            ),
          ],
        ],
      ),
    ),
  );
}

/// 删除 = 移入回收站（可撤销；超过保留期自动永久清除）。
/// 私密条目需先解锁
Future<bool> trashEntry(BuildContext context, ThoughtEntry entry) async {
  if (entry.locked) {
    final ok = await showLockVerify(context);
    if (!ok || !context.mounted) return false;
  }
  final l = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  await appDb.trashThought(entry.id);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(l.movedToTrash),
      action: SnackBarAction(
        label: l.undo,
        onPressed: () => appDb.restoreThought(entry.id),
      ),
    ),
  );
  return true;
}

/// 永久删除确认（回收站内）；返回是否确实删除。私密条目需先解锁
Future<bool> confirmDelete(BuildContext context, ThoughtEntry entry) async {
  if (entry.locked) {
    final ok = await showLockVerify(context);
    if (!ok || !context.mounted) return false;
  }
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.deleteForever),
      content: Text(l.deleteForeverBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.deleteForever),
        ),
      ],
    ),
  );
  if (ok == true) {
    await appDb.deleteThought(entry.id);
  }
  return ok == true;
}
