// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sudoku159';

  @override
  String get navHome => 'Home';

  @override
  String get navChallenge => 'Challenge';

  @override
  String get navRecords => 'Records';

  @override
  String get navSettings => 'Settings';

  @override
  String get recordsHeroImageSubtitle => 'My growing record of solving';

  @override
  String get settingsHeroSubtitle => 'Make it yours';

  @override
  String get recordsScreenTitle => 'Records & stats';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionGame => 'Game';

  @override
  String get settingsSectionInfo => 'About';

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
  String get settingsLanguageJapanese => 'Japanese';

  @override
  String get settingsLanguageChinese => '中文';

  @override
  String get settingsLanguageSpanish => 'Español';

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
  String gameCellLabel(int row, int col, String content) {
    return 'Row $row, column $col: $content';
  }

  @override
  String get gameCellEmpty => 'empty';

  @override
  String gameCellNotes(String notes) {
    return 'notes $notes';
  }

  @override
  String get gameCellGiven => 'given';

  @override
  String get gameCellHint => 'hint';

  @override
  String get gameCellWrong => 'incorrect';

  @override
  String get gameEraseShort => 'Erase';

  @override
  String get gameMemoStateOff => 'OFF';

  @override
  String get gameMemoStateOn => 'ON';

  @override
  String get gameMemoModeOffSemantics => 'Notes mode off';

  @override
  String get gameMemoModeOnSemantics => 'Notes mode on';

  @override
  String gameHintSemanticsRemaining(int count) {
    return 'Hint, $count left';
  }

  @override
  String get gameHintSemanticsNone => 'No hints left';

  @override
  String get gameEraseSemanticsSelected => 'Erase selected cell';

  @override
  String get gameMoreOptions => 'More options';

  @override
  String get gameMemoOnShort => 'Memo ON';

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
  String get gameAnswerPreview => 'Answer';

  @override
  String get challengeCompletedToday => 'You completed today’s challenge!';

  @override
  String get shareCopySuccess => 'Result copied to clipboard.';

  @override
  String get shareSubject => 'Sudoku159 result';

  @override
  String get shareClearHeader => 'Sudoku159 clear';

  @override
  String shareClearLine(String level, int number) {
    return '$level · Game $number';
  }

  @override
  String shareClearStats(String time, int wrong) {
    return '$time · $wrong mistakes';
  }

  @override
  String get shareClearTags => '#Sudoku159 #SudokuChallenge';

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
  String get dialogBackToLevels => 'Puzzle list';

  @override
  String get dialogPlayAgain => 'Solve again';

  @override
  String get dialogPuzzleCompleteTitle => 'You solved the puzzle';

  @override
  String get dialogNewBestMessage => 'New best record!';

  @override
  String dialogHintsUsed(int count) {
    return 'Hints: $count';
  }

  @override
  String get dialogSolveSameAgain => 'Solve this puzzle again';

  @override
  String get dialogNextPuzzle => 'Next puzzle';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredMessage =>
      'A new version of this app is available.\nPlease update to continue playing.';

  @override
  String get updateNowButton => 'Update now';

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
  String get settingsAboutDeveloperNote => 'Enjoy playing Sudoku159!';

  @override
  String get settingsAboutSupportEmail => '· team929.support@gmail.com';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get gameOverTitle => 'You reached the mistake limit';

  @override
  String get gameOverMessage =>
      'You can start this puzzle over or choose another one.';

  @override
  String gameOverWrongLabel(int count, int maxCount) {
    return 'This game: $count mistakes / limit $maxCount';
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
  String get recordsSummaryTitle => 'Last 7 days';

  @override
  String get recordsTrendTitle => 'Last 7 days';

  @override
  String get recordsTrendEmpty =>
      'Not enough recent clears to show a 7-day trend.';

  @override
  String get recordsTrendClears => 'Clears';

  @override
  String get recordsTrendWindowAvgTime => 'Avg. time (same window)';

  @override
  String get recordsTrendWindowAvgWrong => 'Avg. mistakes (same window)';

  @override
  String get recordsHeroBadgeFlow => 'Flow';

  @override
  String get recordsHeroTitle =>
      'Start with the gentle shape of your progress.';

  @override
  String get recordsHeroSubtitle =>
      'The curve above is the same week, softened for a quick read. Use the card below for exact clears per day.';

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
      'Day-by-day clears for the last seven days.';

  @override
  String get recordsTrendLegendDailyClears => 'Daily clears';

  @override
  String get recordsTrendTodayLabel => 'Today';

  @override
  String get recordsPlayInsightsTitle => 'This week\'s activity';

  @override
  String get gameResultWeeklyGoalAchieved => 'You reached this week\'s goal';

  @override
  String get recordsPlayCalendarTitle => 'By day';

  @override
  String get recordsWeeklyReportTitle => 'Weekly report';

  @override
  String get recordsWeeklyReportBusiestDay => 'Most active day';

  @override
  String recordsWeeklyReportTopDayValue(String day, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clears',
      one: '$count clear',
    );
    return '$day, $_temp0';
  }

  @override
  String get recordsWeeklyReportTopDayFallback => 'No clears yet';

  @override
  String get recordsTimelineTitle => 'Recent timeline';

  @override
  String get recordsTimelineEmpty =>
      'Recent clears will show up here as you play.';

  @override
  String recordsTimelineMistakesValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mistakes',
      one: '$count mistake',
    );
    return '$_temp0';
  }

  @override
  String get recordsTimelinePerfect => 'Perfect clear';

  @override
  String get recordsPaceTitle => 'Pace change';

  @override
  String get recordsPaceEmpty =>
      'We need another week of records before we can compare your pace.';

  @override
  String get recordsPaceRecentWindow => 'Recent 7 days';

  @override
  String get recordsPacePreviousWindow => 'Previous 7 days';

  @override
  String get recordsPaceDelta => 'Change';

  @override
  String get recordsMetricClears => 'Clears (filtered)';

  @override
  String get recordsMetricPerfectRate => 'Mistake-free share';

  @override
  String get recordsSummaryMetricsFootnote =>
      'Each puzzle counts once, using its best record, and follows your active filters. Completion compares those puzzles with the total number of puzzles in the same scope.';

  @override
  String get recordsByLevelTitle => 'Records by level';

  @override
  String get recordsByLevelSubtitle => 'Select a difficulty to compare records';

  @override
  String get recordsByLevelEmpty => 'No stats for this filter.';

  @override
  String get recordsByLevelSectionSubtitle =>
      'See which levels are starting to feel more comfortable.';

  @override
  String get recordsLevelInfographicClearRate => 'Puzzle completion';

  @override
  String get recordsLevelMiniBest => 'Best';

  @override
  String get recordsLevelMiniPerfectRate => 'Perfect';

  @override
  String get recordsLevelMiniAvgWrong => 'Avg wrong';

  @override
  String get recordsStatsLoadError =>
      'Unable to load statistics right now. Please try again shortly.';

  @override
  String get recordsRetry => 'Try again';

  @override
  String get recordsEmptyAction => 'Start a puzzle';

  @override
  String get recordsLevelEmpty => 'No completed puzzles at this level yet.';

  @override
  String recordsCalendarTitle(int weeks) {
    return 'Last $weeks weeks of activity';
  }

  @override
  String get recordsCalendarSubtitle =>
      'See which days you cleared puzzles and how often you played';

  @override
  String recordsOverallNote(int cleared, int total) {
    return '$cleared of $total puzzles completed across all levels.';
  }

  @override
  String recordsWeekDayDone(String day, int count) {
    return '$day: $count completed';
  }

  @override
  String recordsWeekDayNone(String day) {
    return '$day: no completions';
  }

  @override
  String get recordsStatsPageSubtitle => 'Clears and average time at a glance.';

  @override
  String get recordsKpiWeeklyClearsLabel => 'Puzzles cleared';

  @override
  String get recordsKpiAvgSolveTimeLabel => 'Avg. best time';

  @override
  String get recordsActivityOverviewTitle => 'Activity overview';

  @override
  String get recordsActivityHeatmapTitle => 'Recent activity';

  @override
  String get recordsActivityHeatmapCaption =>
      'Activity for every puzzle you\'ve completed.';

  @override
  String get recordsActivityTotalClearsLabel => 'Total completions';

  @override
  String get recordsActivityCurrentStreakLabel => 'Current streak';

  @override
  String get recordsActivityBestStreakLabel => 'Longest streak';

  @override
  String recordsActivityDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String recordsActivityClearCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clears',
      one: '$count clear',
    );
    return '$_temp0';
  }

  @override
  String get recordsSectionBestRecordTitle => 'Best run';

  @override
  String get recordsSectionDifficultyTitle => 'By difficulty';

  @override
  String get recordsSectionDetailStatsTitle => 'Session details';

  @override
  String get recordsBestSingleEmpty => 'No standout run yet.';

  @override
  String get recordsHintUsageLabel => 'Hints';

  @override
  String get recordsHintUsageNoData => 'No data';

  @override
  String get recordsDetailMistakesShort => 'Avg. mistakes';

  @override
  String get recordsDetailStreakShort => 'Active streak';

  @override
  String recordsDetailStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get recordsDifficultySnapshotEmpty =>
      'Play a few games to see your difficulty mix here.';

  @override
  String get recordsLevelDoneShort => 'Done';

  @override
  String get recordsStatsHeroEyebrow => 'Sudoku in the last 7 days';

  @override
  String get recordsStatsHeroHeadline =>
      'See your last 7 days of Sudoku at a glance.';

  @override
  String recordsTrendA11yMaxClears(int count) {
    return 'Peak $count';
  }

  @override
  String get recordsHeroChartEmptyHint =>
      'Clear a puzzle within the last 7 days to see your flow sketch here.';

  @override
  String get recordsHeroSubtitleNoChart =>
      'Use the card below for daily clears from the last 7 days.';

  @override
  String get recordsCalendarPlayedLabel => 'Cleared';

  @override
  String get recordsCalendarEmptyLabel => 'No clears';

  @override
  String get recordsNoAverageTime => 'No records';

  @override
  String get recordsStatsBasisFootnote =>
      'Statistics are calculated from the best clear record for each puzzle.';

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
  String get recordsRecentTitle => 'Recent completions';

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
  String get challengeTabHeroHeadline =>
      'Today\'s puzzle and weekly rhythm, in one calm view.';

  @override
  String get challengeOpenTodayOnHomeButton => 'Open today\'s puzzle on Home';

  @override
  String get challengeHeroDoneCaption =>
      'You finished today\'s challenge. Come back tomorrow to extend your streak.';

  @override
  String get challengeHeroPendingCaption =>
      'Today\'s puzzle is still open—start now to keep your streak alive.';

  @override
  String get homeGuestTitle => 'Traveler';

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
  String get levelTapToStart => 'Start now';

  @override
  String get levelClearedBadge => 'Cleared';

  @override
  String get levelOverviewTitle => 'Level overview';

  @override
  String get levelPuzzlesSectionTitle => 'Puzzle list';

  @override
  String get levelProgressLabel => 'Progress';

  @override
  String get levelNoRecordYet => 'No records yet';

  @override
  String get levelStatusReady => 'Fresh puzzle';

  @override
  String get levelStatusCleared => 'Completed puzzle';

  @override
  String levelEmptyCellsLabel(int count) {
    return '$count empty cells';
  }

  @override
  String levelPuzzleCountSummary(int count) {
    return '$count puzzles';
  }

  @override
  String levelCatalogPreparingShort(int done, int total) {
    return 'Preparing more puzzles · $done/$total';
  }

  @override
  String get commonSave => 'Save';

  @override
  String get settingsDisplaySection => 'Display';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get profileEditorTitle => 'Edit profile';

  @override
  String get profileEditorRemovePhoto => 'Remove photo';

  @override
  String get profileEditorNameLabel => 'Name';

  @override
  String get profileEditorDefaultProfile => 'Default profile';

  @override
  String get profileEditorDefaultProfileDesc =>
      'Start with the app\'s default image';

  @override
  String get profileEditorPickFromAlbum => 'Choose from album';

  @override
  String get profileEditorPickFromAlbumDesc => 'Set your own photo as profile';

  @override
  String get homeTodayLabel => 'TODAY';

  @override
  String get homeTodayPuzzleTitle => 'A quiet moment to focus.';

  @override
  String get homeChallengeStartButton => 'Start challenge';

  @override
  String get homeChallengeReplayButton => 'Play again';

  @override
  String get homeChallengeNotStarted => 'Not started yet';

  @override
  String get homeChallengeFirstLine =>
      'Your first challenge starts at Beginner';

  @override
  String homeChallengePromotedLine(String level) {
    return 'Try $level today?';
  }

  @override
  String homeChallengeProgress(int percent) {
    return '$percent% done';
  }

  @override
  String get homeChallengeDoneLine => 'Today\'s challenge complete!';

  @override
  String homeChallengeStreak(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day challenge streak',
      one: '1-day challenge streak',
    );
    return '$_temp0';
  }

  @override
  String get homeChallengeLoadErrorTitle => 'Couldn\'t load today\'s challenge';

  @override
  String get homeChallengeLoadErrorBody => 'Please try again in a moment.';

  @override
  String get homeTodayChallengeDateChanged =>
      'A new day started. Today\'s challenge was refreshed.';

  @override
  String get homeFirstStartTitle => 'Start your first puzzle';

  @override
  String get homeNewPuzzleTitle => 'Start a new puzzle';

  @override
  String get homeChooseLevelBody =>
      'Choose a level. Your progress is saved automatically.';

  @override
  String get homeChooseLevelButton => 'Choose a level';

  @override
  String homeViewAllInProgress(int count) {
    return 'View all in-progress games ($count)';
  }

  @override
  String get homeNewGameSectionTitle => 'New game · choose a level';

  @override
  String homeLevelBlankCells(int count) {
    return '$count blanks';
  }

  @override
  String get homeSavedGamesTitle => 'In-progress games';

  @override
  String get homeSavedGamesDescription =>
      'Pick one to resume. Deleting removes only the saved progress, not your records.';

  @override
  String get homeSavedGameDeleteTooltip => 'Delete saved progress';

  @override
  String get homeSavedGameDeleteTitle => 'Delete saved progress?';

  @override
  String get homeSavedGameDeleteBody =>
      'Your entries and notes for this puzzle will be removed. Completion records are kept.';

  @override
  String get homeSavedGameDeleteConfirm => 'Delete';

  @override
  String get homeLoadError => 'Couldn\'t load your games.';

  @override
  String get homeCatalogFirstTitle => 'Preparing your first puzzle set';

  @override
  String get homeCatalogFirstBody =>
      'On your first launch, Sudoku puzzles are saved on your device. After this, the app opens much faster.';

  @override
  String get homeCatalogFirstNote =>
      'Preparation continues in the background, so you can keep exploring right away.';

  @override
  String get homeCatalogFirstContinue => 'Continue to home';

  @override
  String homeLevelProgressSolved(int cleared, int total) {
    return '$cleared / $total';
  }

  @override
  String get levelFilterAll => 'All';

  @override
  String get levelFilterNew => 'New';

  @override
  String get levelFilterInProgress => 'In progress';

  @override
  String get levelFilterDone => 'Done';

  @override
  String levelPuzzleListTitle(int count) {
    return 'Puzzles · $count';
  }

  @override
  String get levelRecentBadge => 'Recent';

  @override
  String get levelStatusInProgress => 'In progress';

  @override
  String get levelNoResults => 'No results.';

  @override
  String levelReplayTitle(int number) {
    return 'Replay puzzle $number?';
  }

  @override
  String get levelReplayBody =>
      'Your completed record stays as it is. If you finish with a better result, only your best record is updated.';

  @override
  String get levelReplayConfirm => 'Replay';

  @override
  String levelInProgressLimitTitle(int maxCount) {
    return '$maxCount puzzles in progress';
  }

  @override
  String levelInProgressLimitBody(int maxCount) {
    return 'You can keep up to $maxCount puzzles going at once.\nPick one below to continue.';
  }

  @override
  String get levelInProgressLimitLater => 'Later';

  @override
  String get levelTryAgain => 'Try again';

  @override
  String get levelContinueButton => 'Continue';

  @override
  String levelStartNextNew(String number) {
    return 'Start new puzzle · $number';
  }

  @override
  String get levelStartNewButton => 'Start puzzle';

  @override
  String levelPuzzleNumber(int number) {
    return 'Puzzle $number';
  }

  @override
  String levelCompletedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed',
      one: '1 completed',
    );
    return '$_temp0';
  }

  @override
  String get levelCardFirstSub => 'Shall we start with the first puzzle?';

  @override
  String get levelCardNextSub => 'Start the next puzzle';

  @override
  String levelCardAllDoneTitle(String levelName) {
    return 'You completed every $levelName puzzle';
  }

  @override
  String get levelCardAllDoneSub => 'Try your completed puzzles again';

  @override
  String get levelCardViewCompleted => 'View completed puzzles';

  @override
  String levelViewInProgress(int count) {
    return 'View $count in progress';
  }

  @override
  String get levelNotesInProgress => 'Writing notes';

  @override
  String get levelEmptyInProgress =>
      'You don\'t have a puzzle to continue yet.';

  @override
  String get levelEmptyCompleted => 'Make your first completion record.';

  @override
  String get levelEmptyFresh => 'No new puzzles to start.';

  @override
  String get levelAllCompleted =>
      'You\'ve completed every puzzle at this level.';

  @override
  String get levelActionShowNew => 'Show new puzzles';

  @override
  String get levelActionShowInProgress => 'Show in progress';

  @override
  String get levelActionShowAll => 'Show all';

  @override
  String levelBestTime(String time) {
    return 'Best time $time';
  }

  @override
  String levelCellSemantics(String number, String status) {
    return 'Puzzle $number, $status';
  }

  @override
  String get gameRestartMenuTitle => 'Restart from the beginning';

  @override
  String get gameRestartDialogTitle => 'Start this puzzle over?';

  @override
  String get gameRestartDialogBody =>
      'Your numbers, notes, time, hint usage, and mistakes are all reset. Your existing completion records are kept.';

  @override
  String get gameRestartConfirm => 'Restart';

  @override
  String get gameNumberInputLegend =>
      'Small numbers show what remains, checks mean completed.';

  @override
  String get dialogSuggestedNextStep => 'Suggested next step';

  @override
  String get dialogSetTomorrowReminder => 'Set tomorrow reminder';

  @override
  String get dialogTryAnotherLevel => 'Try another level';

  @override
  String get savedGamesSortRecent => 'Recent';

  @override
  String get savedGamesSortProgress => 'Progress';

  @override
  String get savedGamesSortPlayTime => 'Play time';

  @override
  String get savedGamesEmpty => 'No saved games match this filter.';

  @override
  String get savedGamesDeleteFailed =>
      'Couldn\'t delete this puzzle. Please try again.';

  @override
  String get recordsMyRecordTitle => 'So far';

  @override
  String recordsSummaryHeroSentence(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You\'ve completed $count puzzles',
      one: 'You\'ve completed 1 puzzle',
    );
    return '$_temp0';
  }

  @override
  String get recordsSummaryHeroFirst => 'You completed your first puzzle';

  @override
  String recordsSummaryHeroMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You\'ve reached $count puzzles — steady progress!',
      one: 'You\'ve reached 1 puzzle — steady progress!',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryHeroGrowing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You\'ve already solved $count puzzles',
      one: 'You\'ve already solved 1 puzzle',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryHeroStacked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puzzles solved, and your record keeps growing',
      one: '1 puzzle solved, and your record keeps growing',
    );
    return '$_temp0';
  }

  @override
  String recordsLevelRingSemantics(String level, int cleared, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      cleared,
      locale: localeName,
      other: '$cleared of $total completed',
      one: '1 of $total completed',
    );
    return '$level, $_temp0';
  }

  @override
  String get recordsSummaryAllPerfect => 'You solved them all without mistakes';

  @override
  String recordsSummaryPartialPerfect(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You solved $count of them without mistakes',
      one: 'You solved 1 of them without mistakes',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryStreakPlaying(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'You\'ve been playing $days days in a row',
      one: 'You played 1 day in a row',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryPlayDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'You\'ve played on $days days',
      one: 'You\'ve played on 1 day',
    );
    return '$_temp0';
  }

  @override
  String get recordsSummaryEmptyTitle => 'Ready to make your first record?';

  @override
  String get recordsSummaryEmptyBody =>
      'Finish a puzzle and your records will build up here';

  @override
  String get challengeTodayEyebrow => 'Today';

  @override
  String homeStreakChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String homeStreakActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Solved a puzzle $count days in a row',
      one: 'Solved a puzzle today',
    );
    return '$_temp0';
  }

  @override
  String homeStreakAtRisk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak. Finish a puzzle today to keep it going.',
      one: '1-day streak. Finish a puzzle today to keep it going.',
    );
    return '$_temp0';
  }

  @override
  String get hintStepLookTitle => 'Hint · Where to look';

  @override
  String get hintLookCell =>
      'Look at the row, column, and box of the highlighted cell.';

  @override
  String hintLookBox(int value) {
    return 'Find where $value goes in the highlighted box.';
  }

  @override
  String hintLookRow(int value) {
    return 'Find where $value goes in the highlighted row.';
  }

  @override
  String hintLookCol(int value) {
    return 'Find where $value goes in the highlighted column.';
  }

  @override
  String get hintMovedFromSelection =>
      'There\'s an easier cell to solve first.';

  @override
  String get hintTechniqueNakedSingle => 'Naked single';

  @override
  String get hintTechniqueHiddenSingle => 'Hidden single';

  @override
  String get hintTechniqueReveal => 'Answer';

  @override
  String hintExplainNakedSingle(int value) {
    return 'The row, column, and box of this cell already hold the other eight numbers, so only $value fits.';
  }

  @override
  String hintExplainHiddenSingleBox(int value) {
    return 'In this box, $value can only go here. Every other empty cell shares a row or column with a highlighted $value.';
  }

  @override
  String hintExplainHiddenSingleRow(int value) {
    return 'In this row, $value can only go here. Every other empty cell shares a column or box with a highlighted $value.';
  }

  @override
  String hintExplainHiddenSingleCol(int value) {
    return 'In this column, $value can only go here. Every other empty cell shares a row or box with a highlighted $value.';
  }

  @override
  String get hintExplainReveal =>
      'This cell needs a more advanced technique. You can fill in the answer below.';

  @override
  String get hintNextStep => 'Tell me more';

  @override
  String get hintFillAnswer => 'Fill in answer';

  @override
  String get hintClose => 'Close hint';

  @override
  String get notificationOptInTitle => 'Want a daily puzzle reminder?';

  @override
  String get notificationOptInBody =>
      'If you haven\'t solved a puzzle by 8 PM, we\'ll remind you. You can turn this off anytime in Settings.';

  @override
  String get notificationOptInAccept => 'Turn on reminders';

  @override
  String get notificationOptInLater => 'Not now';

  @override
  String get notificationOptInDenied =>
      'Notifications aren\'t allowed. Allow them in your device settings, then turn reminders on in Settings.';

  @override
  String get notificationSetupFailed =>
      'We couldn\'t set up reminders. Please try again later in Settings.';

  @override
  String get beginnerTutorialPromptTitle => 'New to Sudoku?';

  @override
  String get beginnerTutorialPromptBody =>
      'Try a short practice to learn the basic rules and controls.';

  @override
  String get beginnerTutorialStart => 'Start practice';

  @override
  String get beginnerTutorialSkip => 'Skip';

  @override
  String beginnerTutorialStepIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String get beginnerTutorialPracticeTitle => 'Practice puzzle';

  @override
  String get beginnerTutorialStepRulesTitle => 'Basic rules';

  @override
  String get beginnerTutorialStepRulesBody =>
      'Each row, column, and 3×3 box holds the numbers 1 to 9 exactly once.';

  @override
  String get beginnerTutorialRuleRow => 'Row';

  @override
  String get beginnerTutorialRuleColumn => 'Column';

  @override
  String get beginnerTutorialRuleBox => '3×3 box';

  @override
  String get beginnerTutorialStepInputTitle => 'Enter a number';

  @override
  String get beginnerTutorialStepInputBody =>
      'Tap the highlighted cell, then choose the number that fits.';

  @override
  String get beginnerTutorialStepInputWrongHint =>
      'A number already in the same row, column, or 3×3 box can\'t go here.';

  @override
  String get beginnerTutorialStepMemoTitle => 'Note candidates';

  @override
  String get beginnerTutorialStepMemoAddBody =>
      'Turn on Notes, then jot candidate numbers in the highlighted cell.';

  @override
  String get beginnerTutorialStepMemoEraseBody =>
      'Tap the same number again to erase a note.';

  @override
  String get beginnerTutorialStepHintTitle => 'Use a hint';

  @override
  String get beginnerTutorialStepHintBody =>
      'When you\'re stuck, tap Hint to see which cell to look at and why.';

  @override
  String get beginnerTutorialStepDoneTitle => 'You\'re ready!';

  @override
  String get beginnerTutorialStepDoneBody =>
      'You\'ve learned entering numbers, notes, and hints.';

  @override
  String get beginnerTutorialFirstPuzzleButton => 'Start my first puzzle';

  @override
  String get beginnerTutorialNextButton => 'Next';

  @override
  String get beginnerTutorialCloseButton => 'Done';

  @override
  String get settingsHowToPlayTitle => 'How to play';

  @override
  String get settingsHowToPlaySubtitle => 'Replay the guided tutorial';

  @override
  String get autoNotesConfirmTitle => 'Refill all notes?';

  @override
  String get autoNotesConfirmBody =>
      'This replaces every blank cell\'s notes with the current candidates. Candidates you removed by hand may reappear.';

  @override
  String get autoNotesConfirmApply => 'Refill notes';

  @override
  String get autoNotesContradictionMessage =>
      'Some cells have no possible number left, so notes were not filled in. Check your entries and try again.';

  @override
  String get autoNotesTipMessage =>
      'Tip: long-press Notes to fill in all candidate numbers at once.';

  @override
  String get gameNumberLockTipMessage =>
      'Long-press a number to lock it and fill it into several cells quickly.';

  @override
  String gameNumberButtonLockedSemantics(int number) {
    return '$number, locked, long press to unlock';
  }

  @override
  String get gameNumberButtonLockHint => 'Long press to lock';

  @override
  String get gameMemoLongPressHint =>
      'Tap to toggle Notes. Long-press to auto-fill candidate notes.';

  @override
  String get homeGreetingMorning => 'Start with a light puzzle.';

  @override
  String get homeGreetingAfternoon => 'A focused puzzle fits now.';

  @override
  String get homeGreetingEvening => 'Wind down with a calm puzzle.';

  @override
  String get levelNoPuzzlesAvailable =>
      'No puzzles are available for this level.';

  @override
  String get levelLastPlayedToday => 'Today';

  @override
  String get levelLastPlayedYesterday => 'Yesterday';

  @override
  String levelLastPlayedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get recordsRecentSubtitle => 'Tap a puzzle to play it again';

  @override
  String recordsRecentViewAll(int count) {
    return 'View all ($count)';
  }

  @override
  String get recordsRecentYesterday => 'Yesterday';

  @override
  String get recordsMetricHintFree => 'Solved without hints';

  @override
  String get recordsMetricMistakeFree => 'Solved without mistakes';

  @override
  String get recordsMetricTypicalTime => 'Typical time per puzzle';

  @override
  String recordsTypicalTimeValue(int minutes) {
    return 'About $minutes min';
  }
}
