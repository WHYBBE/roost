import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roost/data/app_database.dart';
import 'package:roost/data/thoughts_table.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.connect(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<ThoughtEntry> insert(
    String content, {
    required String day,
    Mood mood = Mood.calm,
    required DateTime createdAt,
  }) async {
    final id = await db.insertThought(
      content: content,
      mood: mood,
      day: day,
      createdAt: createdAt,
    );
    return ThoughtEntry(
      id: id,
      content: content,
      mood: mood,
      day: day,
      createdAt: createdAt.millisecondsSinceEpoch,
      updatedAt: createdAt.millisecondsSinceEpoch,
    );
  }

  test('insert / watchDay', () async {
    final now = DateTime(2026, 9, 16, 10, 30);
    final today = AppDatabase.formatDay(now);
    await insert('a', day: today, createdAt: now);
    await insert('b', day: today, createdAt: now.add(const Duration(minutes: 5)));
    await insert('old', day: '2026-09-15', createdAt: now);

    final dayEntries = await db.watchDay(today).first;
    expect(dayEntries, hasLength(2));
    // 倒序：后写的在前
    expect(dayEntries.first.content, 'b');
  });

  test('onThisDay matches same month-day in past years, excludes today', () async {
    final now = DateTime(2026, 9, 16, 10, 30);
    await insert('this year', day: '2026-09-16', createdAt: now);
    await insert('last year', day: '2025-09-16', createdAt: now);
    await insert('two years ago', day: '2024-09-16', createdAt: now);
    await insert('other day', day: '2025-09-17', createdAt: now);
    await insert('other month', day: '2025-08-16', createdAt: now);

    final memories = await db.onThisDay(month: 9, day: 16);
    final contents = memories.map((e) => e.content).toSet();
    expect(contents, {'last year', 'two years ago'});
    expect(contents, isNot(contains('this year')));
  });

  test('randomThoughts excludes today', () async {
    final now = DateTime(2026, 9, 16, 10, 30);
    await insert('today one', day: '2026-09-16', createdAt: now);
    await insert('today two', day: '2026-09-16', createdAt: now);
    await insert('past one', day: '2025-01-01', createdAt: now);

    final random = await db.randomThoughts(limit: 10);
    expect(random.map((e) => e.content), contains('past one'));
    expect(
      random.map((e) => e.day),
      everyElement(isNot('2026-09-16')),
    );
  });

  test('search filters by content and mood', () async {
    final now = DateTime(2026, 9, 16, 10, 30);
    await insert('flutter thoughts', day: '2026-09-16', createdAt: now, mood: Mood.happy);
    await insert('sql notes', day: '2026-09-15', createdAt: now, mood: Mood.calm);
    await insert('flutter again', day: '2026-09-14', createdAt: now, mood: Mood.calm);

    final all = await db.watchSearch('flutter').first;
    expect(all, hasLength(2));

    final filtered = await db.watchSearch('flutter', mood: Mood.calm).first;
    expect(filtered, hasLength(1));
    expect(filtered.first.content, 'flutter again');
  });

  test('update and delete', () async {
    final now = DateTime(2026, 9, 16, 10, 30);
    final day = AppDatabase.formatDay(now);
    final entry = await insert('original', day: day, createdAt: now);

    await db.updateThought(entry.id, 'updated', Mood.happy);
    final afterUpdate = await db.watchDay(day).first;
    expect(afterUpdate.single.content, 'updated');
    expect(afterUpdate.single.mood, Mood.happy);

    await db.deleteThought(entry.id);
    expect(await db.watchDay(day).first, isEmpty);
  });

  group('tags', () {
    late ThoughtEntry a;
    late ThoughtEntry b;
    final now = DateTime(2026, 9, 16, 10, 30);

    setUp(() async {
      a = await insert('flutter diary', day: '2026-09-16', createdAt: now);
      b = await insert('sql notes', day: '2026-09-15', createdAt: now);
    });

    test('getOrCreateTag 去重', () async {
      final t1 = await db.getOrCreateTag('工作');
      final t2 = await db.getOrCreateTag('工作 ');
      expect(t2.id, t1.id);
      expect(await db.select(db.tags).get(), hasLength(1));
    });

    test('setThoughtTags 整体替换并去重', () async {
      await db.setThoughtTags(a.id, ['flutter', '工作', 'flutter', '工作']);
      expect(await db.tagNamesFor(a.id), unorderedEquals(['flutter', '工作']));

      await db.setThoughtTags(a.id, ['flutter']);
      expect(await db.tagNamesFor(a.id), ['flutter']);
    });

    test('watchTagsWithCount 统计数量并排序', () async {
      await db.setThoughtTags(a.id, ['flutter', '工作']);
      await db.setThoughtTags(b.id, ['flutter']);

      final tags = await db.watchTagsWithCount().first;
      expect(tags, hasLength(2));
      expect(tags.first.tag.name, 'flutter');
      expect(tags.first.count, 2);
      expect(tags.last.tag.name, '工作');
      expect(tags.last.count, 1);
    });

    test('watchSearch 按标签过滤', () async {
      await db.setThoughtTags(a.id, ['flutter']);
      await db.setThoughtTags(b.id, ['sql']);

      expect((await db.watchSearch('', tagName: 'flutter').first), hasLength(1));
      expect(
        (await db.watchSearch('', tagName: 'flutter').first).single.content,
        'flutter diary',
      );
      // 不存在的标签 → 空结果
      expect((await db.watchSearch('', tagName: 'nope').first), isEmpty);
      // 无标签过滤 → 全部
      expect((await db.watchSearch('').first), hasLength(2));
    });

    test('watchEntriesWithTag', () async {
      await db.setThoughtTags(a.id, ['shared']);
      await db.setThoughtTags(b.id, ['shared']);

      final entries = await db.watchEntriesWithTag(
              (await db.getOrCreateTag('shared')).id)
          .first;
      expect(entries, hasLength(2));
    });

    test('renameTag 重命名，重名时合并', () async {
      await db.setThoughtTags(a.id, ['old']);
      await db.setThoughtTags(b.id, ['new']);

      await db.renameTag((await db.getOrCreateTag('old')).id, 'renamed');
      expect(await db.tagNamesFor(a.id), ['renamed']);
      expect((await db.watchTagsWithCount().first).length, 2);

      // 重命名为已存在的 'new' → 合并，'old' 标签消失
      await db.renameTag((await db.getOrCreateTag('renamed')).id, 'new');
      final tags = await db.watchTagsWithCount().first;
      expect(tags, hasLength(1));
      expect(tags.single.tag.name, 'new');
      expect(tags.single.count, 2);
      expect(await db.tagNamesFor(a.id), ['new']);
    });

    test('deleteTag 删除标签但保留思绪（联结行级联清理）', () async {
      await db.setThoughtTags(a.id, ['temp']);
      final tag = await db.getOrCreateTag('temp');

      await db.deleteTag(tag.id);
      expect(await db.watchTagsWithCount().first, isEmpty);
      expect(await db.tagNamesFor(a.id), isEmpty);
      // 思绪本身保留
      expect((await db.watchAllEntries().first).where((e) => e.id == a.id),
          isNotEmpty);
    });

    test('删除思绪时级联清理其标签联结行', () async {
      await db.setThoughtTags(a.id, ['flutter']);
      final tag = await db.getOrCreateTag('flutter');

      await db.deleteThought(a.id);
      // 'flutter' 标签仍存在（b 未使用它→count 0），但联结行已清理
      final tags = await db.watchTagsWithCount().first;
      expect(tags.single.tag.id, tag.id);
      expect(tags.single.count, 0);
    });
  });
}
