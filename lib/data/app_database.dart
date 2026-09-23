import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tag_presets.dart';
import 'thoughts_table.dart';

part 'app_database.g.dart';

/// Material Icons 使用 Unicode 私用区（0xE000-0xF8FF）；区外码点视为 emoji
bool isEmojiCodepoint(int codePoint) =>
    codePoint < 0xE000 || codePoint > 0xF8FF;

@DriftDatabase(tables: [
  Thoughts,
  EntryTemplates,
  TagCategories,
  Tags,
  ThoughtTags,
  ThoughtCategories,
  Attachments,
  AttachmentBlobs,
  Comments,
  Reactions,
  EventTypes,
  EventStatuses,
  CalendarEvents,
])
class AppDatabase extends _$AppDatabase {
  /// [name] 同时用作原生库文件名与 Web 端 IndexedDB 库名；
  /// 不同 name 即不同 vault，数据完全隔离
  AppDatabase({String name = 'roost'}) : super(_open(name));

  AppDatabase.connect(super.connection);

  @override
  int get schemaVersion => 17;

  /// 回收站保留天数：超期由 [purgeExpiredTrash] 永久清除
  static const int trashRetentionDays = 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // 不做兼容迁移：版本不一致即丢弃全部业务表后重建
        onUpgrade: _wipeRebuild,
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // 仅新建或升级（清空重建）后播种；用户删除的预设不会被重新种回
          final needsSeed = details.wasCreated ||
              (details.versionBefore != null &&
                  details.versionBefore != details.versionNow);
          if (needsSeed) await _seedMoodCategory();
        },
      );

  /// 丢弃全部业务表（版本无关于历史结构）后重建
  Future<void> _wipeRebuild(Migrator m, int from, int to) async {
    await customStatement('PRAGMA foreign_keys = OFF');
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get();
    for (final row in rows) {
      final name = row.read<String>('name');
      if (name.startsWith('sqlite_')) continue;
      await customStatement('DROP TABLE IF EXISTS "$name"');
    }
    await customStatement('PRAGMA foreign_keys = ON');
    await m.createAll();
  }

  /// 播种内置"心情"高级标签组及其预设选项（不可删除）
  Future<void> _seedMoodCategory() async {
    final categoryName = seedUseChinese ? '心情' : 'Mood';
    final existing = await (select(tagCategories)
          ..where((c) => c.builtin.equals(true)))
        .getSingleOrNull();
    final categoryId = existing?.id ??
        await into(tagCategories).insert(
          TagCategoriesCompanion.insert(
            name: categoryName,
            builtin: const Value(true),
          ),
        );
    for (final preset in moodPresets) {
      final presetName = seedUseChinese ? preset.nameZh : preset.nameEn;
      final dup = await (select(tags)
            ..where((t) =>
                t.name.equals(presetName) & t.categoryId.equals(categoryId)))
          .getSingleOrNull();
      if (dup != null) continue;
      await into(tags).insert(
        TagsCompanion.insert(
          name: presetName,
          categoryId: Value(categoryId),
          icon: Value(preset.icon.codePoint),
          color: Value(preset.color),
        ),
      );
    }
  }

  /// 健康检查：quick_check 通过且业务表可读。文件损坏、表结构不匹配均视为异常
  Future<bool> isHealthy() async {
    try {
      final rows = await customSelect('PRAGMA quick_check').get();
      final ok = rows.isNotEmpty && rows.first.read<String>('quick_check') == 'ok';
      if (!ok) return false;
      await select(tags).get();
      await select(tagCategories).get();
      await select(entryTemplates).get();
      await select(thoughtCategories).get();
      await select(thoughts).get();
      await select(eventTypes).get();
      await select(eventStatuses).get();
      await select(calendarEvents).get();
      await select(comments).get();
      await select(reactions).get();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 插入附件：元数据 + 二进制一次事务写入，返回附件元数据
  Future<Attachment> insertAttachment({
    required int thoughtId,
    required AttachmentKind kind,
    required String mime,
    required List<int> bytes,
    int? durationMs,
  }) async {
    return transaction(() async {
      final id = await into(attachments).insert(
        AttachmentsCompanion.insert(
          thoughtId: thoughtId,
          kind: kind,
          mime: mime,
          durationMs: Value(durationMs),
          sizeBytes: bytes.length,
        ),
      );
      await into(attachmentBlobs).insert(
        AttachmentBlobsCompanion.insert(
          attachmentId: Value(id),
          data: Uint8List.fromList(bytes),
        ),
      );
      return (select(attachments)..where((a) => a.id.equals(id))).getSingle();
    });
  }

  /// 某条思绪的附件（元数据，按插入顺序）
  Stream<List<Attachment>> watchAttachmentsFor(int thoughtId) {
    return (select(attachments)
          ..where((a) => a.thoughtId.equals(thoughtId))
          ..orderBy([(a) => OrderingTerm.asc(a.id)]))
        .watch();
  }

  /// 全部附件按思绪分组（thoughtId → 附件列表），供列表页使用
  Stream<Map<int, List<Attachment>>> watchAllAttachmentMeta() {
    return select(attachments).watch().map((rows) {
      final map = <int, List<Attachment>>{};
      for (final r in rows) {
        map.putIfAbsent(r.thoughtId, () => []).add(r);
      }
      return map;
    });
  }

  /// 读取附件二进制（仅展示/播放时调用）
  Future<List<int>?> attachmentData(int id) async {
    final row = await (select(attachmentBlobs)
            ..where((b) => b.attachmentId.equals(id)))
        .getSingleOrNull();
    return row?.data;
  }

  /// 删除附件（blob 由外键级联删除）
  Future<void> deleteAttachment(int id) async {
    await (delete(attachments)..where((a) => a.id.equals(id))).go();
  }

  /// 清空全部业务数据并恢复预设心情
  Future<void> resetAllData() async {
    await transaction(() async {
      await customStatement('DELETE FROM attachment_blobs');
      await customStatement('DELETE FROM attachments');
      await customStatement('DELETE FROM thought_tags');
      await customStatement('DELETE FROM comments');
      await customStatement('DELETE FROM reactions');
      await customStatement('DELETE FROM calendar_events');
      await customStatement('DELETE FROM event_statuses');
      await customStatement('DELETE FROM event_types');
      await customStatement('DELETE FROM thoughts');
      await customStatement('DELETE FROM thought_categories');
      await customStatement('DELETE FROM tags');
      await customStatement('DELETE FROM tag_categories');
      await customStatement('DELETE FROM entry_templates');
    });
    await _seedMoodCategory();
  }

  /// 重置心情标签组：删除内置组下全部选项（联结级联清理），恢复预设
  Future<void> resetMoodTags() async {
    final cat = await (select(tagCategories)
          ..where((c) => c.builtin.equals(true)))
        .getSingleOrNull();
    if (cat != null) {
      await (delete(tags)..where((t) => t.categoryId.equals(cat.id))).go();
    }
    await _seedMoodCategory();
  }

  // ---------- 写作模板 ----------

  /// 全部模板（按 sortOrder、id）
  Stream<List<EntryTemplate>> watchEntryTemplates() {
    return (select(entryTemplates)..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.id),
        ]))
        .watch();
  }

  Future<List<EntryTemplate>> _orderedTemplates() {
    return (select(entryTemplates)..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.id),
        ]))
        .get();
  }

  /// 新建模板（追加到末尾）
  Future<int> createEntryTemplate({
    required String name,
    required String content,
  }) async {
    final list = await _orderedTemplates();
    return into(entryTemplates).insert(
      EntryTemplatesCompanion.insert(
        name: name,
        content: content,
        sortOrder: Value(list.length),
      ),
    );
  }

  Future<void> updateEntryTemplate(
    int id, {
    required String name,
    required String content,
  }) {
    return (update(entryTemplates)..where((t) => t.id.equals(id))).write(
      EntryTemplatesCompanion(
        name: Value(name),
        content: Value(content),
      ),
    );
  }

  Future<void> deleteEntryTemplate(int id) {
    return (delete(entryTemplates)..where((t) => t.id.equals(id))).go();
  }

  /// 上移/下移：delta 为 -1 / +1，与相邻模板交换顺序后重排 sortOrder
  Future<void> moveEntryTemplate(int id, int delta) async {
    final list = await _orderedTemplates();
    final index = list.indexWhere((t) => t.id == id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= list.length) return;
    final reordered = [...list];
    reordered.insert(target, reordered.removeAt(index));
    await transaction(() async {
      for (var i = 0; i < reordered.length; i++) {
        await (update(entryTemplates)
              ..where((t) => t.id.equals(reordered[i].id)))
            .write(EntryTemplatesCompanion(sortOrder: Value(i)));
      }
    });
  }

  /// 完整导出为纯数据结构（文件读写交给 UI 层）。
  /// links 以思绪在 thoughts 数组中的下标 + 标签名表达联结关系；
  /// attachments 同样以思绪下标表达，data 为 base64。
  Future<Map<String, dynamic>> exportData() async {
    final thoughtRows = await select(thoughts).get();
    final categoryRows = await select(tagCategories).get();
    final tagRows = await select(tags).get();
    final linkRows = await select(thoughtTags).get();
    final thoughtCategoryRows = await select(thoughtCategories).get();
    final attachmentRows = await select(attachments).get();
    final blobRows = await select(attachmentBlobs).get();
    final commentRows = await select(comments).get();
    final reactionRows = await select(reactions).get();
    final typeRows = await select(eventTypes).get();
    final statusRows = await select(eventStatuses).get();
    final eventRows = await select(calendarEvents).get();
    final templateRows = await _orderedTemplates();
    final tagNameById = {for (final t in tagRows) t.id: t.name};
    final categoryIndexById = <int, int>{
      for (var i = 0; i < categoryRows.length; i++) categoryRows[i].id: i,
    };
    // 标签 → 所属组在 tagCategories 中的下标（null = 普通标签）
    final tagCategoryIndex = <int, int?>{
      for (final t in tagRows)
        t.id: t.categoryId == null ? null : categoryIndexById[t.categoryId],
    };
    final blobById = {for (final b in blobRows) b.attachmentId: b.data};
    final typeIdByIndex = <int, int>{
      for (var i = 0; i < typeRows.length; i++) typeRows[i].id: i,
    };
    return {
      'app': 'roost',
      'schema': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'thoughts': [
        for (final t in thoughtRows)
          {
            'content': t.content,
            'day': t.day,
            'createdAt': t.createdAt,
            'updatedAt': t.updatedAt,
            'annualDate': t.annualDate,
            'archivedAt': t.archivedAt,
            'deletedAt': t.deletedAt,
            'locked': t.locked,
          },
      ],
      // 写作模板
      'templates': [
        for (final t in templateRows)
          {
            'name': t.name,
            'content': t.content,
            'sortOrder': t.sortOrder,
          },
      ],
      // 高级标签组
      'tagCategories': [
        for (final c in categoryRows)
          {
            'name': c.name,
            'multi': c.multi,
            'builtin': c.builtin,
            'color': c.color,
            'icon': c.icon,
            'glyph': c.glyph,
            'sortOrder': c.sortOrder,
          },
      ],
      'tags': [
        for (final t in tagRows)
          {
            'name': t.name,
            // 所属高级标签组在 tagCategories 中的下标；null = 普通标签
            'category': t.categoryId == null
                ? null
                : categoryIndexById[t.categoryId],
            'icon': t.icon,
            'glyph': t.glyph,
            'color': t.color,
          },
      ],
      'links': [
        for (final l in linkRows)
          {
            'thought': thoughtRows.indexWhere((t) => t.id == l.thoughtId),
            'tag': tagNameById[l.tagId],
            // 所属高级标签组下标（null = 普通标签），用于同名标签的定位
            'category': tagCategoryIndex[l.tagId],
          },
      ],
      'thoughtCategories': [
        for (final l in thoughtCategoryRows)
          if (thoughtRows.indexWhere((t) => t.id == l.thoughtId) >= 0 &&
              categoryIndexById.containsKey(l.categoryId))
            {
              'thought': thoughtRows.indexWhere((t) => t.id == l.thoughtId),
              'category': categoryIndexById[l.categoryId],
            },
      ],
      'attachments': [
        for (final a in attachmentRows)
          if (blobById.containsKey(a.id) &&
              thoughtRows.indexWhere((t) => t.id == a.thoughtId) >= 0)
            {
              'thought': thoughtRows.indexWhere((t) => t.id == a.thoughtId),
              'kind': a.kind.value,
              'mime': a.mime,
              'durationMs': a.durationMs,
              'data': base64Encode(blobById[a.id]!),
            },
      ],
      'comments': [
        for (final c in commentRows)
          if (thoughtRows.indexWhere((t) => t.id == c.thoughtId) >= 0)
            {
              'thought': thoughtRows.indexWhere((t) => t.id == c.thoughtId),
              'content': c.content,
              'createdAt': c.createdAt,
            },
      ],
      'reactions': [
        for (final r in reactionRows)
          if (thoughtRows.indexWhere((t) => t.id == r.thoughtId) >= 0)
            {
              'thought': thoughtRows.indexWhere((t) => t.id == r.thoughtId),
              'kind': r.kind.value,
              'createdAt': r.createdAt,
            },
      ],
      'eventTypes': [
        for (var i = 0; i < typeRows.length; i++)
          {
            'name': typeRows[i].name,
            'color': typeRows[i].color,
            'glyph': typeRows[i].glyph,
            'sortOrder': typeRows[i].sortOrder,
            'counter': typeRows[i].counter,
            'kind': typeRows[i].kind.value,
            // 状态随类型导出；事件以本表内的原始 id 引用
            'statuses': [
              for (final s in statusRows.where((s) => s.typeId == typeRows[i].id))
                {
                  'id': s.id,
                  'name': s.name,
                  'color': s.color,
                  'glyph': s.glyph,
                  'sortOrder': s.sortOrder,
                  'isDone': s.isDone,
                },
            ],
          },
      ],
      'calendarEvents': [
        for (final e in eventRows)
          if (typeIdByIndex.containsKey(e.typeId))
            {
              'type': typeIdByIndex[e.typeId],
              'title': e.title,
              'startDate': e.startDate,
              'endDate': e.endDate,
              'annual': e.annual,
              'count': e.count,
              'status': e.statusId,
              // 以思绪的"记录日"表达联动，导入时按日匹配重建
              'thoughtDay': e.thoughtId == null
                  ? null
                  : thoughtRows
                      .where((t) => t.id == e.thoughtId)
                      .map((t) => t.day)
                      .firstOrNull,
            },
      ],
    };
  }

  /// 导入（合并）：思绪按“同日同内容同创建时间”去重追加；
  /// 标签按名称合并（已存在则沿用现有定义）；联结按名重建；
  /// 附件跟随本次新导入的思绪（已存在的重复思绪不再附加，避免重复入库）。
  /// 返回新增思绪数。
  Future<int> importData(Map<String, dynamic> data) async {
    final thoughtsIn = (data['thoughts'] as List?) ?? const [];
    final templatesIn = (data['templates'] as List?) ?? const [];
    final categoriesIn = (data['tagCategories'] as List?) ?? const [];
    final tagsIn = (data['tags'] as List?) ?? const [];
    final linksIn = (data['links'] as List?) ?? const [];
    final thoughtCategoriesIn =
        (data['thoughtCategories'] as List?) ?? const [];
    final attachmentsIn = (data['attachments'] as List?) ?? const [];
    var imported = 0;
    await transaction(() async {
      final thoughtIdByIndex = <int, int>{};
      final importedIndexes = <int>{};
      for (var i = 0; i < thoughtsIn.length; i++) {
        final m = thoughtsIn[i] as Map;
        final content = (m['content'] ?? '') as String;
        final day = (m['day'] ?? '') as String;
        final createdAt = (m['createdAt'] as num?)?.toInt() ?? 0;
        final updatedAt = (m['updatedAt'] as num?)?.toInt() ?? createdAt;
        if (content.isEmpty || day.isEmpty) continue;
        final dup = await (select(thoughts)
              ..where((t) => t.day.equals(day) &
                  t.createdAt.equals(createdAt) &
                  t.content.equals(content)))
            .getSingleOrNull();
        if (dup != null) {
          thoughtIdByIndex[i] = dup.id;
          continue;
        }
        final id = await into(thoughts).insert(
          ThoughtsCompanion.insert(
            content: content,
            day: day,
            createdAt: createdAt,
            updatedAt: updatedAt,
            annualDate: Value(m['annualDate'] as String?),
            archivedAt: Value((m['archivedAt'] as num?)?.toInt()),
            deletedAt: Value((m['deletedAt'] as num?)?.toInt()),
            locked: Value((m['locked'] as bool?) ?? false),
          ),
        );
        thoughtIdByIndex[i] = id;
        importedIndexes.add(i);
        imported++;
      }
      // 写作模板：按名称合并（同名已存在则跳过）
      for (final raw in templatesIn) {
        final m = raw as Map;
        final name = ((m['name'] ?? '') as String).trim();
        final content = (m['content'] ?? '') as String;
        if (name.isEmpty || content.trim().isEmpty) continue;
        final dup = await (select(entryTemplates)
              ..where((t) => t.name.equals(name)))
            .getSingleOrNull();
        if (dup != null) continue;
        await createEntryTemplate(name: name, content: content);
      }
      // 高级标签组：按名称合并（内置"心情"组已存在则沿用）
      final categoryIdByIndex = <int, int>{};
      for (var i = 0; i < categoriesIn.length; i++) {
        final m = categoriesIn[i] as Map;
        final name = ((m['name'] ?? '') as String).trim();
        if (name.isEmpty) continue;
        final existing = await (select(tagCategories)
              ..where((c) => c.name.equals(name)))
            .getSingleOrNull();
        if (existing != null) {
          categoryIdByIndex[i] = existing.id;
          continue;
        }
        final id = await into(tagCategories).insert(
          TagCategoriesCompanion.insert(
            name: name,
            multi: Value((m['multi'] as bool?) ?? false),
            color: Value((m['color'] as num?)?.toInt()),
            icon: Value((m['icon'] as num?)?.toInt()),
            glyph: Value(m['glyph'] as String?),
            sortOrder: Value((m['sortOrder'] as num?)?.toInt() ?? 0),
          ),
        );
        categoryIdByIndex[i] = id;
      }
      for (final raw in tagsIn) {
        final m = raw as Map;
        final name = ((m['name'] ?? '') as String).trim();
        if (name.isEmpty) continue;
        final catIndex = (m['category'] as num?)?.toInt();
        await getOrCreateTag(
          name,
          categoryId: catIndex == null ? null : categoryIdByIndex[catIndex],
          icon: (m['icon'] as num?)?.toInt(),
          glyph: m['glyph'] as String?,
          color: (m['color'] as num?)?.toInt(),
        );
      }
      for (final raw in linksIn) {
        final m = raw as Map;
        final tid = thoughtIdByIndex[(m['thought'] as num?)?.toInt() ?? -1];
        final tagName = m['tag'] as String?;
        if (tid == null || tagName == null) continue;
        final catIndex = (m['category'] as num?)?.toInt();
        final tag = await tagByName(
          tagName,
          categoryId: catIndex == null ? null : categoryIdByIndex[catIndex],
        );
        if (tag == null) continue;
        await into(thoughtTags).insert(
          ThoughtTagsCompanion.insert(thoughtId: tid, tagId: tag.id),
          mode: InsertMode.insertOrIgnore,
        );
      }
      for (final raw in attachmentsIn) {
        final m = raw as Map;
        final index = (m['thought'] as num?)?.toInt() ?? -1;
        if (!importedIndexes.contains(index)) continue;
        final kindIdx = (m['kind'] as num?)?.toInt() ?? 0;
        if (kindIdx < 0 || kindIdx >= AttachmentKind.values.length) continue;
        final b64 = m['data'] as String?;
        if (b64 == null || b64.isEmpty) continue;
        late final List<int> bytes;
        try {
          bytes = base64Decode(b64);
        } catch (_) {
          continue;
        }
        final attachmentId = await into(attachments).insert(
          AttachmentsCompanion.insert(
            thoughtId: thoughtIdByIndex[index]!,
            kind: AttachmentKind.values[kindIdx],
            mime: (m['mime'] ?? '') as String,
            durationMs: Value((m['durationMs'] as num?)?.toInt()),
            sizeBytes: bytes.length,
          ),
        );
        await into(attachmentBlobs).insert(
          AttachmentBlobsCompanion.insert(
            attachmentId: Value(attachmentId),
            data: Uint8List.fromList(bytes),
          ),
        );
      }
      // 思绪已添加的高级标签组关联
      for (final raw in thoughtCategoriesIn) {
        final m = raw as Map;
        final tid = thoughtIdByIndex[(m['thought'] as num?)?.toInt() ?? -1];
        final cid = categoryIdByIndex[(m['category'] as num?)?.toInt() ?? -1];
        if (tid == null || cid == null) continue;
        await into(thoughtCategories).insert(
          ThoughtCategoriesCompanion.insert(
            thoughtId: tid,
            categoryId: cid,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      final typesIn = (data['eventTypes'] as List?) ?? const [];
      final commentsIn = (data['comments'] as List?) ?? const [];
      final reactionsIn = (data['reactions'] as List?) ?? const [];
      final v7TypeIds = <int, int>{};
      // 导出内的原始状态 id → 新库状态 id
      final statusIdMap = <int, int>{};
      for (final raw in typesIn) {
        final m = raw as Map;
        final name = ((m['name'] ?? '') as String).trim();
        if (name.isEmpty) continue;
        final id = await into(eventTypes).insert(
          EventTypesCompanion.insert(
            name: name,
            color: (m['color'] as num?)?.toInt() ?? 0xFF4A7DC4,
            glyph: Value(m['glyph'] as String?),
            sortOrder: Value((m['sortOrder'] as num?)?.toInt() ?? 0),
            counter: Value((m['counter'] as bool?) ?? false),
            kind: Value(EventTypeKind.fromValue(
                (m['kind'] as num?)?.toInt() ?? 0)),
          ),
        );
        v7TypeIds[typesIn.indexOf(raw)] = id;
        for (final sRaw in (m['statuses'] as List?) ?? const []) {
          final sm = sRaw as Map;
          final sName = ((sm['name'] ?? '') as String).trim();
          if (sName.isEmpty) continue;
          final oldSid = (sm['id'] as num?)?.toInt();
          final sid = await into(eventStatuses).insert(
            EventStatusesCompanion.insert(
              typeId: id,
              name: sName,
              color: (sm['color'] as num?)?.toInt() ?? 0xFF9E9E9E,
              glyph: Value((sm['glyph'] ?? '') as String),
              sortOrder: Value((sm['sortOrder'] as num?)?.toInt() ?? 0),
              isDone: Value((sm['isDone'] as bool?) ?? false),
            ),
          );
          if (oldSid != null) statusIdMap[oldSid] = sid;
        }
      }
      final eventsIn = (data['calendarEvents'] as List?) ?? const [];
      for (final raw in eventsIn) {
        final m = raw as Map;
        final typeId = v7TypeIds[(m['type'] as num?)?.toInt() ?? -1];
        final start = m['startDate'] as String?;
        if (typeId == null || start == null || start.isEmpty) continue;
        // 联动思绪：按导出的 thoughtDay + 标题匹配现有思绪重建
        final thoughtDay = m['thoughtDay'] as String?;
        final eventTitle = m['title'] as String?;
        int? thoughtId;
        if (thoughtDay != null && thoughtDay.isNotEmpty &&
            eventTitle != null && eventTitle.isNotEmpty) {
          final row = await (select(thoughts)
                ..where((t) =>
                    t.day.equals(thoughtDay) & t.content.equals(eventTitle)))
              .getSingleOrNull();
          thoughtId = row?.id;
        }
        final rawStatus = (m['status'] as num?)?.toInt();
        await into(calendarEvents).insert(
          CalendarEventsCompanion.insert(
            typeId: typeId,
            title: Value(eventTitle),
            startDate: start,
            endDate: Value(m['endDate'] as String?),
            annual: Value((m['annual'] as bool?) ?? false),
            count: Value((m['count'] as num?)?.toInt() ?? 1),
            statusId: Value(
                rawStatus == null ? null : statusIdMap[rawStatus]),
            thoughtId: Value(thoughtId),
          ),
        );
      }
      for (final raw in commentsIn) {
        final m = raw as Map;
        final tid = thoughtIdByIndex[(m['thought'] as num?)?.toInt() ?? -1];
        final content = ((m['content'] ?? '') as String).trim();
        if (tid == null || content.isEmpty) continue;
        await into(comments).insert(
          CommentsCompanion.insert(
            thoughtId: tid,
            content: content,
            createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
          ),
        );
      }
      for (final raw in reactionsIn) {
        final m = raw as Map;
        final tid = thoughtIdByIndex[(m['thought'] as num?)?.toInt() ?? -1];
        final kind = ReactionKind.fromValue(
            (m['kind'] as num?)?.toInt() ?? -1);
        if (tid == null || kind == null) continue;
        await into(reactions).insert(
          ReactionsCompanion.insert(
            thoughtId: tid,
            kind: kind,
            createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
          ),
        );
      }
    });
    return imported;
  }

  static QueryExecutor _open(String name) {
    return driftDatabase(
      name: name,
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  // ---------- 思绪：写入 ----------

  Future<int> insertThought({
    required String content,
    required String day,
    DateTime? createdAt,
    // 非空即"特殊日子"思绪（MM-DD，每年循环）
    String? annualDate,
    // 私密：不参与搜索与漫步，查看需解锁
    bool locked = false,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return into(thoughts).insert(
      ThoughtsCompanion.insert(
        content: content,
        day: day,
        createdAt: createdAt?.millisecondsSinceEpoch ?? now,
        updatedAt: now,
        annualDate: Value(annualDate),
        locked: Value(locked),
      ),
    );
  }

  /// 更新内容；传 [day] 即改记录日（用于补记与改日期）
  Future<int> updateThought(int id, String content, {String? day}) {
    return (update(thoughts)..where((t) => t.id.equals(id))).write(
      ThoughtsCompanion(
        content: Value(content),
        day: day == null ? const Value.absent() : Value(day),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// 切换私密状态
  Future<void> setThoughtLocked(int id, bool locked) {
    return (update(thoughts)..where((t) => t.id.equals(id)))
        .write(ThoughtsCompanion(locked: Value(locked)));
  }

  Future<int> deleteThought(int id) {
    return (delete(thoughts)..where((t) => t.id.equals(id))).go();
  }

  // ---------- 思绪：查询 ----------

  /// 搜索全部思绪（内容 LIKE + 可选标签过滤），按日期分组排列。
  /// 搜索时排除私密思绪（私密内容不可被搜到）；浏览（空查询）时保留，
  /// 由列表侧遮罩显示
  Stream<List<ThoughtEntry>> watchSearch(String query, {String? tagName}) {
    final joined = (select(thoughts)
          ..where((t) {
            final content = query.trim();
            final searching = content.isNotEmpty;
            final match = content.isEmpty
                ? const Constant(true)
                : t.content.like('%$content%');
            // 活跃思绪：未归档、未进回收站；搜索时私密不参与
            return match &
                t.archivedAt.isNull() &
                t.deletedAt.isNull() &
                (searching ? t.locked.equals(false) : const Constant(true));
          })
          ..orderBy([
            (t) => OrderingTerm.desc(t.day),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .join([
      if (tagName != null) ...[
        innerJoin(thoughtTags, thoughtTags.thoughtId.equalsExp(thoughts.id)),
        innerJoin(tags, tags.id.equalsExp(thoughtTags.tagId)),
      ],
    ]);
    if (tagName != null) {
      joined.where(tags.name.equals(tagName));
    }
    return joined.watch().map((rows) {
      final list = rows.map((r) => r.readTable(thoughts)).toList()
        ..sort((a, b) {
          final byDay = b.day.compareTo(a.day);
          return byDay != 0 ? byDay : b.createdAt.compareTo(a.createdAt);
        });
      return list;
    });
  }

  /// 某一天的思绪（按时间倒序，仅活跃：未归档、未回收）
  Stream<List<ThoughtEntry>> watchDay(String day) {
    return (select(thoughts)
          ..where((t) =>
              t.day.equals(day) &
              t.archivedAt.isNull() &
              t.deletedAt.isNull()))
        .watch()
        .map((rows) => rows..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// 随机漫步：随机抽 N 条旧思绪（仅活跃；私密条目保留，由列表遮罩）
  Future<List<ThoughtEntry>> randomThoughts({int limit = 5}) {
    final now = DateTime.now();
    final today = formatDay(now);
    return (select(thoughts)
          ..where((t) =>
              t.day.equals(today).not() &
              t.archivedAt.isNull() &
              t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(
                  expression: CustomExpression<Object>('RANDOM()'),
                ),
          ])
          ..limit(limit))
        .get();
  }

  /// "那年今日"：历史上同月同日的所有思绪（不含今天，仅活跃；
  /// 私密条目保留，由列表遮罩）
  Future<List<ThoughtEntry>> onThisDay({required int month, required int day}) {
    final today = formatDay(DateTime.now());
    final suffix =
        '-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    return (select(thoughts)
          ..where((t) =>
              t.day.like('%$suffix') &
              t.day.equals(today).not() &
              t.archivedAt.isNull() &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.day)]))
        .get();
  }

  /// 全部思绪（供热力图与漫步页统计；仅活跃）
  Stream<List<ThoughtEntry>> watchAllEntries() {
    return (select(thoughts)
          ..where((t) => t.archivedAt.isNull() & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.day),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  // ---------- 归档与回收站 ----------

  /// 已归档思绪（未进回收站），最近归档在前
  Stream<List<ThoughtEntry>> watchArchivedEntries() {
    return (select(thoughts)
          ..where((t) => t.archivedAt.isNotNull() & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.archivedAt)]))
        .watch();
  }

  /// 回收站中的思绪，最近移入在前
  Stream<List<ThoughtEntry>> watchTrashedEntries() {
    return (select(thoughts)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .watch();
  }

  /// 归档（保留原回收站状态，归档 ≠ 删除）
  Future<void> archiveThought(int id) {
    return (update(thoughts)..where((t) => t.id.equals(id))).write(
      ThoughtsCompanion(
        archivedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> unarchiveThought(int id) {
    return (update(thoughts)..where((t) => t.id.equals(id)))
        .write(const ThoughtsCompanion(archivedAt: Value(null)));
  }

  /// 移入回收站（软删除），保留期后由 purge 永久清除
  Future<void> trashThought(int id) {
    return (update(thoughts)..where((t) => t.id.equals(id))).write(
      ThoughtsCompanion(
        deletedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// 从回收站恢复
  Future<void> restoreThought(int id) {
    return (update(thoughts)..where((t) => t.id.equals(id)))
        .write(const ThoughtsCompanion(deletedAt: Value(null)));
  }

  /// 永久清除：删除回收站中超过保留期的思绪（返回清除条数）
  Future<int> purgeExpiredTrash() {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: trashRetentionDays))
        .millisecondsSinceEpoch;
    return (delete(thoughts)
          ..where((t) =>
              t.deletedAt.isNotNull() & t.deletedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// 清空回收站（永久删除全部）
  Future<int> emptyTrash() {
    return (delete(thoughts)..where((t) => t.deletedAt.isNotNull())).go();
  }

  // ---------- 评论与反应 ----------

  /// 某条思绪的评论（时间正序）
  Stream<List<Comment>> watchCommentsFor(int thoughtId) {
    return (select(comments)
          ..where((c) => c.thoughtId.equals(thoughtId))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt), (c) => OrderingTerm.asc(c.id)]))
        .watch();
  }

  /// 某条思绪的反应（时间正序）
  Stream<List<Reaction>> watchReactionsFor(int thoughtId) {
    return (select(reactions)
          ..where((r) => r.thoughtId.equals(thoughtId))
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt), (r) => OrderingTerm.asc(r.id)]))
        .watch();
  }

  Future<int> addComment({
    required int thoughtId,
    required String content,
  }) {
    final c = content.trim();
    if (c.isEmpty) return Future.value(-1);
    return into(comments).insert(
      CommentsCompanion.insert(
        thoughtId: thoughtId,
        content: c,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> deleteComment(int id) {
    return (delete(comments)..where((c) => c.id.equals(id))).go();
  }

  Future<int> addReaction({
    required int thoughtId,
    required ReactionKind kind,
  }) {
    return into(reactions).insert(
      ReactionsCompanion.insert(
        thoughtId: thoughtId,
        kind: kind,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> deleteReaction(int id) {
    return (delete(reactions)..where((r) => r.id.equals(id))).go();
  }

  // ---------- 日历：特殊日子（思绪） ----------

  /// 特殊日子（生日、纪念日等）：annualDate 非空的思绪，按 MM-DD 升序（仅活跃）
  Stream<List<ThoughtEntry>> watchAnnualEvents() {
    return (select(thoughts)
          ..where((t) =>
              t.annualDate.isNotNull() &
              t.archivedAt.isNull() &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.annualDate)]))
        .watch();
  }

  // ---------- 日历：事件类型与事件 ----------

  /// 全部事件类型（按 sortOrder、id 排序）
  Stream<List<EventType>> watchEventTypes() {
    return (select(eventTypes)..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.id),
        ]))
        .watch();
  }

  /// 全部日历事件
  Stream<List<CalendarEvent>> watchEvents() {
    return (select(calendarEvents)
          ..orderBy([(e) => OrderingTerm.asc(e.startDate)]))
        .watch();
  }

  /// 全部私密思绪的 id 集合（含归档/回收站）。
  /// 供日历事件标题遮罩等使用：编辑器创建的事件标题即思绪内容，
  /// 关联到私密思绪时不应直接显示
  Stream<Set<int>> watchLockedThoughtIds() {
    final q = selectOnly(thoughts)
      ..addColumns([thoughts.id])
      ..where(thoughts.locked.equals(true));
    return q.watch().map(
          (rows) => {for (final r in rows) r.read(thoughts.id)!},
        );
  }

  /// 全部事件状态（按类型、sortOrder 排序）
  Stream<List<EventStatus>> watchEventStatuses() {
    return (select(eventStatuses)..orderBy([
          (s) => OrderingTerm.asc(s.typeId),
          (s) => OrderingTerm.asc(s.sortOrder),
          (s) => OrderingTerm.asc(s.id),
        ]))
        .watch();
  }

  /// 待办聚合视图：跨类型汇总所有"未完成"的事件。
  /// 完成的定义：
  /// - 类型定义了至少一个"完成态"状态（isDone）才参与待办
  ///   （节假日、生日、计数器等类型不参与，避免无关事件混入）；
  /// - 事件状态为完成态 → 已完成；无状态（或状态被删后置空）→ 未完成
  /// 按开始日期升序；每条附带类型、当前状态与该类型的完成态状态
  Stream<List<TodoItem>> watchTodos() {
    final q = select(calendarEvents).join([
      innerJoin(eventTypes, eventTypes.id.equalsExp(calendarEvents.typeId)),
      leftOuterJoin(
          eventStatuses, eventStatuses.id.equalsExp(calendarEvents.statusId)),
    ])
      ..orderBy([
        OrderingTerm.asc(calendarEvents.startDate),
        OrderingTerm.asc(calendarEvents.id),
      ]);
    return q.watch().asyncMap((rows) async {
      // 完成态状态按类型归组（同类型多个完成态取 sortOrder 最小者）
      final allStatuses = await select(eventStatuses).get();
      final doneByType = <int, EventStatus>{};
      for (final s in allStatuses) {
        if (!s.isDone) continue;
        final cur = doneByType[s.typeId];
        if (cur == null || s.sortOrder < cur.sortOrder) {
          doneByType[s.typeId] = s;
        }
      }
      final items = <TodoItem>[];
      for (final r in rows) {
        final type = r.readTable(eventTypes);
        final doneStatus = doneByType[type.id];
        if (doneStatus == null) continue; // 类型未参与待办
        final status = r.read(eventStatuses.id) == null
            ? null
            : r.readTable(eventStatuses);
        if (status?.isDone ?? false) continue; // 已完成
        items.add(TodoItem(
          event: r.readTable(calendarEvents),
          type: type,
          status: status,
          doneStatusId: doneStatus.id,
        ));
      }
      return items;
    });
  }

  /// 某类型的全部状态（按 sortOrder、id）
  Future<List<EventStatus>> statusesFor(int typeId) {
    return (select(eventStatuses)
          ..where((s) => s.typeId.equals(typeId))
          ..orderBy([
            (s) => OrderingTerm.asc(s.sortOrder),
            (s) => OrderingTerm.asc(s.id),
          ]))
        .get();
  }

  Future<int> createEventType({
    required String name,
    required int color,
    String? glyph,
    bool counter = false,
    EventTypeKind kind = EventTypeKind.custom,
    // 新建时一并种入的状态（如节假日的 放假/补班）
    List<EventStatusesCompanion> statuses = const [],
  }) async {
    return transaction(() async {
      final typeId = await into(eventTypes).insert(
        EventTypesCompanion.insert(
          name: name,
          color: color,
          glyph: Value(glyph),
          counter: Value(counter),
          kind: Value(kind),
        ),
      );
      for (final s in statuses) {
        await into(eventStatuses).insert(
          EventStatusesCompanion.insert(
            typeId: typeId,
            name: s.name.value,
            color: s.color.value,
            glyph: s.glyph,
            sortOrder: s.sortOrder,
            isDone: s.isDone,
          ),
        );
      }
      return typeId;
    });
  }

  Future<void> updateEventType(
    int id, {
    required String name,
    required int color,
    String? glyph,
    bool counter = false,
    EventTypeKind kind = EventTypeKind.custom,
  }) {
    return (update(eventTypes)..where((t) => t.id.equals(id))).write(
      EventTypesCompanion(
        name: Value(name),
        color: Value(color),
        glyph: Value(glyph),
        counter: Value(counter),
        kind: Value(kind),
      ),
    );
  }

  Future<int> createEventStatus({
    required int typeId,
    required String name,
    required int color,
    String glyph = '',
    int sortOrder = 0,
    // 完成态：该状态代表已完成，事件到达即退出待办
    bool isDone = false,
  }) {
    return into(eventStatuses).insert(
      EventStatusesCompanion.insert(
        typeId: typeId,
        name: name,
        color: color,
        glyph: Value(glyph),
        sortOrder: Value(sortOrder),
        isDone: Value(isDone),
      ),
    );
  }

  Future<void> updateEventStatus(
    int id, {
    required String name,
    required int color,
    String glyph = '',
    bool isDone = false,
  }) {
    return (update(eventStatuses)..where((s) => s.id.equals(id))).write(
      EventStatusesCompanion(
        name: Value(name),
        color: Value(color),
        glyph: Value(glyph),
        isDone: Value(isDone),
      ),
    );
  }

  /// 删除状态（其上事件实例的 statusId 由外键置空）
  Future<void> deleteEventStatus(int id) {
    return (delete(eventStatuses)..where((s) => s.id.equals(id))).go();
  }

  /// 删除类型（其下事件由外键级联删除）
  Future<void> deleteEventType(int id) {
    return (delete(eventTypes)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertEvent({
    required int typeId,
    required String startDate,
    String? endDate,
    String? title,
    bool annual = false,
    int? thoughtId,
    // 选中的状态（所属类型的状态之一）；null = 无状态
    int? statusId,
  }) {
    return into(calendarEvents).insert(
      CalendarEventsCompanion.insert(
        typeId: typeId,
        title: Value(title),
        startDate: startDate,
        endDate: Value(endDate),
        annual: Value(annual),
        count: const Value(1),
        statusId: Value(statusId),
        thoughtId: Value(thoughtId),
      ),
    );
  }

  Future<void> updateEvent(
    int id, {
    required String startDate,
    String? endDate,
    String? title,
    required bool annual,
    int? statusId,
  }) {
    return (update(calendarEvents)..where((e) => e.id.equals(id))).write(
      CalendarEventsCompanion(
        title: Value(title),
        startDate: Value(startDate),
        endDate: Value(endDate),
        annual: Value(annual),
        statusId: Value(statusId),
      ),
    );
  }

  /// 取消思绪与事件的关联（事件保留）
  Future<void> unlinkEventFromThought(int thoughtId) {
    return (update(calendarEvents)
            ..where((e) => e.thoughtId.equals(thoughtId)))
        .write(const CalendarEventsCompanion(thoughtId: Value(null)));
  }

  /// 一键勾完成：把事件状态改为该类型的完成态状态（isDone）
  Future<void> completeTodo(TodoItem item) {
    return (update(calendarEvents)..where((e) => e.id.equals(item.event.id)))
        .write(CalendarEventsCompanion(statusId: Value(item.doneStatusId)));
  }

  /// 快捷改事件状态（待办勾完成后的撤销恢复等）
  Future<void> setEventStatus(int eventId, int? statusId) {
    return (update(calendarEvents)..where((e) => e.id.equals(eventId)))
        .write(CalendarEventsCompanion(statusId: Value(statusId)));
  }

  /// 把事件关联到思绪（覆盖该事件原有的关联）
  Future<void> linkEventToThought(int eventId, int thoughtId) {
    return (update(calendarEvents)..where((e) => e.id.equals(eventId)))
        .write(CalendarEventsCompanion(thoughtId: Value(thoughtId)));
  }

  Future<void> deleteEvent(int id) {
    return (delete(calendarEvents)..where((e) => e.id.equals(id))).go();
  }

  /// 计数器 +1：当日已有计数行则 count+1，否则插入一行（count=1）
  Future<void> incrementCounter({
    required int typeId,
    required String date,
  }) async {
    final existing = await (select(calendarEvents)..where(
            (e) =>
                e.typeId.equals(typeId) &
                e.startDate.equals(date) &
                e.endDate.isNull()))
        .getSingleOrNull();
    if (existing == null) {
      await into(calendarEvents).insert(
        CalendarEventsCompanion.insert(
          typeId: typeId,
          startDate: date,
          count: const Value(1),
        ),
      );
    } else {
      await (update(calendarEvents)..where((e) => e.id.equals(existing.id)))
          .write(CalendarEventsCompanion(count: Value(existing.count + 1)));
    }
  }

  /// 计数器 -1：count 减到 0 时删除该行；无行时忽略
  Future<void> decrementCounter({
    required int typeId,
    required String date,
  }) async {
    final existing = await (select(calendarEvents)..where(
            (e) =>
                e.typeId.equals(typeId) &
                e.startDate.equals(date) &
                e.endDate.isNull()))
        .getSingleOrNull();
    if (existing == null) return;
    if (existing.count <= 1) {
      await deleteEvent(existing.id);
    } else {
      await (update(calendarEvents)..where((e) => e.id.equals(existing.id)))
          .write(CalendarEventsCompanion(count: Value(existing.count - 1)));
    }
  }

  /// 事件在某年覆盖的日期（yyyy-MM-dd 升序）。
  /// annual 事件按 startDate 的月-日在 [year] 重复；区间裁剪到年内
  static List<String> eventDaysInYear(CalendarEvent e, int year) {    String fmt(DateTime d) => formatDay(d);
    if (e.annual) {
      final start = DateTime.parse(e.startDate);
      final month = start.month.toString().padLeft(2, '0');
      final day = start.day.toString().padLeft(2, '0');
      return ['${year.toString().padLeft(4, '0')}-$month-$day'];
    }
    final start = DateTime.parse(e.startDate);
    final end = DateTime.parse(e.endDate ?? e.startDate);
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year, 12, 31);
    final from = start.isBefore(yearStart) ? yearStart : start;
    final to = end.isAfter(yearEnd) ? yearEnd : end;
    if (to.isBefore(from)) return const [];
    final days = <String>[];
    for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
      days.add(fmt(d));
    }
    return days;
  }

  // ---------- 高级标签组 ----------

  /// 全部高级标签组（内置在前，其后按 sortOrder、id）
  Stream<List<TagCategory>> watchTagCategories() {
    return (select(tagCategories)..orderBy([
          (c) => OrderingTerm.desc(c.builtin),
          (c) => OrderingTerm.asc(c.sortOrder),
          (c) => OrderingTerm.asc(c.id),
        ]))
        .watch();
  }

  /// 内置"心情"组（首页筛选与洞察心情分布用）
  Stream<TagCategory?> watchMoodCategory() {
    return (select(tagCategories)..where((c) => c.builtin.equals(true)))
        .watchSingleOrNull();
  }

  /// 新建高级标签组（自定义；builtin 仅种子使用）
  Future<int> createTagCategory({
    required String name,
    bool multi = false,
    int? color,
    int? icon,
    String? glyph,
  }) {
    return into(tagCategories).insert(
      TagCategoriesCompanion.insert(
        name: name,
        multi: Value(multi),
        color: Value(color),
        icon: Value(icon),
        glyph: Value(glyph),
      ),
    );
  }

  /// 更新高级标签组（名称/选择模式/外观）
  Future<void> updateTagCategory(
    int id, {
    required String name,
    required bool multi,
    int? color,
    int? icon,
    String? glyph,
  }) {
    return (update(tagCategories)..where((c) => c.id.equals(id))).write(
      TagCategoriesCompanion(
        name: Value(name),
        multi: Value(multi),
        color: Value(color),
        icon: Value(icon),
        glyph: Value(glyph),
      ),
    );
  }

  /// 删除高级标签组（其选项与思绪关联由外键级联清理）；内置组不可删除
  Future<void> deleteTagCategory(int id) async {
    final cat = await (select(tagCategories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    if (cat == null || cat.builtin) return;
    await (delete(tagCategories)..where((c) => c.id.equals(id))).go();
  }

  /// 某高级标签组的全部选项
  Future<List<Tag>> categoryTags(int categoryId) {
    return (select(tags)
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  // ---------- 标签 ----------

  /// 按名称查找标签（同组内重名唯一；categoryId 为空即普通标签）
  Future<Tag?> tagByName(String name, {int? categoryId}) {
    return (select(tags)
          ..where((t) =>
              t.name.equals(name) &
              (categoryId == null
                  ? t.categoryId.isNull()
                  : t.categoryId.equals(categoryId))))
        .getSingleOrNull();
  }

  /// 获取或创建标签（同组内按名称唯一）；仅创建时应用 icon/glyph/color
  Future<Tag> getOrCreateTag(
    String name, {
    int? categoryId,
    int? icon,
    String? glyph,
    int? color,
  }) async {
    final trimmed = name.trim();
    final existing = await tagByName(trimmed, categoryId: categoryId);
    if (existing != null) return existing;
    final id = await into(tags).insert(
      TagsCompanion.insert(
        name: trimmed,
        categoryId: Value(categoryId),
        icon: Value(icon),
        glyph: Value(glyph),
        color: Value(color),
      ),
    );
    return (select(tags)..where((t) => t.id.equals(id))).getSingle();
  }

  /// 设置某条思绪的普通标签（整体替换；高级标签不动）
  Future<void> setThoughtNormalTags(int thoughtId, List<String> names) async {
    await transaction(() async {
      // 仅清理普通标签（categoryId 为空）的联结
      final normalIds = await (select(tags)
            ..where((t) => t.categoryId.isNull()))
          .get();
      final normalIdSet = normalIds.map((t) => t.id).toSet();
      final joins = await (select(thoughtTags)
            ..where((t) => t.thoughtId.equals(thoughtId)))
          .get();
      for (final j in joins) {
        if (normalIdSet.contains(j.tagId)) {
          await (delete(thoughtTags)
                ..where((t) =>
                    t.thoughtId.equals(thoughtId) & t.tagId.equals(j.tagId)))
              .go();
        }
      }
      final unique =
          names.map((n) => n.trim()).where((n) => n.isNotEmpty).toSet();
      for (final name in unique) {
        final tag = await getOrCreateTag(name);
        await into(thoughtTags).insert(
          ThoughtTagsCompanion.insert(thoughtId: thoughtId, tagId: tag.id),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// 某条思绪已添加的高级标签组 id
  Future<Set<int>> thoughtCategoryIds(int thoughtId) async {
    final rows = await (select(thoughtCategories)
          ..where((t) => t.thoughtId.equals(thoughtId)))
        .get();
    return rows.map((r) => r.categoryId).toSet();
  }

  /// 已添加的高级标签组 id 流
  Stream<Set<int>> watchThoughtCategoryIds(int thoughtId) {
    return (select(thoughtCategories)
          ..where((t) => t.thoughtId.equals(thoughtId)))
        .watch()
        .map((rows) => rows.map((r) => r.categoryId).toSet());
  }

  /// 给思绪添加一个高级标签组（已存在则忽略）
  Future<void> addThoughtCategory(int thoughtId, int categoryId) async {
    await into(thoughtCategories).insert(
      ThoughtCategoriesCompanion.insert(
        thoughtId: thoughtId,
        categoryId: categoryId,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// 移除思绪的高级标签组（该组下的标签值一并从思绪移除）
  Future<void> removeThoughtCategory(int thoughtId, int categoryId) async {
    await transaction(() async {
      final tagRows = await (select(tags)
            ..where((t) => t.categoryId.equals(categoryId)))
          .get();
      for (final t in tagRows) {
        await (delete(thoughtTags)
              ..where((j) =>
                  j.thoughtId.equals(thoughtId) & j.tagId.equals(t.id)))
            .go();
      }
      await (delete(thoughtCategories)
            ..where((j) =>
                j.thoughtId.equals(thoughtId) & j.categoryId.equals(categoryId)))
          .go();
    });
  }

  /// 设置某条思绪在指定高级标签组下的选项（整体替换该组；
  /// 单选组传入多个时只取第一个）
  Future<void> setThoughtCategoryTags(
    int thoughtId,
    int categoryId,
    List<String> names,
  ) async {
    await transaction(() async {
      final cat = await (select(tagCategories)
            ..where((c) => c.id.equals(categoryId)))
          .getSingleOrNull();
      final tagRows = await (select(tags)
            ..where((t) => t.categoryId.equals(categoryId)))
          .get();
      final tagIdSet = tagRows.map((t) => t.id).toSet();
      final joins = await (select(thoughtTags)
            ..where((t) => t.thoughtId.equals(thoughtId)))
          .get();
      for (final j in joins) {
        if (tagIdSet.contains(j.tagId)) {
          await (delete(thoughtTags)
                ..where((t) =>
                    t.thoughtId.equals(thoughtId) & t.tagId.equals(j.tagId)))
              .go();
        }
      }
      var unique =
          names.map((n) => n.trim()).where((n) => n.isNotEmpty).toSet().toList();
      if (cat != null && !cat.multi && unique.length > 1) {
        unique = [unique.first];
      }
      for (final name in unique) {
        final tag = await getOrCreateTag(name, categoryId: categoryId);
        await into(thoughtTags).insert(
          ThoughtTagsCompanion.insert(thoughtId: thoughtId, tagId: tag.id),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// 某条思绪的全部标签（含其所属高级标签组；一次性查询）
  Future<List<TagWithCategory>> tagsFor(int thoughtId) async {
    final q = select(thoughtTags).join([
      innerJoin(tags, tags.id.equalsExp(thoughtTags.tagId)),
      leftOuterJoin(tagCategories, tagCategories.id.equalsExp(tags.categoryId)),
    ])
      ..where(thoughtTags.thoughtId.equals(thoughtId));
    final rows = await q.get();
    return rows
        .map((r) => TagWithCategory(
              tag: r.readTable(tags),
              category: r.readTableOrNull(tagCategories),
            ))
        .toList();
  }

  /// 全部思绪的标签映射（thoughtId → 标签列表，含所属高级标签组）
  Stream<Map<int, List<TagWithCategory>>> watchAllThoughtTags() {
    final q = select(thoughtTags).join([
      innerJoin(tags, tags.id.equalsExp(thoughtTags.tagId)),
      leftOuterJoin(tagCategories, tagCategories.id.equalsExp(tags.categoryId)),
    ]);
    return q.watch().map((rows) {
      final map = <int, List<TagWithCategory>>{};
      for (final r in rows) {
        map.putIfAbsent(r.read(thoughtTags.thoughtId)!, () => []).add(
              TagWithCategory(
                tag: r.readTable(tags),
                category: r.readTableOrNull(tagCategories),
              ),
            );
      }
      return map;
    });
  }

  /// 所有标签及其使用数量（按数量降序；仅统计活跃思绪）
  Stream<List<TagWithCount>> watchTagsWithCount() {
    final usage = thoughts.id.count();
    final q = select(tags).join([
      leftOuterJoin(
        thoughtTags,
        thoughtTags.tagId.equalsExp(tags.id),
      ),
      leftOuterJoin(
        thoughts,
        thoughts.id.equalsExp(thoughtTags.thoughtId) &
            thoughts.archivedAt.isNull() &
            thoughts.deletedAt.isNull(),
      ),
      leftOuterJoin(
        tagCategories,
        tagCategories.id.equalsExp(tags.categoryId),
      ),
    ])
      ..addColumns([usage])
      ..groupBy([tags.id])
      ..orderBy([
        OrderingTerm.desc(usage),
        OrderingTerm.asc(tags.name),
      ]);
    return q.watch().map(
          (rows) => rows
              .map((r) => TagWithCount(
                    tag: r.readTable(tags),
                    category: r.readTableOrNull(tagCategories),
                    count: r.read(usage) ?? 0,
                  ))
              .toList(),
        );
  }

  /// 某个标签下的全部思绪（仅活跃）
  Stream<List<ThoughtEntry>> watchEntriesWithTag(int tagId) {
    final q = select(thoughts).join([
      innerJoin(thoughtTags, thoughtTags.thoughtId.equalsExp(thoughts.id)),
    ])
      ..where(thoughtTags.tagId.equals(tagId) &
          thoughts.archivedAt.isNull() &
          thoughts.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.desc(thoughts.day),
        OrderingTerm.desc(thoughts.createdAt),
      ]);
    return q.watch().map((rows) => rows.map((r) => r.readTable(thoughts)).toList());
  }

  /// 重命名标签；同组内若新名称已存在则合并到已存在标签（联结行去重）
  Future<void> renameTag(int tagId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    await transaction(() async {
      final target = await (select(tags)..where((t) => t.id.equals(tagId)))
          .getSingleOrNull();
      if (target == null) return;
      final targetCategory = target.categoryId;
      final existing = await (select(tags)
            ..where((t) =>
                t.name.equals(trimmed) &
                (targetCategory == null
                    ? t.categoryId.isNull()
                    : t.categoryId.equals(targetCategory))))
          .getSingleOrNull();
      if (existing != null && existing.id != tagId) {
        final joins = await (select(thoughtTags)
                ..where((t) => t.tagId.equals(tagId)))
            .get();
        for (final row in joins) {
          await into(thoughtTags).insert(
            ThoughtTagsCompanion.insert(
                thoughtId: row.thoughtId, tagId: existing.id),
            mode: InsertMode.insertOrIgnore,
          );
        }
        await (delete(tags)..where((t) => t.id.equals(tagId))).go();
      } else {
        await (update(tags)..where((t) => t.id.equals(tagId)))
            .write(TagsCompanion(name: Value(trimmed)));
      }
    });
  }

  /// 更新标签外观；传 null 即清除（icon 与 glyph 互斥，调用方保证）
  Future<void> setTagAppearance(
    int tagId, {
    int? icon,
    String? glyph,
    int? color,
  }) async {
    await (update(tags)..where((t) => t.id.equals(tagId))).write(
      TagsCompanion(
        icon: Value(icon),
        glyph: Value(glyph),
        color: Value(color),
      ),
    );
  }

  /// 更新高级标签组外观（名称由 updateTagCategory 负责）
  Future<void> setCategoryAppearance(
    int categoryId, {
    int? icon,
    String? glyph,
    int? color,
  }) async {
    await (update(tagCategories)..where((c) => c.id.equals(categoryId))).write(
      TagCategoriesCompanion(
        icon: Value(icon),
        glyph: Value(glyph),
        color: Value(color),
      ),
    );
  }

  /// 删除标签（联结行由外键级联删除，思绪保留）
  Future<void> deleteTag(int tagId) async {
    await (delete(tags)..where((t) => t.id.equals(tagId))).go();
  }

  static String formatDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String today() => formatDay(DateTime.now());
}

/// 标签、其使用数量与所属高级标签组
class TagWithCount {
  final Tag tag;
  final TagCategory? category;
  final int count;

  const TagWithCount({required this.tag, this.category, required this.count});
}

/// 标签及其所属高级标签组（category 为空即普通标签）
class TagWithCategory {
  final Tag tag;
  final TagCategory? category;

  const TagWithCategory({required this.tag, this.category});

  bool get isNormal => category == null;
  bool get isBuiltin => category?.builtin ?? false;
}

/// 待办聚合视图的一条：事件实例 + 所属类型 + 当前状态 + 完成态状态 id。
/// [doneStatusId] 供 UI 一键勾完成（把事件状态写成该状态）
class TodoItem {
  final CalendarEvent event;
  final EventType type;
  final EventStatus? status;
  final int doneStatusId;

  const TodoItem({
    required this.event,
    required this.type,
    required this.status,
    required this.doneStatusId,
  });
}
