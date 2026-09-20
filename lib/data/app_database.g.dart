// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ThoughtsTable extends Thoughts
    with TableInfo<$ThoughtsTable, ThoughtEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThoughtsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annualDateMeta = const VerificationMeta(
    'annualDate',
  );
  @override
  late final GeneratedColumn<String> annualDate = GeneratedColumn<String>(
    'annual_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    content,
    day,
    createdAt,
    updatedAt,
    annualDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'thoughts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ThoughtEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('annual_date')) {
      context.handle(
        _annualDateMeta,
        annualDate.isAcceptableOrUnknown(data['annual_date']!, _annualDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ThoughtEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThoughtEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      annualDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annual_date'],
      ),
    );
  }

  @override
  $ThoughtsTable createAlias(String alias) {
    return $ThoughtsTable(attachedDatabase, alias);
  }
}

class ThoughtEntry extends DataClass implements Insertable<ThoughtEntry> {
  final int id;
  final String content;
  final String day;
  final int createdAt;
  final int updatedAt;
  final String? annualDate;
  const ThoughtEntry({
    required this.id,
    required this.content,
    required this.day,
    required this.createdAt,
    required this.updatedAt,
    this.annualDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['content'] = Variable<String>(content);
    map['day'] = Variable<String>(day);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || annualDate != null) {
      map['annual_date'] = Variable<String>(annualDate);
    }
    return map;
  }

  ThoughtsCompanion toCompanion(bool nullToAbsent) {
    return ThoughtsCompanion(
      id: Value(id),
      content: Value(content),
      day: Value(day),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      annualDate: annualDate == null && nullToAbsent
          ? const Value.absent()
          : Value(annualDate),
    );
  }

