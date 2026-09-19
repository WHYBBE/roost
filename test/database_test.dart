import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roost/data/app_database.dart';
import 'package:roost/data/tag_presets.dart';
import 'package:roost/data/thoughts_table.dart';
import 'package:roost/ui/mood.dart';
import 'package:roost/ui/tag_view.dart';

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
    required DateTime createdAt,
  }) async {
    final id = await db.insertThought(
      content: content,
      day: day,
      createdAt: createdAt,
    );
    return ThoughtEntry(
      id: id,
      content: content,
      day: day,
      createdAt: createdAt.millisecondsSinceEpoch,
      updatedAt: createdAt.millisecondsSinceEpoch,
    );
  }

  test('新建数据库自动播种 5 个心情标签', () async {
    final moods = await db.moodTags();
    expect(moods, hasLength(moodPresets.length));
    expect(moods.every((t) => t.tagKind == TagKind.mood), isTrue);
  });

  test('formatDay pads correctly', () {
    expect(AppDatabase.formatDay(DateTime(2026, 9, 16)), '2026-09-16');
    expect(AppDatabase.formatDay(DateTime(2026, 1, 2)), '2026-01-02');
  });

  test('heat level thresholds', () {
    expect(heatLevel(0), 0);
    expect(heatLevel(2), 2);
    expect(heatLevel(10), moodLevels.length - 1);
  });

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
    final now = DateTime.now();
    final today = AppDatabase.formatDay(now);
    final lastYear = AppDatabase.formatDay(DateTime(now.year - 1, now.month, now.day));
    final twoYearsAgo = AppDatabase.formatDay(DateTime(now.year - 2, now.month, now.day));
    await insert('this year', day: today, createdAt: now);
    await insert('last year', day: lastYear, createdAt: now);
    await insert('two years ago', day: twoYearsAgo, createdAt: now);
    await insert('other day', day: '2025-09-17', createdAt: now);
    await insert('other month', day: '2025-08-16', createdAt: now);

    final memories = await db.onThisDay(month: now.month, day: now.day);
    final contents = memories.map((e) => e.content).toSet();
    expect(contents, {'last year', 'two years ago'});
    expect(contents, isNot(contains('this year')));
  });

  test('randomThoughts excludes today', () async {
    final now = DateTime.now();
    final today = AppDatabase.formatDay(now);
    await insert('today one', day: today, createdAt: now);
    await insert('today two', day: today, createdAt: now);
    await insert('past one', day: '2025-01-01', createdAt: now);

    final random = await db.randomThoughts(limit: 10);
    expect(random.map((e) => e.content), contains('past one'));
    expect(
      random.map((e) => e.day),
      everyElement(isNot(today)),
    );
  });

  test('search filters by content and tag', () async {
    final now = DateTime(2026, 9, 16, 10, 30);
    final a = await insert('flutter thoughts', day: '2026-09-16', createdAt: now);
    final b = await insert('sql notes', day: '2026-09-15', createdAt: now);
    final c = await insert('flutter again', day: '2026-09-14', createdAt: now);
    await db.setThoughtTags(a.id, ['flutter']);
    await db.setThoughtTags(b.id, ['sql']);
    await db.setThoughtTags(c.id, ['flutter']);

    final all = await db.watchSearch('flutter').first;
    expect(all, hasLength(2));

    final filtered = await db.watchSearch('', tagName: 'flutter').first;
    expect(filtered, hasLength(2));

    final none = await db.watchSearch('', tagName: 'nope').first;
    expect(none, isEmpty);
  });

  test('update and delete', () async {
    final now = DateTime(2026, 9, 16, 10, 30);
    final day = AppDatabase.formatDay(now);
    final entry = await insert('original', day: day, createdAt: now);

    await db.updateThought(entry.id, 'updated');
    final afterUpdate = await db.watchDay(day).first;
    expect(afterUpdate.single.content, 'updated');

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

    test('getOrCreateTag 去重，kind 仅创建时生效', () async {
      final t1 = await db.getOrCreateTag('工作', kind: TagKind.mood);
      final t2 = await db.getOrCreateTag('工作 ');
      expect(t2.id, t1.id);
      expect(t2.tagKind, TagKind.mood);
    });

    test('setThoughtTags 整体替换并去重', () async {
      await db.setThoughtTags(a.id, ['flutter', '工作', 'flutter', '工作']);
      final names = (await db.tagsFor(a.id)).map((t) => t.name);
      expect(names, unorderedEquals(['flutter', '工作']));

      await db.setThoughtTags(a.id, ['flutter']);
      expect((await db.tagsFor(a.id)).map((t) => t.name), ['flutter']);
    });

    test('心情标签通过 setThoughtTags 标记后可用于筛选', () async {
      final mood = await db.getOrCreateTag('平静', kind: TagKind.mood);
      await db.setThoughtTags(a.id, [mood.name, 'flutter']);
      await db.setThoughtTags(b.id, ['flutter']);

      // 心情标签出现在 watchTagsWithCount 中（kind=mood, count>0）
      final tags = await db.watchTagsWithCount().first;
      final moodItem = tags.firstWhere((t) => t.tag.id == mood.id);
      expect(moodItem.count, 1);
      expect(moodItem.tag.tagKind, TagKind.mood);

      // 按心情标签名筛选
      final byMood = await db.watchSearch('', tagName: mood.name).first;
      expect(byMood, hasLength(1));
      expect(byMood.single.content, 'flutter diary');
    });

    test('watchAllThoughtTags 映射', () async {
      await db.setThoughtTags(a.id, ['flutter']);
      await db.setThoughtTags(b.id, ['flutter', 'sql']);

      final map = await db.watchAllThoughtTags().first;
      expect(map[a.id], hasLength(1));
      expect(map[b.id], hasLength(2));
    });

    test('watchEntriesWithTag', () async {
      await db.setThoughtTags(a.id, ['shared']);
      await db.setThoughtTags(b.id, ['shared']);

      final entries =
          await db.watchEntriesWithTag((await db.getOrCreateTag('shared')).id)
              .first;
      expect(entries, hasLength(2));
    });

    test('renameTag 重命名，重名时合并', () async {
      await db.setThoughtTags(a.id, ['old']);
      await db.setThoughtTags(b.id, ['new']);

      await db.renameTag((await db.getOrCreateTag('old')).id, 'renamed');
      expect((await db.tagsFor(a.id)).map((t) => t.name), ['renamed']);
      expect(
        (await db.watchTagsWithCount().first)
            .where((t) => t.tag.tagKind == TagKind.normal)
            .length,
        2,
      );

      // 重命名为已存在的 'new' → 合并，'renamed' 标签消失
      await db.renameTag((await db.getOrCreateTag('renamed')).id, 'new');
      final tags = await db.watchTagsWithCount().first;
      final normal = tags.where((t) => t.tag.tagKind == TagKind.normal).toList();
      expect(normal, hasLength(1));
      expect(normal.single.tag.name, 'new');
      expect(normal.single.count, 2);
      expect((await db.tagsFor(a.id)).map((t) => t.name), ['new']);
    });

    test('setTagAppearance 设置图标与颜色（可留空）', () async {
      final tag = await db.getOrCreateTag('styled');

      await db.setTagAppearance(tag.id,
          icon: 0x1F3E0, color: 0xFF009688);
      final after = (await db.watchTagsWithCount().first)
          .firstWhere((t) => t.tag.name == 'styled')
          .tag;
      expect(after.icon, 0x1F3E0);
      expect(after.color, 0xFF009688);

      // 留空 → 无图标/默认色
      await db.setTagAppearance(tag.id);
      final cleared = (await db.watchTagsWithCount().first)
          .firstWhere((t) => t.tag.name == 'styled')
          .tag;
      expect(cleared.icon, isNull);
      expect(cleared.color, isNull);
    });

    test('deleteTag 删除标签但保留思绪（联结行级联清理）', () async {
      await db.setThoughtTags(a.id, ['temp']);
      final tag = await db.getOrCreateTag('temp');

      await db.deleteTag(tag.id);
      expect(
        (await db.watchTagsWithCount().first)
            .where((t) => t.tag.tagKind == TagKind.normal),
        isEmpty,
      );
      expect(await db.tagsFor(a.id), isEmpty);
      // 思绪本身保留
      expect((await db.watchAllEntries().first).where((e) => e.id == a.id),
          isNotEmpty);
    });

    test('修复历史种子遗留的透明颜色', () async {
      final dir = await Directory.systemTemp.createTemp('roost_test');
      final path = '${dir.path}/repair.sqlite';

      // 第一次打开：播种后注入旧种子 bug（全部心情标签 alpha=0）
      var d = AppDatabase.connect(NativeDatabase(File(path)));
      await d.customStatement('UPDATE tags SET color = 16757504 WHERE kind = 1');
      await d.close();

      // 重连：beforeOpen 应修复透明色
      d = AppDatabase.connect(NativeDatabase(File(path)));
      final moods = (await d.watchTagsWithCount().first)
          .where((t) => t.tag.tagKind == TagKind.mood)
          .toList();
      expect(moods, isNotEmpty);
      expect(moods.every((t) => (t.tag.color! & 0xFF000000) != 0), isTrue);
      await d.close();
      await dir.delete(recursive: true);
    });

    test('glyph 字符图标持久化，与 icon 互斥', () async {
      final t = await db.getOrCreateTag('自定义', glyph: '⚡', color: 0xFF112233);
      expect(t.glyph, '⚡');
      expect(t.hasIcon, isTrue);
      expect(t.displayGlyph, '⚡');

      // 改成 Material 图标：glyph 应清空
      await db.setTagAppearance(t.id, icon: Icons.star.codePoint, color: null);
      final after = await db.tagByName('自定义');
      expect(after?.glyph, isNull);
      expect(after?.icon, Icons.star.codePoint);

      // 改回任意多字符
      await db.setTagAppearance(t.id, glyph: '哈哈', color: 0xFF112233);
      final back = await db.tagByName('自定义');
      expect(back?.displayGlyph, '哈哈');
    });

    test('删除思绪时级联清理其标签联结行', () async {
      await db.setThoughtTags(a.id, ['flutter']);
      final tag = await db.getOrCreateTag('flutter');

      await db.deleteThought(a.id);
      // 'flutter' 标签仍存在（无使用者→count 0），但联结行已清理
      final normal = (await db.watchTagsWithCount().first)
          .where((t) => t.tag.tagKind == TagKind.normal)
          .toList();
      expect(normal.single.tag.id, tag.id);
      expect(normal.single.count, 0);
    });
  });
}
