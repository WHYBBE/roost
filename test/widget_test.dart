import 'package:flutter_test/flutter_test.dart';
import 'package:roost/data/app_database.dart';
import 'package:roost/data/thoughts_table.dart';
import 'package:roost/ui/mood.dart';

void main() {
  test('formatDay pads correctly', () {
    expect(AppDatabase.formatDay(DateTime(2026, 9, 16)), '2026-09-16');
    expect(AppDatabase.formatDay(DateTime(2026, 1, 2)), '2026-01-02');
  });

  test('mood round trip', () {
    for (final m in Mood.values) {
      expect(Mood.fromValue(m.value), m);
    }
  });

  test('heat level thresholds', () {
    expect(heatLevel(0), 0);
    expect(heatLevel(2), 2);
    expect(heatLevel(10), moodLevels.length - 1);
  });
}
