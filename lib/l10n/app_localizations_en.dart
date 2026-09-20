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

  @override
  String get attachments => 'Attachments';

  @override
  String get addImage => 'Add image';

  @override
  String get recordAudio => 'Record audio';

  @override
  String get recordHint => 'Tap to start recording';

  @override
  String get recording => 'Recording';

  @override
  String get stopRecord => 'Stop';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get attachmentTooLarge => 'File too large (max 20 MB each)';

  @override
  String get micPermissionDenied => 'Microphone permission denied';

  @override
  String get specialDaysTitle => 'Special days';

  @override
  String get specialDaysHint =>
      'Stored as special thoughts (everything is a thought), recurring on the same date each year.';

  @override
  String get specialDayEmpty => 'No special days yet';

  @override
  String get addSpecialDay => 'Add special day';

  @override
  String get specialDayNameHint => 'Name, e.g. Mom\'s birthday';

  @override
  String get specialDayDate => 'Date';

  @override
  String get holidayPlanTitle => 'Holiday schedule';

  @override
  String get holidayPlanHint =>
      'Weekends are off by default; tap a date to mark rest/work. Enter national holidays and makeup workdays manually.';

  @override
  String get restLabel => 'Off';

  @override
  String get workLabel => 'Work';

  @override
  String get clearFlag => 'Clear mark';

  @override
  String get defaultRestLabel => 'Default off';

  @override
  String get glyphRest => 'O';

  @override
  String get glyphWork => 'W';

  @override
  String get weekStartTitle => 'First day of week';

  @override
  String get weekStartSunday => 'Sunday';

  @override
  String get weekStartMonday => 'Monday';

  @override
  String get calendarManageTitle => 'Calendar manager';

  @override
  String get dayEventsLabel => 'Events';

  @override
  String get eventTypesSection => 'Event types';

  @override
  String get specialThoughtsSection => 'Special days (thoughts)';

  @override
  String get addEventType => 'New type';

  @override
  String get editType => 'Edit type';

  @override
  String get typeNameHint => 'Name, e.g. 2026 holidays';

  @override
  String get markNone => 'None';

  @override
  String get cornerGlyphHint => 'Corner glyph (optional)';

  @override
  String get addEvent => 'Add event';

  @override
  String get editEvent => 'Edit event';

  @override
  String get deleteEvent => 'Delete event';

  @override
  String get eventTitleHint => 'Title (optional, defaults to type name)';

  @override
  String get startDateLabel => 'Start date';

  @override
  String get endDateLabel => 'End date (optional, long-press to clear)';

  @override
  String get annualRecur => 'Repeat yearly';

  @override
  String get recordAsThought => 'Also save as thought';

  @override
  String get deleteType => 'Delete type';

  @override
  String deleteTypeBody(String name) {
    return 'Deletes \"$name\" and all its events.';
  }

  @override
  String get emptyTypes => 'No types yet — tap + to create';

  @override
  String eventsCount(int count) {
    return '$count events';
  }

  @override
  String get presetHoliday => 'Holidays';

  @override
  String get presetMakeup => 'Makeup workdays';

  @override
  String get presetBirthday => 'Birthdays';

  @override
  String get presetPeriod => 'Cycle';

  @override
  String get presetTravel => 'Travel';

  @override
  String get counterType => 'Counter';

  @override
  String get counterHint => 'Tap +1 daily (habit tallies); no date ranges';

  @override
  String get counterLabel => 'Counters';

  @override
  String get addOne => '+1';

  @override
  String totalCount(int count) {
    return '$count in total';
  }

  @override
  String get presetCheckIn => 'Check-in';
}
