import 'package:flutter_test/flutter_test.dart';
import 'package:roost/ui/heatmap.dart';

void main() {
  group('buildWeeksForYear', () {
    test('2024 年（1月1日=周一，无前导空位）不崩溃', () {
      final weeks = buildWeeksForYear(2024);
      expect(weeks.first.whereType<DateTime>().first, DateTime(2024, 1, 1));
      // 第一列无空位，满 7 天
      expect(weeks.first, hasLength(7));
      // 全年 366 天（闰年）
      final totalDays = weeks.expand((w) => w).whereType<DateTime>().length;
      expect(totalDays, 366);
      // 所有列除最后一列外都是完整一周
      for (var i = 0; i < weeks.length - 1; i++) {
        expect(weeks[i], hasLength(7), reason: 'week $i');
      }
      // 最后一天是 12 月 31 日（周二）
      expect(weeks.last.last, DateTime(2024, 12, 31));
    });

    test('2026 年（1月1日=周四，3 个前导空位）', () {
      final weeks = buildWeeksForYear(2026);
      expect(weeks.first.take(3), everyElement(isNull));
      expect(weeks.first[3], DateTime(2026, 1, 1));
      final totalDays = weeks.expand((w) => w).whereType<DateTime>().length;
      expect(totalDays, 365);
    });

    test('2023 年（1月1日=周日，6 个前导空位）', () {
      final weeks = buildWeeksForYear(2023);
      expect(weeks.first.whereType<DateTime>().length, 1); // 只有 1 月 1 日
      expect(weeks.first[6], DateTime(2023, 1, 1));
    });

    test('每周内的日期都是连续的且周一开头（忽略空位）', () {
      final weeks = buildWeeksForYear(2025);
      for (final week in weeks) {
        final days = week.whereType<DateTime>().toList();
        for (var i = 1; i < days.length; i++) {
          expect(days[i].difference(days[i - 1]).inDays, 1);
        }
        if (days.isNotEmpty) {
          expect(days.first.weekday,
              inInclusiveRange(DateTime.monday, DateTime.sunday));
        }
      }
    });

    test('周日开头：2026 年（1月1日=周四 → 4 个前导空位）', () {
      final weeks =
          buildWeeksForYear(2026, startWeekday: DateTime.sunday);
      expect(weeks.first.take(4), everyElement(isNull));
      expect(weeks.first[4], DateTime(2026, 1, 1));
      // 完整周列以周日开头
      expect(weeks[1].first, isNotNull);
      expect(weeks[1].first!.weekday, DateTime.sunday);
      final totalDays = weeks.expand((w) => w).whereType<DateTime>().length;
      expect(totalDays, 365);
    });
  });
}
