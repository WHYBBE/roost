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
  // 年度循环日期（MM-DD，如 03-08）；非空即"特殊日子"思绪，日历每年该日展示
  TextColumn get annualDate => text().nullable()();
}

@DataClassName('Tag')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  // TagKind.normal / TagKind.mood（存 int，Dart 侧转换）
  IntColumn get kind => integer().withDefault(const Constant(0))();
  // 自定义图标（Material Icons codepoint），null = 无图标
  IntColumn get icon => integer().nullable()();
  // 自定义字符图标（任意 emoji/字符），null = 无；与 icon 互斥，glyph 优先
  TextColumn get glyph => text().nullable()();
  // 自定义颜色（ARGB32），null = 使用主题默认
  IntColumn get color => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 思绪 ↔ 标签 多对多联结表（心情标签也是普通联结）
@DataClassName('ThoughtTag')
class ThoughtTags extends Table {
  IntColumn get thoughtId =>
      integer().references(Thoughts, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {thoughtId, tagId};
}

/// 附件类型
enum AttachmentKind {
  image(0),
  audio(1);

  final int value;
  const AttachmentKind(this.value);
}

/// 附件元数据。与大字段分表：列表查询只读这里，避免误载大 blob
@DataClassName('Attachment')
class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get thoughtId =>
      integer().references(Thoughts, #id, onDelete: KeyAction.cascade)();
  IntColumn get kind => intEnum<AttachmentKind>()();
  TextColumn get mime => text()();
  // 音频时长（毫秒）；图片为 null
  IntColumn get durationMs => integer().nullable()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 附件二进制内容（与 Attachments 1:1，按需读取）
@DataClassName('AttachmentBlob')
class AttachmentBlobs extends Table {
  IntColumn get attachmentId =>
      integer().references(Attachments, #id, onDelete: KeyAction.cascade)();
  BlobColumn get data => blob()();

  @override
  Set<Column> get primaryKey => {attachmentId};
}

/// 日历事件在格子上的标记形式：无 / 休（红）/ 班（主题色）
enum CalendarMark {
  none(0),
  rest(1),
  work(2);

  final int value;
  const CalendarMark(this.value);

  static CalendarMark fromValue(int v) => (v >= 0 && v < CalendarMark.values.length)
      ? CalendarMark.values[v]
      : CalendarMark.none;
}

/// 日历事件类型：完全自定义（颜色/字符/标记）。
/// 国家节假日（mark=rest）、调休补班（mark=work）、生日、月经周期、
/// 旅行计划等都是它的特例；年份归属写进名称（如"2026 法定节假日"）
@DataClassName('EventType')
class EventTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  // ARGB32
  IntColumn get color => integer()();
  // 字符角标（如 休/班/🩸），null = 无
  TextColumn get glyph => text().nullable()();
  IntColumn get mark =>
      intEnum<CalendarMark>().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// 日历事件：单日或日期区间，可每年循环（生日），可选联动一条思绪
@DataClassName('CalendarEvent')
class CalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get typeId =>
      integer().references(EventTypes, #id, onDelete: KeyAction.cascade)();
  // null = 直接显示类型名
  TextColumn get title => text().nullable()();
  TextColumn get startDate => text()();
  // null = 单日
  TextColumn get endDate => text().nullable()();
  // 每年循环（按 startDate 的月-日）
  BoolColumn get annual => boolean().withDefault(const Constant(false))();
  // 联动思绪（万物皆思绪）；思绪被删时置空，事件保留
  IntColumn get thoughtId =>
      integer().nullable().references(Thoughts, #id, onDelete: KeyAction.setNull)();
}
