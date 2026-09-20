/// GitHub 风格热力图的纯计算逻辑，独立于 UI 便于测试。
library;

/// 构建某年的周列布局：列 = 周，行 = 星期几。
///
/// [startWeekday] 为每周首日（DateTime.monday=1 … DateTime.sunday=7）。
/// 第一列在 1 月 1 日之前用 null 填充；每列 7 行，按 (weekday - start + 7) % 7 定位。
List<List<DateTime?>> buildWeeksForYear(int year, {int startWeekday = DateTime.monday}) {
  final jan1 = DateTime(year, 1, 1);
  final daysInYear = DateTime(year + 1, 1, 1).difference(jan1).inDays;
  final offset = (jan1.weekday - startWeekday + 7) % 7;

  final weeks = <List<DateTime?>>[
    List<DateTime?>.filled(offset, null, growable: true),
  ];
  for (var i = 0; i < daysInYear; i++) {
    final d = DateTime(year, 1, 1 + i);
    if ((d.weekday - startWeekday + 7) % 7 == 0 && weeks.last.isNotEmpty) {
      weeks.add(<DateTime?>[]);
    }
    weeks.last.add(d);
  }
  return weeks;
}
