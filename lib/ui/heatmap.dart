/// GitHub 风格热力图的纯计算逻辑，独立于 UI 便于测试。
library;

/// 构建某年的周列布局：列 = 周，行 = 星期几（周一在上，与 GitHub 一致）。
///
/// 第一列在 1 月 1 日之前用 null 填充；每列 7 行，按 weekday 定位。
/// 兼容 1 月 1 日恰好是周一（无前导空位）的情况。
List<List<DateTime?>> buildWeeksForYear(int year) {
  final jan1 = DateTime(year, 1, 1);
  final daysInYear = DateTime(year + 1, 1, 1).difference(jan1).inDays;

  final weeks = <List<DateTime?>>[
    List<DateTime?>.filled(jan1.weekday - 1, null, growable: true),
  ];
  for (var i = 0; i < daysInYear; i++) {
    final d = DateTime(year, 1, 1 + i);
    if (d.weekday == DateTime.monday && weeks.last.isNotEmpty) {
      weeks.add(<DateTime?>[]);
    }
    weeks.last.add(d);
  }
  return weeks;
}
