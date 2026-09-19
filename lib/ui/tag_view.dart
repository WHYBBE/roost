import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/tag_presets.dart';
import '../data/thoughts_table.dart';

extension TagX on Tag {
  /// 标签种类（kind 列存 int，此处转换）
  TagKind get tagKind => TagKind.fromValue(kind);

  /// 自定义图标；null = 无图标。从候选集中查表保证 const 引用（图标可被 tree-shake）。
  IconData? get iconData {
    final codePoint = icon;
    if (codePoint == null) return null;
    for (final candidate in tagIconChoices) {
      if (candidate.codePoint == codePoint) return candidate;
    }
    return null;
  }

  /// 自定义颜色；null = 使用主题默认
  Color? get uiColor => color == null ? null : Color(color!);
}
