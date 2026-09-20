import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tag_presets.dart';
import 'thoughts_table.dart';

part 'app_database.g.dart';

/// Material Icons 使用 Unicode 私用区（0xE000-0xF8FF）；区外码点视为 emoji
bool isEmojiCodepoint(int codePoint) =>
    codePoint < 0xE000 || codePoint > 0xF8FF;

@DriftDatabase(tables: [Thoughts, Tags, ThoughtTags, Attachments, AttachmentBlobs, CalendarFlags])
class AppDatabase extends _$AppDatabase {
  /// [name] 同时用作原生库文件名与 Web 端 IndexedDB 库名；
  /// 不同 name 即不同 vault，数据完全隔离
  AppDatabase({String name = 'roost'}) : super(_open(name));

  AppDatabase.connect(super.connection);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // v5→v6 为无损迁移（加列 + 建表），保留用户数据；
        // 其余历史版本升级仍清空重建，由 UI 引导用户清理异常数据
        onUpgrade: (m, from, to) async {
          if (from == 5) {
            await m.addColumn(thoughts, thoughts.annualDate);
            await m.createTable(calendarFlags);
            return;
          }
          await _wipeRebuild(m, from, to);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // 仅新建或升级（清空重建）后播种；用户删除的预设不会被重新种回
          final needsSeed = details.wasCreated ||
              (details.versionBefore != null &&
                  details.versionBefore != details.versionNow);
          if (needsSeed) await _seedMoodPresets();
        },
      );

  Future<void> _wipeRebuild(Migrator m, int from, int to) async {
    await m.deleteTable('attachment_blobs');
    await m.deleteTable('attachments');
    await m.deleteTable('thought_tags');
    await m.deleteTable('calendar_flags');
    await m.deleteTable('tags');
    await m.deleteTable('thoughts');
    await m.createAll();
  }

  Future<void> _seedMoodPresets() async {
    for (final preset in moodPresets) {
      final name = seedUseChinese ? preset.nameZh : preset.nameEn;
      final existing =
          await (select(tags)..where((t) => t.name.equals(name)))
              .getSingleOrNull();
      if (existing != null) continue;
      await into(tags).insert(
        TagsCompanion.insert(
          name: name,
          kind: Value(TagKind.mood.value),
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
      await select(thoughts).get();
      await select(calendarFlags).get();
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
      await customStatement('DELETE FROM calendar_flags');
      await customStatement('DELETE FROM thoughts');
      await customStatement('DELETE FROM tags');
    });
    await _seedMoodPresets();
  }

  /// 重置心情标签：删除全部心情标签（联结级联清理），恢复预设
  Future<void> resetMoodTags() async {
    await (delete(tags)..where((t) => t.kind.equals(TagKind.mood.value))).go();
    await _seedMoodPresets();
  }

  /// 完整导出为纯数据结构（文件读写交给 UI 层）。
  /// links 以思绪在 thoughts 数组中的下标 + 标签名表达联结关系；
  /// attachments 同样以思绪下标表达，data 为 base64。
  Future<Map<String, dynamic>> exportData() async {
    final thoughtRows = await select(thoughts).get();
    final tagRows = await select(tags).get();
    final linkRows = await select(thoughtTags).get();
    final attachmentRows = await select(attachments).get();
    final blobRows = await select(attachmentBlobs).get();
    final flagRows = await select(calendarFlags).get();
    final tagNameById = {for (final t in tagRows) t.id: t.name};
    final blobById = {for (final b in blobRows) b.attachmentId: b.data};
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
          },
      ],
      'tags': [
        for (final t in tagRows)
          {
            'name': t.name,
            'kind': t.kind,
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
      'calendarFlags': [
        for (final f in flagRows)
          {'date': f.date, 'flag': f.flag.value},
      ],
    };
  }

  /// 导入（合并）：思绪按“同日同内容同创建时间”去重追加；
  /// 标签按名称合并（已存在则沿用现有定义）；联结按名重建；
  /// 附件跟随本次新导入的思绪（已存在的重复思绪不再附加，避免重复入库）。
  /// 返回新增思绪数。
  Future<int> importData(Map<String, dynamic> data) async {
    final thoughtsIn = (data['thoughts'] as List?) ?? const [];
    final tagsIn = (data['tags'] as List?) ?? const [];
    final linksIn = (data['links'] as List?) ?? const [];
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
          ),
        );
        thoughtIdByIndex[i] = id;
        importedIndexes.add(i);
        imported++;
      }
      for (final raw in tagsIn) {
        final m = raw as Map;
        final name = ((m['name'] ?? '') as String).trim();
        if (name.isEmpty) continue;
        await getOrCreateTag(
          name,
          kind: TagKind.fromValue((m['kind'] as num?)?.toInt() ?? 0),
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
        final tag = await tagByName(tagName);
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
      final flagsIn = (data['calendarFlags'] as List?) ?? const [];
      for (final raw in flagsIn) {
        final m = raw as Map;
        final date = m['date'] as String?;
        final idx = (m['flag'] as num?)?.toInt() ?? -1;
        if (date == null || idx < 0 || idx >= DayFlag.values.length) continue;
        await into(calendarFlags).insertOnConflictUpdate(
          CalendarFlagsCompanion.insert(date: date, flag: DayFlag.values[idx]),
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
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return into(thoughts).insert(
      ThoughtsCompanion.insert(
        content: content,
        day: day,
        createdAt: createdAt?.millisecondsSinceEpoch ?? now,
        updatedAt: now,
        annualDate: Value(annualDate),
      ),
    );
  }

  Future<int> updateThought(int id, String content) {
    return (update(thoughts)..where((t) => t.id.equals(id))).write(
      ThoughtsCompanion(
        content: Value(content),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<int> deleteThought(int id) {
    return (delete(thoughts)..where((t) => t.id.equals(id))).go();
  }

  // ---------- 思绪：查询 ----------

  /// 搜索全部思绪（内容 LIKE + 可选标签过滤），按日期分组排列
  Stream<List<ThoughtEntry>> watchSearch(String query, {String? tagName}) {
    final joined = (select(thoughts)
          ..where((t) {
            final content = query.trim();
            return content.isEmpty
                ? const Constant(true)
                : t.content.like('%$content%');
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

  /// 某一天的思绪（按时间倒序）
  Stream<List<ThoughtEntry>> watchDay(String day) {
    return (select(thoughts)..where((t) => t.day.equals(day)))
        .watch()
        .map((rows) => rows..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// 随机漫步：随机抽 N 条旧思绪
  Future<List<ThoughtEntry>> randomThoughts({int limit = 5}) {
    final now = DateTime.now();
    final today = formatDay(now);
    return (select(thoughts)
          ..where((t) => t.day.equals(today).not())
          ..orderBy([
            (t) => OrderingTerm(
                  expression: CustomExpression<Object>('RANDOM()'),
                ),
          ])
          ..limit(limit))
        .get();
  }

  /// "那年今日"：历史上同月同日的所有思绪（不含今天）
  Future<List<ThoughtEntry>> onThisDay({required int month, required int day}) {
    final today = formatDay(DateTime.now());
    final suffix =
        '-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    return (select(thoughts)
          ..where((t) => t.day.like('%$suffix') & t.day.equals(today).not())
          ..orderBy([(t) => OrderingTerm.desc(t.day)]))
        .get();
  }

  /// 全部思绪（供热力图与漫步页统计）
  Stream<List<ThoughtEntry>> watchAllEntries() {
    return (select(thoughts)
          ..orderBy([
            (t) => OrderingTerm.desc(t.day),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  // ---------- 日历：特殊日子与放假安排 ----------

  /// 特殊日子（生日、纪念日等）：annualDate 非空的思绪，按 MM-DD 升序
  Stream<List<ThoughtEntry>> watchAnnualEvents() {
    return (select(thoughts)
          ..where((t) => t.annualDate.isNotNull())
          ..orderBy([(t) => OrderingTerm.asc(t.annualDate)]))
        .watch();
  }

  /// 放假标记（date 'yyyy-MM-dd' → 休/班）
  Stream<Map<String, DayFlag>> watchCalendarFlags() {
    return select(calendarFlags)
        .watch()
        .map((rows) => {for (final r in rows) r.date: r.flag});
  }

  /// 设置某天的休/班标记；flag 为 null 即清除
  Future<void> setCalendarFlag(String date, DayFlag? flag) async {
    if (flag == null) {
      await (delete(calendarFlags)..where((f) => f.date.equals(date))).go();
    } else {
      await into(calendarFlags).insertOnConflictUpdate(
        CalendarFlagsCompanion.insert(date: date, flag: flag),
      );
    }
  }

  // ---------- 标签 ----------

  /// 按名称查找标签（重名唯一）
  Future<Tag?> tagByName(String name) {
    return (select(tags)..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  /// 获取或创建标签（按名称唯一）；仅创建时应用 kind/icon/glyph/color
  Future<Tag> getOrCreateTag(
    String name, {
    TagKind kind = TagKind.normal,
    int? icon,
    String? glyph,
    int? color,
  }) async {
    final trimmed = name.trim();
    final existing =
        await (select(tags)..where((t) => t.name.equals(trimmed)))
            .getSingleOrNull();
    if (existing != null) return existing;
    final id = await into(tags).insert(
      TagsCompanion.insert(
        name: trimmed,
        kind: Value(kind.value),
        icon: Value(icon),
        glyph: Value(glyph),
        color: Value(color),
      ),
    );
    return (select(tags)..where((t) => t.id.equals(id))).getSingle();
  }

  /// 设置某条思绪的标签（整体替换；心情标签与普通标签同名唯一）
  Future<void> setThoughtTags(int thoughtId, List<String> names) async {
    await transaction(() async {
      await (delete(thoughtTags)
              ..where((t) => t.thoughtId.equals(thoughtId)))
          .go();
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

  /// 某条思绪的全部标签（一次性查询）
  Future<List<Tag>> tagsFor(int thoughtId) async {
    final q = select(thoughtTags).join([
      innerJoin(tags, tags.id.equalsExp(thoughtTags.tagId)),
    ])
      ..addColumns([tags.id, tags.name, tags.kind, tags.icon, tags.color, tags.createdAt])
      ..where(thoughtTags.thoughtId.equals(thoughtId));
    final rows = await q.get();
    return rows.map((r) => r.readTable(tags)).toList();
  }

  /// 全部思绪的标签映射（thoughtId → 标签列表）
  Stream<Map<int, List<Tag>>> watchAllThoughtTags() {
    final q = select(thoughtTags).join([
      innerJoin(tags, tags.id.equalsExp(thoughtTags.tagId)),
    ]);
    return q.watch().map((rows) {
      final map = <int, List<Tag>>{};
      for (final r in rows) {
        map
            .putIfAbsent(r.read(thoughtTags.thoughtId)!, () => [])
            .add(r.readTable(tags));
      }
      return map;
    });
  }

  /// 所有标签及其使用数量（按数量降序）
  Stream<List<TagWithCount>> watchTagsWithCount() {
    final usage = thoughts.id.count();
    final q = select(tags).join([
      leftOuterJoin(thoughtTags, thoughtTags.tagId.equalsExp(tags.id)),
      leftOuterJoin(thoughts, thoughts.id.equalsExp(thoughtTags.thoughtId)),
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
                    count: r.read(usage) ?? 0,
                  ))
              .toList(),
        );
  }

  /// 全部心情标签（编辑器选择用）
  Future<List<Tag>> moodTags() {
    return (select(tags)
          ..where((t) => t.kind.equals(TagKind.mood.value))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// 某个标签下的全部思绪
  Stream<List<ThoughtEntry>> watchEntriesWithTag(int tagId) {
    final q = select(thoughts).join([
      innerJoin(thoughtTags, thoughtTags.thoughtId.equalsExp(thoughts.id)),
    ])
      ..where(thoughtTags.tagId.equals(tagId))
      ..orderBy([
        OrderingTerm.desc(thoughts.day),
        OrderingTerm.desc(thoughts.createdAt),
      ]);
    return q.watch().map((rows) => rows.map((r) => r.readTable(thoughts)).toList());
  }

  /// 重命名标签；若新名称已存在则合并到已存在标签（联结行去重）
  Future<void> renameTag(int tagId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    await transaction(() async {
      final existing = await (select(tags)
              ..where((t) => t.name.equals(trimmed)))
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

/// 标签及其使用数量
class TagWithCount {
  final Tag tag;
  final int count;

  const TagWithCount({required this.tag, required this.count});
}
