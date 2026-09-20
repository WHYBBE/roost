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

    test('清空全部数据并恢复预设心情', () async {
      await db.setThoughtTags(a.id, ['工作']);
      await db.resetAllData();
      expect(await db.select(db.thoughts).get(), isEmpty);
      expect(await db.select(db.thoughtTags).get(), isEmpty);
      final moods = (await db.select(db.tags).get())
          .where((t) => t.tagKind == TagKind.mood)
          .toList();
      expect(moods, hasLength(moodPresets.length));
      expect(
        moods.every((t) => t.icon != null && t.color != null),
        isTrue,
      );
    });

    test('重置心情标签：预设恢复，普通标签与思绪保留', () async {
      final t2 = await insert('另一条',
          day: AppDatabase.today(), createdAt: DateTime(2026, 9, 19, 9));
      final mood =
          await db.getOrCreateTag('心情X', kind: TagKind.mood, icon: 1, color: 2);
      await db.setThoughtTags(a.id, [mood.name, '工作']);
      await db.resetMoodTags();
      // 自定义心情被清掉，预设已恢复
      final moods = (await db.select(db.tags).get())
          .where((t) => t.tagKind == TagKind.mood)
          .toList();
      expect(moods.map((t) => t.name), isNot(contains('心情X')));
      expect(moods, hasLength(moodPresets.length));
      // 心情联结被清掉，普通标签与思绪保留
      expect((await db.tagsFor(a.id)).map((t) => t.name), ['工作']);
      expect((await db.watchAllEntries().first).map((e) => e.id),
          containsAll([a.id, t2.id]));
    });

    test('导出/清空/导入（合并）往返，重复导入去重', () async {
      final t2 = await insert('第二条',
          day: '2026-09-18', createdAt: DateTime(2026, 9, 18, 9));
      await db.setThoughtTags(a.id, ['焦虑']);
      await db.setThoughtTags(t2.id, ['工作']);
      // 手动改一下心情标签外观，验证导入合并时沿用现有定义
      await db.setTagAppearance(
          (await db.tagByName('焦虑'))!.id, color: 0xFF123456);

      final data = await db.exportData();
      expect((data['thoughts'] as List), hasLength(3));
      expect((data['tags'] as List), isNotEmpty);

      await db.resetAllData();
      expect(await db.select(db.thoughts).get(), isEmpty);

      final count = await db.importData(data);
      expect(count, 3);
      final entries = await db.watchAllEntries().first;
      expect(entries, hasLength(3));
      final restored = entries.firstWhere((e) => e.content == a.content);
      expect((await db.tagsFor(restored.id)).map((t) => t.name),
          contains('焦虑'));
      // 导入时沿用现有标签定义（自定义颜色保留）
      final mood = await db.tagByName('焦虑');
      expect(mood?.color, 0xFF123456);

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
        mark: CalendarMark.rest,
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

    test('类型种类：节假日/生日特殊类型持久化', () async {
      await db.createEventType(
        name: '2026 法定节假日',
        color: 0xFFCF4B3F,
        glyph: '休',
        mark: CalendarMark.rest,
        kind: EventTypeKind.holiday,
      );
      await db.createEventType(
        name: '生日',
        color: 0xFFCF9F3F,
        glyph: '🎂',
        kind: EventTypeKind.birthday,
      );
      final types = await db.watchEventTypes().first;
      expect(types[0].kind, EventTypeKind.holiday);
      expect(types[0].mark, CalendarMark.rest);
      expect(types[1].kind, EventTypeKind.birthday);
      expect(types[1].mark, CalendarMark.none);

      // 往返保留
      final data = await db.exportData();
      final db2 = AppDatabase.connect(NativeDatabase.memory());
      addTearDown(db2.close);
      await db2.importData(data);
      final imported = await db2.watchEventTypes().first;
      expect(imported[0].kind, EventTypeKind.holiday);
      expect(imported[1].kind, EventTypeKind.birthday);
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

    test('实例级 休/班 覆盖与解关联', () async {
      final typeId = await db.createEventType(
        name: '2026 法定节假日',
        color: 0xFFCF4B3F,
        glyph: '休',
        mark: CalendarMark.rest,
        kind: EventTypeKind.holiday,
      );
      // 放假日（继承类型休）与调休日（实例级班）
      final restId = await db.insertEvent(
        typeId: typeId,
        startDate: '2026-10-01',
        endDate: '2026-10-08',
        title: '国庆',
      );
      final workId = await db.insertEvent(
        typeId: typeId,
        startDate: '2026-09-27',
        mark: CalendarMark.work,
      );
      var rows = await db.watchEvents().first;
      expect(rows.firstWhere((e) => e.id == restId).mark, isNull);
      expect(
        rows.firstWhere((e) => e.id == workId).mark,
        CalendarMark.work,
      );

      // 编辑清除覆盖
      await db.updateEvent(
        workId,
        startDate: '2026-09-27',
        endDate: null,
        title: null,
        annual: false,
        mark: null,
      );
      expect(
        (await db.watchEvents().first).firstWhere((e) => e.id == workId).mark,
        isNull,
      );

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

    test('导出/导入往返：类型、事件与联动', () async {
      final typeId = await db.createEventType(
        name: '生日',
        color: 0xFFCF9F3F,
        glyph: '🎂',
      );
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

      final events = await db2.watchEvents().first;
      expect(events.single.annual, isTrue);
      expect(events.single.startDate, '2026-05-04');
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
}
