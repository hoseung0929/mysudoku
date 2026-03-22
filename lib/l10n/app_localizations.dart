import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

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
    Locale('ko')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Sudoku'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navChallenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get navChallenge;

  /// No description provided for @navRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get navRecords;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @recordsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Records & stats'**
  String get recordsScreenTitle;

  /// No description provided for @challengeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challengeScreenTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsSectionGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get settingsSectionGame;

  /// No description provided for @settingsSectionInfo.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionInfo;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage game notifications'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsNotificationTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification time'**
  String get settingsNotificationTimeTitle;

  /// No description provided for @settingsNotificationTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose when to receive reminders'**
  String get settingsNotificationTimeSubtitle;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light, dark, or system default'**
  String get settingsThemeSubtitle;

  /// No description provided for @settingsDarkModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkModeTitle;

  /// No description provided for @settingsDarkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn dark mode on or off'**
  String get settingsDarkModeSubtitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get settingsLanguageKorean;

  /// No description provided for @settingsLanguagePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get settingsLanguagePickerTitle;

  /// No description provided for @settingsVibrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsVibrationTitle;

  /// No description provided for @settingsVibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate when entering numbers'**
  String get settingsVibrationSubtitle;

  /// No description provided for @settingsAppInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'App info'**
  String get settingsAppInfoTitle;

  /// No description provided for @settingsAppInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version and developer info'**
  String get settingsAppInfoSubtitle;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsTabletNotificationsHeader.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get settingsTabletNotificationsHeader;

  /// No description provided for @settingsTabletNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Manage and configure game notifications.'**
  String get settingsTabletNotificationsBody;

  /// No description provided for @settingsGameCompleteNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Game complete notification'**
  String get settingsGameCompleteNotifTitle;

  /// No description provided for @settingsGameCompleteNotifSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when you finish a puzzle'**
  String get settingsGameCompleteNotifSubtitle;

  /// No description provided for @settingsDailyGoalNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily goal notification'**
  String get settingsDailyGoalNotifTitle;

  /// No description provided for @settingsDailyGoalNotifSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when you reach your daily goal'**
  String get settingsDailyGoalNotifSubtitle;

  /// No description provided for @settingsHintNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Hint usage notification'**
  String get settingsHintNotifTitle;

  /// No description provided for @settingsHintNotifSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify when you use a hint'**
  String get settingsHintNotifSubtitle;

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelAdvanced;

  /// No description provided for @levelExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get levelExpert;

  /// No description provided for @levelMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get levelMaster;

  /// No description provided for @levelDescBeginner.
  ///
  /// In en, this message translates to:
  /// **'Perfect if you are new to Sudoku'**
  String get levelDescBeginner;

  /// No description provided for @levelDescIntermediate.
  ///
  /// In en, this message translates to:
  /// **'For those who know the basic rules'**
  String get levelDescIntermediate;

  /// No description provided for @levelDescAdvanced.
  ///
  /// In en, this message translates to:
  /// **'For experienced players'**
  String get levelDescAdvanced;

  /// No description provided for @levelDescExpert.
  ///
  /// In en, this message translates to:
  /// **'For Sudoku masters'**
  String get levelDescExpert;

  /// No description provided for @levelDescMaster.
  ///
  /// In en, this message translates to:
  /// **'The ultimate challenge'**
  String get levelDescMaster;

  /// No description provided for @gameGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get gameGuideTitle;

  /// No description provided for @gameGuideTapCellTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a cell first'**
  String get gameGuideTapCellTitle;

  /// No description provided for @gameGuideTapCellBody.
  ///
  /// In en, this message translates to:
  /// **'Tap an empty cell, then use the number buttons below.'**
  String get gameGuideTapCellBody;

  /// No description provided for @gameGuideMistakesTitle.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 mistakes'**
  String get gameGuideMistakesTitle;

  /// No description provided for @gameGuideMistakesBody.
  ///
  /// In en, this message translates to:
  /// **'Three wrong numbers end this puzzle.'**
  String get gameGuideMistakesBody;

  /// No description provided for @gameGuideColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Use color hints'**
  String get gameGuideColorsTitle;

  /// No description provided for @gameGuideColorsBody.
  ///
  /// In en, this message translates to:
  /// **'Selected cell, same numbers, and related cells are highlighted.'**
  String get gameGuideColorsBody;

  /// No description provided for @gameGuidePlayButton.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get gameGuidePlayButton;

  /// No description provided for @gameNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Game {number}'**
  String gameNumberLabel(int number);

  /// No description provided for @gameHintShort.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get gameHintShort;

  /// No description provided for @gameMemoShort.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get gameMemoShort;

  /// No description provided for @gameMemoOnShort.
  ///
  /// In en, this message translates to:
  /// **'Memo ON'**
  String get gameMemoOnShort;

  /// No description provided for @gameMemoStateOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get gameMemoStateOn;

  /// No description provided for @gameMemoStateOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get gameMemoStateOff;

  /// No description provided for @gameWrongShort.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get gameWrongShort;

  /// No description provided for @gameProgressShort.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get gameProgressShort;

  /// No description provided for @gameTimeShort.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get gameTimeShort;

  /// No description provided for @gameNumberInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Number input'**
  String get gameNumberInputTitle;

  /// No description provided for @gamePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get gamePause;

  /// No description provided for @gameResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get gameResume;

  /// No description provided for @gameAnswerPreview.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get gameAnswerPreview;

  /// No description provided for @challengeCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'You completed today’s challenge!'**
  String get challengeCompletedToday;

  /// No description provided for @shareCopySuccess.
  ///
  /// In en, this message translates to:
  /// **'Result copied to clipboard.'**
  String get shareCopySuccess;

  /// No description provided for @shareSubject.
  ///
  /// In en, this message translates to:
  /// **'My Sudoku result'**
  String get shareSubject;

  /// No description provided for @shareClearHeader.
  ///
  /// In en, this message translates to:
  /// **'My Sudoku clear'**
  String get shareClearHeader;

  /// No description provided for @shareClearLine.
  ///
  /// In en, this message translates to:
  /// **'{level} · Game {number}'**
  String shareClearLine(String level, int number);

  /// No description provided for @shareClearStats.
  ///
  /// In en, this message translates to:
  /// **'{time} · {wrong} mistakes'**
  String shareClearStats(String time, int wrong);

  /// No description provided for @shareClearTags.
  ///
  /// In en, this message translates to:
  /// **'#MySudoku #SudokuChallenge'**
  String get shareClearTags;

  /// No description provided for @shareSummaryPattern.
  ///
  /// In en, this message translates to:
  /// **'{time} · {wrong} mistakes'**
  String shareSummaryPattern(String time, int wrong);

  /// No description provided for @dialogCongratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get dialogCongratulations;

  /// No description provided for @dialogNewBest.
  ///
  /// In en, this message translates to:
  /// **'NEW BEST'**
  String get dialogNewBest;

  /// No description provided for @dialogSudokuComplete.
  ///
  /// In en, this message translates to:
  /// **'You completed the puzzle!'**
  String get dialogSudokuComplete;

  /// No description provided for @dialogNewBadges.
  ///
  /// In en, this message translates to:
  /// **'New badges'**
  String get dialogNewBadges;

  /// No description provided for @dialogElapsedTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get dialogElapsedTime;

  /// No description provided for @dialogWrongCount.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get dialogWrongCount;

  /// No description provided for @dialogWrongCountValue.
  ///
  /// In en, this message translates to:
  /// **'{count} times'**
  String dialogWrongCountValue(int count);

  /// No description provided for @dialogSharePreview.
  ///
  /// In en, this message translates to:
  /// **'Share text'**
  String get dialogSharePreview;

  /// No description provided for @dialogCopyResult.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get dialogCopyResult;

  /// No description provided for @dialogShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get dialogShare;

  /// No description provided for @dialogBackToLevels.
  ///
  /// In en, this message translates to:
  /// **'Level list'**
  String get dialogBackToLevels;

  /// No description provided for @dialogPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get dialogPlayAgain;

  /// No description provided for @dialogNextPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Next puzzle'**
  String get dialogNextPuzzle;

  /// No description provided for @settingsAppearancePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearancePickerTitle;

  /// No description provided for @settingsThemeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeModeLight;

  /// No description provided for @settingsThemeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeModeDark;

  /// No description provided for @settingsNotificationsComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsComingSoonTitle;

  /// No description provided for @settingsNotificationsComingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'Push reminders and notification options will be available in a future update. Thanks for your patience!'**
  String get settingsNotificationsComingSoonBody;

  /// No description provided for @settingsAboutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get settingsAboutDialogTitle;

  /// No description provided for @settingsAboutVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsAboutVersionLabel(String version);

  /// No description provided for @settingsAboutDeveloperNote.
  ///
  /// In en, this message translates to:
  /// **'Enjoy playing My Sudoku!'**
  String get settingsAboutDeveloperNote;

  /// No description provided for @settingsPrivacyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacyDialogTitle;

  /// No description provided for @settingsPrivacyDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This app stores your game progress and records only on this device. We do not collect personal data or require an account. If you uninstall the app, local data may be removed unless your device backs up app data.'**
  String get settingsPrivacyDialogBody;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @gameOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get gameOverTitle;

  /// No description provided for @gameOverMessage.
  ///
  /// In en, this message translates to:
  /// **'You made more than 3 mistakes.'**
  String get gameOverMessage;

  /// No description provided for @gameOverWrongLabel.
  ///
  /// In en, this message translates to:
  /// **'Mistakes: {count}/3'**
  String gameOverWrongLabel(int count);

  /// No description provided for @recordsFilterSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get recordsFilterSectionTitle;

  /// No description provided for @recordsFilterAllLevels.
  ///
  /// In en, this message translates to:
  /// **'All levels'**
  String get recordsFilterAllLevels;

  /// No description provided for @recordsPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get recordsPeriodLabel;

  /// No description provided for @recordsPeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get recordsPeriodAll;

  /// No description provided for @recordsPeriodLastDays.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String recordsPeriodLastDays(int days);

  /// No description provided for @recordsSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get recordsSummaryTitle;

  /// No description provided for @recordsMetricClears.
  ///
  /// In en, this message translates to:
  /// **'Clears'**
  String get recordsMetricClears;

  /// No description provided for @recordsMetricClearRate.
  ///
  /// In en, this message translates to:
  /// **'Clear rate'**
  String get recordsMetricClearRate;

  /// No description provided for @recordsMetricAvgTime.
  ///
  /// In en, this message translates to:
  /// **'Avg. time'**
  String get recordsMetricAvgTime;

  /// No description provided for @recordsMetricAvgWrong.
  ///
  /// In en, this message translates to:
  /// **'Avg. mistakes'**
  String get recordsMetricAvgWrong;

  /// No description provided for @recordsByLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'By level'**
  String get recordsByLevelTitle;

  /// No description provided for @recordsByLevelEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stats for this filter.'**
  String get recordsByLevelEmpty;

  /// No description provided for @recordsAvgTimeDetail.
  ///
  /// In en, this message translates to:
  /// **'Avg. time {time}'**
  String recordsAvgTimeDetail(String time);

  /// No description provided for @recordsRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent clears'**
  String get recordsRecentTitle;

  /// No description provided for @recordsRecentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No clears match this filter.'**
  String get recordsRecentEmpty;

  /// No description provided for @recordsBestTitle.
  ///
  /// In en, this message translates to:
  /// **'Best times (Top 5)'**
  String get recordsBestTitle;

  /// No description provided for @recordsBestEmpty.
  ///
  /// In en, this message translates to:
  /// **'No best times for this filter.'**
  String get recordsBestEmpty;

  /// No description provided for @recordsGameNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'{level} · Game {number}'**
  String recordsGameNumberTitle(String level, int number);

  /// No description provided for @recordsRecentDetail.
  ///
  /// In en, this message translates to:
  /// **'{time} · Mistakes: {wrongCount} · {date}'**
  String recordsRecentDetail(String time, int wrongCount, String date);

  /// No description provided for @recordsBestDetail.
  ///
  /// In en, this message translates to:
  /// **'{time} · Mistakes: {wrongCount}'**
  String recordsBestDetail(String time, int wrongCount);

  /// No description provided for @recordsGameLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load puzzle data.'**
  String get recordsGameLoadError;

  /// No description provided for @challengeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load challenge data.'**
  String get challengeLoadError;

  /// No description provided for @challengeTodaysChallengeTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s challenge'**
  String get challengeTodaysChallengeTitle;

  /// No description provided for @challengeTodayDoneHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already finished today. Open it again anytime to review.'**
  String get challengeTodayDoneHint;

  /// No description provided for @challengeTodayPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Keep your streak with today\'s featured puzzle.'**
  String get challengeTodayPendingHint;

  /// No description provided for @challengeTodayReviewButton.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get challengeTodayReviewButton;

  /// No description provided for @challengeTodayStartButton.
  ///
  /// In en, this message translates to:
  /// **'Start challenge'**
  String get challengeTodayStartButton;

  /// No description provided for @challengeSuggestedActions.
  ///
  /// In en, this message translates to:
  /// **'Suggested next steps'**
  String get challengeSuggestedActions;

  /// No description provided for @challengeWeeklyGoalReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly goal reached'**
  String get challengeWeeklyGoalReachedTitle;

  /// No description provided for @challengeWeeklyGoalRemainingTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} more clears to hit your weekly goal'**
  String challengeWeeklyGoalRemainingTitle(int count);

  /// No description provided for @challengeWeeklyGoalReachedBody.
  ///
  /// In en, this message translates to:
  /// **'Add more perfect clears to build an even stronger rhythm.'**
  String get challengeWeeklyGoalReachedBody;

  /// No description provided for @challengeWeeklyGoalCatchUpBody.
  ///
  /// In en, this message translates to:
  /// **'A few quick sessions can finish this week\'s target.'**
  String get challengeWeeklyGoalCatchUpBody;

  /// No description provided for @challengePerfectThisWeek.
  ///
  /// In en, this message translates to:
  /// **'{count} perfect clears this week'**
  String challengePerfectThisWeek(int count);

  /// No description provided for @challengePerfectThisWeekFirst.
  ///
  /// In en, this message translates to:
  /// **'Try your first perfect clear this week'**
  String get challengePerfectThisWeekFirst;

  /// No description provided for @challengePerfectPositiveBody.
  ///
  /// In en, this message translates to:
  /// **'Flawless runs make your progress easier to see.'**
  String get challengePerfectPositiveBody;

  /// No description provided for @challengePerfectZeroBody.
  ///
  /// In en, this message translates to:
  /// **'Memo mode gets you much closer to mistake-free clears.'**
  String get challengePerfectZeroBody;

  /// No description provided for @challengeWeeklyGoalHeading.
  ///
  /// In en, this message translates to:
  /// **'Weekly goal'**
  String get challengeWeeklyGoalHeading;

  /// No description provided for @challengeWeeklyClearsLine.
  ///
  /// In en, this message translates to:
  /// **'{count} clears this week'**
  String challengeWeeklyClearsLine(int count);

  /// No description provided for @challengeWeeklyProgressShort.
  ///
  /// In en, this message translates to:
  /// **'{done} / {target} done'**
  String challengeWeeklyProgressShort(int done, int target);

  /// No description provided for @challengeWeeklyPerfectShort.
  ///
  /// In en, this message translates to:
  /// **'{count} perfect'**
  String challengeWeeklyPerfectShort(int count);

  /// No description provided for @challengeWeeklyCongratsFooter.
  ///
  /// In en, this message translates to:
  /// **'Weekly goal complete—keep stacking great records!'**
  String get challengeWeeklyCongratsFooter;

  /// No description provided for @challengeWeeklyAlmostFooter.
  ///
  /// In en, this message translates to:
  /// **'{count} more clears to finish the week.'**
  String challengeWeeklyAlmostFooter(int count);

  /// No description provided for @challengeAchievementsHeading.
  ///
  /// In en, this message translates to:
  /// **'Achievements · badges'**
  String get challengeAchievementsHeading;

  /// No description provided for @challengeBadgesCollected.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} / {total} earned'**
  String challengeBadgesCollected(int unlocked, int total);

  /// No description provided for @challengeViewAllBadges.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get challengeViewAllBadges;

  /// No description provided for @challengeEarnedBadgesHeading.
  ///
  /// In en, this message translates to:
  /// **'Earned badges'**
  String get challengeEarnedBadgesHeading;

  /// No description provided for @challengeNextBadgeTargets.
  ///
  /// In en, this message translates to:
  /// **'Next targets'**
  String get challengeNextBadgeTargets;

  /// No description provided for @challengeBadgeProgressLine.
  ///
  /// In en, this message translates to:
  /// **'{desc} · Progress: {progress}'**
  String challengeBadgeProgressLine(String desc, String progress);

  /// No description provided for @challengeStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String challengeStreakDays(int days);

  /// No description provided for @challengeStreakStartToday.
  ///
  /// In en, this message translates to:
  /// **'Chase your first clear today'**
  String get challengeStreakStartToday;

  /// No description provided for @challengeHeroDoneCaption.
  ///
  /// In en, this message translates to:
  /// **'You finished today\'s challenge. Come back tomorrow to extend your streak.'**
  String get challengeHeroDoneCaption;

  /// No description provided for @challengeHeroPendingCaption.
  ///
  /// In en, this message translates to:
  /// **'Today\'s puzzle is still open—start now to keep your streak alive.'**
  String get challengeHeroPendingCaption;

  /// No description provided for @challengeHeroReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review results'**
  String get challengeHeroReviewAction;

  /// No description provided for @challengeHeroStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start today\'s challenge'**
  String get challengeHeroStartAction;

  /// No description provided for @challengeQuickStartRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick start'**
  String get challengeQuickStartRecommendedTitle;

  /// No description provided for @challengeQuickStartRecommendedBody.
  ///
  /// In en, this message translates to:
  /// **'{level} — recommended'**
  String challengeQuickStartRecommendedBody(String level);

  /// No description provided for @challengeQuickStartBeginnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Beginner start'**
  String get challengeQuickStartBeginnerTitle;

  /// No description provided for @challengeQuickStartBeginnerBody.
  ///
  /// In en, this message translates to:
  /// **'Start an easy, low-pressure game'**
  String get challengeQuickStartBeginnerBody;

  /// No description provided for @challengeQuickStartRandomTitle.
  ///
  /// In en, this message translates to:
  /// **'Random challenge'**
  String get challengeQuickStartRandomTitle;

  /// No description provided for @challengeQuickStartRandomBody.
  ///
  /// In en, this message translates to:
  /// **'Play something light to match your mood'**
  String get challengeQuickStartRandomBody;

  /// No description provided for @homeOnboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get homeOnboardingWelcomeTitle;

  /// No description provided for @homeOnboardingStepQuickTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick start'**
  String get homeOnboardingStepQuickTitle;

  /// No description provided for @homeOnboardingStepQuickBody.
  ///
  /// In en, this message translates to:
  /// **'Jump into a recommended difficulty right away.'**
  String get homeOnboardingStepQuickBody;

  /// No description provided for @homeOnboardingStepDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge'**
  String get homeOnboardingStepDailyTitle;

  /// No description provided for @homeOnboardingStepDailyBody.
  ///
  /// In en, this message translates to:
  /// **'Try the daily puzzle to check your skills in one short game.'**
  String get homeOnboardingStepDailyBody;

  /// No description provided for @homeOnboardingStepResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeOnboardingStepResumeTitle;

  /// No description provided for @homeOnboardingStepResumeBody.
  ///
  /// In en, this message translates to:
  /// **'Continue saved games from the card at the top of Home.'**
  String get homeOnboardingStepResumeBody;

  /// No description provided for @homeOnboardingStartButton.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get homeOnboardingStartButton;

  /// No description provided for @homeGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get homeGuestTitle;

  /// No description provided for @homeGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a game in one tap'**
  String get homeGuestSubtitle;

  /// No description provided for @homeContinueTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeContinueTitle;

  /// No description provided for @homeContinueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{level} · Game {gameNumber} · {cells} cells filled'**
  String homeContinueSubtitle(String level, int gameNumber, int cells);

  /// No description provided for @homeContinueDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick up your paused puzzle where you left off.'**
  String get homeContinueDescription;

  /// No description provided for @homeContinueActionButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinueActionButton;

  /// No description provided for @homeProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'Progress {percent}%'**
  String homeProgressPercent(int percent);

  /// No description provided for @homeTodayChallengeCardDoneBody.
  ///
  /// In en, this message translates to:
  /// **'You finished today\'s challenge. Keep your streak going!'**
  String get homeTodayChallengeCardDoneBody;

  /// No description provided for @homeTodayChallengeCardPendingBody.
  ///
  /// In en, this message translates to:
  /// **'One puzzle a day—light practice, steady progress.'**
  String get homeTodayChallengeCardPendingBody;

  /// No description provided for @homeTodayChallengeFooterDoneStreak.
  ///
  /// In en, this message translates to:
  /// **'Today\'s challenge done · {days}-day streak'**
  String homeTodayChallengeFooterDoneStreak(int days);

  /// No description provided for @homeTodayChallengeFooterPending.
  ///
  /// In en, this message translates to:
  /// **'Use today\'s puzzle to build a streak.'**
  String get homeTodayChallengeFooterPending;

  /// No description provided for @homeQuickStartSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick start'**
  String get homeQuickStartSectionTitle;

  /// No description provided for @homeBrowseLevelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse levels'**
  String get homeBrowseLevelsTitle;

  /// No description provided for @homeStreakTodayDoneLine.
  ///
  /// In en, this message translates to:
  /// **'Today\'s challenge is done too.'**
  String get homeStreakTodayDoneLine;

  /// No description provided for @homeStreakTodayPendingLine.
  ///
  /// In en, this message translates to:
  /// **'Finish today\'s challenge to extend your streak.'**
  String get homeStreakTodayPendingLine;

  /// No description provided for @homeBadgeProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Badge progress'**
  String get homeBadgeProgressTitle;

  /// No description provided for @homeCatalogPreparingTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing puzzle catalog'**
  String get homeCatalogPreparingTitle;

  /// No description provided for @homeCatalogProgressDetail.
  ///
  /// In en, this message translates to:
  /// **'{generated}/{target} puzzles ready · {remaining} to go'**
  String homeCatalogProgressDetail(int generated, int target, int remaining);

  /// No description provided for @levelPickDifficultyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose difficulty'**
  String get levelPickDifficultyTitle;

  /// No description provided for @levelPickDifficultySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a difficulty to start playing.'**
  String get levelPickDifficultySubtitle;

  /// No description provided for @levelPickGameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a puzzle to begin.'**
  String get levelPickGameSubtitle;

  /// No description provided for @levelGamesScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'{levelName} games'**
  String levelGamesScreenTitle(String levelName);

  /// No description provided for @levelLoadingGames.
  ///
  /// In en, this message translates to:
  /// **'Loading puzzles…'**
  String get levelLoadingGames;

  /// No description provided for @levelTapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap to start'**
  String get levelTapToStart;

  /// No description provided for @levelClearedBadge.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get levelClearedBadge;

  /// No description provided for @levelCatalogPreparingShort.
  ///
  /// In en, this message translates to:
  /// **'Preparing more puzzles · {done}/{total}'**
  String levelCatalogPreparingShort(int done, int total);

  /// No description provided for @achievementCollectionAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get achievementCollectionAppBarTitle;

  /// No description provided for @achievementLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load badges.'**
  String get achievementLoadError;

  /// No description provided for @achievementViewSettings.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get achievementViewSettings;

  /// No description provided for @achievementSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get achievementSortLabel;

  /// No description provided for @achievementFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get achievementFilterAll;

  /// No description provided for @achievementFilterUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get achievementFilterUnlocked;

  /// No description provided for @achievementFilterLocked.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get achievementFilterLocked;

  /// No description provided for @achievementSectionAll.
  ///
  /// In en, this message translates to:
  /// **'All badges'**
  String get achievementSectionAll;

  /// No description provided for @achievementSectionUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked badges'**
  String get achievementSectionUnlocked;

  /// No description provided for @achievementSectionLocked.
  ///
  /// In en, this message translates to:
  /// **'Badges in progress'**
  String get achievementSectionLocked;

  /// No description provided for @achievementEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'No badges to show.'**
  String get achievementEmptyAll;

  /// No description provided for @achievementEmptyUnlocked.
  ///
  /// In en, this message translates to:
  /// **'No badges unlocked yet.'**
  String get achievementEmptyUnlocked;

  /// No description provided for @achievementEmptyLocked.
  ///
  /// In en, this message translates to:
  /// **'You\'ve unlocked every badge.'**
  String get achievementEmptyLocked;

  /// No description provided for @achievementHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementHeroTitle;

  /// No description provided for @achievementHeroProgress.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} / {total} unlocked'**
  String achievementHeroProgress(int unlocked, int total);

  /// No description provided for @achievementHeroAllUnlocked.
  ///
  /// In en, this message translates to:
  /// **'You collected every badge. Amazing!'**
  String get achievementHeroAllUnlocked;

  /// No description provided for @achievementHeroKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep playing to unlock more badges.'**
  String get achievementHeroKeepGoing;

  /// No description provided for @achievementBadgeFirstClearTitle.
  ///
  /// In en, this message translates to:
  /// **'First clear'**
  String get achievementBadgeFirstClearTitle;

  /// No description provided for @achievementBadgeFirstClearDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish your first puzzle to begin your Sudoku journey.'**
  String get achievementBadgeFirstClearDesc;

  /// No description provided for @achievementBadgeStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'3-day streak'**
  String get achievementBadgeStreakTitle;

  /// No description provided for @achievementBadgeStreakDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear puzzles three days in a row to build a habit.'**
  String get achievementBadgeStreakDesc;

  /// No description provided for @achievementBadgeWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly runner'**
  String get achievementBadgeWeeklyTitle;

  /// No description provided for @achievementBadgeWeeklyDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear five puzzles in the last seven days.'**
  String get achievementBadgeWeeklyDesc;

  /// No description provided for @achievementBadgePerfectTitle.
  ///
  /// In en, this message translates to:
  /// **'Perfect clear'**
  String get achievementBadgePerfectTitle;

  /// No description provided for @achievementBadgePerfectDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish a puzzle with zero mistakes.'**
  String get achievementBadgePerfectDesc;

  /// No description provided for @achievementBadgeMasterTitle.
  ///
  /// In en, this message translates to:
  /// **'Master first win'**
  String get achievementBadgeMasterTitle;

  /// No description provided for @achievementBadgeMasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear a Master puzzle for the first time.'**
  String get achievementBadgeMasterDesc;

  /// No description provided for @achievementProgressFraction.
  ///
  /// In en, this message translates to:
  /// **'{current}/{max}'**
  String achievementProgressFraction(int current, int max);

  /// No description provided for @achievementProgressStreak.
  ///
  /// In en, this message translates to:
  /// **'{current}/{max} days'**
  String achievementProgressStreak(int current, int max);

  /// No description provided for @achievementProgressWeekly.
  ///
  /// In en, this message translates to:
  /// **'{current}/{max} clears'**
  String achievementProgressWeekly(int current, int max);

  /// No description provided for @achievementStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get achievementStatusDone;

  /// No description provided for @achievementStatusNotMet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get achievementStatusNotMet;

  /// No description provided for @achievementStatusTrying.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get achievementStatusTrying;

  /// No description provided for @achievementTileProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress: {label}'**
  String achievementTileProgress(String label);

  /// No description provided for @achievementTileRarity.
  ///
  /// In en, this message translates to:
  /// **'Rarity: {label}'**
  String achievementTileRarity(String label);

  /// No description provided for @achievementRarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get achievementRarityCommon;

  /// No description provided for @achievementRarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get achievementRarityRare;

  /// No description provided for @achievementRarityEpic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get achievementRarityEpic;

  /// No description provided for @achievementSortDefault.
  ///
  /// In en, this message translates to:
  /// **'Default order'**
  String get achievementSortDefault;

  /// No description provided for @achievementSortRarity.
  ///
  /// In en, this message translates to:
  /// **'By rarity'**
  String get achievementSortRarity;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
