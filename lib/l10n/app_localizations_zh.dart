// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '思栖';

  @override
  String get navHome => '思绪';

  @override
  String get navCalendar => '日历';

  @override
  String get navWander => '漫步';

  @override
  String get navSettings => '设置';

  @override
  String get newThought => '新的思绪';

  @override
  String get editThought => '编辑思绪';

  @override
  String get thoughtHint => '此刻在想什么？';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get confirmDeleteTitle => '删除这条思绪？';

  @override
  String get confirmDeleteBody => '删除后无法恢复。';

  @override
  String get emptyThoughts => '还没有思绪。\n写下第一条吧。';

  @override
  String get emptyDay => '这一天没有记录。';

  @override
  String get moodLabel => '心情';

  @override
  String get moodCalm => '平静';

  @override
  String get moodHappy => '开心';

  @override
  String get moodNeutral => '一般';

  @override
  String get moodDown => '低落';

  @override
  String get moodAnxious => '焦虑';

  @override
  String get searchHint => '搜索思绪…';

  @override
  String get wanderTitle => '每日漫步';

  @override
  String get onThisDayHeader => '那年今日';

  @override
  String get randomHeader => '随机漫游';

  @override
  String get showAll => '显示全部';

  @override
  String onThisDay(int years) {
    return '$years 年前的今天';
  }

  @override
  String get noMemories => '还没有可以回味的记忆。\n写一段时间后再来看看。';

  @override
  String get shuffle => '换一换';

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条记录',
      zero: '无记录',
    );
    return '$_temp0';
  }

  @override
  String streak(int days) {
    return '连续 $days 天';
  }

  @override
  String totalEntries(int count) {
    return '共 $count 条';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get themeTitle => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get less => '少';

  @override
  String get more => '多';

  @override
  String get today => '今天';

  @override
  String get saved => '已保存';

  @override
  String get todayEntryExists => '今天已经写过啦，不错。';

  @override
  String wordCount(int count) {
    return '$count 字';
  }

  @override
  String get filterAll => '全部';

  @override
  String get filterByMood => '按心情筛选';

  @override
  String yearTotal(int year, int count) {
    return '$year 年 · $count 条';
  }

  @override
  String get keepWriting => '继续记录';

  @override
  String longestStreak(int days) {
    return '最长 $days 天';
  }
}
