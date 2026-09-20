import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/database_provider.dart';
import '../data/tag_presets.dart';
import '../data/thoughts_table.dart';
import '../l10n/app_localizations.dart';
import 'attachment_widgets.dart';
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

  /// 标签列表（含心情标签）；为 null 时自动加载
  final List<Tag>? tags;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = entry.createdAtLocal;
    final mood = tags
        ?.where((t) => t.tagKind == TagKind.mood)
        .fold<Tag?>(null, (prev, t) => prev ?? t);
    final normalTags =
        tags?.where((t) => t.tagKind == TagKind.normal).toList() ?? const [];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectionArea(
                child: Text(
                  entry.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              AttachmentStrip(thoughtId: entry.id),
              if (normalTags.isNotEmpty) TagChips(tags: normalTags),
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

class _TagChipsLoader extends StatefulWidget {
  const _TagChipsLoader({required this.entryId});

  final int entryId;

  @override
  State<_TagChipsLoader> createState() => _TagChipsLoaderState();
}

class _TagChipsLoaderState extends State<_TagChipsLoader> {
  List<Tag>? _tags;

  @override
  void initState() {
    super.initState();
    appDb.tagsFor(widget.entryId).then((tags) {
      if (mounted) setState(() => _tags = tags);
    });
  }

  @override
  Widget build(BuildContext context) {
    final normal = _tags?.where((t) => t.tagKind == TagKind.normal).toList();
    if (normal == null || normal.isEmpty) return const SizedBox.shrink();
    return TagChips(tags: normal);
  }
}

Future<void> showEntryEditor(
  BuildContext context, {
  ThoughtEntry? existing,
  String? initialText,
}) async {
  final l = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: existing?.content ?? initialText ?? '');
  var saved = false;
  final allTags = existing == null
      ? <Tag>[]
      : List<Tag>.of(await appDb.tagsFor(existing.id));
  if (!context.mounted) return;
  final moodTags = await appDb.moodTags();
  if (!context.mounted) return;
  // 该思绪的心情标签若已被删除，仍保留在选项里供本次保存
  for (final t in allTags) {
    if (t.tagKind == TagKind.mood && !moodTags.any((m) => m.id == t.id)) {
      moodTags.add(t);
    }
  }
  final tagController = TextEditingController();
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
  // 新建思绪保存后待创建的关联
  int? pendingTypeId;
  bool pendingAnnual = false;

  await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
      var mood = allTags
          .where((t) => t.tagKind == TagKind.mood)
          .fold<Tag?>(null, (prev, t) => prev ?? t);
      final normalTags =
          allTags.where((t) => t.tagKind == TagKind.normal).toList();
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
          title: Text(existing == null ? l.newThought : l.editThought),
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
                const SizedBox(height: 12),
                // 心情：特殊标签，单选；可即时新建心情标签
                Row(
                  children: [
                    Text(l.moodLabel, style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    Tooltip(
                      message: l.createMoodTag,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final name = await _promptText(
                            context,
                            title: l.createMoodTag,
                          );
                          if (name == null || name.trim().isEmpty) return;
                          final tag = await appDb.getOrCreateTag(
                            name,
                            kind: TagKind.mood,
                            icon: moodPresets.first.icon.codePoint,
                            color: moodPresets.first.color,
                          );
                          allTags.removeWhere((t) => t.id == tag.id);
                          allTags.add(tag);
                          setState(() {});
                        },
                        child: const Icon(Icons.add, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final m in moodTags)
                      ChoiceChip(
                        label: Text(m.name),
                        selected: mood?.id == m.id,
                        avatar: TagIcon(
                          tag: m,
                          size: 16,
                          fallback: Icons.mood,
                        ),
                        onSelected: (sel) {
                          allTags.removeWhere((t) => t.tagKind == TagKind.mood);
                          if (sel) allTags.add(m);
                          setState(() {});
                        },
                      ),
                  ],
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
                                setState(() => allTags.remove(t)),
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
                          tagController, allTags, () => setState(() {})),
                    ),
                  ),
                  onSubmitted: (_) => _addTagsFromField(
                      tagController, allTags, () => setState(() {})),
                ),
                const SizedBox(height: 12),
                // 关联到日历：事件以该思绪为载体（万物皆思绪，可选）
                Row(
                  children: [
                    Text(l.calendarLink,
                        style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    if (linkedEvent == null && pendingTypeId == null)
                      Tooltip(
                        message: l.addToCalendar,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            if (calTypes.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.noEventTypes)),
                              );
                              return;
                            }
                            final picked =
                                await showModalBottomSheet<EventType>(
                              context: context,
                              builder: (context) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 16, 16, 4),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          l.pickTypeTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ),
                                    for (final t in calTypes)
                                      ListTile(
                                        leading: t.glyph == null ||
                                                t.glyph!.isEmpty
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
                                                  color: Color(t.color)
                                                      .withValues(
                                                          alpha: 0.15),
                                                ),
                                                child: Text(
                                                  t.glyph!,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Color(t.color)),
                                                ),
                                              ),
                                        title: Text(t.name),
                                        onTap: () =>
                                            Navigator.pop(context, t),
                                      ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            );
                            if (picked == null || !context.mounted) return;
                            // 生日类型默认每年循环
                            final annual = await _promptAnnual(
                              context,
                              initial: picked.kind ==
                                  EventTypeKind.birthday,
                            );
                            if (annual == null || !context.mounted) return;
                            pendingTypeId = picked.id;
                            pendingAnnual = annual;
                            setState(() {});
                          },
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
                _addTagsFromField(tagController, allTags, () {});
                final text = controller.text.trim();
                if (text.isEmpty) return;
                var thoughtId = existing?.id;
                if (existing == null) {
                  thoughtId = await appDb.insertThought(
                    content: text,
                    day: AppDatabase.today(),
                  );
                } else {
                  await appDb.updateThought(existing.id, text);
                }
                await appDb.setThoughtTags(
                  thoughtId!,
                  allTags.map((t) => t.name).toList(),
                );
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
                // 新建的日历关联：事件以该思绪为载体
                if (pendingTypeId != null) {
                  await appDb.insertEvent(
                    typeId: pendingTypeId!,
                    startDate: existing?.day ?? AppDatabase.today(),
                    annual: pendingAnnual,
                    title: text,
                    thoughtId: thoughtId,
                  );
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
          kind: TagKind.normal.value,
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

Future<void> confirmDelete(BuildContext context, ThoughtEntry entry) async {
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.confirmDeleteTitle),
      content: Text(l.confirmDeleteBody),
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
          child: Text(l.delete),
        ),
      ],
    ),
  );
  if (ok == true) {
    await appDb.deleteThought(entry.id);
  }
}
