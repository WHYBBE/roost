import 'package:drift/drift.dart';

/// 心情枚举
enum Mood {
  calm(0),
  happy(1),
  neutral(2),
  down(3),
  anxious(4);

  final int value;
  const Mood(this.value);

  static Mood fromValue(int v) =>
      Mood.values.firstWhere((m) => m.value == v, orElse: () => Mood.neutral);
}

@DataClassName('ThoughtEntry')
class Thoughts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  IntColumn get mood => intEnum<Mood>()();
  // 用户所属的"记录日"（本地日期，yyyy-MM-dd）
  TextColumn get day => text()();
  // 创建时间（UTC 时间戳毫秒）
  IntColumn get createdAt => integer()();
  // 最后修改时间（UTC 时间戳毫秒）
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [];
}
