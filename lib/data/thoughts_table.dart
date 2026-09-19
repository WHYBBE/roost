import 'package:drift/drift.dart';

/// 标签种类：普通标签 / 心情（特殊标签）
enum TagKind {
  normal(0),
  mood(1);

  final int value;
  const TagKind(this.value);

  static TagKind fromValue(int v) => TagKind.values
      .firstWhere((k) => k.value == v, orElse: () => TagKind.normal);
}

@DataClassName('ThoughtEntry')
class Thoughts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  // 用户所属的"记录日"（本地日期，yyyy-MM-dd）
  TextColumn get day => text()();
  // 创建时间（UTC 时间戳毫秒）
  IntColumn get createdAt => integer()();
  // 最后修改时间（UTC 时间戳毫秒）
  IntColumn get updatedAt => integer()();
}

@DataClassName('Tag')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  // TagKind.normal / TagKind.mood（存 int，Dart 侧转换）
  IntColumn get kind => integer().withDefault(const Constant(0))();
  // 自定义图标（Material Icons codepoint），null = 无图标
  IntColumn get icon => integer().nullable()();
  // 自定义颜色（ARGB32），null = 使用主题默认
  IntColumn get color => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 思绪 ↔ 标签 多对多联结表（心情标签也是普通联结）
@DataClassName('ThoughtTag')
class ThoughtTags extends Table {
  IntColumn get thoughtId => integer().references(Thoughts, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {thoughtId, tagId};
}
