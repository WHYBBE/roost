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
  String get addEntry => 'Add entry';

  @override
  String get recordDay => 'Date';

  @override
  String get moodLabel => 'Mood';

  @override
  String get star => 'Star';

  @override
  String get unstar => 'Unstar';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get emptyFavoritesHint =>
      'No favorites yet.\nTap the star on a thought card to save it here.';

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
  String get thisWeekTitle => 'This week';

  @override
  String get thisMonthTitle => 'This month';

  @override
  String get recapEmpty => 'Nothing recorded in this period yet.';

  @override
  String get showAll => 'Show all';

  @override
  String get collapse => 'Show less';

  @override
  String get templatesTitle => 'Writing templates';

  @override
  String get templatesHint =>
      'Reusable multi-line snippets (e.g. \"Three questions\") you can insert while writing.';

  @override
  String get manageTemplates => 'Manage templates';

  @override
  String get insertTemplate => 'Insert template';

  @override
  String get pickTemplate => 'Choose a template';

  @override
  String get newTemplate => 'New template';

  @override
  String get editTemplate => 'Edit template';

  @override
  String get templateName => 'Template name';

  @override
  String get templateContent => 'Content';

  @override
  String get templateHint =>
      'Multiple lines allowed; still editable after inserting.';

  @override
  String get templatesEmpty =>
      'No templates yet.\nTap + to add one, e.g. \"Three questions\".';

  @override
  String get templateNameEmpty => 'Template name can\'t be empty';

  @override
  String get templateContentEmpty => 'Template content can\'t be empty';

  @override
  String get deleteTemplateTitle => 'Delete this template?';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

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
  String get settingsTabAppearance => 'Appearance';

  @override
  String get settingsTabGeneral => 'General';

  @override
  String get settingsTabWriting => 'Writing';

  @override
  String get settingsTabSecurity => 'Security';

  @override
  String get settingsTabData => 'Data';

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
  String get longestStreakLabel => 'Longest streak';

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
  String get commentsLabel => 'Comments';

  @override
  String get commentHint => 'Write a comment…';

  @override
  String get addComment => 'Add comment';

  @override
  String get deleteComment => 'Delete comment';

  @override
  String get reactionsLabel => 'Reactions';

  @override
  String get addReaction => 'Add reaction';

  @override
  String get deleteReaction => 'Remove reaction';

  @override
  String get archiveTrashTitle => 'Archive & Trash';

  @override
  String get archiveTab => 'Archive';

  @override
  String get trashTab => 'Trash';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get moveToTrash => 'Delete';

  @override
  String get restore => 'Restore';

  @override
  String get deleteForever => 'Delete forever';

  @override
  String get deleteForeverBody => 'This cannot be undone.';

  @override
  String get emptyTrash => 'Empty trash';

  @override
  String get emptyTrashBody =>
      'All thoughts in trash will be permanently deleted. This cannot be undone.';

  @override
  String get emptyArchiveHint => 'No archived thoughts';

  @override
  String get emptyTrashHint => 'Trash is empty';

  @override
  String get trashRetentionHint =>
      'Thoughts in trash are removed automatically after 7 days.';

  @override
  String get movedToTrash => 'Moved to trash';

  @override
  String get undo => 'Undo';

  @override
  String get archiveHint =>
      'Archive is not delete: archived thoughts stay here and can be unarchived anytime.';

  @override
  String get navInsights => 'Insights';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsOverview => 'Overview';

  @override
  String get totalThoughts => 'Thoughts';

  @override
  String get totalWords => 'Words';

  @override
  String get activeDays => 'Active days';

  @override
  String get currentStreak => 'Current streak';

  @override
  String daysValue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get insightsMonthly => 'Monthly trend';

  @override
  String get seriesThoughts => 'Entries';

  @override
  String get seriesWords => 'Words';

  @override
  String get insightsMood => 'Mood';

  @override
  String get moodDistribution => 'Mood distribution';

  @override
  String get insightsTags => 'Top tags';

  @override
  String get insightsWritingTime => 'Writing time';

  @override
  String get insightsCalendar => 'Calendar';

  @override
  String get eventTotal => 'Events';

  @override
  String get eventTypeDistribution => 'By type';

  @override
  String get insightsEmpty => 'No data yet';

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
  String get statusPresetTitle => 'Statuses';

  @override
  String get statusLabel => 'Status';

  @override
  String get statusNameHint => 'Status name (e.g. Done)';

  @override
  String get statusGlyphHint => 'Glyph';

  @override
  String get addStatus => 'Add status';

  @override
  String get statusRest => 'Holiday';

  @override
  String get statusMakeup => 'Makeup';

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

  @override
  String get kindHoliday => 'Holidays (with makeup)';

  @override
  String get kindCustom => 'Custom';

  @override
  String get typeNameSimpleHint => 'Name';

  @override
  String get holidayMakeupHint =>
      'A \"makeup workdays\" type will be created along (color and off/work marks are set automatically).';

  @override
  String get instancesHint =>
      'Instances above appear on the calendar; the section below only defines types (e.g. create \"Mom\'s birthday\" under a Birthday type).';

  @override
  String get emptyEvents => 'No events yet — tap Add event below';

  @override
  String get pickTypeTitle => 'Pick a type';

  @override
  String get noEventTypes => 'Create a type below first';

  @override
  String get calendarLink => 'Link to calendar';

  @override
  String get addToCalendar => 'Add to calendar';

  @override
  String get unlinkEvent => 'Unlink';

  @override
  String get newEvent => 'New event';

  @override
  String get linkExistingHint => 'Existing events on that day (link directly)';

  @override
  String get navTodos => 'To-dos';

  @override
  String get todosTitle => 'To-dos';

  @override
  String get todoBadgeHint =>
      'Mark a status as \"done\" (e.g. Done); unfinished events of that type will show up in To-dos.';

  @override
  String get statusDoneToggle => 'Done state';

  @override
  String get todosEmpty =>
      'No to-dos. Give a type a \"done\" status and unfinished events will appear here.';

  @override
  String get todoComplete => 'Done';

  @override
  String todoCompleted(String title) {
    return 'Completed \"$title\"';
  }

  @override
  String get todoNoStatus => 'No status';

  @override
  String get lockTitle => 'App lock';

  @override
  String get lockSectionHint =>
      'Set a passcode for the app; locked thoughts are excluded from search and require unlock to view.';

  @override
  String get lockChooseMethod => 'Choose unlock method';

  @override
  String get lockPin => 'PIN';

  @override
  String get lockPattern => 'Pattern';

  @override
  String get lockSetPin => 'Set PIN';

  @override
  String get lockSetPattern => 'Set pattern';

  @override
  String get lockEnterPinHint => 'Enter 4-8 digits';

  @override
  String get lockConfirmHint => 'Confirm once more';

  @override
  String get lockPatternHint => 'Connect at least 4 dots';

  @override
  String get lockMismatch => 'Doesn\'t match — try again';

  @override
  String get lockWrong => 'Wrong passcode';

  @override
  String get lockPatternShort => 'Connect at least 4 dots';

  @override
  String get lockVerifyTitle => 'Locked';

  @override
  String get lockPrivate => 'Mark as private';

  @override
  String get lockUnlockEntry => 'Unmark private';

  @override
  String get lockChange => 'Change passcode';

  @override
  String get lockTurnOff => 'Turn off app lock';

  @override
  String get lockTurnOffBody =>
      'After turning off, private thoughts can be viewed without unlocking (the private mark is kept).';

  @override
  String get lockLockNow => 'Lock now';

  @override
  String get lockedBadge => 'Private';

  @override
  String get lockProtectedHint =>
      'Private thoughts are excluded from search and wander.';

  @override
  String get advancedTagsSection => 'Advanced tags';

  @override
  String get advancedTagsHint =>
      'Add tag groups to a thought as needed; each group can be single- or multi-select.';

  @override
  String get advancedTagsEmpty => 'No tag groups added yet';

  @override
  String get addTagCategory => 'Add tag group';

  @override
  String get removeTagCategory => 'Remove tag group';

  @override
  String get allTagCategoriesAdded => 'All tag groups added';

  @override
  String get addOption => 'New option';

  @override
  String get optionsEmpty => 'No options yet — tap + to add';

  @override
  String optionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count options',
      zero: 'No options',
    );
    return '$_temp0';
  }

  @override
  String get categorySingle => 'Single';

  @override
  String get categoryMulti => 'Multi';

  @override
  String get editTagCategory => 'Edit tag group';

  @override
  String get deleteTagCategory => 'Delete tag group';

  @override
  String deleteTagCategoryBody(String name) {
    return 'Deletes \"$name\" and all its options; those values are removed from thoughts.';
  }

  @override
  String get normalTagsSection => 'Tags';
}