  factory ThoughtEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThoughtEntry(
      id: serializer.fromJson<int>(json['id']),
      content: serializer.fromJson<String>(json['content']),
      day: serializer.fromJson<String>(json['day']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      annualDate: serializer.fromJson<String?>(json['annualDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'content': serializer.toJson<String>(content),
      'day': serializer.toJson<String>(day),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'annualDate': serializer.toJson<String?>(annualDate),
    };
  }

  ThoughtEntry copyWith({
    int? id,
    String? content,
    String? day,
    int? createdAt,
    int? updatedAt,
    Value<String?> annualDate = const Value.absent(),
  }) => ThoughtEntry(
    id: id ?? this.id,
    content: content ?? this.content,
    day: day ?? this.day,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    annualDate: annualDate.present ? annualDate.value : this.annualDate,
  );
  ThoughtEntry copyWithCompanion(ThoughtsCompanion data) {
    return ThoughtEntry(
      id: data.id.present ? data.id.value : this.id,
      content: data.content.present ? data.content.value : this.content,
      day: data.day.present ? data.day.value : this.day,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      annualDate: data.annualDate.present
          ? data.annualDate.value
          : this.annualDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThoughtEntry(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('annualDate: $annualDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, content, day, createdAt, updatedAt, annualDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThoughtEntry &&
          other.id == this.id &&
          other.content == this.content &&
          other.day == this.day &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.annualDate == this.annualDate);
}

class ThoughtsCompanion extends UpdateCompanion<ThoughtEntry> {
  final Value<int> id;
  final Value<String> content;
  final Value<String> day;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String?> annualDate;
  const ThoughtsCompanion({
    this.id = const Value.absent(),
    this.content = const Value.absent(),
    this.day = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.annualDate = const Value.absent(),
  });
  ThoughtsCompanion.insert({
    this.id = const Value.absent(),
    required String content,
    required String day,
    required int createdAt,
    required int updatedAt,
    this.annualDate = const Value.absent(),
  }) : content = Value(content),
       day = Value(day),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ThoughtEntry> custom({
    Expression<int>? id,
    Expression<String>? content,
    Expression<String>? day,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? annualDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (content != null) 'content': content,
      if (day != null) 'day': day,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (annualDate != null) 'annual_date': annualDate,
    });
  }

  ThoughtsCompanion copyWith({
    Value<int>? id,
    Value<String>? content,
    Value<String>? day,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String?>? annualDate,
  }) {
    return ThoughtsCompanion(
      id: id ?? this.id,
      content: content ?? this.content,
      day: day ?? this.day,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      annualDate: annualDate ?? this.annualDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (annualDate.present) {
      map['annual_date'] = Variable<String>(annualDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThoughtsCompanion(')
          ..write('id: $id, ')
          ..write('content: $content, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('annualDate: $annualDate')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<int> icon = GeneratedColumn<int>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _glyphMeta = const VerificationMeta('glyph');
  @override
  late final GeneratedColumn<String> glyph = GeneratedColumn<String>(
    'glyph',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    icon,
    glyph,
    color,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('glyph')) {
      context.handle(
        _glyphMeta,
        glyph.isAcceptableOrUnknown(data['glyph']!, _glyphMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon'],
      ),
      glyph: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}glyph'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  final int kind;
  final int? icon;
  final String? glyph;
  final int? color;
  final DateTime createdAt;
  const Tag({
    required this.id,
    required this.name,
    required this.kind,
    this.icon,
    this.glyph,
    this.color,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<int>(kind);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<int>(icon);
    }
    if (!nullToAbsent || glyph != null) {
      map['glyph'] = Variable<String>(glyph);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      glyph: glyph == null && nullToAbsent
          ? const Value.absent()
          : Value(glyph),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      createdAt: Value(createdAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<int>(json['kind']),
      icon: serializer.fromJson<int?>(json['icon']),
      glyph: serializer.fromJson<String?>(json['glyph']),
      color: serializer.fromJson<int?>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<int>(kind),
      'icon': serializer.toJson<int?>(icon),
      'glyph': serializer.toJson<String?>(glyph),
      'color': serializer.toJson<int?>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Tag copyWith({
    int? id,
    String? name,
    int? kind,
    Value<int?> icon = const Value.absent(),
    Value<String?> glyph = const Value.absent(),
    Value<int?> color = const Value.absent(),
    DateTime? createdAt,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    icon: icon.present ? icon.value : this.icon,
    glyph: glyph.present ? glyph.value : this.glyph,
    color: color.present ? color.value : this.color,
    createdAt: createdAt ?? this.createdAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      icon: data.icon.present ? data.icon.value : this.icon,
      glyph: data.glyph.present ? data.glyph.value : this.glyph,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('icon: $icon, ')
          ..write('glyph: $glyph, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, kind, icon, glyph, color, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.icon == this.icon &&
          other.glyph == this.glyph &&
          other.color == this.color &&
          other.createdAt == this.createdAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> kind;
  final Value<int?> icon;
  final Value<String?> glyph;
  final Value<int?> color;
  final Value<DateTime> createdAt;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.icon = const Value.absent(),
    this.glyph = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.kind = const Value.absent(),
    this.icon = const Value.absent(),
    this.glyph = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? kind,
    Expression<int>? icon,
    Expression<String>? glyph,
    Expression<int>? color,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (icon != null) 'icon': icon,
      if (glyph != null) 'glyph': glyph,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TagsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? kind,
    Value<int?>? icon,
    Value<String?>? glyph,
    Value<int?>? color,
    Value<DateTime>? createdAt,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      icon: icon ?? this.icon,
      glyph: glyph ?? this.glyph,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (icon.present) {
      map['icon'] = Variable<int>(icon.value);
    }
    if (glyph.present) {
      map['glyph'] = Variable<String>(glyph.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('icon: $icon, ')
          ..write('glyph: $glyph, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ThoughtTagsTable extends ThoughtTags
    with TableInfo<$ThoughtTagsTable, ThoughtTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ThoughtTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _thoughtIdMeta = const VerificationMeta(
    'thoughtId',
  );
  @override
  late final GeneratedColumn<int> thoughtId = GeneratedColumn<int>(
    'thought_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES thoughts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [thoughtId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'thought_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ThoughtTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('thought_id')) {
      context.handle(
        _thoughtIdMeta,
        thoughtId.isAcceptableOrUnknown(data['thought_id']!, _thoughtIdMeta),
      );
    } else if (isInserting) {
      context.missing(_thoughtIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {thoughtId, tagId};
  @override
  ThoughtTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThoughtTag(
      thoughtId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}thought_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $ThoughtTagsTable createAlias(String alias) {
    return $ThoughtTagsTable(attachedDatabase, alias);
  }
}

class ThoughtTag extends DataClass implements Insertable<ThoughtTag> {
  final int thoughtId;
  final int tagId;
  const ThoughtTag({required this.thoughtId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['thought_id'] = Variable<int>(thoughtId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  ThoughtTagsCompanion toCompanion(bool nullToAbsent) {
    return ThoughtTagsCompanion(
      thoughtId: Value(thoughtId),
      tagId: Value(tagId),
    );
  }

  factory ThoughtTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThoughtTag(
      thoughtId: serializer.fromJson<int>(json['thoughtId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'thoughtId': serializer.toJson<int>(thoughtId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  ThoughtTag copyWith({int? thoughtId, int? tagId}) => ThoughtTag(
    thoughtId: thoughtId ?? this.thoughtId,
    tagId: tagId ?? this.tagId,
  );
  ThoughtTag copyWithCompanion(ThoughtTagsCompanion data) {
    return ThoughtTag(
      thoughtId: data.thoughtId.present ? data.thoughtId.value : this.thoughtId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThoughtTag(')
          ..write('thoughtId: $thoughtId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(thoughtId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThoughtTag &&
          other.thoughtId == this.thoughtId &&
          other.tagId == this.tagId);
}

class ThoughtTagsCompanion extends UpdateCompanion<ThoughtTag> {
  final Value<int> thoughtId;
  final Value<int> tagId;
  final Value<int> rowid;
  const ThoughtTagsCompanion({
    this.thoughtId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ThoughtTagsCompanion.insert({
    required int thoughtId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : thoughtId = Value(thoughtId),
       tagId = Value(tagId);
  static Insertable<ThoughtTag> custom({
    Expression<int>? thoughtId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (thoughtId != null) 'thought_id': thoughtId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ThoughtTagsCompanion copyWith({
    Value<int>? thoughtId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return ThoughtTagsCompanion(
      thoughtId: thoughtId ?? this.thoughtId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (thoughtId.present) {
      map['thought_id'] = Variable<int>(thoughtId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ThoughtTagsCompanion(')
          ..write('thoughtId: $thoughtId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _thoughtIdMeta = const VerificationMeta(
    'thoughtId',
  );
  @override
  late final GeneratedColumn<int> thoughtId = GeneratedColumn<int>(
    'thought_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES thoughts (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AttachmentKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<AttachmentKind>($AttachmentsTable.$converterkind);
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    thoughtId,
    kind,
    mime,
    durationMs,
    sizeBytes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('thought_id')) {
      context.handle(
        _thoughtIdMeta,
        thoughtId.isAcceptableOrUnknown(data['thought_id']!, _thoughtIdMeta),
      );
    } else if (isInserting) {
      context.missing(_thoughtIdMeta);
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      thoughtId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}thought_id'],
      )!,
      kind: $AttachmentsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AttachmentKind, int, int> $converterkind =
      const EnumIndexConverter<AttachmentKind>(AttachmentKind.values);
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final int id;
  final int thoughtId;
  final AttachmentKind kind;
  final String mime;
  final int? durationMs;
  final int sizeBytes;
  final DateTime createdAt;
  const Attachment({
    required this.id,
    required this.thoughtId,
    required this.kind,
    required this.mime,
    this.durationMs,
    required this.sizeBytes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['thought_id'] = Variable<int>(thoughtId);
    {
      map['kind'] = Variable<int>($AttachmentsTable.$converterkind.toSql(kind));
    }
    map['mime'] = Variable<String>(mime);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      thoughtId: Value(thoughtId),
      kind: Value(kind),
      mime: Value(mime),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      sizeBytes: Value(sizeBytes),
      createdAt: Value(createdAt),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<int>(json['id']),
      thoughtId: serializer.fromJson<int>(json['thoughtId']),
      kind: $AttachmentsTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
      mime: serializer.fromJson<String>(json['mime']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'thoughtId': serializer.toJson<int>(thoughtId),
      'kind': serializer.toJson<int>(
        $AttachmentsTable.$converterkind.toJson(kind),
      ),
      'mime': serializer.toJson<String>(mime),
      'durationMs': serializer.toJson<int?>(durationMs),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Attachment copyWith({
    int? id,
    int? thoughtId,
    AttachmentKind? kind,
    String? mime,
    Value<int?> durationMs = const Value.absent(),
    int? sizeBytes,
    DateTime? createdAt,
  }) => Attachment(
    id: id ?? this.id,
    thoughtId: thoughtId ?? this.thoughtId,
    kind: kind ?? this.kind,
    mime: mime ?? this.mime,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    createdAt: createdAt ?? this.createdAt,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      thoughtId: data.thoughtId.present ? data.thoughtId.value : this.thoughtId,
      kind: data.kind.present ? data.kind.value : this.kind,
      mime: data.mime.present ? data.mime.value : this.mime,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('thoughtId: $thoughtId, ')
          ..write('kind: $kind, ')
          ..write('mime: $mime, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, thoughtId, kind, mime, durationMs, sizeBytes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.thoughtId == this.thoughtId &&
          other.kind == this.kind &&
          other.mime == this.mime &&
          other.durationMs == this.durationMs &&
          other.sizeBytes == this.sizeBytes &&
          other.createdAt == this.createdAt);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<int> id;
  final Value<int> thoughtId;
  final Value<AttachmentKind> kind;
  final Value<String> mime;
  final Value<int?> durationMs;
  final Value<int> sizeBytes;
  final Value<DateTime> createdAt;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.thoughtId = const Value.absent(),
    this.kind = const Value.absent(),
    this.mime = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    this.id = const Value.absent(),
    required int thoughtId,
    required AttachmentKind kind,
    required String mime,
    this.durationMs = const Value.absent(),
    required int sizeBytes,
    this.createdAt = const Value.absent(),
  }) : thoughtId = Value(thoughtId),
       kind = Value(kind),
       mime = Value(mime),
       sizeBytes = Value(sizeBytes);
  static Insertable<Attachment> custom({
    Expression<int>? id,
    Expression<int>? thoughtId,
    Expression<int>? kind,
    Expression<String>? mime,
    Expression<int>? durationMs,
    Expression<int>? sizeBytes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (thoughtId != null) 'thought_id': thoughtId,
      if (kind != null) 'kind': kind,
      if (mime != null) 'mime': mime,
      if (durationMs != null) 'duration_ms': durationMs,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AttachmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? thoughtId,
    Value<AttachmentKind>? kind,
    Value<String>? mime,
    Value<int?>? durationMs,
    Value<int>? sizeBytes,
    Value<DateTime>? createdAt,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      thoughtId: thoughtId ?? this.thoughtId,
      kind: kind ?? this.kind,
      mime: mime ?? this.mime,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (thoughtId.present) {
      map['thought_id'] = Variable<int>(thoughtId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $AttachmentsTable.$converterkind.toSql(kind.value),
      );
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('thoughtId: $thoughtId, ')
          ..write('kind: $kind, ')
          ..write('mime: $mime, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AttachmentBlobsTable extends AttachmentBlobs
    with TableInfo<$AttachmentBlobsTable, AttachmentBlob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentBlobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<int> attachmentId = GeneratedColumn<int>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES attachments (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<Uint8List> data = GeneratedColumn<Uint8List>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [attachmentId, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachment_blobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentBlob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attachmentId};
  @override
  AttachmentBlob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentBlob(
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attachment_id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}data'],
      )!,
    );
  }

  @override
  $AttachmentBlobsTable createAlias(String alias) {
    return $AttachmentBlobsTable(attachedDatabase, alias);
  }
}

class AttachmentBlob extends DataClass implements Insertable<AttachmentBlob> {
  final int attachmentId;
  final Uint8List data;
  const AttachmentBlob({required this.attachmentId, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attachment_id'] = Variable<int>(attachmentId);
    map['data'] = Variable<Uint8List>(data);
    return map;
  }

  AttachmentBlobsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentBlobsCompanion(
      attachmentId: Value(attachmentId),
      data: Value(data),
    );
  }

  factory AttachmentBlob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentBlob(
      attachmentId: serializer.fromJson<int>(json['attachmentId']),
      data: serializer.fromJson<Uint8List>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attachmentId': serializer.toJson<int>(attachmentId),
      'data': serializer.toJson<Uint8List>(data),
    };
  }

  AttachmentBlob copyWith({int? attachmentId, Uint8List? data}) =>
      AttachmentBlob(
        attachmentId: attachmentId ?? this.attachmentId,
        data: data ?? this.data,
      );
  AttachmentBlob copyWithCompanion(AttachmentBlobsCompanion data) {
    return AttachmentBlob(
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentBlob(')
          ..write('attachmentId: $attachmentId, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(attachmentId, $driftBlobEquality.hash(data));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentBlob &&
          other.attachmentId == this.attachmentId &&
          $driftBlobEquality.equals(other.data, this.data));
}

class AttachmentBlobsCompanion extends UpdateCompanion<AttachmentBlob> {
  final Value<int> attachmentId;
  final Value<Uint8List> data;
  const AttachmentBlobsCompanion({
    this.attachmentId = const Value.absent(),
    this.data = const Value.absent(),
  });
  AttachmentBlobsCompanion.insert({
    this.attachmentId = const Value.absent(),
    required Uint8List data,
  }) : data = Value(data);
  static Insertable<AttachmentBlob> custom({
    Expression<int>? attachmentId,
    Expression<Uint8List>? data,
  }) {
    return RawValuesInsertable({
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (data != null) 'data': data,
    });
  }

  AttachmentBlobsCompanion copyWith({
    Value<int>? attachmentId,
    Value<Uint8List>? data,
  }) {
    return AttachmentBlobsCompanion(
      attachmentId: attachmentId ?? this.attachmentId,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attachmentId.present) {
      map['attachment_id'] = Variable<int>(attachmentId.value);
    }
    if (data.present) {
      map['data'] = Variable<Uint8List>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentBlobsCompanion(')
          ..write('attachmentId: $attachmentId, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

class $CalendarFlagsTable extends CalendarFlags
    with TableInfo<$CalendarFlagsTable, CalendarFlag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarFlagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DayFlag, int> flag =
      GeneratedColumn<int>(
        'flag',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DayFlag>($CalendarFlagsTable.$converterflag);
  @override
  List<GeneratedColumn> get $columns => [date, flag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_flags';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarFlag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  CalendarFlag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarFlag(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      flag: $CalendarFlagsTable.$converterflag.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}flag'],
        )!,
      ),
    );
  }

  @override
  $CalendarFlagsTable createAlias(String alias) {
    return $CalendarFlagsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DayFlag, int, int> $converterflag =
      const EnumIndexConverter<DayFlag>(DayFlag.values);
}

class CalendarFlag extends DataClass implements Insertable<CalendarFlag> {
  final String date;
  final DayFlag flag;
  const CalendarFlag({required this.date, required this.flag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    {
      map['flag'] = Variable<int>(
        $CalendarFlagsTable.$converterflag.toSql(flag),
      );
    }
    return map;
  }

  CalendarFlagsCompanion toCompanion(bool nullToAbsent) {
    return CalendarFlagsCompanion(date: Value(date), flag: Value(flag));
  }

  factory CalendarFlag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarFlag(
      date: serializer.fromJson<String>(json['date']),
      flag: $CalendarFlagsTable.$converterflag.fromJson(
        serializer.fromJson<int>(json['flag']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'flag': serializer.toJson<int>(
        $CalendarFlagsTable.$converterflag.toJson(flag),
      ),
    };
  }

  CalendarFlag copyWith({String? date, DayFlag? flag}) =>
      CalendarFlag(date: date ?? this.date, flag: flag ?? this.flag);
  CalendarFlag copyWithCompanion(CalendarFlagsCompanion data) {
    return CalendarFlag(
      date: data.date.present ? data.date.value : this.date,
      flag: data.flag.present ? data.flag.value : this.flag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarFlag(')
          ..write('date: $date, ')
          ..write('flag: $flag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, flag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarFlag &&
          other.date == this.date &&
          other.flag == this.flag);
}

class CalendarFlagsCompanion extends UpdateCompanion<CalendarFlag> {
  final Value<String> date;
  final Value<DayFlag> flag;
  final Value<int> rowid;
  const CalendarFlagsCompanion({
    this.date = const Value.absent(),
    this.flag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarFlagsCompanion.insert({
    required String date,
    required DayFlag flag,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       flag = Value(flag);
  static Insertable<CalendarFlag> custom({
    Expression<String>? date,
    Expression<int>? flag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (flag != null) 'flag': flag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarFlagsCompanion copyWith({
    Value<String>? date,
    Value<DayFlag>? flag,
    Value<int>? rowid,
  }) {
    return CalendarFlagsCompanion(
      date: date ?? this.date,
      flag: flag ?? this.flag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (flag.present) {
      map['flag'] = Variable<int>(
        $CalendarFlagsTable.$converterflag.toSql(flag.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarFlagsCompanion(')
          ..write('date: $date, ')
          ..write('flag: $flag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ThoughtsTable thoughts = $ThoughtsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $ThoughtTagsTable thoughtTags = $ThoughtTagsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $AttachmentBlobsTable attachmentBlobs = $AttachmentBlobsTable(
    this,
  );
  late final $CalendarFlagsTable calendarFlags = $CalendarFlagsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    thoughts,
    tags,
    thoughtTags,
    attachments,
    attachmentBlobs,
    calendarFlags,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'thoughts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('thought_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('thought_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'thoughts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attachments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'attachments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attachment_blobs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ThoughtsTableCreateCompanionBuilder =
    ThoughtsCompanion Function({
      Value<int> id,
      required String content,
      required String day,
      required int createdAt,
      required int updatedAt,
      Value<String?> annualDate,
    });
typedef $$ThoughtsTableUpdateCompanionBuilder =
    ThoughtsCompanion Function({
      Value<int> id,
      Value<String> content,
      Value<String> day,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String?> annualDate,
    });

final class $$ThoughtsTableReferences
    extends BaseReferences<_$AppDatabase, $ThoughtsTable, ThoughtEntry> {
  $$ThoughtsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ThoughtTagsTable, List<ThoughtTag>>
  _thoughtTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.thoughtTags,
    aliasName: 'thoughts__id__thought_tags__thought_id',
  );

  $$ThoughtTagsTableProcessedTableManager get thoughtTagsRefs {
    final manager = $$ThoughtTagsTableTableManager(
      $_db,
      $_db.thoughtTags,
    ).filter((f) => f.thoughtId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_thoughtTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'thoughts__id__attachments__thought_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.thoughtId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ThoughtsTableFilterComposer
    extends Composer<_$AppDatabase, $ThoughtsTable> {
  $$ThoughtsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get annualDate => $composableBuilder(
    column: $table.annualDate,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> thoughtTagsRefs(
    Expression<bool> Function($$ThoughtTagsTableFilterComposer f) f,
  ) {
    final $$ThoughtTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.thoughtTags,
      getReferencedColumn: (t) => t.thoughtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThoughtTagsTableFilterComposer(
            $db: $db,
            $table: $db.thoughtTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.thoughtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ThoughtsTableOrderingComposer
    extends Composer<_$AppDatabase, $ThoughtsTable> {
  $$ThoughtsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annualDate => $composableBuilder(
    column: $table.annualDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ThoughtsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThoughtsTable> {
  $$ThoughtsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get annualDate => $composableBuilder(
    column: $table.annualDate,
    builder: (column) => column,
  );

  Expression<T> thoughtTagsRefs<T extends Object>(
    Expression<T> Function($$ThoughtTagsTableAnnotationComposer a) f,
  ) {
    final $$ThoughtTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.thoughtTags,
      getReferencedColumn: (t) => t.thoughtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThoughtTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.thoughtTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.thoughtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ThoughtsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ThoughtsTable,
          ThoughtEntry,
          $$ThoughtsTableFilterComposer,
          $$ThoughtsTableOrderingComposer,
          $$ThoughtsTableAnnotationComposer,
          $$ThoughtsTableCreateCompanionBuilder,
          $$ThoughtsTableUpdateCompanionBuilder,
          (ThoughtEntry, $$ThoughtsTableReferences),
          ThoughtEntry,
          PrefetchHooks Function({bool thoughtTagsRefs, bool attachmentsRefs})
        > {
  $$ThoughtsTableTableManager(_$AppDatabase db, $ThoughtsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThoughtsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThoughtsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThoughtsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String?> annualDate = const Value.absent(),
              }) => ThoughtsCompanion(
                id: id,
                content: content,
                day: day,
                createdAt: createdAt,
                updatedAt: updatedAt,
                annualDate: annualDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String content,
                required String day,
                required int createdAt,
                required int updatedAt,
                Value<String?> annualDate = const Value.absent(),
              }) => ThoughtsCompanion.insert(
                id: id,
                content: content,
                day: day,
                createdAt: createdAt,
                updatedAt: updatedAt,
                annualDate: annualDate,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ThoughtsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({thoughtTagsRefs = false, attachmentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (thoughtTagsRefs) db.thoughtTags,
                    if (attachmentsRefs) db.attachments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (thoughtTagsRefs)
                        await $_getPrefetchedData<
                          ThoughtEntry,
                          $ThoughtsTable,
                          ThoughtTag
                        >(
                          currentTable: table,
                          referencedTable: $$ThoughtsTableReferences
                              ._thoughtTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ThoughtsTableReferences(
                                db,
                                table,
                                p0,
                              ).thoughtTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.thoughtId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          ThoughtEntry,
                          $ThoughtsTable,
                          Attachment
                        >(
                          currentTable: table,
                          referencedTable: $$ThoughtsTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ThoughtsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.thoughtId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ThoughtsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ThoughtsTable,
      ThoughtEntry,
      $$ThoughtsTableFilterComposer,
      $$ThoughtsTableOrderingComposer,
      $$ThoughtsTableAnnotationComposer,
      $$ThoughtsTableCreateCompanionBuilder,
      $$ThoughtsTableUpdateCompanionBuilder,
      (ThoughtEntry, $$ThoughtsTableReferences),
      ThoughtEntry,
      PrefetchHooks Function({bool thoughtTagsRefs, bool attachmentsRefs})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      Value<int> id,
      required String name,
      Value<int> kind,
      Value<int?> icon,
      Value<String?> glyph,
      Value<int?> color,
      Value<DateTime> createdAt,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> kind,
      Value<int?> icon,
      Value<String?> glyph,
      Value<int?> color,
      Value<DateTime> createdAt,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ThoughtTagsTable, List<ThoughtTag>>
  _thoughtTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.thoughtTags,
    aliasName: 'tags__id__thought_tags__tag_id',
  );

  $$ThoughtTagsTableProcessedTableManager get thoughtTagsRefs {
    final manager = $$ThoughtTagsTableTableManager(
      $_db,
      $_db.thoughtTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_thoughtTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get glyph => $composableBuilder(
    column: $table.glyph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> thoughtTagsRefs(
    Expression<bool> Function($$ThoughtTagsTableFilterComposer f) f,
  ) {
    final $$ThoughtTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.thoughtTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThoughtTagsTableFilterComposer(
            $db: $db,
            $table: $db.thoughtTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glyph => $composableBuilder(
    column: $table.glyph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get glyph =>
      $composableBuilder(column: $table.glyph, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> thoughtTagsRefs<T extends Object>(
    Expression<T> Function($$ThoughtTagsTableAnnotationComposer a) f,
  ) {
    final $$ThoughtTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.thoughtTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThoughtTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.thoughtTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool thoughtTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> kind = const Value.absent(),
                Value<int?> icon = const Value.absent(),
                Value<String?> glyph = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                kind: kind,
                icon: icon,
                glyph: glyph,
                color: color,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> kind = const Value.absent(),
                Value<int?> icon = const Value.absent(),
                Value<String?> glyph = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                icon: icon,
                glyph: glyph,
                color: color,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({thoughtTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (thoughtTagsRefs) db.thoughtTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (thoughtTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, ThoughtTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._thoughtTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).thoughtTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool thoughtTagsRefs})
    >;
typedef $$ThoughtTagsTableCreateCompanionBuilder =
    ThoughtTagsCompanion Function({
      required int thoughtId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$ThoughtTagsTableUpdateCompanionBuilder =
    ThoughtTagsCompanion Function({
      Value<int> thoughtId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$ThoughtTagsTableReferences
    extends BaseReferences<_$AppDatabase, $ThoughtTagsTable, ThoughtTag> {
  $$ThoughtTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ThoughtsTable _thoughtIdTable(_$AppDatabase db) =>
      db.thoughts.createAlias('thought_tags__thought_id__thoughts__id');

  $$ThoughtsTableProcessedTableManager get thoughtId {
    final $_column = $_itemColumn<int>('thought_id')!;

    final manager = $$ThoughtsTableTableManager(
      $_db,
      $_db.thoughts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_thoughtIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('thought_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ThoughtTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ThoughtTagsTable> {
  $$ThoughtTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ThoughtsTableFilterComposer get thoughtId {
    final $$ThoughtsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.thoughtId,
      referencedTable: $db.thoughts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThoughtsTableFilterComposer(
            $db: $db,
            $table: $db.thoughts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ThoughtTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ThoughtTagsTable> {
  $$ThoughtTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ThoughtsTableOrderingComposer get thoughtId {
    final $$ThoughtsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.thoughtId,
      referencedTable: $db.thoughts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThoughtsTableOrderingComposer(
            $db: $db,
            $table: $db.thoughts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ThoughtTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ThoughtTagsTable> {
  $$ThoughtTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ThoughtsTableAnnotationComposer get thoughtId {
    final $$ThoughtsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.thoughtId,
      referencedTable: $db.thoughts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThoughtsTableAnnotationComposer(
            $db: $db,
            $table: $db.thoughts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ThoughtTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ThoughtTagsTable,
          ThoughtTag,
          $$ThoughtTagsTableFilterComposer,
          $$ThoughtTagsTableOrderingComposer,
          $$ThoughtTagsTableAnnotationComposer,
          $$ThoughtTagsTableCreateCompanionBuilder,
          $$ThoughtTagsTableUpdateCompanionBuilder,
          (ThoughtTag, $$ThoughtTagsTableReferences),
          ThoughtTag,
          PrefetchHooks Function({bool thoughtId, bool tagId})
        > {
  $$ThoughtTagsTableTableManager(_$AppDatabase db, $ThoughtTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ThoughtTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ThoughtTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ThoughtTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> thoughtId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ThoughtTagsCompanion(
                thoughtId: thoughtId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int thoughtId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => ThoughtTagsCompanion.insert(
                thoughtId: thoughtId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ThoughtTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({thoughtId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (thoughtId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.thoughtId,
                                referencedTable: $$ThoughtTagsTableReferences
                                    ._thoughtIdTable(db),
                                referencedColumn: $$ThoughtTagsTableReferences
                                    ._thoughtIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$ThoughtTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$ThoughtTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ThoughtTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ThoughtTagsTable,
      ThoughtTag,
      $$ThoughtTagsTableFilterComposer,
      $$ThoughtTagsTableOrderingComposer,
      $$ThoughtTagsTableAnnotationComposer,
      $$ThoughtTagsTableCreateCompanionBuilder,
      $$ThoughtTagsTableUpdateCompanionBuilder,
      (ThoughtTag, $$ThoughtTagsTableReferences),
      ThoughtTag,
      PrefetchHooks Function({bool thoughtId, bool tagId})
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<int> id,
      required int thoughtId,
      required AttachmentKind kind,
      required String mime,
      Value<int?> durationMs,
      required int sizeBytes,
      Value<DateTime> createdAt,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<int> id,
      Value<int> thoughtId,
      Value<AttachmentKind> kind,
      Value<String> mime,
      Value<int?> durationMs,
      Value<int> sizeBytes,
      Value<DateTime> createdAt,
    });

final class $$AttachmentsTableReferences
    extends BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ThoughtsTable _thoughtIdTable(_$AppDatabase db) =>
      db.thoughts.createAlias('attachments__thought_id__thoughts__id');

  $$ThoughtsTableProcessedTableManager get thoughtId {
    final $_column = $_itemColumn<int>('thought_id')!;

    final manager = $$ThoughtsTableTableManager(
      $_db,
      $_db.thoughts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_thoughtIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttachmentBlobsTable, List<AttachmentBlob>>
  _attachmentBlobsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachmentBlobs,
    aliasName: 'attachments__id__attachment_blobs__attachment_id',
  );

  $$AttachmentBlobsTableProcessedTableManager get attachmentBlobsRefs {
    final manager = $$AttachmentBlobsTableTableManager(
      $_db,
      $_db.attachmentBlobs,
    ).filter((f) => f.attachmentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attachmentBlobsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AttachmentKind, AttachmentKind, int>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ThoughtsTableFilterComposer get thoughtId {
    final $$ThoughtsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.thoughtId,
      referencedTable: $db.thoughts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThoughtsTableFilterComposer(
            $db: $db,
            $table: $db.thoughts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attachmentBlobsRefs(
    Expression<bool> Function($$AttachmentBlobsTableFilterComposer f) f,
  ) {
    final $$AttachmentBlobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachmentBlobs,
      getReferencedColumn: (t) => t.attachmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentBlobsTableFilterComposer(
            $db: $db,
            $table: $db.attachmentBlobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ThoughtsTableOrderingComposer get thoughtId {
    final $$ThoughtsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.thoughtId,
      referencedTable: $db.thoughts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThoughtsTableOrderingComposer(
            $db: $db,
            $table: $db.thoughts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AttachmentKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ThoughtsTableAnnotationComposer get thoughtId {
    final $$ThoughtsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.thoughtId,
      referencedTable: $db.thoughts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ThoughtsTableAnnotationComposer(
            $db: $db,
            $table: $db.thoughts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attachmentBlobsRefs<T extends Object>(
    Expression<T> Function($$AttachmentBlobsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentBlobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachmentBlobs,
      getReferencedColumn: (t) => t.attachmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentBlobsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachmentBlobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (Attachment, $$AttachmentsTableReferences),
          Attachment,
          PrefetchHooks Function({bool thoughtId, bool attachmentBlobsRefs})
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> thoughtId = const Value.absent(),
                Value<AttachmentKind> kind = const Value.absent(),
                Value<String> mime = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                thoughtId: thoughtId,
                kind: kind,
                mime: mime,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int thoughtId,
                required AttachmentKind kind,
                required String mime,
                Value<int?> durationMs = const Value.absent(),
                required int sizeBytes,
                Value<DateTime> createdAt = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                thoughtId: thoughtId,
                kind: kind,
                mime: mime,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({thoughtId = false, attachmentBlobsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attachmentBlobsRefs) db.attachmentBlobs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (thoughtId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.thoughtId,
                                    referencedTable:
                                        $$AttachmentsTableReferences
                                            ._thoughtIdTable(db),
                                    referencedColumn:
                                        $$AttachmentsTableReferences
                                            ._thoughtIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attachmentBlobsRefs)
                        await $_getPrefetchedData<
                          Attachment,
                          $AttachmentsTable,
                          AttachmentBlob
                        >(
                          currentTable: table,
                          referencedTable: $$AttachmentsTableReferences
                              ._attachmentBlobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AttachmentsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentBlobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.attachmentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (Attachment, $$AttachmentsTableReferences),
      Attachment,
      PrefetchHooks Function({bool thoughtId, bool attachmentBlobsRefs})
    >;
typedef $$AttachmentBlobsTableCreateCompanionBuilder =
    AttachmentBlobsCompanion Function({
      Value<int> attachmentId,
      required Uint8List data,
    });
typedef $$AttachmentBlobsTableUpdateCompanionBuilder =
    AttachmentBlobsCompanion Function({
      Value<int> attachmentId,
      Value<Uint8List> data,
    });

final class $$AttachmentBlobsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AttachmentBlobsTable, AttachmentBlob> {
  $$AttachmentBlobsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AttachmentsTable _attachmentIdTable(_$AppDatabase db) => db
      .attachments
      .createAlias('attachment_blobs__attachment_id__attachments__id');

  $$AttachmentsTableProcessedTableManager get attachmentId {
    final $_column = $_itemColumn<int>('attachment_id')!;

    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attachmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentBlobsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentBlobsTable> {
  $$AttachmentBlobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  $$AttachmentsTableFilterComposer get attachmentId {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attachmentId,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentBlobsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentBlobsTable> {
  $$AttachmentBlobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  $$AttachmentsTableOrderingComposer get attachmentId {
    final $$AttachmentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attachmentId,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableOrderingComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentBlobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentBlobsTable> {
  $$AttachmentBlobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  $$AttachmentsTableAnnotationComposer get attachmentId {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attachmentId,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentBlobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentBlobsTable,
          AttachmentBlob,
          $$AttachmentBlobsTableFilterComposer,
          $$AttachmentBlobsTableOrderingComposer,
          $$AttachmentBlobsTableAnnotationComposer,
          $$AttachmentBlobsTableCreateCompanionBuilder,
          $$AttachmentBlobsTableUpdateCompanionBuilder,
          (AttachmentBlob, $$AttachmentBlobsTableReferences),
          AttachmentBlob,
          PrefetchHooks Function({bool attachmentId})
        > {
  $$AttachmentBlobsTableTableManager(
    _$AppDatabase db,
    $AttachmentBlobsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentBlobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentBlobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentBlobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> attachmentId = const Value.absent(),
                Value<Uint8List> data = const Value.absent(),
              }) => AttachmentBlobsCompanion(
                attachmentId: attachmentId,
                data: data,
              ),
          createCompanionCallback:
              ({
                Value<int> attachmentId = const Value.absent(),
                required Uint8List data,
              }) => AttachmentBlobsCompanion.insert(
                attachmentId: attachmentId,
                data: data,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttachmentBlobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({attachmentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (attachmentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.attachmentId,
                                referencedTable:
                                    $$AttachmentBlobsTableReferences
                                        ._attachmentIdTable(db),
                                referencedColumn:
                                    $$AttachmentBlobsTableReferences
                                        ._attachmentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttachmentBlobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentBlobsTable,
      AttachmentBlob,
      $$AttachmentBlobsTableFilterComposer,
      $$AttachmentBlobsTableOrderingComposer,
      $$AttachmentBlobsTableAnnotationComposer,
      $$AttachmentBlobsTableCreateCompanionBuilder,
      $$AttachmentBlobsTableUpdateCompanionBuilder,
      (AttachmentBlob, $$AttachmentBlobsTableReferences),
      AttachmentBlob,
      PrefetchHooks Function({bool attachmentId})
    >;
typedef $$CalendarFlagsTableCreateCompanionBuilder =
    CalendarFlagsCompanion Function({
      required String date,
      required DayFlag flag,
      Value<int> rowid,
    });
typedef $$CalendarFlagsTableUpdateCompanionBuilder =
    CalendarFlagsCompanion Function({
      Value<String> date,
      Value<DayFlag> flag,
      Value<int> rowid,
    });

class $$CalendarFlagsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarFlagsTable> {
  $$CalendarFlagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DayFlag, DayFlag, int> get flag =>
      $composableBuilder(
        column: $table.flag,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$CalendarFlagsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarFlagsTable> {
  $$CalendarFlagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flag => $composableBuilder(
    column: $table.flag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalendarFlagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarFlagsTable> {
  $$CalendarFlagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DayFlag, int> get flag =>
      $composableBuilder(column: $table.flag, builder: (column) => column);
}

class $$CalendarFlagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarFlagsTable,
          CalendarFlag,
          $$CalendarFlagsTableFilterComposer,
          $$CalendarFlagsTableOrderingComposer,
          $$CalendarFlagsTableAnnotationComposer,
          $$CalendarFlagsTableCreateCompanionBuilder,
          $$CalendarFlagsTableUpdateCompanionBuilder,
          (
            CalendarFlag,
            BaseReferences<_$AppDatabase, $CalendarFlagsTable, CalendarFlag>,
          ),
          CalendarFlag,
          PrefetchHooks Function()
        > {
  $$CalendarFlagsTableTableManager(_$AppDatabase db, $CalendarFlagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarFlagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarFlagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarFlagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<DayFlag> flag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  CalendarFlagsCompanion(date: date, flag: flag, rowid: rowid),
          createCompanionCallback:
              ({
                required String date,
                required DayFlag flag,
                Value<int> rowid = const Value.absent(),
              }) => CalendarFlagsCompanion.insert(
                date: date,
                flag: flag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarFlagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarFlagsTable,
      CalendarFlag,
      $$CalendarFlagsTableFilterComposer,
      $$CalendarFlagsTableOrderingComposer,
      $$CalendarFlagsTableAnnotationComposer,
      $$CalendarFlagsTableCreateCompanionBuilder,
      $$CalendarFlagsTableUpdateCompanionBuilder,
      (
        CalendarFlag,
        BaseReferences<_$AppDatabase, $CalendarFlagsTable, CalendarFlag>,
      ),
      CalendarFlag,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ThoughtsTableTableManager get thoughts =>
      $$ThoughtsTableTableManager(_db, _db.thoughts);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$ThoughtTagsTableTableManager get thoughtTags =>
      $$ThoughtTagsTableTableManager(_db, _db.thoughtTags);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$AttachmentBlobsTableTableManager get attachmentBlobs =>
      $$AttachmentBlobsTableTableManager(_db, _db.attachmentBlobs);
  $$CalendarFlagsTableTableManager get calendarFlags =>
      $$CalendarFlagsTableTableManager(_db, _db.calendarFlags);
}
