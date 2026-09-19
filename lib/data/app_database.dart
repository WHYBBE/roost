import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tag_presets.dart';
import 'thoughts_table.dart';

part 'app_database.g.dart';

/// Material Icons 使用 Unicode 私用区（0xE000-0xF8FF）；区外码点视为 emoji
bool isEmojiCodepoint(int codePoint) =>
    codePoint < 0xE000 || codePoint > 0xF8FF;

@DriftDatabase(tables: [Thoughts, Tags, ThoughtTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.connect(super.connection);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // 标签结构经历过不兼容重构：版本不一致直接清空重建
        onUpgrade: _wipeRebuild,
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          if (details.wasCreated || details.versionBefore != null) {
            await _seedMoodPresets();
          }
          await _repairTransparentSeedColors();
        },
      );

  Future<void> _wipeRebuild(Migrator m, int from, int to) async {
    await m.deleteTable('thought_tags');
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

  /// 修复历史种子数据中 alpha=0 的透明颜色（选择器只提供不透明候选，
  /// alpha=0 一定是旧种子 bug；幂等，每次打开执行）
  Future<void> _repairTransparentSeedColors() async {
    final moods =
        await (select(tags)..where((t) => t.kind.equals(TagKind.mood.value)))
            .get();
    for (final mood in moods) {
      final c = mood.color;
      if (c != null && (c & 0xFF000000) == 0) {
        await (update(tags)..where((t) => t.id.equals(mood.id))).write(
          TagsCompanion(color: Value(0xFF000000 | (c & 0xFFFFFF))),
        );
      }
    }
  }

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'roost',
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
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return into(thoughts).insert(
      ThoughtsCompanion.insert(
        content: content,
        day: day,
        createdAt: createdAt?.millisecondsSinceEpoch ?? now,
        updatedAt: now,
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
