import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'thoughts_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Thoughts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.connect(super.connection);

  @override
  int get schemaVersion => 1;

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

  /// 搜索全部思绪（内容 LIKE + 可选心情过滤），按日期分组排列
  Stream<List<ThoughtEntry>> watchSearch(String query, {Mood? mood}) {
    return (select(thoughts)
          ..where((t) {
            final q = query.trim();
            final like = q.isEmpty ? const Constant(true) : t.content.like('%$q%');
            if (mood != null) {
              return like & t.mood.equalsValue(mood);
            }
            return like;
          })
          ..orderBy([
            (t) => OrderingTerm.desc(t.day),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
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
}
