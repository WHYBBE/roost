import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 内置心情标签预设（用于初始化种子数据）
class MoodPreset {
  final String nameZh;
  final String nameEn;
  final IconData icon;
  final int color;

  const MoodPreset(this.nameZh, this.nameEn, this.icon, this.color);
}

const moodPresets = [
  MoodPreset('平静', 'Calm', Icons.spa, 0xFF009688),
  MoodPreset('开心', 'Happy', Icons.sentiment_very_satisfied, 0xFFFFB300),
  MoodPreset('一般', 'Neutral', Icons.sentiment_neutral, 0xFF607D8B),
  MoodPreset('低落', 'Down', Icons.sentiment_dissatisfied, 0xFF3F51B5),
  MoodPreset('焦虑', 'Anxious', Icons.waving_hand, 0xFFFF5722),
];

/// 标签图标候选（编辑器图标选择器）
const tagIconChoices = <IconData>[
  Icons.spa,
  Icons.sentiment_very_satisfied,
  Icons.sentiment_neutral,
  Icons.sentiment_dissatisfied,
  Icons.waving_hand,
  Icons.favorite,
  Icons.star,
  Icons.bolt,
  Icons.work,
  Icons.school,
  Icons.home,
  Icons.fitness_center,
  Icons.menu_book,
  Icons.music_note,
  Icons.flight,
  Icons.coffee,
  Icons.park,
  Icons.pets,
  Icons.laptop_mac,
  Icons.cloud,
  Icons.light_mode,
  Icons.dark_mode,
  Icons.eco,
  Icons.psychology,
];

/// 标签颜色候选（编辑器颜色选择器）
const tagColorChoices = <int>[
  0xFF009688, // teal
  0xFFFFB300, // amber
  0xFF607D8B, // blueGrey
  0xFF3F51B5, // indigo
  0xFFFF5722, // deepOrange
  0xFFE91E63, // pink
  0xFF9C27B0, // purple
  0xFF2196F3, // blue
  0xFF4CAF50, // green
  0xFF795548, // brown
];

/// 迁移时的种子语言判断
bool get seedUseChinese => Intl.systemLocale.startsWith('zh');
