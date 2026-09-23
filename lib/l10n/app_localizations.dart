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

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addEntry;

  /// No description provided for @recordDay.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get recordDay;

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

  /// No description provided for @thisWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeekTitle;

  /// No description provided for @thisMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonthTitle;

  /// No description provided for @recapEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded in this period yet.'**
  String get recapEmpty;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get collapse;

  /// No description provided for @templatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Writing templates'**
  String get templatesTitle;

  /// No description provided for @templatesHint.
  ///
  /// In en, this message translates to:
  /// **'Reusable multi-line snippets (e.g. \"Three questions\") you can insert while writing.'**
  String get templatesHint;

  /// No description provided for @manageTemplates.
  ///
  /// In en, this message translates to:
  /// **'Manage templates'**
  String get manageTemplates;

  /// No description provided for @insertTemplate.
  ///
  /// In en, this message translates to:
  /// **'Insert template'**
  String get insertTemplate;

  /// No description provided for @pickTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose a template'**
  String get pickTemplate;

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get newTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit template'**
  String get editTemplate;

  /// No description provided for @templateName.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get templateName;

  /// No description provided for @templateContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get templateContent;

  /// No description provided for @templateHint.
  ///
  /// In en, this message translates to:
  /// **'Multiple lines allowed; still editable after inserting.'**
  String get templateHint;

  /// No description provided for @templatesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No templates yet.\nTap + to add one, e.g. \"Three questions\".'**
  String get templatesEmpty;

  /// No description provided for @templateNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Template name can\'t be empty'**
  String get templateNameEmpty;

  /// No description provided for @templateContentEmpty.
  ///
  /// In en, this message translates to:
  /// **'Template content can\'t be empty'**
  String get templateContentEmpty;

  /// No description provided for @deleteTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this template?'**
  String get deleteTemplateTitle;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

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

  /// No description provided for @longestStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get longestStreakLabel;

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

  /// No description provided for @commentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsLabel;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get commentHint;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get addComment;

  /// No description provided for @deleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get deleteComment;

  /// No description provided for @reactionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get reactionsLabel;

  /// No description provided for @addReaction.
  ///
  /// In en, this message translates to:
  /// **'Add reaction'**
  String get addReaction;

  /// No description provided for @deleteReaction.
  ///
  /// In en, this message translates to:
  /// **'Remove reaction'**
  String get deleteReaction;

  /// No description provided for @archiveTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive & Trash'**
  String get archiveTrashTitle;

  /// No description provided for @archiveTab.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveTab;

  /// No description provided for @trashTab.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trashTab;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @moveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get moveToTrash;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get deleteForever;

  /// No description provided for @deleteForeverBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteForeverBody;

  /// No description provided for @emptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Empty trash'**
  String get emptyTrash;

  /// No description provided for @emptyTrashBody.
  ///
  /// In en, this message translates to:
  /// **'All thoughts in trash will be permanently deleted. This cannot be undone.'**
  String get emptyTrashBody;

  /// No description provided for @emptyArchiveHint.
  ///
  /// In en, this message translates to:
  /// **'No archived thoughts'**
  String get emptyArchiveHint;

  /// No description provided for @emptyTrashHint.
  ///
  /// In en, this message translates to:
  /// **'Trash is empty'**
  String get emptyTrashHint;

  /// No description provided for @trashRetentionHint.
  ///
  /// In en, this message translates to:
  /// **'Thoughts in trash are removed automatically after 7 days.'**
  String get trashRetentionHint;

  /// No description provided for @movedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Moved to trash'**
  String get movedToTrash;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @archiveHint.
  ///
  /// In en, this message translates to:
  /// **'Archive is not delete: archived thoughts stay here and can be unarchived anytime.'**
  String get archiveHint;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @insightsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get insightsOverview;

  /// No description provided for @totalThoughts.
  ///
  /// In en, this message translates to:
  /// **'Thoughts'**
  String get totalThoughts;

  /// No description provided for @totalWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get totalWords;

  /// No description provided for @activeDays.
  ///
  /// In en, this message translates to:
  /// **'Active days'**
  String get activeDays;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @daysValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysValue(num count);

  /// No description provided for @insightsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly trend'**
  String get insightsMonthly;

  /// No description provided for @seriesThoughts.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get seriesThoughts;

  /// No description provided for @seriesWords.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get seriesWords;

  /// No description provided for @insightsMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get insightsMood;

  /// No description provided for @moodDistribution.
  ///
  /// In en, this message translates to:
  /// **'Mood distribution'**
  String get moodDistribution;

  /// No description provided for @insightsTags.
  ///
  /// In en, this message translates to:
  /// **'Top tags'**
  String get insightsTags;

  /// No description provided for @insightsWritingTime.
  ///
  /// In en, this message translates to:
  /// **'Writing time'**
  String get insightsWritingTime;

  /// No description provided for @insightsCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get insightsCalendar;

  /// No description provided for @eventTotal.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventTotal;

  /// No description provided for @eventTypeDistribution.
  ///
  /// In en, this message translates to:
  /// **'By type'**
  String get eventTypeDistribution;

  /// No description provided for @insightsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get insightsEmpty;

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

  /// No description provided for @weekStartTitle.
  ///
  /// In en, this message translates to:
  /// **'First day of week'**
  String get weekStartTitle;

  /// No description provided for @weekStartSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekStartSunday;

  /// No description provided for @weekStartMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekStartMonday;

  /// No description provided for @calendarManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar manager'**
  String get calendarManageTitle;

  /// No description provided for @dayEventsLabel.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get dayEventsLabel;

  /// No description provided for @eventTypesSection.
  ///
  /// In en, this message translates to:
  /// **'Event types'**
  String get eventTypesSection;

  /// No description provided for @specialThoughtsSection.
  ///
  /// In en, this message translates to:
  /// **'Special days (thoughts)'**
  String get specialThoughtsSection;

  /// No description provided for @addEventType.
  ///
  /// In en, this message translates to:
  /// **'New type'**
  String get addEventType;

  /// No description provided for @editType.
  ///
  /// In en, this message translates to:
  /// **'Edit type'**
  String get editType;

  /// No description provided for @typeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name, e.g. 2026 holidays'**
  String get typeNameHint;

  /// No description provided for @markNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get markNone;

  /// No description provided for @cornerGlyphHint.
  ///
  /// In en, this message translates to:
  /// **'Corner glyph (optional)'**
  String get cornerGlyphHint;

  /// No description provided for @statusPresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Statuses'**
  String get statusPresetTitle;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @statusNameHint.
  ///
  /// In en, this message translates to:
  /// **'Status name (e.g. Done)'**
  String get statusNameHint;

  /// No description provided for @statusGlyphHint.
  ///
  /// In en, this message translates to:
  /// **'Glyph'**
  String get statusGlyphHint;

  /// No description provided for @addStatus.
  ///
  /// In en, this message translates to:
  /// **'Add status'**
  String get addStatus;

  /// No description provided for @statusRest.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get statusRest;

  /// No description provided for @statusMakeup.
  ///
  /// In en, this message translates to:
  /// **'Makeup'**
  String get statusMakeup;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEvent;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get editEvent;

  /// No description provided for @deleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get deleteEvent;

  /// No description provided for @eventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title (optional, defaults to type name)'**
  String get eventTitleHint;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDateLabel;

  /// No description provided for @endDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End date (optional, long-press to clear)'**
  String get endDateLabel;

  /// No description provided for @annualRecur.
  ///
  /// In en, this message translates to:
  /// **'Repeat yearly'**
  String get annualRecur;

  /// No description provided for @recordAsThought.
  ///
  /// In en, this message translates to:
  /// **'Also save as thought'**
  String get recordAsThought;

  /// No description provided for @deleteType.
  ///
  /// In en, this message translates to:
  /// **'Delete type'**
  String get deleteType;

  /// No description provided for @deleteTypeBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes \"{name}\" and all its events.'**
  String deleteTypeBody(String name);

  /// No description provided for @emptyTypes.
  ///
  /// In en, this message translates to:
  /// **'No types yet — tap + to create'**
  String get emptyTypes;

  /// No description provided for @eventsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String eventsCount(int count);

  /// No description provided for @presetHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get presetHoliday;

  /// No description provided for @presetMakeup.
  ///
  /// In en, this message translates to:
  /// **'Makeup workdays'**
  String get presetMakeup;

  /// No description provided for @presetBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get presetBirthday;

  /// No description provided for @presetPeriod.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get presetPeriod;

  /// No description provided for @presetTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get presetTravel;

  /// No description provided for @counterType.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get counterType;

  /// No description provided for @counterHint.
  ///
  /// In en, this message translates to:
  /// **'Tap +1 daily (habit tallies); no date ranges'**
  String get counterHint;

  /// No description provided for @counterLabel.
  ///
  /// In en, this message translates to:
  /// **'Counters'**
  String get counterLabel;

  /// No description provided for @addOne.
  ///
  /// In en, this message translates to:
  /// **'+1'**
  String get addOne;

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} in total'**
  String totalCount(int count);

  /// No description provided for @presetCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get presetCheckIn;

  /// No description provided for @kindHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holidays (with makeup)'**
  String get kindHoliday;

  /// No description provided for @kindCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get kindCustom;

  /// No description provided for @typeNameSimpleHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get typeNameSimpleHint;

  /// No description provided for @holidayMakeupHint.
  ///
  /// In en, this message translates to:
  /// **'A \"makeup workdays\" type will be created along (color and off/work marks are set automatically).'**
  String get holidayMakeupHint;

  /// No description provided for @instancesHint.
  ///
  /// In en, this message translates to:
  /// **'Instances above appear on the calendar; the section below only defines types (e.g. create \"Mom\'s birthday\" under a Birthday type).'**
  String get instancesHint;

  /// No description provided for @emptyEvents.
  ///
  /// In en, this message translates to:
  /// **'No events yet — tap Add event below'**
  String get emptyEvents;

  /// No description provided for @pickTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a type'**
  String get pickTypeTitle;

  /// No description provided for @noEventTypes.
  ///
  /// In en, this message translates to:
  /// **'Create a type below first'**
  String get noEventTypes;

  /// No description provided for @calendarLink.
  ///
  /// In en, this message translates to:
  /// **'Link to calendar'**
  String get calendarLink;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get addToCalendar;

  /// No description provided for @unlinkEvent.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlinkEvent;

  /// No description provided for @newEvent.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get newEvent;

  /// No description provided for @linkExistingHint.
  ///
  /// In en, this message translates to:
  /// **'Existing events on that day (link directly)'**
  String get linkExistingHint;

  /// No description provided for @navTodos.
  ///
  /// In en, this message translates to:
  /// **'To-dos'**
  String get navTodos;

  /// No description provided for @todosTitle.
  ///
  /// In en, this message translates to:
  /// **'To-dos'**
  String get todosTitle;

  /// No description provided for @todoBadgeHint.
  ///
  /// In en, this message translates to:
  /// **'Mark a status as \"done\" (e.g. Done); unfinished events of that type will show up in To-dos.'**
  String get todoBadgeHint;

  /// No description provided for @statusDoneToggle.
  ///
  /// In en, this message translates to:
  /// **'Done state'**
  String get statusDoneToggle;

  /// No description provided for @todosEmpty.
  ///
  /// In en, this message translates to:
  /// **'No to-dos. Give a type a \"done\" status and unfinished events will appear here.'**
  String get todosEmpty;

  /// No description provided for @todoComplete.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get todoComplete;

  /// No description provided for @todoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed \"{title}\"'**
  String todoCompleted(String title);

  /// No description provided for @todoNoStatus.
  ///
  /// In en, this message translates to:
  /// **'No status'**
  String get todoNoStatus;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get lockTitle;

  /// No description provided for @lockSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Set a passcode for the app; locked thoughts are excluded from search and require unlock to view.'**
  String get lockSectionHint;

  /// No description provided for @lockChooseMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose unlock method'**
  String get lockChooseMethod;

  /// No description provided for @lockPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get lockPin;

  /// No description provided for @lockPattern.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get lockPattern;

  /// No description provided for @lockSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get lockSetPin;

  /// No description provided for @lockSetPattern.
  ///
  /// In en, this message translates to:
  /// **'Set pattern'**
  String get lockSetPattern;

  /// No description provided for @lockEnterPinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 4-8 digits'**
  String get lockEnterPinHint;

  /// No description provided for @lockConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm once more'**
  String get lockConfirmHint;

  /// No description provided for @lockPatternHint.
  ///
  /// In en, this message translates to:
  /// **'Connect at least 4 dots'**
  String get lockPatternHint;

  /// No description provided for @lockMismatch.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t match — try again'**
  String get lockMismatch;

  /// No description provided for @lockWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong passcode'**
  String get lockWrong;

  /// No description provided for @lockPatternShort.
  ///
  /// In en, this message translates to:
  /// **'Connect at least 4 dots'**
  String get lockPatternShort;

  /// No description provided for @lockVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockVerifyTitle;

  /// No description provided for @lockPrivate.
  ///
  /// In en, this message translates to:
  /// **'Mark as private'**
  String get lockPrivate;

  /// No description provided for @lockUnlockEntry.
  ///
  /// In en, this message translates to:
  /// **'Unmark private'**
  String get lockUnlockEntry;

  /// No description provided for @lockChange.
  ///
  /// In en, this message translates to:
  /// **'Change passcode'**
  String get lockChange;

  /// No description provided for @lockTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off app lock'**
  String get lockTurnOff;

  /// No description provided for @lockTurnOffBody.
  ///
  /// In en, this message translates to:
  /// **'After turning off, private thoughts can be viewed without unlocking (the private mark is kept).'**
  String get lockTurnOffBody;

  /// No description provided for @lockLockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock now'**
  String get lockLockNow;

  /// No description provided for @lockedBadge.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get lockedBadge;

  /// No description provided for @lockProtectedHint.
  ///
  /// In en, this message translates to:
  /// **'Private thoughts are excluded from search and wander.'**
  String get lockProtectedHint;

  /// No description provided for @advancedTagsSection.
  ///
  /// In en, this message translates to:
  /// **'Advanced tags'**
  String get advancedTagsSection;

  /// No description provided for @advancedTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Add tag groups to a thought as needed; each group can be single- or multi-select.'**
  String get advancedTagsHint;

  /// No description provided for @advancedTagsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tag groups added yet'**
  String get advancedTagsEmpty;

  /// No description provided for @addTagCategory.
  ///
  /// In en, this message translates to:
  /// **'Add tag group'**
  String get addTagCategory;

  /// No description provided for @removeTagCategory.
  ///
  /// In en, this message translates to:
  /// **'Remove tag group'**
  String get removeTagCategory;

  /// No description provided for @allTagCategoriesAdded.
  ///
  /// In en, this message translates to:
  /// **'All tag groups added'**
  String get allTagCategoriesAdded;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'New option'**
  String get addOption;

  /// No description provided for @optionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No options yet — tap + to add'**
  String get optionsEmpty;

  /// No description provided for @optionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No options} other{{count} options}}'**
  String optionCount(int count);

  /// No description provided for @categorySingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get categorySingle;

  /// No description provided for @categoryMulti.
  ///
  /// In en, this message translates to:
  /// **'Multi'**
  String get categoryMulti;

  /// No description provided for @editTagCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit tag group'**
  String get editTagCategory;

  /// No description provided for @deleteTagCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete tag group'**
  String get deleteTagCategory;

  /// No description provided for @deleteTagCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes \"{name}\" and all its options; those values are removed from thoughts.'**
  String deleteTagCategoryBody(String name);

  /// No description provided for @normalTagsSection.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get normalTagsSection;
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
