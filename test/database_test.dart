import 'dart:io';

import 'package:drift/drift.dart' show Value;
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
      locked: false,
      starred: false,
    );
  }

  test('新建数据库自动播种内置"心情"高级标签组（5 个选项）', () async {
    final moodCat = await db.watchMoodCategory().first;
    expect(moodCat, isNotNull);
    expect(moodCat!.builtin, isTrue);
    expect(moodCat.multi, isFalse);
    final options = await db.categoryTags(moodCat.id);
    expect(options, hasLength(moodPresets.length));
    expect(options.every((t) => t.icon != null && t.color != null), isTrue);
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
    await db.setThoughtNormalTags(a.id, ['flutter']);
    await db.setThoughtNormalTags(b.id, ['sql']);
    await db.setThoughtNormalTags(c.id, ['flutter']);

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

  test('updateThought 可改记录日（补记与改日期）', () async {
    final now = DateTime(2026, 9, 16, 10, 30);
    final entry = await insert('a', day: '2026-09-16', createdAt: now);

    await db.updateThought(entry.id, 'a', day: '2026-09-10');
    expect(await db.watchDay('2026-09-10').first, hasLength(1));
    expect(await db.watchDay('2026-09-16').first, isEmpty);

    // 不传 day 时保持原记录日
    await db.updateThought(entry.id, 'a2');
    expect((await db.watchDay('2026-09-10').first).single.content, 'a2');
  });

  group('writing templates', () {
    test('新建按顺序追加，可上移/下移/编辑/删除', () async {
      final a = await db.createEntryTemplate(
          name: '今日三问', content: '1. 发生了什么？\n2. 学到了什么？\n3. 感恩什么？');
      final b = await db.createEntryTemplate(name: '晨间日记', content: '天气：');

      var list = await db.watchEntryTemplates().first;
      expect(list.map((t) => t.name), ['今日三问', '晨间日记']);

      // 下移第一个 → 顺序交换
      await db.moveEntryTemplate(a, 1);
      list = await db.watchEntryTemplates().first;
      expect(list.map((t) => t.name), ['晨间日记', '今日三问']);
      // 越界移动无效
      await db.moveEntryTemplate(a, 1);
      list = await db.watchEntryTemplates().first;
      expect(list.map((t) => t.name), ['晨间日记', '今日三问']);

      await db.updateEntryTemplate(a, name: '今日三问', content: '更新后的内容');
      list = await db.watchEntryTemplates().first;
      expect(list.firstWhere((t) => t.id == a).content, '更新后的内容');

      await db.deleteEntryTemplate(b);
      list = await db.watchEntryTemplates().first;
      expect(list, hasLength(1));
      expect(list.single.id, a);
    });

    test('导出/导入往返：同名模板不重复', () async {
      await db.createEntryTemplate(name: '今日三问', content: '问题一\n问题二');
      final data = await db.exportData();
      final templates = (data['templates'] as List);
      expect(templates, hasLength(1));
      expect((templates.single as Map)['name'], '今日三问');

      final other = AppDatabase.connect(NativeDatabase.memory());
      await other.importData(data);
      // 再次导入应跳过同名
      await other.importData(data);
      final list = await other.watchEntryTemplates().first;
      expect(list, hasLength(1));
      expect(list.single.content, '问题一\n问题二');
      await other.close();
    });
  });

  group('starred', () {
    test('收藏：仅活跃且按天倒序，切换与归档生效', () async {
      final now = DateTime(2026, 9, 16, 10, 30);
      final a = await insert('a', day: '2026-09-16', createdAt: now);
      final b = await insert('b', day: '2026-09-10', createdAt: now);

      await db.setThoughtStarred(a.id, true);
      await db.setThoughtStarred(b.id, true);
      var list = await db.watchStarredEntries().first;
      expect(list.map((e) => e.content), ['a', 'b']);

      // 取消收藏
      await db.setThoughtStarred(a.id, false);
      list = await db.watchStarredEntries().first;
      expect(list.map((e) => e.content), ['b']);

      // 归档后不再出现在收藏视图
      await db.archiveThought(b.id);
      expect(await db.watchStarredEntries().first, isEmpty);
    });

    test('导出/导入往返：星标保留', () async {
      final now = DateTime(2026, 9, 16, 10, 30);
      final a = await insert('a', day: '2026-09-16', createdAt: now);
      await db.setThoughtStarred(a.id, true);

      final data = await db.exportData();
      final other = AppDatabase.connect(NativeDatabase.memory());
      await other.importData(data);
      final list = await other.watchStarredEntries().first;
      expect(list, hasLength(1));
      expect(list.single.starred, isTrue);
      await other.close();
    });
  });

  group('attachments', () {
    final now = DateTime(2026, 9, 16, 10, 30);

    test('插入/读取附件，blob 独立存储', () async {
      final entry = await insert('带图思绪', day: '2026-09-16', createdAt: now);
      final a = await db.insertAttachment(
        thoughtId: entry.id,
        kind: AttachmentKind.image,
        mime: 'image/png',
        bytes: [1, 2, 3, 4],
      );
      expect(a.kind, AttachmentKind.image);
      expect(a.mime, 'image/png');
      expect(a.sizeBytes, 4);
      expect(a.durationMs, isNull);
      expect(await db.attachmentData(a.id), [1, 2, 3, 4]);
      expect((await db.watchAttachmentsFor(entry.id).first).single.id, a.id);
    });

    test('音频附件带时长，全部分组流', () async {
      final entry = await insert('带音频', day: '2026-09-16', createdAt: now);
      final a = await db.insertAttachment(
        thoughtId: entry.id,
        kind: AttachmentKind.audio,
        mime: 'audio/mp4',
        bytes: List.generate(10, (i) => i),
        durationMs: 30000,
      );
      expect(a.durationMs, 30000);
      final map = await db.watchAllAttachmentMeta().first;
      expect(map[entry.id]!.single.id, a.id);
    });

    test('删除思绪级联清理附件与 blob；也可单独删附件', () async {
      final e1 = await insert('one', day: '2026-09-16', createdAt: now);
      final e2 = await insert('two', day: '2026-09-16', createdAt: now);
      final a1 = await db.insertAttachment(
        thoughtId: e1.id,
        kind: AttachmentKind.image,
        mime: 'image/jpeg',
        bytes: [9],
      );
      final a2 = await db.insertAttachment(
        thoughtId: e2.id,
        kind: AttachmentKind.audio,
        mime: 'audio/mp4',
        bytes: [8],
        durationMs: 1000,
      );
      await db.deleteAttachment(a2.id);
      expect(await db.attachmentData(a2.id), isNull);
      await db.deleteThought(e1.id);
      expect(await db.attachmentData(a1.id), isNull);
      expect(await db.watchAllAttachmentMeta().first, isEmpty);
    });

    test('导出导入往返：附件跟随新思绪，重复思绪不重复附加', () async {
      final entry = await insert('有附件', day: '2026-09-16', createdAt: now);
      await db.insertAttachment(
        thoughtId: entry.id,
        kind: AttachmentKind.audio,
        mime: 'audio/mp4',
        bytes: [1, 2, 3],
        durationMs: 5000,
      );
      final data = await db.exportData();
      expect(data['attachments'], hasLength(1));

      // 另一个空库导入
      var other = AppDatabase.connect(NativeDatabase.memory());
      final count = await other.importData(data);
      expect(count, 1);
      final importedThoughts = await other.select(other.thoughts).get();
      final importedAtts = await other.select(other.attachments).get();
      final importedBlob = await other.select(other.attachmentBlobs).get();
      expect(importedThoughts, hasLength(1));
      expect(importedAtts.single.durationMs, 5000);
      expect(importedBlob.single.data, [1, 2, 3]);
      await other.close();

      // 重复导入：思绪去重，附件不追加
      other = AppDatabase.connect(NativeDatabase.memory());
      await other.importData(data);
      await other.importData(data);
      expect(await other.select(other.attachments).get(), hasLength(1));
      await other.close();
    });
  });

  group('tags', () {
    late ThoughtEntry a;
    late ThoughtEntry b;
    final now = DateTime(2026, 9, 16, 10, 30);

    setUp(() async {
      a = await insert('flutter diary', day: '2026-09-16', createdAt: now);
      b = await insert('sql notes', day: '2026-09-15', createdAt: now);
    });

    Future<int> moodCategoryId() async =>
        (await db.watchMoodCategory().first)!.id;

    test('getOrCreateTag 同组内去重；跨组同名互不影响', () async {
      final t1 = await db.getOrCreateTag('工作 ');
      final t2 = await db.getOrCreateTag('工作');
      expect(t2.id, t1.id);
      expect(t2.categoryId, isNull);

      final cat = await db.createTagCategory(name: '项目');
      final inCat = await db.getOrCreateTag('工作', categoryId: cat);
      expect(inCat.id, isNot(t1.id));
      expect(inCat.categoryId, cat);
      final again = await db.getOrCreateTag('工作', categoryId: cat);
      expect(again.id, inCat.id);
    });

    test('setThoughtNormalTags 整体替换并去重（不影响高级标签）', () async {
      final moodCat = await moodCategoryId();
      await db.setThoughtCategoryTags(a.id, moodCat, ['平静']);
      await db.setThoughtNormalTags(a.id, ['flutter', '工作', 'flutter']);
      final tags = await db.tagsFor(a.id);
      expect(tags.where((t) => t.isNormal).map((t) => t.tag.name),
          unorderedEquals(['flutter', '工作']));
      expect(tags.where((t) => !t.isNormal).map((t) => t.tag.name), ['平静']);

      await db.setThoughtNormalTags(a.id, ['flutter']);
      final after = await db.tagsFor(a.id);
      expect(after.where((t) => t.isNormal).map((t) => t.tag.name), ['flutter']);
      expect(after.where((t) => !t.isNormal), hasLength(1));
    });

    test('高级标签组：单选只保留一个，多选可多个', () async {
      final single = await db.createTagCategory(name: '天气');
      final multi = await db.createTagCategory(name: '食物', multi: true);
      await db.setThoughtCategoryTags(a.id, single, ['晴', '雨']);
      await db.setThoughtCategoryTags(a.id, multi, ['面', '饭', '面']);
      final tags = await db.tagsFor(a.id);
      expect(
        tags.where((t) => t.category?.id == single).map((t) => t.tag.name),
        ['晴'],
      );
      expect(
        tags
            .where((t) => t.category?.id == multi)
            .map((t) => t.tag.name)
            .toSet(),
        {'面', '饭'},
      );
    });

    test('思绪添加/移除标签组；移除时该组标签值一并移除，选项定义保留', () async {
      final cat = await db.createTagCategory(name: '洗澡');
      await db.addThoughtCategory(a.id, cat);
      await db.setThoughtCategoryTags(a.id, cat, ['已洗']);
      expect(await db.thoughtCategoryIds(a.id), {cat});

      await db.removeThoughtCategory(a.id, cat);
      expect(await db.thoughtCategoryIds(a.id), isEmpty);
      expect(
        (await db.tagsFor(a.id)).where((t) => t.category?.id == cat),
        isEmpty,
      );
      expect(await db.categoryTags(cat), hasLength(1));
    });

    test('删除标签组级联清理选项与思绪关联', () async {
      final cat = await db.createTagCategory(name: '天气');
      await db.addThoughtCategory(a.id, cat);
      await db.setThoughtCategoryTags(a.id, cat, ['晴']);
      await db.deleteTagCategory(cat);
      expect(await db.watchTagCategories().first.then(
            (list) => list.where((c) => c.id == cat).toList(),
          ), isEmpty);
      expect(await db.categoryTags(cat), isEmpty);
      expect(await db.thoughtCategoryIds(a.id), isEmpty);
      expect(await db.tagsFor(a.id), isEmpty);
    });

    test('内置"心情"组不可删除', () async {
      final moodCat = await moodCategoryId();
      await db.deleteTagCategory(moodCat);
      expect(
        (await db.watchTagCategories().first).where((c) => c.id == moodCat),
        hasLength(1),
      );
    });

    test('心情标签（内置组）用于计数与筛选', () async {
      final moodCat = await moodCategoryId();
      await db.addThoughtCategory(a.id, moodCat);
      await db.setThoughtCategoryTags(a.id, moodCat, ['平静']);
      await db.setThoughtNormalTags(b.id, ['flutter']);

      final tags = await db.watchTagsWithCount().first;
      final moodItem = tags.firstWhere((t) => t.tag.name == '平静');
      expect(moodItem.count, 1);
      expect(moodItem.category?.builtin, isTrue);

      final byMood = await db.watchSearch('', tagName: '平静').first;
      expect(byMood, hasLength(1));
      expect(byMood.single.content, 'flutter diary');
    });

    test('watchAllThoughtTags 映射（含所属组）', () async {
      final moodCat = await moodCategoryId();
      await db.setThoughtNormalTags(a.id, ['flutter']);
      await db.setThoughtCategoryTags(a.id, moodCat, ['平静']);
      await db.setThoughtNormalTags(b.id, ['flutter', 'sql']);

      final map = await db.watchAllThoughtTags().first;
      expect(map[a.id], hasLength(2));
      expect(map[a.id]!.where((t) => t.isBuiltin), hasLength(1));
      expect(map[b.id], hasLength(2));
    });

    test('watchEntriesWithTag', () async {
      await db.setThoughtNormalTags(a.id, ['shared']);
      await db.setThoughtNormalTags(b.id, ['shared']);

      final entries = await db
          .watchEntriesWithTag((await db.getOrCreateTag('shared')).id)
          .first;
      expect(entries, hasLength(2));
    });

    test('renameTag 重命名，同组重名时合并', () async {
      await db.setThoughtNormalTags(a.id, ['old']);
      await db.setThoughtNormalTags(b.id, ['new']);

      await db.renameTag((await db.getOrCreateTag('old')).id, 'renamed');
      expect((await db.tagsFor(a.id)).map((t) => t.tag.name), ['renamed']);
      expect(
        (await db.watchTagsWithCount().first)
            .where((t) => t.category == null)
            .length,
        2,
      );

      // 重命名为已存在的 'new' → 合并，'renamed' 标签消失
      await db.renameTag((await db.getOrCreateTag('renamed')).id, 'new');
      final tags = await db.watchTagsWithCount().first;
      final normal = tags.where((t) => t.category == null).toList();
      expect(normal, hasLength(1));
      expect(normal.single.tag.name, 'new');
      expect(normal.single.count, 2);
      expect((await db.tagsFor(a.id)).map((t) => t.tag.name), ['new']);
    });

    test('setTagAppearance 设置图标与颜色（可留空）', () async {
      final tag = await db.getOrCreateTag('styled');

      await db.setTagAppearance(tag.id, icon: 0x1F3E0, color: 0xFF009688);
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
      await db.setThoughtNormalTags(a.id, ['temp']);
      final tag = await db.getOrCreateTag('temp');

      await db.deleteTag(tag.id);
      expect(
        (await db.watchTagsWithCount().first)
            .where((t) => t.category == null),
        isEmpty,
      );
      expect(await db.tagsFor(a.id), isEmpty);
      // 思绪本身保留
      expect((await db.watchAllEntries().first).where((e) => e.id == a.id),
          isNotEmpty);
    });

    test('用户删除的预设心情不会重新播种', () async {
      final dir = await Directory.systemTemp.createTemp('roost_test');
      final path = '${dir.path}/noseed.sqlite';

      var d = AppDatabase.connect(NativeDatabase(File(path)));
      await d.customStatement("DELETE FROM tags WHERE name = 'Happy'");
      await d.close();

      // 重连：正常打开不播种，删除的预设不复活
      d = AppDatabase.connect(NativeDatabase(File(path)));
      final names = (await d.select(d.tags).get()).map((t) => t.name).toSet();
      expect(names.contains('Happy'), isFalse);
      expect(names.contains('Calm'), isTrue);
      await d.close();
      await dir.delete(recursive: true);
    });

    test('清空全部数据并恢复预设心情；自定义标签组一并清空', () async {
      await db.setThoughtNormalTags(a.id, ['工作']);
      await db.createTagCategory(name: '天气');
      await db.resetAllData();
      expect(await db.select(db.thoughts).get(), isEmpty);
      expect(await db.select(db.thoughtTags).get(), isEmpty);
      expect(await db.select(db.thoughtCategories).get(), isEmpty);
      final cats = await db.watchTagCategories().first;
      expect(cats.where((c) => !c.builtin), isEmpty);
      final moodCat = cats.firstWhere((c) => c.builtin);
      final options = await db.categoryTags(moodCat.id);
      expect(options, hasLength(moodPresets.length));
      expect(options.every((t) => t.icon != null && t.color != null), isTrue);
    });

    test('重置心情标签：预设恢复，普通标签与思绪保留', () async {
      final t2 = await insert('另一条',
          day: AppDatabase.today(), createdAt: DateTime(2026, 9, 19, 9));
      final moodCat = await moodCategoryId();
      final custom = await db.getOrCreateTag('心情X',
          categoryId: moodCat, icon: 1, color: 2);
      await db.addThoughtCategory(a.id, moodCat);
      await db.setThoughtCategoryTags(a.id, moodCat, [custom.name]);
      await db.setThoughtNormalTags(a.id, ['工作']);
      await db.resetMoodTags();
      // 自定义心情被清掉，预设已恢复
      final options = await db.categoryTags(moodCat);
      expect(options.map((t) => t.name), isNot(contains('心情X')));
      expect(options, hasLength(moodPresets.length));
      // 心情联结被清掉，普通标签与思绪保留
      expect((await db.tagsFor(a.id)).map((t) => t.tag.name), ['工作']);
      expect((await db.watchAllEntries().first).map((e) => e.id),
          containsAll([a.id, t2.id]));
    });

    test('导出/清空/导入（合并）往返：普通标签、高级标签组与关联', () async {
      final t2 = await insert('第二条',
          day: '2026-09-18', createdAt: DateTime(2026, 9, 18, 9));
      final moodCat = await moodCategoryId();
      final weather = await db.createTagCategory(name: '天气', multi: true);
      await db.addThoughtCategory(a.id, moodCat);
      await db.setThoughtCategoryTags(a.id, moodCat, ['焦虑']);
      await db.addThoughtCategory(t2.id, weather);
      await db.setThoughtCategoryTags(t2.id, weather, ['晴']);
      await db.setThoughtNormalTags(t2.id, ['工作']);
      // 手动改一下心情标签外观，验证导入合并时沿用现有定义
      await db.setTagAppearance(
          (await db.tagByName('焦虑', categoryId: moodCat))!.id,
          color: 0xFF123456);

      final data = await db.exportData();
      expect((data['thoughts'] as List), hasLength(3));
      expect((data['tags'] as List), isNotEmpty);
      expect((data['tagCategories'] as List), isNotEmpty);
      expect((data['thoughtCategories'] as List), isNotEmpty);

      await db.resetAllData();
      expect(await db.select(db.thoughts).get(), isEmpty);

      final count = await db.importData(data);
      expect(count, 3);
      final entries = await db.watchAllEntries().first;
      expect(entries, hasLength(3));
      final restored = entries.firstWhere((e) => e.content == a.content);
      final restoredTags = await db.tagsFor(restored.id);
      expect(restoredTags.map((t) => t.tag.name), contains('焦虑'));
      expect(restoredTags.where((t) => t.isBuiltin), hasLength(1));
      // 导入时沿用现有标签定义（自定义颜色保留）；内置组重建后 id 变化
      final moodCat2 = (await db.watchMoodCategory().first)!.id;
      final mood = await db.tagByName('焦虑', categoryId: moodCat2);
      expect(mood?.color, 0xFF123456);
      // 自定义标签组与选项随导入恢复
      final weatherIn =
          (await db.watchTagCategories().first).firstWhere((c) => c.name == '天气');
      expect(weatherIn.multi, isTrue);
      expect((await db.categoryTags(weatherIn.id)).map((t) => t.name), ['晴']);

      // 再次导入：全部命中去重，不新增
      expect(await db.importData(data), 0);
      expect((await db.watchAllEntries().first), hasLength(3));
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
      await db.setThoughtNormalTags(a.id, ['flutter']);
      final tag = await db.getOrCreateTag('flutter');

      await db.deleteThought(a.id);
      // 'flutter' 标签仍存在（无使用者→count 0），但联结行已清理
      final normal = (await db.watchTagsWithCount().first)
          .where((t) => t.category == null)
          .toList();
      expect(normal.single.tag.id, tag.id);
      expect(normal.single.count, 0);
    });
  });

  group('calendar', () {
    test('特殊日子：annualDate 思绪可查询，同时也是普通思绪', () async {
      final now = DateTime(2026, 9, 20, 10, 30);
      await db.insertThought(
        content: '妈妈的生日',
        day: '2026-09-20',
        createdAt: now,
        annualDate: '03-08',
      );
      await db.insertThought(
        content: '普通思绪',
        day: '2026-09-20',
        createdAt: now.add(const Duration(minutes: 5)),
      );

      final events = await db.watchAnnualEvents().first;
      expect(events, hasLength(1));
      expect(events.single.annualDate, '03-08');
      expect(events.single.content, '妈妈的生日');

      // 万物皆思绪：特殊日子也在全部思绪流里
      final all = await db.watchAllEntries().first;
      expect(all, hasLength(2));
    });

    test('事件模型：区间与每年循环的日期展开', () async {
      final holidayType = await db.createEventType(
        name: '2026 法定节假日',
        color: 0xFFCF4B3F,
        glyph: '休',
      );
      await db.insertEvent(
        typeId: holidayType,
        startDate: '2026-10-01',
        endDate: '2026-10-03',
        title: '国庆',
      );
      final events = await db.watchEvents().first;
      expect(events, hasLength(1));
      expect(
        AppDatabase.eventDaysInYear(events.single, 2026),
        ['2026-10-01', '2026-10-02', '2026-10-03'],
      );

      // 跨年区间：按年裁剪
      final travelType = await db.createEventType(
        name: '旅行',
        color: 0xFF4A7DC4,
      );
      final tripId = await db.insertEvent(
        typeId: travelType,
        startDate: '2026-12-30',
        endDate: '2027-01-02',
      );
      final trip = (await db.watchEvents().first).firstWhere((e) => e.id == tripId);
      expect(
        AppDatabase.eventDaysInYear(trip, 2026),
        ['2026-12-30', '2026-12-31'],
      );
      expect(
        AppDatabase.eventDaysInYear(trip, 2027),
        ['2027-01-01', '2027-01-02'],
      );

      // 每年循环：按 startDate 的月-日展开到目标年
      final annualId = await db.insertEvent(
        typeId: travelType,
        startDate: '2015-05-04',
        annual: true,
      );
      final annual =
          (await db.watchEvents().first).firstWhere((e) => e.id == annualId);
      expect(annual.annual, isTrue);
      expect(AppDatabase.eventDaysInYear(annual, 2026), ['2026-05-04']);
    });

    test('事件的编辑与删除', () async {
      final typeId = await db.createEventType(name: '周期', color: 0xFFCF9F3F);
      final id = await db.insertEvent(typeId: typeId, startDate: '2026-09-01');
      await db.updateEvent(
        id,
        startDate: '2026-09-05',
        endDate: '2026-09-07',
        title: '记录',
        annual: false,
      );
      final e = (await db.watchEvents().first).single;
      expect(e.startDate, '2026-09-05');
      expect(e.endDate, '2026-09-07');
      expect(e.title, '记录');
      await db.deleteEvent(id);
      expect(await db.watchEvents().first, isEmpty);
    });

    test('删除类型级联删除其下事件', () async {
      final typeId = await db.createEventType(name: '类型', color: 0xFF112233);
      await db.insertEvent(typeId: typeId, startDate: '2026-01-01');
      await db.insertEvent(typeId: typeId, startDate: '2026-02-01');
      await db.deleteEventType(typeId);
      expect(await db.watchEventTypes().first, isEmpty);
      expect(await db.watchEvents().first, isEmpty);
    });

    test('类型种类：节假日/生日特殊类型持久化，状态随类型', () async {
      final holidayId = await db.createEventType(
        name: '2026 法定节假日',
        color: 0xFFCF4B3F,
        glyph: '休',
        kind: EventTypeKind.holiday,
        statuses: [
          EventStatusesCompanion.insert(
            typeId: 0, name: '放假', color: 0xFFCF4B3F, glyph: const Value('休')),
          EventStatusesCompanion.insert(
            typeId: 0, name: '补班', color: 0xFF3F7DCF, glyph: const Value('班')),
        ],
      );
      await db.createEventType(
        name: '生日',
        color: 0xFFCF9F3F,
        glyph: '🎂',
        kind: EventTypeKind.birthday,
      );
      final types = await db.watchEventTypes().first;
      expect(types[0].kind, EventTypeKind.holiday);
      expect(types[1].kind, EventTypeKind.birthday);
      // 状态随类型种入，按 sortOrder 排序
      final statuses = await db.statusesFor(holidayId);
      expect(statuses.map((s) => s.name), ['放假', '补班']);
      expect(statuses[0].glyph, '休');
      expect(statuses[0].color, 0xFFCF4B3F);

      // 往返保留（状态含 id 重映射）
      final data = await db.exportData();
      final db2 = AppDatabase.connect(NativeDatabase.memory());
      addTearDown(db2.close);
      await db2.importData(data);
      final imported = await db2.watchEventTypes().first;
      expect(imported[0].kind, EventTypeKind.holiday);
      expect(imported[1].kind, EventTypeKind.birthday);
      final importedStatuses =
          await db2.statusesFor(imported[0].id);
      expect(importedStatuses.map((s) => s.name), ['放假', '补班']);
      expect(importedStatuses[0].glyph, '休');
    });

    test('事件联动思绪（万物皆思绪）', () async {
      final typeId = await db.createEventType(name: '生日', color: 0xFFCF9F3F);
      final thoughtId = await db.insertThought(
        content: '妈妈的生日',
        day: '2026-03-08',
        createdAt: DateTime(2026, 3, 8, 9),
      );
      await db.insertEvent(
        typeId: typeId,
        startDate: '2026-03-08',
        annual: true,
        thoughtId: thoughtId,
      );
      final e = (await db.watchEvents().first).single;
      expect(e.thoughtId, thoughtId);
      // 删除思绪：事件保留，联动置空
      await db.deleteThought(thoughtId);
      final kept = (await db.watchEvents().first).single;
      expect(kept.thoughtId, isNull);
    });

    test('计数器：+1 累计、-1 清零删行', () async {
      final typeId = await db.createEventType(
        name: '打卡',
        color: 0xFF4CAF50,
        counter: true,
      );
      // 普通（非计数器）类型不受影响
      final normalType = await db.createEventType(name: '事件', color: 0xFF112233);

      await db.incrementCounter(typeId: typeId, date: '2026-09-20');
      await db.incrementCounter(typeId: typeId, date: '2026-09-20');
      await db.incrementCounter(typeId: typeId, date: '2026-09-21');
      var rows = await db.watchEvents().first;
      expect(rows.where((e) => e.typeId == typeId), hasLength(2));
      final day1 = rows.firstWhere(
          (e) => e.typeId == typeId && e.startDate == '2026-09-20');
      expect(day1.count, 2);

      // 计数行不算区间/循环事件
      expect(day1.endDate, isNull);
      expect(day1.annual, isFalse);

      // -1 到 0：行删除
      await db.decrementCounter(typeId: typeId, date: '2026-09-20');
      await db.decrementCounter(typeId: typeId, date: '2026-09-20');
      rows = await db.watchEvents().first;
      expect(
        rows.where(
            (e) => e.typeId == typeId && e.startDate == '2026-09-20'),
        isEmpty,
      );
      // 无行时 -1 忽略不崩溃
      await db.decrementCounter(typeId: typeId, date: '2026-09-20');

      // 普通事件的 count 恒为 1
      await db.insertEvent(typeId: normalType, startDate: '2026-01-01');
      expect((await db.watchEvents().first).last.count, 1);
    });

    test('事件状态：实例选择/清除，删除状态置空', () async {
      final typeId = await db.createEventType(
        name: '2026 法定节假日',
        color: 0xFFCF4B3F,
        glyph: '休',
        kind: EventTypeKind.holiday,
        statuses: [
          EventStatusesCompanion.insert(
            typeId: 0, name: '放假', color: 0xFFCF4B3F, glyph: const Value('休')),
          EventStatusesCompanion.insert(
            typeId: 0, name: '补班', color: 0xFF3F7DCF, glyph: const Value('班'),
            sortOrder: const Value(1)),
        ],
      );
      final statuses = await db.statusesFor(typeId);
      final restSid = statuses[0].id;
      final workSid = statuses[1].id;
      // 放假日（选放假）与调休日（选补班）
      final restId = await db.insertEvent(
        typeId: typeId,
        startDate: '2026-10-01',
        endDate: '2026-10-08',
        title: '国庆',
        statusId: restSid,
      );
      final workId = await db.insertEvent(
        typeId: typeId,
        startDate: '2026-09-27',
        statusId: workSid,
      );
      var rows = await db.watchEvents().first;
      expect(rows.firstWhere((e) => e.id == restId).statusId, restSid);
      expect(rows.firstWhere((e) => e.id == workId).statusId, workSid);

      // 编辑清除状态（无状态）
      await db.updateEvent(
        workId,
        startDate: '2026-09-27',
        endDate: null,
        title: null,
        annual: false,
        statusId: null,
      );
      expect(
        (await db.watchEvents().first).firstWhere((e) => e.id == workId).statusId,
        isNull,
      );

      // 删除状态：其上事件实例置空（外键 setNull），事件保留
      await db.deleteEventStatus(workSid);
      rows = await db.watchEvents().first;
      expect(rows, hasLength(2));
      expect(rows.firstWhere((e) => e.id == workId).statusId, isNull);

      // 关联思绪后解关联：事件保留
      final thoughtId = await db.insertThought(
        content: '国庆出行计划',
        day: '2026-09-20',
        createdAt: DateTime(2026, 9, 20, 9),
      );
      await db.insertEvent(
        typeId: typeId,
        startDate: '2026-10-01',
        thoughtId: thoughtId,
      );
      await db.unlinkEventFromThought(thoughtId);
      final kept = (await db.watchEvents().first)
          .firstWhere((e) => e.startDate == '2026-10-01' && e.endDate == null);
      expect(kept.thoughtId, isNull);

      // 关联已有事件（覆盖原关联）
      final thought2 = await db.insertThought(
        content: '另一条',
        day: '2026-09-21',
        createdAt: DateTime(2026, 9, 21, 9),
      );
      await db.linkEventToThought(restId, thought2);
      expect(
        (await db.watchEvents().first).firstWhere((e) => e.id == restId).thoughtId,
        thought2,
      );
    });

    test('待办聚合：仅含完成态状态的类型，未完成事件跨类型汇总', () async {
      // 任务类型：未完成/已完成（完成态）——参与待办
      final taskType = await db.createEventType(
        name: '任务',
        color: 0xFF4A7DC4,
        statuses: [
          EventStatusesCompanion.insert(
              typeId: 0, name: '未完成', color: 0xFF9E9E9E),
          EventStatusesCompanion.insert(
              typeId: 0, name: '已完成', color: 0xFF4CAF50,
              sortOrder: const Value(1), isDone: const Value(true)),
        ],
      );
      final taskStatuses = await db.statusesFor(taskType);
      final undoneSid = taskStatuses[0].id;
      final doneSid = taskStatuses[1].id;

      // 节假日类型：无完成态状态——不参与待办
      final holidayType = await db.createEventType(
        name: '节假日',
        color: 0xFFCF4B3F,
        kind: EventTypeKind.holiday,
        statuses: [
          EventStatusesCompanion.insert(
              typeId: 0, name: '放假', color: 0xFFCF4B3F),
        ],
      );
      final holidaySid = (await db.statusesFor(holidayType)).single.id;

      // 无状态自定义类型：不参与待办
      await db.createEventType(name: '旅行', color: 0xFF9C27B0);

      final todoA = await db.insertEvent(
        typeId: taskType,
        title: '写周报',
        startDate: '2026-09-20',
        statusId: undoneSid,
      );
      await db.insertEvent(
        typeId: taskType,
        title: '交房租',
        startDate: '2026-09-25',
        statusId: doneSid, // 已完成
      );
      await db.insertEvent(
        typeId: taskType,
        title: '无状态任务',
        startDate: '2026-09-22',
        statusId: null, // 无状态 = 未完成
      );
      await db.insertEvent(
        typeId: holidayType,
        title: '国庆',
        startDate: '2026-10-01',
        statusId: holidaySid, // 类型无完成态 → 不出现
      );
      await db.insertEvent(typeId: holidayType, startDate: '2026-10-02');

      var todos = await db.watchTodos().first;
      expect(todos.map((t) => t.event.title), ['写周报', '无状态任务']);
      expect(todos.first.doneStatusId, doneSid);
      expect(todos.first.status?.id, undoneSid);

      // 勾完成：状态写成完成态后退出待办
      await db.completeTodo(todos.first);
      todos = await db.watchTodos().first;
      expect(todos.map((t) => t.event.title), ['无状态任务']);

      // 撤销：恢复原状态回到待办
      await db.setEventStatus(todoA, undoneSid);
      todos = await db.watchTodos().first;
      expect(todos.map((t) => t.event.title), ['写周报', '无状态任务']);

      // 导出/导入：isDone 随状态保留，事件引用重映射后待办一致
      final data = await db.exportData();
      final db2 = AppDatabase.connect(NativeDatabase.memory());
      addTearDown(db2.close);
      await db2.importData(data);
      final importedTypes = await db2.watchEventTypes().first;
      final importedTask = importedTypes.firstWhere((t) => t.name == '任务');
      final importedStatuses = await db2.statusesFor(importedTask.id);
      expect(importedStatuses.where((s) => s.isDone), hasLength(1));
      final importedTodos = await db2.watchTodos().first;
      expect(importedTodos.map((t) => t.event.title), ['写周报', '无状态任务']);

      // 删除完成态状态 → 类型不再参与待办
      await db.deleteEventStatus(doneSid);
      todos = await db.watchTodos().first;
      expect(todos, isEmpty);
    });

    test('导出/导入往返：类型、事件与联动', () async {
      final typeId = await db.createEventType(
        name: '生日',
        color: 0xFFCF9F3F,
        glyph: '🎂',
        statuses: [
          EventStatusesCompanion.insert(
            typeId: 0, name: '筹备中', color: 0xFF4CAF50, glyph: const Value('备')),
        ],
      );
      final sid = (await db.statusesFor(typeId)).single.id;
      final thoughtId = await db.insertThought(
        content: '我的生日',
        day: '2026-09-20',
        createdAt: DateTime(2026, 9, 20, 9),
        annualDate: '05-04',
      );
      await db.insertEvent(
        typeId: typeId,
        startDate: '2026-05-04',
        annual: true,
        title: '我的生日',
        statusId: sid,
        thoughtId: thoughtId,
      );

      final data = await db.exportData();
      final db2 = AppDatabase.connect(NativeDatabase.memory());
      addTearDown(db2.close);

      final count = await db2.importData(data);
      expect(count, 1);

      final types = await db2.watchEventTypes().first;
      expect(types.single.name, '生日');
      expect(types.single.glyph, '🎂');

      // 状态重映射：事件引用导入后的新状态 id
      final importedStatuses = await db2.statusesFor(types.single.id);
      expect(importedStatuses.single.name, '筹备中');
      final events = await db2.watchEvents().first;
      expect(events.single.annual, isTrue);
      expect(events.single.startDate, '2026-05-04');
      expect(events.single.statusId, importedStatuses.single.id);
      expect(events.single.thoughtId, isNotNull);
      // 联动的思绪也一并导入
      final linked = await db2.watchAnnualEvents().first;
      expect(linked.single.annualDate, '05-04');
    });

    test('导出/导入往返：计数器类型与次数', () async {
      final typeId = await db.createEventType(
        name: '打卡',
        color: 0xFF4CAF50,
        counter: true,
      );
      await db.incrementCounter(typeId: typeId, date: '2026-09-20');
      await db.incrementCounter(typeId: typeId, date: '2026-09-20');
      await db.incrementCounter(typeId: typeId, date: '2026-09-21');

      final data = await db.exportData();
      final db2 = AppDatabase.connect(NativeDatabase.memory());
      addTearDown(db2.close);
      await db2.importData(data);

      final types = await db2.watchEventTypes().first;
      expect(types.single.counter, isTrue);
      final rows = await db2.watchEvents().first;
      expect(rows, hasLength(2));
      expect(
        rows.firstWhere((e) => e.startDate == '2026-09-20').count,
        2,
      );
    });

    test('清空数据时同时清空类型与事件', () async {
      final typeId = await db.createEventType(name: '类型', color: 0xFF112233);
      await db.insertEvent(typeId: typeId, startDate: '2026-01-01');
      await db.resetAllData();
      expect(await db.watchEventTypes().first, isEmpty);
      expect(await db.watchEvents().first, isEmpty);
    });
  });

  group('comments-reactions', () {
    test('评论：追加/正序/删除，思绪删除级联清理', () async {
      final thoughtId = await db.insertThought(
        content: '一条思绪',
        day: '2026-09-21',
        createdAt: DateTime(2026, 9, 21, 9),
      );
      final c1 = await db.addComment(
          thoughtId: thoughtId, content: '第一条评论');
      await db.addComment(
          thoughtId: thoughtId,
          content: '第二条评论',
      );
      // 空白评论被忽略
      expect(await db.addComment(thoughtId: thoughtId, content: '  '), -1);

      var comments = await db.watchCommentsFor(thoughtId).first;
      expect(comments, hasLength(2));
      expect(comments.first.content, '第一条评论');
      expect(comments.first.id, c1);

      await db.deleteComment(c1);
      comments = await db.watchCommentsFor(thoughtId).first;
      expect(comments.single.content, '第二条评论');

      // 删除思绪：评论级联清理
      await db.deleteThought(thoughtId);
      final other = await db.insertThought(
        content: '另一条',
        day: '2026-09-21',
        createdAt: DateTime(2026, 9, 21, 10),
      );
      expect((await db.watchCommentsFor(other).first), isEmpty);
    });

    test('反应：6 种内置 emoji，可多次追加、可移除，级联清理', () async {
      final thoughtId = await db.insertThought(
        content: '一条思绪',
        day: '2026-09-21',
        createdAt: DateTime(2026, 9, 21, 9),
      );
      expect(ReactionKind.values, hasLength(6));

      // 不同时候加不同反应；同种也可多次
      await db.addReaction(
          thoughtId: thoughtId, kind: ReactionKind.like);
      await db.addReaction(
          thoughtId: thoughtId, kind: ReactionKind.love);
      await db.addReaction(
          thoughtId: thoughtId, kind: ReactionKind.like);

      var reactions = await db.watchReactionsFor(thoughtId).first;
      expect(reactions, hasLength(3));
      expect(
        reactions.map((r) => r.kind),
        [ReactionKind.like, ReactionKind.love, ReactionKind.like],
      );
      // emoji 与种类对应
      expect(reactions.first.kind.emoji, '👍');
      expect(reactions[1].kind.emoji, '❤️');

      // 移除单条（后加的 like）
      await db.deleteReaction(reactions.last.id);
      reactions = await db.watchReactionsFor(thoughtId).first;
      expect(reactions, hasLength(2));

      // 删除思绪：反应级联清理
      await db.deleteThought(thoughtId);
      final other = await db.insertThought(
        content: '另一条',
        day: '2026-09-21',
        createdAt: DateTime(2026, 9, 21, 10),
      );
      expect((await db.watchReactionsFor(other).first), isEmpty);
    });

    test('导出/导入往返：评论与反应', () async {
      final thoughtId = await db.insertThought(
        content: '我的思绪',
        day: '2026-09-21',
        createdAt: DateTime(2026, 9, 21, 9),
      );
      await db.addComment(thoughtId: thoughtId, content: '好想法');
      await db.addReaction(thoughtId: thoughtId, kind: ReactionKind.love);
      await db.addReaction(
          thoughtId: thoughtId, kind: ReactionKind.celebrate);

      final data = await db.exportData();
      final db2 = AppDatabase.connect(NativeDatabase.memory());
      addTearDown(db2.close);
      final count = await db2.importData(data);
      expect(count, 1);

      final imported = await db2.watchAllEntries().first;
      expect(imported.single.content, '我的思绪');
      final comments =
          await db2.watchCommentsFor(imported.single.id).first;
      expect(comments.single.content, '好想法');
      final reactions =
          await db2.watchReactionsFor(imported.single.id).first;
      expect(
        reactions.map((r) => r.kind),
        containsAll(
            [ReactionKind.love, ReactionKind.celebrate]),
      );
    });
  });

  group('archive-trash', () {
    test('归档：从活跃列表移除、归档列表可见、可取消归档，标签计数同步', () async {
      final id = await db.insertThought(
        content: '归档的思绪',
        day: '2026-09-21',
        createdAt: DateTime(2026, 9, 21, 9),
      );
      await db.setThoughtNormalTags(id, ['测试标签']);
      // 归档后：活跃列表与搜索都不再出现
      await db.archiveThought(id);
      expect(await db.watchAllEntries().first, isEmpty);
      expect(await db.watchSearch('').first, isEmpty);
      final archived = await db.watchArchivedEntries().first;
      expect(archived.single.content, '归档的思绪');
      expect(archived.single.archivedAt, isNotNull);
      // 归档不参与活跃标签统计（归档 ≠ 删除，只是不计入活跃）
      final tagged = (await db.watchTagsWithCount().first)
          .where((t) => t.tag.name == '测试标签');
      expect(tagged.single.count, 0);

      // 取消归档
      await db.unarchiveThought(id);
      expect((await db.watchAllEntries().first).single.id, id);
      expect(await db.watchArchivedEntries().first, isEmpty);
    });

    test('回收站：软删除、恢复、永久删除、清空', () async {
      final id = await db.insertThought(
        content: '待删除',
        day: '2026-09-21',
        createdAt: DateTime(2026, 9, 21, 9),
      );
      await db.trashThought(id);
      expect(await db.watchAllEntries().first, isEmpty);
      var trash = await db.watchTrashedEntries().first;
      expect(trash.single.id, id);
      expect(trash.single.deletedAt, isNotNull);

      // 恢复
      await db.restoreThought(id);
      expect((await db.watchAllEntries().first).single.id, id);
      expect(await db.watchTrashedEntries().first, isEmpty);

      // 再删并永久删除
      await db.trashThought(id);
      await db.deleteThought(id);
      expect(await db.watchTrashedEntries().first, isEmpty);

      // 清空回收站
      final a = await db.insertThought(
        content: 'a', day: '2026-09-21', createdAt: DateTime(2026, 9, 21, 10));
      final b = await db.insertThought(
        content: 'b', day: '2026-09-21', createdAt: DateTime(2026, 9, 21, 11));
      await db.trashThought(a);
      await db.trashThought(b);
      expect(await db.emptyTrash(), 2);
      expect(await db.watchTrashedEntries().first, isEmpty);
    });

    test('回收站保留期：超期由 purge 清除，未超期保留', () async {
      final old = await db.insertThought(
        content: '旧的',
        day: '2026-09-01',
        createdAt: DateTime(2026, 9, 1, 9),
      );
      final fresh = await db.insertThought(
        content: '新的',
        day: '2026-09-21',
        createdAt: DateTime(2026, 9, 21, 9),
      );
      await db.trashThought(old);
      await db.trashThought(fresh);
      // 把旧的 deletedAt 改到保留期之前
      final expired = DateTime.now()
          .subtract(const Duration(days: AppDatabase.trashRetentionDays + 1))
          .millisecondsSinceEpoch;
      await (db.update(db.thoughts)..where((t) => t.id.equals(old))).write(
        ThoughtsCompanion(deletedAt: Value(expired)),
      );

      final purged = await db.purgeExpiredTrash();
      expect(purged, 1);
      final trash = await db.watchTrashedEntries().first;
      expect(trash.single.id, fresh);
    });

    test('导出/导入往返：归档状态保留', () async {
      await db.insertThought(
        content: '活跃',
        day: '2026-09-21',
        createdAt: DateTime(2026, 9, 21, 9),
      );
      final archived = await db.insertThought(
        content: '归档',
        day: '2026-09-21',
        createdAt: DateTime(2026, 9, 21, 10),
      );
      await db.archiveThought(archived);

      final data = await db.exportData();
      final db2 = AppDatabase.connect(NativeDatabase.memory());
      addTearDown(db2.close);
      await db2.importData(data);

      expect((await db2.watchAllEntries().first).single.content, '活跃');
      final archivedIn = await db2.watchArchivedEntries().first;
      expect(archivedIn.single.content, '归档');
    });
  });

  group('lock', () {
    test('私密思绪：排除于搜索/漫步/那年今日，仍在日视图与全量中', () async {
      final publicId = await db.insertThought(
        content: '公开的日记',
        day: '2026-09-20',
        createdAt: DateTime(2026, 9, 20, 9),
      );
      final secretId = await db.insertThought(
        content: '私密的心情',
        day: '2026-09-20',
        createdAt: DateTime(2026, 9, 20, 10),
        locked: true,
      );

      // 搜索（非空查询）：私密不参与；浏览（空查询）：私密保留由列表遮罩
      expect(await db.watchSearch('心情').first, isEmpty);
      expect(
        (await db.watchSearch('').first).map((e) => e.id).toSet(),
        {publicId, secretId},
      );

      // 非今天的旧思绪：漫步与那年今日保留私密条目（由列表遮罩），不因上锁消失
      final oldPublic = await db.insertThought(
        content: '去年的公开',
        day: '2020-01-05',
        createdAt: DateTime(2020, 1, 5, 9),
      );
      final oldSecret = await db.insertThought(
        content: '去年的秘密',
        day: '2020-01-05',
        createdAt: DateTime(2020, 1, 5, 10),
        locked: true,
      );
      final randomIds =
          (await db.randomThoughts(limit: 50)).map((e) => e.id).toSet();
      expect(randomIds, contains(oldPublic));
      expect(randomIds, contains(oldSecret));

      expect(
        (await db.onThisDay(month: 1, day: 5)).map((e) => e.id).toSet(),
        {oldPublic, oldSecret},
      );

      // 日视图与全量仍包含私密（列表侧负责遮罩）
      expect(
        (await db.watchDay('2026-09-20').first).map((e) => e.id).toSet(),
        {publicId, secretId},
      );
      expect(
        (await db.watchAllEntries().first).map((e) => e.id).toSet(),
        {publicId, secretId, oldPublic, oldSecret},
      );

      // 切换私密
      await db.setThoughtLocked(secretId, false);
      expect((await db.watchSearch('心情').first).map((e) => e.id), [secretId]);
      await db.setThoughtLocked(secretId, true);
      expect(await db.watchSearch('心情').first, isEmpty);
    });

    test('私密思绪 id 集合：含归档与回收站，供事件标题遮罩', () async {
      final active = await db.insertThought(
        content: 'A',
        day: '2026-09-20',
        createdAt: DateTime(2026, 9, 20, 9),
        locked: true,
      );
      final public = await db.insertThought(
        content: 'B',
        day: '2026-09-20',
        createdAt: DateTime(2026, 9, 20, 10),
      );
      final archived = await db.insertThought(
        content: 'C',
        day: '2026-09-20',
        createdAt: DateTime(2026, 9, 20, 11),
        locked: true,
      );
      await db.archiveThought(archived);
      final trashed = await db.insertThought(
        content: 'D',
        day: '2026-09-20',
        createdAt: DateTime(2026, 9, 20, 12),
        locked: true,
      );
      await db.trashThought(trashed);

      var ids = await db.watchLockedThoughtIds().first;
      expect(ids, {active, archived, trashed});
      expect(ids, isNot(contains(public)));

      await db.setThoughtLocked(active, false);
      ids = await db.watchLockedThoughtIds().first;
      expect(ids, {archived, trashed});
    });

    test('导出/导入往返：私密标记保留，导入后仍不参与搜索', () async {      await db.insertThought(
        content: '私密内容',
        day: '2026-09-20',
        createdAt: DateTime(2026, 9, 20, 9),
        locked: true,
      );
      await db.insertThought(
        content: '公开内容',
        day: '2026-09-20',
        createdAt: DateTime(2026, 9, 20, 10),
      );
      final data = await db.exportData();
      final db2 = AppDatabase.connect(NativeDatabase.memory());
      addTearDown(db2.close);
      await db2.importData(data);

      final all = await db2.watchAllEntries().first;
      expect(all.firstWhere((e) => e.content == '私密内容').locked, isTrue);
      expect(all.firstWhere((e) => e.content == '公开内容').locked, isFalse);
      expect(await db2.watchSearch('私密').first, isEmpty);
      expect((await db2.watchSearch('内容').first).single.content, '公开内容');
    });
  });
}
