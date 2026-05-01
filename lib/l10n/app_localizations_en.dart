// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Sudoku';

  @override
  String get navHome => 'Home';

  @override
  String get navChallenge => 'Challenge';

  @override
  String get navRecords => 'Records';

  @override
  String get navSettings => 'Settings';

  @override
  String get recordsScreenTitle => 'Records & stats';

  @override
  String get challengeScreenTitle => 'Challenge';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionGame => 'Game';

  @override
  String get settingsSectionCloud => 'Cloud save';

  @override
  String get settingsSectionInfo => 'About';

  @override
  String get settingsCloudAccountTitle => 'Cloud save account';

  @override
  String get settingsCloudUnavailableSubtitle =>
      'Firebase setup is not available in this build.';

  @override
  String get settingsCloudAnonymousSubtitle =>
      'Using a temporary device account. Connect an email account to carry progress across devices.';

  @override
  String get settingsCloudDisconnectedSubtitle =>
      'Sign in to sync your progress across devices.';

  @override
  String settingsCloudConnectedSubtitle(String email) {
    return 'Signed in as $email. Your progress can follow you to other devices.';
  }

  @override
  String get settingsCloudSyncNowTitle => 'Sync now';

  @override
  String get settingsCloudSyncNowSubtitle =>
      'Upload local progress and pull the latest cloud saves.';

  @override
  String get settingsCloudConnectSheetTitle =>
      'Keep your progress across devices';

  @override
  String get settingsCloudConnectSheetBody =>
      'Create an account or sign in with an existing email account to keep playing on another device.';

  @override
  String get settingsCloudManageSheetTitle => 'Cloud save account';

  @override
  String get settingsCloudManageSheetBody =>
      'Your linked account is ready. You can sync now or sign out on this device.';

  @override
  String get settingsCloudSignInAction => 'Sign in';

  @override
  String get settingsCloudCreateAccountAction => 'Create account';

  @override
  String get settingsCloudSignOutAction => 'Sign out';

  @override
  String get settingsCloudEmailLabel => 'Email';

  @override
  String get settingsCloudPasswordLabel => 'Password';

  @override
  String get settingsCloudCreateDialogTitle => 'Create cloud account';

  @override
  String get settingsCloudSignInDialogTitle => 'Sign in to sync';

  @override
  String get settingsCloudAuthSuccessSignIn =>
      'Signed in and synced your progress.';

  @override
  String get settingsCloudAuthSuccessCreate =>
      'Cloud account connected and synced.';

  @override
  String get settingsCloudSyncSuccess => 'Cloud sync completed.';

  @override
  String get settingsCloudSignOutSuccess => 'Signed out on this device.';

  @override
  String get settingsCloudValidationMissingCredentials =>
      'Enter both an email address and password.';

  @override
  String get settingsCloudErrorGeneric =>
      'We couldn\'t complete that cloud account request.';

  @override
  String get settingsCloudErrorFirebaseUnavailable =>
      'Firebase is not configured in this build.';

  @override
  String get settingsCloudErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get settingsCloudErrorWrongPassword => 'The password is incorrect.';

  @override
  String get settingsCloudErrorUserNotFound =>
      'No account matches that email address.';

  @override
  String get settingsCloudErrorEmailAlreadyInUse =>
      'That email address is already in use.';

  @override
  String get settingsCloudErrorWeakPassword =>
      'Use a password with at least 6 characters.';

  @override
  String get settingsNotificationsTitle => 'Notification settings';

  @override
  String get settingsNotificationsSubtitle =>
      'Send a reminder when today’s challenge is still unfinished';

  @override
  String get settingsStreakReminderTitle => 'Streak reminder';

  @override
  String get settingsStreakReminderSubtitle =>
      'Send one more reminder when you already have an active streak';

  @override
  String get settingsNotificationTimeTitle => 'Notification time';

  @override
  String get settingsNotificationTimeSubtitle =>
      'Choose when to receive reminders';

  @override
  String get settingsNotificationsPermissionDenied =>
      'Notification permission is required to turn reminders on.';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Change app language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageKorean => 'Korean';

  @override
  String get settingsLanguagePickerTitle => 'Choose language';

  @override
  String get settingsVibrationTitle => 'Haptic feedback';

  @override
  String get settingsVibrationSubtitle => 'Vibrate when entering numbers';

  @override
  String get settingsKeepScreenAwakeTitle => 'Keep screen awake';

  @override
  String get settingsKeepScreenAwakeSubtitle =>
      'Prevent the game screen from sleeping automatically';

  @override
  String get settingsOneHandModeTitle => 'One-hand mode';

  @override
  String get settingsOneHandModeSubtitle =>
      'Use a denser button layout on the mobile game screen';

  @override
  String get settingsMemoHighlightTitle => 'Memo highlight';

  @override
  String get settingsMemoHighlightSubtitle =>
      'Show memo focus, candidate, and unique-note highlights';

  @override
  String get settingsSmartHintTitle => 'Playable-cell highlight';

  @override
  String get settingsSmartHintSubtitle =>
      'Softly highlight cells that can be filled immediately by rules';

  @override
  String get settingsAppInfoTitle => 'App info';

  @override
  String get settingsAppInfoSubtitle => 'Version and developer info';

  @override
  String get settingsPrivacyTitle => 'Privacy policy';

  @override
  String get settingsPrivacySubtitle => 'How we handle your data';

  @override
  String get settingsTabletNotificationsHeader => 'Notification settings';

  @override
  String get settingsTabletNotificationsBody =>
      'Manage and configure game notifications.';

  @override
  String get settingsGameCompleteNotifTitle => 'Game complete notification';

  @override
  String get settingsGameCompleteNotifSubtitle =>
      'Notify when you finish a puzzle';

  @override
  String get settingsDailyGoalNotifTitle => 'Daily goal notification';

  @override
  String get settingsDailyGoalNotifSubtitle =>
      'Celebrate the moment you reach your weekly goal';

  @override
  String get settingsHintNotifTitle => 'Hint usage notification';

  @override
  String get settingsHintNotifSubtitle => 'Notify when you use a hint';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get levelExpert => 'Expert';

  @override
  String get levelMaster => 'Master';

  @override
  String get levelDescBeginner => 'Perfect if you are new to Sudoku';

  @override
  String get levelDescIntermediate => 'For those who know the basic rules';

  @override
  String get levelDescAdvanced => 'For experienced players';

  @override
  String get levelDescExpert => 'For Sudoku masters';

  @override
  String get levelDescMaster => 'The ultimate challenge';

  @override
  String get gameGuideTitle => 'How to play';

  @override
  String get gameGuideTapCellTitle => 'Select a cell first';

  @override
  String get gameGuideTapCellBody =>
      'Tap an empty cell, then use the number buttons below.';

  @override
  String get gameGuideMistakesTitle => 'Up to 3 mistakes';

  @override
  String get gameGuideMistakesBody => 'Three wrong numbers end this puzzle.';

  @override
  String get gameGuideColorsTitle => 'Use color hints';

  @override
  String get gameGuideColorsBody =>
      'Selected cell, same numbers, and related cells are highlighted.';

  @override
  String get gameGuidePlayButton => 'Play now';

  @override
  String gameNumberLabel(int number) {
    return 'Game $number';
  }

  @override
  String get gameHintShort => 'Hint';

  @override
  String get gameUndoShort => 'Undo';

  @override
  String get gameRedoShort => 'Redo';

  @override
  String get gameMemoShort => 'Memo';

  @override
  String get gameMemoOnShort => 'Memo ON';

  @override
  String get gameMemoStateOn => 'ON';

  @override
  String get gameMemoStateOff => 'OFF';

  @override
  String get gameMemoFocusShort => 'Focus';

  @override
  String get gameMemoFocusIdle => 'None';

  @override
  String get gameWrongShort => 'Wrong';

  @override
  String get gamePerfectShort => 'Perfect';

  @override
  String get gamePerfectReady => 'Active';

  @override
  String get gamePerfectMissed => 'Lost';

  @override
  String get gameProgressShort => 'Progress';

  @override
  String get gameTimeShort => 'Time';

  @override
  String get gameNumberInputTitle => 'Number input';

  @override
  String gameRowsCompleted(int count) {
    return '$count row cleared';
  }

  @override
  String gameColsCompleted(int count) {
    return '$count column cleared';
  }

  @override
  String gameBoxesCompleted(int count) {
    return '$count box cleared';
  }

  @override
  String get gamePause => 'Pause';

  @override
  String get gameResume => 'Resume';

  @override
  String get gameAnswerPreview => 'Answer';

  @override
  String get challengeCompletedToday => 'You completed today’s challenge!';

  @override
  String get shareCopySuccess => 'Result copied to clipboard.';

  @override
  String get shareSubject => 'My Sudoku result';

  @override
  String get shareClearHeader => 'My Sudoku clear';

  @override
  String shareClearLine(String level, int number) {
    return '$level · Game $number';
  }

  @override
  String shareClearStats(String time, int wrong) {
    return '$time · $wrong mistakes';
  }

  @override
  String get shareClearTags => '#MySudoku #SudokuChallenge';

  @override
  String shareSummaryPattern(String time, int wrong) {
    return '$time · $wrong mistakes';
  }

  @override
  String get dialogCongratulations => 'Congratulations!';

  @override
  String get dialogNewBest => 'NEW BEST';

  @override
  String get dialogSudokuComplete => 'You completed the puzzle!';

  @override
  String get dialogNewBadges => 'New badges';

  @override
  String get dialogElapsedTime => 'Time';

  @override
  String get dialogWrongCount => 'Mistakes';

  @override
  String dialogWrongCountValue(int count) {
    return '$count times';
  }

  @override
  String get dialogSharePreview => 'Share text';

  @override
  String get dialogCopyResult => 'Copy';

  @override
  String get dialogShare => 'Share';

  @override
  String get dialogBackToLevels => 'Level list';

  @override
  String get dialogPlayAgain => 'Play again';

  @override
  String get dialogNextPuzzle => 'Next puzzle';

  @override
  String get settingsNotificationsComingSoonTitle => 'Notifications';

  @override
  String get settingsNotificationsComingSoonBody =>
      'Push reminders and notification options will be available in a future update. Thanks for your patience!';

  @override
  String get settingsAboutDialogTitle => 'About this app';

  @override
  String settingsAboutVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get settingsAboutDeveloperNote => 'Enjoy playing My Sudoku!';

  @override
  String get settingsPrivacyDialogTitle => 'Privacy';

  @override
  String get settingsPrivacyDialogBody =>
      'This app stores your game progress and records only on this device. We do not collect personal data or require an account. If you uninstall the app, local data may be removed unless your device backs up app data.';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get gameOverTitle => 'Game over';

  @override
  String get gameOverMessage => 'You made more than 3 mistakes.';

  @override
  String gameOverWrongLabel(int count) {
    return 'Mistakes: $count/3';
  }

  @override
  String get recordsFilterSectionTitle => 'Filters';

  @override
  String get recordsFilterAllLevels => 'All levels';

  @override
  String get recordsPeriodLabel => 'Period';

  @override
  String get recordsPeriodAll => 'All time';

  @override
  String recordsPeriodLastDays(int days) {
    return 'Last $days days';
  }

  @override
  String get recordsSummaryTitle => 'Summary';

  @override
  String get recordsTrendTitle => 'Last 7 days';

  @override
  String get recordsTrendEmpty =>
      'Not enough recent clears to show a 7-day trend.';

  @override
  String get recordsTrendClears => 'Recent clears';

  @override
  String get recordsTrendActiveDays => 'Active days';

  @override
  String get recordsHeroBadgeFlow => 'Flow';

  @override
  String get recordsHeroTitle =>
      'Start with the gentle\nshape of your progress.';

  @override
  String get recordsHeroSubtitle =>
      'The curve above is the same week, softened for a quick read. Use the card below for exact clears per day plus the smoothed trend line.';

  @override
  String get recordsInsightThisWeekEyebrow => 'This week';

  @override
  String recordsInsightClearsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clears',
      one: '$count clear',
    );
    return '$_temp0';
  }

  @override
  String get recordsInsightAvgPaceEyebrow => 'Average pace';

  @override
  String get recordsTrendSectionSubtitle =>
      'Daily clears with a smoothed trend (up to ±2 days on each side).';

  @override
  String get recordsTrendLegendDailyClears => 'Daily clears';

  @override
  String get recordsTrendLegendMovingAverage => 'Moving average';

  @override
  String get recordsTrendMovingAvgFootnote =>
      'Each point averages up to five days (two before and after that day).';

  @override
  String get recordsTrendTodayLabel => 'Today';

  @override
  String get recordsMetricClears => 'Clears (filtered)';

  @override
  String get recordsMetricClearRate => 'Catalog share';

  @override
  String get recordsMetricPerfectRate => 'Perfect rate';

  @override
  String get recordsSummaryMetricsFootnote =>
      'Clear counts follow your period and level filters. Catalog share divides those clears by the puzzle count stored in the catalog for the same scope.';

  @override
  String get recordsMetricAvgTime => 'Avg. time';

  @override
  String get recordsMetricAvgWrong => 'Avg. mistakes';

  @override
  String get recordsByLevelTitle => 'By level';

  @override
  String get recordsByLevelEmpty => 'No stats for this filter.';

  @override
  String get recordsBestByLevelTitle => 'Best by level';

  @override
  String get recordsBestByLevelEmpty =>
      'No best-by-level records for this filter.';

  @override
  String recordsBestByLevelDetail(String time, int wrongCount) {
    return '$time · Mistakes: $wrongCount';
  }

  @override
  String get recordsPerfectBadge => 'Perfect';

  @override
  String recordsAvgTimeDetail(String time) {
    return 'Avg. time $time';
  }

  @override
  String get recordsRecentTitle => 'Recent clears';

  @override
  String get recordsRecentEmpty => 'No clears match this filter.';

  @override
  String get recordsBestTitle => 'Best times (Top 5)';

  @override
  String get recordsBestEmpty => 'No best times for this filter.';

  @override
  String recordsGameNumberTitle(String level, int number) {
    return '$level · Game $number';
  }

  @override
  String recordsRecentDetail(String time, int wrongCount, String date) {
    return '$time · Mistakes: $wrongCount · $date';
  }

  @override
  String recordsBestDetail(String time, int wrongCount) {
    return '$time · Mistakes: $wrongCount';
  }

  @override
  String get recordsGameLoadError => 'Could not load puzzle data.';

  @override
  String get recordsChallengeTabHint =>
      'Weekly goals and streaks are on the Challenge tab.';

  @override
  String get recordsGoToChallengeTab => 'Open Challenge tab';

  @override
  String get challengeLoadError => 'Couldn\'t load challenge data.';

  @override
  String get challengeTodaysChallengeTitle => 'Today\'s challenge';

  @override
  String get challengeTodayDoneHint =>
      'You\'ve already finished today. Open it again anytime to review.';

  @override
  String get challengeTodayPendingHint =>
      'Keep your streak with today\'s featured puzzle.';

  @override
  String get challengeTodayReviewButton => 'Continue at your pace';

  @override
  String get challengeTodayStartButton => 'Start at your pace';

  @override
  String get myPaceNoPlayableTitle => 'No playable game';

  @override
  String get myPaceNoPlayableMessage =>
      'There are no new puzzles left to play across all levels.';

  @override
  String get challengeWeeklyGoalReachedTitle => 'Weekly goal reached';

  @override
  String challengeWeeklyGoalRemainingTitle(int count) {
    return '$count more clears to hit your weekly goal';
  }

  @override
  String get challengeWeeklyGoalReachedBody =>
      'Add more perfect clears to build an even stronger rhythm.';

  @override
  String get challengeWeeklyGoalCatchUpBody =>
      'A few quick sessions can finish this week\'s target.';

  @override
  String challengePerfectThisWeek(int count) {
    return '$count perfect clears this week';
  }

  @override
  String get challengePerfectThisWeekFirst =>
      'Try your first perfect clear this week';

  @override
  String get challengePerfectPositiveBody =>
      'Flawless runs make your progress easier to see.';

  @override
  String get challengePerfectZeroBody =>
      'Memo mode gets you much closer to mistake-free clears.';

  @override
  String get challengeWeeklyGoalHeading => 'Weekly goal';

  @override
  String challengeWeeklyClearsLine(int count) {
    return '$count clears this week';
  }

  @override
  String challengeWeeklyProgressShort(int done, int target) {
    return '$done / $target done';
  }

  @override
  String challengeWeeklyPerfectShort(int count) {
    return '$count perfect';
  }

  @override
  String get challengeWeeklyCongratsFooter =>
      'Weekly goal complete—keep stacking great records!';

  @override
  String challengeWeeklyAlmostFooter(int count) {
    return '$count more clears to finish the week.';
  }

  @override
  String get challengeAchievementsHeading => 'Achievements · badges';

  @override
  String challengeBadgesCollected(int unlocked, int total) {
    return '$unlocked / $total earned';
  }

  @override
  String get challengeViewAllBadges => 'View all';

  @override
  String get challengeEarnedBadgesHeading => 'Earned badges';

  @override
  String get challengeNextBadgeTargets => 'Next targets';

  @override
  String challengeBadgeProgressLine(String desc, String progress) {
    return '$desc · Progress: $progress';
  }

  @override
  String challengeStreakDays(int days) {
    return '$days-day streak';
  }

  @override
  String get challengeStreakStartToday => 'Chase your first clear today';

  @override
  String get challengeTabHeroHeadline =>
      'Today\'s puzzle and weekly rhythm,\nin one calm view.';

  @override
  String get challengeHeroPendingDetail =>
      'Start playing from Home, or use the button below.';

  @override
  String get challengeHeroDoneDetail =>
      'Today\'s challenge is complete. Badges and weekly progress stay on this tab.';

  @override
  String get challengeOpenTodayOnHomeButton => 'Open today\'s puzzle on Home';

  @override
  String get challengeHeroDoneCaption =>
      'You finished today\'s challenge. Come back tomorrow to extend your streak.';

  @override
  String get challengeHeroPendingCaption =>
      'Today\'s puzzle is still open—start now to keep your streak alive.';

  @override
  String get homeOnboardingWelcomeTitle => 'Welcome!';

  @override
  String get homeOnboardingStepQuickTitle => 'Quick start';

  @override
  String get homeOnboardingStepQuickBody =>
      'Jump into a recommended difficulty right away.';

  @override
  String get homeOnboardingStepDailyTitle => 'Daily challenge';

  @override
  String get homeOnboardingStepDailyBody =>
      'Try the daily puzzle to check your skills in one short game.';

  @override
  String get homeOnboardingStepResumeTitle => 'Resume';

  @override
  String get homeOnboardingStepResumeBody =>
      'Continue saved games from the card at the top of Home.';

  @override
  String get homeOnboardingStartButton => 'Get started';

  @override
  String get homeGuestTitle => 'Guest';

  @override
  String get homeGuestSubtitle => 'Start a game in one tap';

  @override
  String get homeContinueTitle => 'Resume';

  @override
  String homeContinueSubtitle(String level, int gameNumber, int cells) {
    return '$level · Game $gameNumber · $cells cells filled';
  }

  @override
  String get homeContinueDescription =>
      'Pick up your paused puzzle where you left off.';

  @override
  String get homeContinueSameAsSpotlightSupporting => 'Resume today\'s puzzle';

  @override
  String get homeContinueActionButton => 'Continue';

  @override
  String homeProgressPercent(int percent) {
    return 'Progress $percent%';
  }

  @override
  String get homeTodayChallengeCardDoneBody =>
      'You finished today\'s challenge. Keep your streak going!';

  @override
  String get homeTodayChallengeCardPendingBody =>
      'One puzzle a day—light practice, steady progress.';

  @override
  String homeTodayChallengeFooterDoneStreak(int days) {
    return 'Today\'s challenge done · $days-day streak';
  }

  @override
  String get homeTodayChallengeFooterPending =>
      'Use today\'s puzzle to build a streak.';

  @override
  String get homeQuickStartSectionTitle => 'Quick start';

  @override
  String get homeBrowseLevelsTitle => 'Browse levels';

  @override
  String get homeStreakTodayDoneLine => 'Today\'s challenge is done too.';

  @override
  String get homeStreakTodayPendingLine =>
      'Finish today\'s challenge to extend your streak.';

  @override
  String get homeBadgeProgressTitle => 'Badge progress';

  @override
  String get homeCatalogPreparingTitle => 'Preparing puzzle catalog';

  @override
  String homeCatalogProgressDetail(int generated, int target, int remaining) {
    return '$generated/$target puzzles ready · $remaining to go';
  }

  @override
  String get levelPickDifficultyTitle => 'Choose difficulty';

  @override
  String get levelPickDifficultySubtitle =>
      'Pick a difficulty to start playing.';

  @override
  String get levelPickGameSubtitle => 'Choose a puzzle to begin.';

  @override
  String levelGamesScreenTitle(String levelName) {
    return '$levelName games';
  }

  @override
  String get levelLoadingGames => 'Loading puzzles…';

  @override
  String get levelTapToStart => 'Tap to start';

  @override
  String get levelClearedBadge => 'Cleared';

  @override
  String levelCatalogPreparingShort(int done, int total) {
    return 'Preparing more puzzles · $done/$total';
  }

  @override
  String get achievementCollectionAppBarTitle => 'Badges';

  @override
  String get achievementLoadError => 'Couldn\'t load badges.';

  @override
  String get achievementViewSettings => 'Display';

  @override
  String get achievementSortLabel => 'Sort';

  @override
  String get achievementFilterAll => 'All';

  @override
  String get achievementFilterUnlocked => 'Unlocked';

  @override
  String get achievementFilterLocked => 'In progress';

  @override
  String get achievementSectionAll => 'All badges';

  @override
  String get achievementSectionUnlocked => 'Unlocked badges';

  @override
  String get achievementSectionLocked => 'Badges in progress';

  @override
  String get achievementEmptyAll => 'No badges to show.';

  @override
  String get achievementEmptyUnlocked => 'No badges unlocked yet.';

  @override
  String get achievementEmptyLocked => 'You\'ve unlocked every badge.';

  @override
  String get achievementHeroTitle => 'Achievements';

  @override
  String achievementHeroProgress(int unlocked, int total) {
    return '$unlocked / $total unlocked';
  }

  @override
  String get achievementHeroAllUnlocked =>
      'You collected every badge. Amazing!';

  @override
  String get achievementHeroKeepGoing => 'Keep playing to unlock more badges.';

  @override
  String get achievementBadgeFirstClearTitle => 'First clear';

  @override
  String get achievementBadgeFirstClearDesc =>
      'Finish your first puzzle to begin your Sudoku journey.';

  @override
  String get achievementBadgeStreakTitle => '3-day streak';

  @override
  String get achievementBadgeStreakDesc =>
      'Clear puzzles three days in a row to build a habit.';

  @override
  String get achievementBadgeWeeklyTitle => 'Weekly runner';

  @override
  String get achievementBadgeWeeklyDesc =>
      'Clear five puzzles in the last seven days.';

  @override
  String get achievementBadgePerfectTitle => 'Perfect clear';

  @override
  String get achievementBadgePerfectDesc =>
      'Finish a puzzle with zero mistakes.';

  @override
  String get achievementBadgeMasterTitle => 'Master first win';

  @override
  String get achievementBadgeMasterDesc =>
      'Clear a Master puzzle for the first time.';

  @override
  String achievementProgressFraction(int current, int max) {
    return '$current/$max';
  }

  @override
  String achievementProgressStreak(int current, int max) {
    return '$current/$max days';
  }

  @override
  String achievementProgressWeekly(int current, int max) {
    return '$current/$max clears';
  }

  @override
  String get achievementStatusDone => 'Done';

  @override
  String get achievementStatusNotMet => 'Not yet';

  @override
  String get achievementStatusTrying => 'In progress';

  @override
  String achievementTileProgress(String label) {
    return 'Progress: $label';
  }

  @override
  String achievementTileRarity(String label) {
    return 'Rarity: $label';
  }

  @override
  String get achievementRarityCommon => 'Common';

  @override
  String get achievementRarityRare => 'Rare';

  @override
  String get achievementRarityEpic => 'Epic';

  @override
  String get achievementSortDefault => 'Default order';

  @override
  String get achievementSortRarity => 'By rarity';
}
