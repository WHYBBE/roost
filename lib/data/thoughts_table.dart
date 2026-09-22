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
  // 归档时间（UTC 毫秒）；非空即已归档。归档 ≠ 删除，归档视图始终可见
  IntColumn get archivedAt => integer().nullable()();
  // 移入回收站时间（UTC 毫秒）；超过保留期后由 purge 永久清除
  IntColumn get deletedAt => integer().nullable()();
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

/// 类型种类：自定义 / 法定节假日 / 调休补班 / 生日。
/// 节假日与生日是"特殊类型"：创建走专属流程，
/// 节假日自带 放假/补班 两个内置状态，生日下的事件默认每年循环
enum EventTypeKind {
  custom(0),
  holiday(1),
  makeup(2),
  birthday(3);

  final int value;
  const EventTypeKind(this.value);

  static EventTypeKind fromValue(int v) =>
      (v >= 0 && v < EventTypeKind.values.length)
          ? EventTypeKind.values[v]
          : EventTypeKind.custom;
}

/// 日历事件类型：完全自定义（颜色/字符/状态）。
/// 国家节假日（放假/补班状态）、生日、月经周期、旅行计划等都是它的特例；
/// 年份归属写进名称（如"2026 法定节假日"）
@DataClassName('EventType')
class EventTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  // ARGB32
  IntColumn get color => integer()();
  // 字符角标（如 休/班/🩸），null = 无
  TextColumn get glyph => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // 计数器类型：每天可 +1 计次（打卡、次数统计），不走日期区间
  BoolColumn get counter => boolean().withDefault(const Constant(false))();
  // 种类：决定创建流程与事件默认行为（状态仅节假日与自定义使用）
  IntColumn get kind =>
      intEnum<EventTypeKind>().withDefault(const Constant(0))();
}

/// 反应种类：内置 6 个 emoji，每次反应选其一；
/// 可随时间追加多条（不同时候可以有不同反应），同种也可多次
enum ReactionKind {
  like(0, '👍'),
  love(1, '❤️'),
  laugh(2, '😂'),
  wow(3, '😮'),
  sad(4, '😢'),
  celebrate(5, '🎉');

  final int value;
  final String emoji;
  const ReactionKind(this.value, this.emoji);

  static ReactionKind? fromValue(int v) =>
      (v >= 0 && v < ReactionKind.values.length)
          ? ReactionKind.values[v]
          : null;
}

/// 评论：思绪下的自由文字（不做楼层/回复），按时间正序
@DataClassName('Comment')
class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get thoughtId =>
      integer().references(Thoughts, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text()();
  // UTC 时间戳毫秒
  IntColumn get createdAt => integer()();
}

/// 反应：一条内置 emoji 记录（同种可多次）
@DataClassName('Reaction')
class Reactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get thoughtId =>
      integer().references(Thoughts, #id, onDelete: KeyAction.cascade)();
  IntColumn get kind => intEnum<ReactionKind>()();
  IntColumn get createdAt => integer()();
}

/// 事件类型的状态（属于类型）：
/// 节假日内置 放假（休·红）/ 补班（班·蓝）；自定义类型可任意预设
/// （如任务：已完成/未完成/放弃）。事件实例选择其中一个（或无状态）。
/// isDone 标记"完成态"：该状态代表已完成，事件到达该状态即不再列入待办
@DataClassName('EventStatus')
class EventStatuses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get typeId =>
      integer().references(EventTypes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  // ARGB32
  IntColumn get color => integer()();
  // 单字符角标（如 休/班/✓），空 = 无角标（不参与格子角标）
  TextColumn get glyph => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // 完成态：待办聚合视图以"未完成（或无状态）"筛选该类型的事件
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
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
  // 计数器当日次数（非计数器事件恒为 1）
  IntColumn get count => integer().withDefault(const Constant(1))();
  // 选中的状态（所属类型的状态之一）；null = 无状态
  IntColumn get statusId =>
      integer().nullable().references(EventStatuses, #id, onDelete: KeyAction.setNull)();
  // 联动思绪（万物皆思绪）；思绪被删时置空，事件保留
  IntColumn get thoughtId =>
      integer().nullable().references(Thoughts, #id, onDelete: KeyAction.setNull)();
}
