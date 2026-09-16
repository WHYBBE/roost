import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'thoughts_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Thoughts, Tags, ThoughtTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.connect(super.connection);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(tags);
            await m.createTable(thoughtTags);
          }
        },
        beforeOpen: (details) async {
          // 思绪删除时级联删除其标签联结行
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _open() {
    return driftDatabase(
      name: 'roost',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  // ---------- 写入 ----------

  Future<int> insertThought({
    required String content,
    required Mood mood,
    required String day,
    DateTime? createdAt,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return into(thoughts).insert(
      ThoughtsCompanion.insert(
        content: content,
        mood: mood,
        day: day,
        createdAt: createdAt?.millisecondsSinceEpoch ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<int> updateThought(int id, String content, Mood mood) {
    return (update(thoughts)..where((t) => t.id.equals(id))).write(
      ThoughtsCompanion(
        content: Value(content),
        mood: Value(mood),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<int> deleteThought(int id) {
    return (delete(thoughts)..where((t) => t.id.equals(id))).go();
  }

  // ---------- 查询 ----------

  /// 搜索全部思绪（内容 LIKE + 可选心情/标签过滤），按日期分组排列
  Stream<List<ThoughtEntry>> watchSearch(String query,
      {Mood? mood, String? tagName}) {
    final joined = (select(thoughts)
          ..where((t) {
            final content = query.trim();
            final like = content.isEmpty
                ? const Constant(true)
                : t.content.like('%$content%');
            if (mood != null) {
              return like & t.mood.equalsValue(mood);
            }
            return like;
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

  static String formatDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String today() => formatDay(DateTime.now());

  // ---------- 标签 ----------

  /// 获取或创建标签（按名称唯一）
  Future<Tag> getOrCreateTag(String name) async {
    final trimmed = name.trim();
    final existing = await (select(tags)..where((t) => t.name.equals(trimmed)))
        .getSingleOrNull();
    if (existing != null) return existing;
    final id = await into(tags).insert(TagsCompanion.insert(name: trimmed));
    return (select(tags)..where((t) => t.id.equals(id))).getSingle();
  }

  /// 设置某条思绪的标签（整体替换）
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

  /// 某条思绪的标签名（一次性查询）
  Future<List<String>> tagNamesFor(int thoughtId) async {
    final q = select(thoughtTags).join([
      innerJoin(tags, tags.id.equalsExp(thoughtTags.tagId)),
    ])
      ..addColumns([tags.name])
      ..where(thoughtTags.thoughtId.equals(thoughtId));
    final rows = await q.get();
    return rows.map((r) => r.read(tags.name)!).toList();
  }

  /// 全部思绪的标签名映射（thoughtId → 标签名列表）
  Stream<Map<int, List<String>>> watchAllTagNames() {
    final q = select(thoughtTags).join([
      innerJoin(tags, tags.id.equalsExp(thoughtTags.tagId)),
    ])
      ..addColumns([thoughtTags.thoughtId, tags.name]);
    return q.watch().map((rows) {
      final map = <int, List<String>>{};
      for (final r in rows) {
        map
            .putIfAbsent(r.read(thoughtTags.thoughtId)!, () => [])
            .add(r.read(tags.name)!);
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

  /// 删除标签（联结行由外键级联删除，思绪保留）
  Future<void> deleteTag(int tagId) async {
    await (delete(tags)..where((t) => t.id.equals(tagId))).go();
  }
}

/// 标签及其使用数量
class TagWithCount {
  final Tag tag;
  final int count;

  const TagWithCount({required this.tag, required this.count});
}
