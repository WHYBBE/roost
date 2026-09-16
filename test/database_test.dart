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
}
