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
  String get tagEditorTitle => 'Edit tag';

  @override
  String get tagName => 'Name';

  @override
  String get tagIcon => 'Icon';

  @override
  String get tagEmoji => 'Emoji';

  @override
  String get glyphHint => 'Any character or emoji';

  @override
  String get glyphOnlyOne => 'Enter a single character or emoji';

  @override
  String get noIcon => 'None';

  @override
  String get tagColor => 'Color';

  @override
  String get defaultColor => 'Default';

  @override
  String get kindMood => 'Mood';

  @override
  String get kindNormal => 'Tag';

  @override
  String get createMoodTag => 'New mood tag';

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
  String get themeColorTitle => 'Theme color';

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
  String get tagExists => 'A tag with this name already exists';

  @override
  String get addTag => 'New tag';

  @override
  String get addMood => 'New mood';

  @override
  String get moodManagement => 'Moods';

  @override
  String moodCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moods',
      one: '1 mood',
    );
    return '$_temp0';
  }

  @override
  String get moodsEmpty => 'No moods yet.\nTap + to create one.';

  @override
  String get viewEntries => 'View entries';

  @override
  String yearTotal(int year, int count) {
    return '$year · $count entries';
  }

  @override
  String get keepWriting => 'Keep writing';

  @override
  String longestStreak(Object days) {
    return 'Longest $days day(s)';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get keepGoing => 'Continue';

  @override
  String get vaultTitle => 'Vaults';

  @override
  String get vaultSectionHint =>
      'Thoughts and tags are fully isolated per vault.';

  @override
  String get vaultActive => 'Active';

  @override
  String get createVault => 'New vault';

  @override
  String get vaultNameHint => 'Vault name';

  @override
  String get vaultCreated => 'Created and switched to the new vault';

  @override
  String get renameVault => 'Rename vault';

  @override
  String get deleteVault => 'Delete vault';

  @override
  String deleteVaultBody(String name) {
    return 'This permanently deletes all data in \"$name\". This cannot be undone.';
  }

  @override
  String get vaultDeleted => 'Vault deleted';

  @override
  String get lastVaultWarn => 'At least one vault is required';

  @override
  String get dataSection => 'Data';

  @override
  String get exportData => 'Export data';

  @override
  String get importData => 'Import data (merge)';

  @override
  String get resetMoodTags => 'Reset mood tags';

  @override
  String get resetAllData => 'Reset all data';

  @override
  String get exportDone => 'Exported';

  @override
  String get exportUnsupported => 'Export is not supported on this platform';

  @override
  String get importMergeBody =>
      'Imported thoughts and tags will be merged into existing data.';

  @override
  String importDone(int count) {
    return 'Imported $count';
  }

  @override
  String get importInvalid => 'Invalid file format';

  @override
  String get resetMoodBody =>
      'All mood tags and their marks will be removed, then the presets will be restored. Normal tags and thoughts are not affected.';

  @override
  String get resetAllBody1 =>
      'All thoughts, tags and moods will be deleted. This cannot be undone.';

  @override
  String get doubleConfirmTitle => 'Confirm again';

  @override
  String get doubleConfirmClear =>
      'One more confirmation: really clear all local data?';

  @override
  String get confirmClear => 'Clear now';

  @override
  String get resetDone => 'Reset done';

  @override
  String get opFailed => 'Operation failed';

  @override
  String get dataCorruptTitle => 'Data issue';

  @override
  String get dataCorruptBody =>
      'Local data can\'t be read and may be corrupted. Clearing will reset the app to its initial state (preset moods restored). This cannot be undone.';

  @override
  String get cleanData => 'Clear data';
}
