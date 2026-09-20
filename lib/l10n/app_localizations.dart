import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Roost'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Thoughts'**
  String get navHome;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navWander.
  ///
  /// In en, this message translates to:
  /// **'Wander'**
  String get navWander;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @newThought.
  ///
  /// In en, this message translates to:
  /// **'New thought'**
  String get newThought;

  /// No description provided for @editThought.
  ///
  /// In en, this message translates to:
  /// **'Edit thought'**
  String get editThought;

  /// No description provided for @thoughtHint.
  ///
  /// In en, this message translates to:
  /// **'What are you thinking about?'**
  String get thoughtHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this thought?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get confirmDeleteBody;

  /// No description provided for @emptyThoughts.
  ///
  /// In en, this message translates to:
  /// **'No thoughts yet.\nWrite down your first one.'**
  String get emptyThoughts;

  /// No description provided for @emptyDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded on this day.'**
  String get emptyDay;

  /// No description provided for @moodLabel.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get moodLabel;

  /// No description provided for @tagEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get tagEditorTitle;

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tagName;

  /// No description provided for @tagIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get tagIcon;

  /// No description provided for @tagEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get tagEmoji;

  /// No description provided for @glyphHint.
  ///
  /// In en, this message translates to:
  /// **'Any character or emoji'**
  String get glyphHint;

  /// No description provided for @glyphOnlyOne.
  ///
  /// In en, this message translates to:
  /// **'Enter a single character or emoji'**
  String get glyphOnlyOne;

  /// No description provided for @noIcon.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noIcon;

  /// No description provided for @tagColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get tagColor;

  /// No description provided for @defaultColor.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultColor;

  /// No description provided for @kindMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get kindMood;

  /// No description provided for @kindNormal.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get kindNormal;

  /// No description provided for @createMoodTag.
  ///
  /// In en, this message translates to:
  /// **'New mood tag'**
  String get createMoodTag;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search thoughts…'**
  String get searchHint;

  /// No description provided for @wanderTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Wander'**
  String get wanderTitle;

  /// No description provided for @onThisDayHeader.
  ///
  /// In en, this message translates to:
  /// **'On this day'**
  String get onThisDayHeader;

  /// No description provided for @randomHeader.
  ///
  /// In en, this message translates to:
  /// **'Random wander'**
  String get randomHeader;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @onThisDay.
  ///
  /// In en, this message translates to:
  /// **'On this day, {years} year(s) ago'**
  String onThisDay(int years);

  /// No description provided for @noMemories.
  ///
  /// In en, this message translates to:
  /// **'No memories to revisit yet.\nCome back after writing for a while.'**
  String get noMemories;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @entriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no entries} =1{1 entry} other{{count} entries}}'**
  String entriesCount(int count);

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak {days} day(s)'**
  String streak(int days);

  /// No description provided for @totalEntries.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String totalEntries(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme color'**
  String get themeColorTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @todayEntryExists.
  ///
  /// In en, this message translates to:
  /// **'You already wrote today. Nice.'**
  String get todayEntryExists;

  /// No description provided for @wordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} chars}}'**
  String wordCount(int count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterByMood.
  ///
  /// In en, this message translates to:
  /// **'Filter by mood'**
  String get filterByMood;

  /// No description provided for @navTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get navTags;

  /// No description provided for @tagsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tags yet.\nAdd tags to your thoughts and they will show up here.'**
  String get tagsEmpty;

  /// No description provided for @tagHint.
  ///
  /// In en, this message translates to:
  /// **'Tags (separated by spaces)'**
  String get tagHint;

  /// No description provided for @tagAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tagAdd;

  /// No description provided for @renameTag.
  ///
  /// In en, this message translates to:
  /// **'Rename tag'**
  String get renameTag;

  /// No description provided for @deleteTag.
  ///
  /// In en, this message translates to:
  /// **'Delete tag'**
  String get deleteTag;

  /// No description provided for @deleteTagBody.
  ///
  /// In en, this message translates to:
  /// **'The tag will be removed from {count} thought(s). The thoughts themselves won\'t be deleted.'**
  String deleteTagBody(int count);

  /// No description provided for @tagNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tag name can\'t be empty'**
  String get tagNameEmpty;

  /// No description provided for @tagExists.
  ///
  /// In en, this message translates to:
  /// **'A tag with this name already exists'**
  String get tagExists;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get addTag;

  /// No description provided for @addMood.
  ///
  /// In en, this message translates to:
  /// **'New mood'**
  String get addMood;

  /// No description provided for @moodManagement.
  ///
  /// In en, this message translates to:
  /// **'Moods'**
  String get moodManagement;

  /// No description provided for @moodCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mood} other{{count} moods}}'**
  String moodCount(int count);

  /// No description provided for @moodsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No moods yet.\nTap + to create one.'**
  String get moodsEmpty;

  /// No description provided for @viewEntries.
  ///
  /// In en, this message translates to:
  /// **'View entries'**
  String get viewEntries;

  /// No description provided for @yearTotal.
  ///
  /// In en, this message translates to:
  /// **'{year} · {count} entries'**
  String yearTotal(int year, int count);

  /// No description provided for @keepWriting.
  ///
  /// In en, this message translates to:
  /// **'Keep writing'**
  String get keepWriting;

  /// No description provided for @longestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest {days} day(s)'**
  String longestStreak(Object days);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get keepGoing;

  /// No description provided for @vaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Vaults'**
  String get vaultTitle;

  /// No description provided for @vaultSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Thoughts and tags are fully isolated per vault.'**
  String get vaultSectionHint;

  /// No description provided for @vaultActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get vaultActive;

  /// No description provided for @createVault.
  ///
  /// In en, this message translates to:
  /// **'New vault'**
  String get createVault;

  /// No description provided for @vaultNameHint.
  ///
  /// In en, this message translates to:
  /// **'Vault name'**
  String get vaultNameHint;

  /// No description provided for @vaultCreated.
  ///
  /// In en, this message translates to:
  /// **'Created and switched to the new vault'**
  String get vaultCreated;

  /// No description provided for @renameVault.
  ///
  /// In en, this message translates to:
  /// **'Rename vault'**
  String get renameVault;

  /// No description provided for @deleteVault.
  ///
  /// In en, this message translates to:
  /// **'Delete vault'**
  String get deleteVault;

  /// No description provided for @deleteVaultBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes all data in \"{name}\". This cannot be undone.'**
  String deleteVaultBody(String name);

  /// No description provided for @vaultDeleted.
  ///
  /// In en, this message translates to:
  /// **'Vault deleted'**
  String get vaultDeleted;

  /// No description provided for @lastVaultWarn.
  ///
  /// In en, this message translates to:
  /// **'At least one vault is required'**
  String get lastVaultWarn;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import data (merge)'**
  String get importData;

  /// No description provided for @resetMoodTags.
  ///
  /// In en, this message translates to:
  /// **'Reset mood tags'**
  String get resetMoodTags;

  /// No description provided for @resetAllData.
  ///
  /// In en, this message translates to:
  /// **'Reset all data'**
  String get resetAllData;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Exported'**
  String get exportDone;

  /// No description provided for @exportUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Export is not supported on this platform'**
  String get exportUnsupported;

  /// No description provided for @importMergeBody.
  ///
  /// In en, this message translates to:
  /// **'Imported thoughts and tags will be merged into existing data.'**
  String get importMergeBody;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Imported {count}'**
  String importDone(int count);

  /// No description provided for @importInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid file format'**
  String get importInvalid;

  /// No description provided for @resetMoodBody.
  ///
  /// In en, this message translates to:
  /// **'All mood tags and their marks will be removed, then the presets will be restored. Normal tags and thoughts are not affected.'**
  String get resetMoodBody;

  /// No description provided for @resetAllBody1.
  ///
  /// In en, this message translates to:
  /// **'All thoughts, tags and moods will be deleted. This cannot be undone.'**
  String get resetAllBody1;

  /// No description provided for @doubleConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm again'**
  String get doubleConfirmTitle;

  /// No description provided for @doubleConfirmClear.
  ///
  /// In en, this message translates to:
  /// **'One more confirmation: really clear all local data?'**
  String get doubleConfirmClear;

  /// No description provided for @confirmClear.
  ///
  /// In en, this message translates to:
  /// **'Clear now'**
  String get confirmClear;

  /// No description provided for @resetDone.
  ///
  /// In en, this message translates to:
  /// **'Reset done'**
  String get resetDone;

  /// No description provided for @opFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get opFailed;

  /// No description provided for @dataCorruptTitle.
  ///
  /// In en, this message translates to:
  /// **'Data issue'**
  String get dataCorruptTitle;

  /// No description provided for @dataCorruptBody.
  ///
  /// In en, this message translates to:
  /// **'Local data can\'t be read and may be corrupted. Clearing will reset the app to its initial state (preset moods restored). This cannot be undone.'**
  String get dataCorruptBody;

  /// No description provided for @cleanData.
  ///
  /// In en, this message translates to:
  /// **'Clear data'**
  String get cleanData;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addImage;

  /// No description provided for @recordAudio.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get recordAudio;

  /// No description provided for @recordHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to start recording'**
  String get recordHint;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording;

  /// No description provided for @stopRecord.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopRecord;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @attachmentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large (max 20 MB each)'**
  String get attachmentTooLarge;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get micPermissionDenied;

  /// No description provided for @specialDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Special days'**
  String get specialDaysTitle;

  /// No description provided for @specialDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Stored as special thoughts (everything is a thought), recurring on the same date each year.'**
  String get specialDaysHint;

  /// No description provided for @specialDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'No special days yet'**
  String get specialDayEmpty;

  /// No description provided for @addSpecialDay.
  ///
  /// In en, this message translates to:
  /// **'Add special day'**
  String get addSpecialDay;

  /// No description provided for @specialDayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name, e.g. Mom\'s birthday'**
  String get specialDayNameHint;

  /// No description provided for @specialDayDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get specialDayDate;

  /// No description provided for @holidayPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Holiday schedule'**
  String get holidayPlanTitle;

  /// No description provided for @holidayPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Weekends are off by default; tap a date to mark rest/work. Enter national holidays and makeup workdays manually.'**
  String get holidayPlanHint;

  /// No description provided for @restLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get restLabel;

  /// No description provided for @workLabel.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workLabel;

  /// No description provided for @clearFlag.
  ///
  /// In en, this message translates to:
  /// **'Clear mark'**
  String get clearFlag;

  /// No description provided for @defaultRestLabel.
  ///
  /// In en, this message translates to:
  /// **'Default off'**
  String get defaultRestLabel;

  /// No description provided for @glyphRest.
  ///
  /// In en, this message translates to:
  /// **'O'**
  String get glyphRest;

  /// No description provided for @glyphWork.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get glyphWork;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
