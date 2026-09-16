// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Roost';

  @override
  String get navHome => 'Thoughts';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navWander => 'Wander';

  @override
  String get navSettings => 'Settings';

  @override
  String get newThought => 'New thought';

  @override
  String get editThought => 'Edit thought';

  @override
  String get thoughtHint => 'What are you thinking about?';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmDeleteTitle => 'Delete this thought?';

  @override
  String get confirmDeleteBody => 'This action cannot be undone.';

  @override
  String get emptyThoughts => 'No thoughts yet.\nWrite down your first one.';

  @override
  String get emptyDay => 'Nothing recorded on this day.';

  @override
  String get moodLabel => 'Mood';

  @override
  String get moodCalm => 'Calm';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodDown => 'Down';

  @override
  String get moodAnxious => 'Anxious';

  @override
  String get searchHint => 'Search thoughts…';

  @override
  String get wanderTitle => 'Daily Wander';

  @override
  String get onThisDayHeader => 'On this day';

  @override
  String get randomHeader => 'Random wander';

  @override
  String get showAll => 'Show all';

  @override
  String onThisDay(int years) {
    return 'On this day, $years year(s) ago';
  }

  @override
  String get noMemories =>
      'No memories to revisit yet.\nCome back after writing for a while.';

  @override
  String get shuffle => 'Shuffle';

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'no entries',
    );
    return '$_temp0';
  }

  @override
  String streak(int days) {
    return 'Streak $days day(s)';
  }

  @override
  String totalEntries(int count) {
    return '$count total';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get less => 'Less';

  @override
  String get more => 'More';

  @override
  String get today => 'Today';

  @override
  String get saved => 'Saved';

  @override
  String get todayEntryExists => 'You already wrote today. Nice.';

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chars',
    );
    return '$_temp0';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterByMood => 'Filter by mood';

  @override
  String get navTags => 'Tags';

  @override
  String get tagsEmpty =>
      'No tags yet.\nAdd tags to your thoughts and they will show up here.';

  @override
  String get tagHint => 'Tags (separated by spaces)';

  @override
  String get tagAdd => 'Add';

  @override
  String get renameTag => 'Rename tag';

  @override
  String get deleteTag => 'Delete tag';

  @override
  String deleteTagBody(int count) {
    return 'The tag will be removed from $count thought(s). The thoughts themselves won\'t be deleted.';
  }

  @override
  String get tagNameEmpty => 'Tag name can\'t be empty';

  @override
  String yearTotal(int year, int count) {
    return '$year · $count entries';
  }

  @override
  String get keepWriting => 'Keep writing';

  @override
  String longestStreak(int days) {
    return 'Longest $days day(s)';
  }
}
