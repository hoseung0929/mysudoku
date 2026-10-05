// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Sudoku159';

  @override
  String get navHome => '首页';

  @override
  String get navChallenge => '挑战';

  @override
  String get navRecords => '记录';

  @override
  String get navSettings => '设置';

  @override
  String get recordsHeroImageSubtitle => '逐步积累的解题记录';

  @override
  String get settingsHeroSubtitle => '按喜好来设置';

  @override
  String get recordsScreenTitle => '记录与统计';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsSectionLanguage => '语言';

  @override
  String get settingsSectionGame => '游戏';

  @override
  String get settingsSectionInfo => '关于';

  @override
  String get settingsNotificationsTitle => '通知设置';

  @override
  String get settingsNotificationsSubtitle => '今天的挑战还未完成时发送提醒';

  @override
  String get settingsStreakReminderTitle => '连续记录提醒';

  @override
  String get settingsStreakReminderSubtitle => '已有连续记录时再多发一次提醒';

  @override
  String get settingsNotificationTimeTitle => '通知时间';

  @override
  String get settingsNotificationTimeSubtitle => '选择接收提醒的时间';

  @override
  String get settingsNotificationsPermissionDenied => '需要通知权限才能开启提醒。';

  @override
  String get settingsLanguageTitle => '语言设置';

  @override
  String get settingsLanguageSubtitle => '更改应用语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageKorean => '한국어';

  @override
  String get settingsLanguageJapanese => '日本語';

  @override
  String get settingsLanguageChinese => '中文';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguagePickerTitle => '选择语言';

  @override
  String get settingsVibrationTitle => '输入震动';

  @override
  String get settingsVibrationSubtitle => '输入数字时使用震动反馈';

  @override
  String get settingsKeepScreenAwakeTitle => '保持屏幕常亮';

  @override
  String get settingsKeepScreenAwakeSubtitle => '防止游戏画面自动熄屏';

  @override
  String get settingsOneHandModeTitle => '单手模式';

  @override
  String get settingsOneHandModeSubtitle => '在手机游戏画面使用更紧凑的按钮布局';

  @override
  String get settingsMemoHighlightTitle => '备注高亮';

  @override
  String get settingsMemoHighlightSubtitle => '显示备注焦点、候选数字和唯一候选高亮';

  @override
  String get settingsSmartHintTitle => '可填格高亮';

  @override
  String get settingsSmartHintSubtitle => '轻微高亮按规则可以立即填入的格子';

  @override
  String get settingsAppInfoTitle => '应用信息';

  @override
  String get settingsAppInfoSubtitle => '版本与开发者信息';

  @override
  String get settingsPrivacyTitle => '隐私政策';

  @override
  String get settingsPrivacySubtitle => '我们如何处理你的数据';

  @override
  String get settingsTabletNotificationsHeader => '通知设置';

  @override
  String get settingsTabletNotificationsBody => '管理并设置游戏通知。';

  @override
  String get settingsGameCompleteNotifTitle => '游戏完成通知';

  @override
  String get settingsGameCompleteNotifSubtitle => '完成一局游戏时通知你';

  @override
  String get settingsDailyGoalNotifTitle => '每日目标通知';

  @override
  String get settingsDailyGoalNotifSubtitle => '达成每周目标的瞬间送上祝贺';

  @override
  String get settingsHintNotifTitle => '使用提示通知';

  @override
  String get settingsHintNotifSubtitle => '使用提示时通知你';

  @override
  String get levelBeginner => '初级';

  @override
  String get levelIntermediate => '中级';

  @override
  String get levelAdvanced => '高级';

  @override
  String get levelExpert => '专家';

  @override
  String get levelMaster => '大师';

  @override
  String get levelDescBeginner => '适合刚接触数独的你';

  @override
  String get levelDescIntermediate => '适合了解基本规则的玩家';

  @override
  String get levelDescAdvanced => '适合有经验的玩家';

  @override
  String get levelDescExpert => '适合数独高手';

  @override
  String get levelDescMaster => '终极挑战';

  @override
  String gameNumberLabel(int number) {
    return '第 $number 局';
  }

  @override
  String get gameHintShort => '提示';

  @override
  String get gameUndoShort => '撤销';

  @override
  String get gameRedoShort => '重做';

  @override
  String get gameMemoShort => '备注';

  @override
  String gameCellLabel(int row, int col, String content) {
    return '第 $row 行第 $col 列：$content';
  }

  @override
  String get gameCellEmpty => '空';

  @override
  String gameCellNotes(String notes) {
    return '笔记 $notes';
  }

  @override
  String get gameCellGiven => '题面数字';

  @override
  String get gameCellHint => '提示';

  @override
  String get gameCellWrong => '错误';

  @override
  String get gameEraseShort => '擦除';

  @override
  String get gameMemoStateOff => '关';

  @override
  String get gameMemoStateOn => '开';

  @override
  String get gameMemoModeOffSemantics => '笔记模式已关闭';

  @override
  String get gameMemoModeOnSemantics => '笔记模式已开启';

  @override
  String gameHintSemanticsRemaining(int count) {
    return '提示，剩余 $count 次';
  }

  @override
  String get gameHintSemanticsNone => '没有提示了';

  @override
  String get gameEraseSemanticsSelected => '擦除所选格子';

  @override
  String get gameMoreOptions => '更多选项';

  @override
  String get gameMemoOnShort => '备注 开';

  @override
  String get gameMemoFocusShort => '聚焦';

  @override
  String get gameMemoFocusIdle => '无';

  @override
  String get gameWrongShort => '错误';

  @override
  String get gamePerfectShort => '完美';

  @override
  String get gamePerfectReady => '保持中';

  @override
  String get gamePerfectMissed => '已中断';

  @override
  String get gameProgressShort => '进度';

  @override
  String get gameTimeShort => '用时';

  @override
  String get gameNumberInputTitle => '数字输入';

  @override
  String get gameAnswerPreview => '答案';

  @override
  String get challengeCompletedToday => '你已完成今天的挑战！';

  @override
  String get shareCopySuccess => '结果已复制到剪贴板。';

  @override
  String get shareSubject => 'Sudoku159 结果';

  @override
  String get shareClearHeader => 'Sudoku159 通关';

  @override
  String shareClearLine(String level, int number) {
    return '$level · 第 $number 局';
  }

  @override
  String shareClearStats(String time, int wrong) {
    return '$time · $wrong 次错误';
  }

  @override
  String get shareClearTags => '#Sudoku159 #SudokuChallenge';

  @override
  String shareSummaryPattern(String time, int wrong) {
    return '$time · $wrong 次错误';
  }

  @override
  String get dialogCongratulations => '恭喜！';

  @override
  String get dialogNewBest => 'NEW BEST';

  @override
  String get dialogSudokuComplete => '你完成了这个数独！';

  @override
  String get dialogNewBadges => '获得新徽章';

  @override
  String get dialogElapsedTime => '用时';

  @override
  String get dialogWrongCount => '失误';

  @override
  String dialogWrongCountValue(int count) {
    return '$count 次';
  }

  @override
  String get dialogSharePreview => '分享文案';

  @override
  String get dialogCopyResult => '复制';

  @override
  String get dialogShare => '分享';

  @override
  String get dialogBackToLevels => '谜题列表';

  @override
  String get dialogPlayAgain => '重新解题';

  @override
  String get dialogPuzzleCompleteTitle => '你完成了谜题';

  @override
  String get dialogNewBestMessage => '刷新了最佳记录';

  @override
  String dialogHintsUsed(int count) {
    return '提示 $count 次';
  }

  @override
  String get dialogSolveSameAgain => '重新解这道谜题';

  @override
  String get dialogNextPuzzle => '下一题';

  @override
  String get updateRequiredTitle => '需要更新';

  @override
  String get updateRequiredMessage => '有新版本可用。\n请更新后继续游戏。';

  @override
  String get updateNowButton => '立即更新';

  @override
  String get settingsNotificationsComingSoonTitle => '通知';

  @override
  String get settingsNotificationsComingSoonBody =>
      '推送提醒和详细通知设置将在后续更新中提供，感谢你的耐心等待！';

  @override
  String get settingsAboutDialogTitle => '关于本应用';

  @override
  String settingsAboutVersionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get settingsAboutDeveloperNote => '祝你玩得开心，Sudoku159！';

  @override
  String get settingsAboutSupportEmail => '· team929.support@gmail.com';

  @override
  String get commonOk => '确定';

  @override
  String get commonCancel => '取消';

  @override
  String get gameOverTitle => '已达到失误上限';

  @override
  String get gameOverMessage => '你可以从头重新解题，或选择其他谜题。';

  @override
  String gameOverWrongLabel(int count, int maxCount) {
    return '本局：失误 $count 次 / 上限 $maxCount 次';
  }

  @override
  String get recordsFilterSectionTitle => '筛选';

  @override
  String get recordsFilterAllLevels => '全部难度';

  @override
  String get recordsPeriodLabel => '时间范围';

  @override
  String get recordsPeriodAll => '全部时间';

  @override
  String recordsPeriodLastDays(int days) {
    return '最近 $days 天';
  }

  @override
  String get recordsSummaryTitle => '最近 7 天';

  @override
  String get recordsTrendTitle => '最近 7 天趋势';

  @override
  String get recordsTrendEmpty => '最近的通关记录还不够，无法显示 7 天趋势。';

  @override
  String get recordsTrendClears => '通关数';

  @override
  String get recordsTrendWindowAvgTime => '平均用时（同一时段）';

  @override
  String get recordsTrendWindowAvgWrong => '平均错误（同一时段）';

  @override
  String get recordsHeroBadgeFlow => '节奏';

  @override
  String get recordsHeroTitle => '先来看看这份 平缓上升的进度曲线。';

  @override
  String get recordsHeroSubtitle => '上方曲线是同样这一周的柔化展示，下方卡片可以查看每天的具体通关数。';

  @override
  String get recordsInsightThisWeekEyebrow => '本周概览';

  @override
  String recordsInsightClearsValue(int count) {
    return '$count 次';
  }

  @override
  String get recordsInsightAvgPaceEyebrow => '平均节奏';

  @override
  String get recordsTrendSectionSubtitle => '最近七天的每日通关数一览。';

  @override
  String get recordsTrendLegendDailyClears => '每日通关';

  @override
  String get recordsTrendTodayLabel => '今天';

  @override
  String get recordsPlayInsightsTitle => '本周活动';

  @override
  String get recordsWeekSubtitle => '点按星期查看记录';

  @override
  String get recordsWeeklyGoalLabel => '本周目标';

  @override
  String recordsWeeklyGoalProgress(int done, int goal) {
    String _temp0 = intl.Intl.pluralLogic(
      goal,
      locale: localeName,
      other: '$done / $goal 道',
    );
    return '$_temp0';
  }

  @override
  String get recordsWeeklyGoalStart => '开始本周的第一道谜题';

  @override
  String recordsWeeklyGoalRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '再完成 $count 道即可达成目标',
    );
    return '$_temp0';
  }

  @override
  String get recordsWeeklyGoalAchieved => '你达成了本周目标';

  @override
  String get gameResultWeeklyGoalAchieved => '你达成了本周目标';

  @override
  String get recordsPlayCalendarTitle => '按天查看';

  @override
  String get recordsWeeklyReportTitle => '本周报告';

  @override
  String get recordsWeeklyReportBusiestDay => '最活跃的一天';

  @override
  String recordsWeeklyReportTopDayValue(String day, int count) {
    return '$day，$count 次';
  }

  @override
  String get recordsWeeklyReportTopDayFallback => '还没有通关记录';

  @override
  String get recordsTimelineTitle => '最近的时间线';

  @override
  String get recordsTimelineEmpty => '开始游玩后，最近的通关记录会显示在这里。';

  @override
  String recordsTimelineMistakesValue(int count) {
    return '$count 次错误';
  }

  @override
  String get recordsTimelinePerfect => '完美通关';

  @override
  String get recordsPaceTitle => '节奏变化';

  @override
  String get recordsPaceEmpty => '还需要再积累一周的记录才能对比你的节奏。';

  @override
  String get recordsPaceRecentWindow => '最近 7 天';

  @override
  String get recordsPacePreviousWindow => '此前 7 天';

  @override
  String get recordsPaceDelta => '变化';

  @override
  String get recordsMetricClears => '通关数（已筛选）';

  @override
  String get recordsMetricClearRate => '已完成谜题';

  @override
  String get recordsMetricPerfectRate => '无失误占比';

  @override
  String get recordsSummaryMetricsFootnote =>
      '每道谜题只按其最佳记录计一次，并遵循当前筛选。完成情况是与同一范围内谜题总数的比较。';

  @override
  String get recordsMetricAvgTime => '平均完成用时';

  @override
  String get recordsMetricAvgWrong => '平均失误';

  @override
  String get recordsByLevelTitle => '按难度的记录';

  @override
  String get recordsByLevelSubtitle => '选择难度来比较记录';

  @override
  String get recordsByLevelEmpty => '该筛选条件下暂无统计数据。';

  @override
  String get recordsByLevelSectionSubtitle => '查看你在哪些难度上越来越得心应手。';

  @override
  String get recordsLevelInfographicClearRate => '谜题完成情况';

  @override
  String get recordsLevelMiniBest => '最佳';

  @override
  String get recordsLevelMiniPerfectRate => '完美率';

  @override
  String get recordsLevelMiniAvgWrong => '平均错误';

  @override
  String get recordsStatsLoadError => '暂时无法加载统计数据，请稍后再试。';

  @override
  String get recordsRetry => '重试';

  @override
  String get recordsEmptyAction => '开始解题';

  @override
  String get recordsLevelEmpty => '该难度还没有完成记录。';

  @override
  String get recordsRowBestTime => '最快记录';

  @override
  String get recordsAverageBasisNote => '平均值以每道谜题的最佳记录为准。';

  @override
  String recordsCalendarTitle(int weeks) {
    return '最近 $weeks 周活动';
  }

  @override
  String get recordsCalendarSubtitle => '查看完成日期和游玩频率';

  @override
  String recordsOverallNote(int cleared, int total) {
    return '所有难度共 $total 道谜题，已完成 $cleared 道。';
  }

  @override
  String recordsWeekActiveDays(int count) {
    return '活动 $count 天';
  }

  @override
  String recordsWeekCompletions(int count) {
    return '完成 $count 局';
  }

  @override
  String recordsWeekDayDone(String day, int count) {
    return '$day：完成 $count 局';
  }

  @override
  String recordsWeekDayNone(String day) {
    return '$day：没有完成';
  }

  @override
  String get recordsStatsPageSubtitle => '一览通关数与平均用时。';

  @override
  String get recordsKpiWeeklyClearsLabel => '完成的谜题';

  @override
  String get recordsKpiAvgSolveTimeLabel => '最佳用时平均';

  @override
  String get recordsActivityOverviewTitle => '活动概览';

  @override
  String get recordsActivityHeatmapTitle => '近期活动';

  @override
  String get recordsActivityHeatmapCaption => '已完成的所有拼图的活动记录。';

  @override
  String get recordsActivityTotalClearsLabel => '累计完成次数';

  @override
  String get recordsActivityCurrentStreakLabel => '当前连续';

  @override
  String get recordsActivityBestStreakLabel => '最长连续';

  @override
  String recordsActivityDayCount(int count) {
    return '$count 天';
  }

  @override
  String recordsActivityClearCount(int count) {
    return '$count 次通关';
  }

  @override
  String get recordsSectionBestRecordTitle => '最佳战绩';

  @override
  String get recordsSectionDifficultyTitle => '按难度统计';

  @override
  String get recordsSectionDetailStatsTitle => '详细记录';

  @override
  String get recordsBestSingleEmpty => '还没有值得展示的最佳战绩。';

  @override
  String get recordsHintUsageLabel => '提示使用记录';

  @override
  String get recordsHintUsageNoData => '暂无数据';

  @override
  String get recordsDetailMistakesShort => '平均错误';

  @override
  String get recordsDetailStreakShort => '连续游玩天数';

  @override
  String recordsDetailStreakDays(int count) {
    return '$count 天';
  }

  @override
  String recordsStatAverageWrongFormatted(String value) {
    return '$value';
  }

  @override
  String get recordsDifficultySnapshotEmpty => '还没有各难度的游玩记录。';

  @override
  String get recordsLevelDoneShort => '完成';

  @override
  String get recordsStatsHeroEyebrow => '最近 7 天的数独记录';

  @override
  String get recordsStatsHeroHeadline => '一眼看清你最近 7 天的 数独记录。';

  @override
  String recordsTrendA11yMaxClears(int count) {
    return '最高 $count 次';
  }

  @override
  String get recordsHeroChartEmptyHint => '在最近 7 天内通关一题，这里就会出现你的节奏曲线。';

  @override
  String get recordsHeroSubtitleNoChart => '下方卡片可查看最近 7 天的每日通关数。';

  @override
  String get recordsCalendarPlayedLabel => '已通关';

  @override
  String get recordsCalendarEmptyLabel => '无通关';

  @override
  String get recordsNoAverageTime => '暂无记录';

  @override
  String get recordsStatsBasisFootnote => '统计数据基于每道题的最佳通关记录计算。';

  @override
  String get recordsBestByLevelTitle => '各难度最佳记录';

  @override
  String get recordsBestByLevelEmpty => '该筛选条件下暂无各难度最佳记录。';

  @override
  String recordsBestByLevelDetail(String time, int wrongCount) {
    return '$time · 错误 $wrongCount 次';
  }

  @override
  String get recordsPerfectBadge => '完美';

  @override
  String recordsAvgTimeDetail(String time) {
    return '平均用时 $time';
  }

  @override
  String get recordsRecentTitle => '最近通关';

  @override
  String get recordsRecentEmpty => '没有符合该筛选条件的通关记录。';

  @override
  String get recordsBestTitle => '最佳用时 Top 5';

  @override
  String get recordsBestEmpty => '该筛选条件下暂无最佳记录。';

  @override
  String recordsGameNumberTitle(String level, int number) {
    return '$level · 第 $number 局';
  }

  @override
  String recordsRecentDetail(String time, int wrongCount, String date) {
    return '$time · 错误 $wrongCount 次 · $date';
  }

  @override
  String recordsBestDetail(String time, int wrongCount) {
    return '$time · 错误 $wrongCount 次';
  }

  @override
  String get recordsGameLoadError => '无法加载题目数据。';

  @override
  String get recordsChallengeTabHint => '每周目标和连续记录可在挑战标签页查看。';

  @override
  String get recordsGoToChallengeTab => '前往挑战标签页';

  @override
  String get challengeTodaysChallengeTitle => '今日挑战';

  @override
  String get challengeTodayDoneHint => '你已经完成今天的挑战，随时可以再回顾一遍。';

  @override
  String get challengeTodayPendingHint => '用今天的精选题目延续你的连续记录。';

  @override
  String get challengeTodayReviewButton => '按自己的节奏继续';

  @override
  String get challengeTodayStartButton => '按自己的节奏开始';

  @override
  String get myPaceNoPlayableTitle => '暂时没有可玩的题目';

  @override
  String get myPaceNoPlayableMessage => '所有难度中都没有可以开始的新题目了。';

  @override
  String get challengeWeeklyGoalReachedBody => '再多几次完美通关，让节奏更上一层楼。';

  @override
  String get challengeWeeklyGoalCatchUpBody => '只要再玩几局，就能完成本周的目标。';

  @override
  String challengePerfectThisWeek(int count) {
    return '本周完成了 $count 次完美通关';
  }

  @override
  String get challengePerfectThisWeekFirst => '试试本周的第一次完美通关吧';

  @override
  String get challengePerfectPositiveBody => '保持零失误通关，你的进步会更明显。';

  @override
  String get challengePerfectZeroBody => '善用备注模式，能让你更接近零失误通关。';

  @override
  String get challengeTabHeroHeadline => '今日题目与每周节奏， 一目了然。';

  @override
  String get challengeOpenTodayOnHomeButton => '在首页打开今日题目';

  @override
  String get challengeHeroDoneCaption => '你完成了今天的挑战，明天再来延续你的连续记录。';

  @override
  String get challengeHeroPendingCaption => '今天的题目还等着你——现在开始，保持连续记录。';

  @override
  String get homeGuestTitle => '旅人';

  @override
  String get homeGuestSubtitle => '轻点一下即可开始游戏';

  @override
  String get homeContinueTitle => '继续游戏';

  @override
  String homeContinueSubtitle(String level, int gameNumber, int cells) {
    return '$level · 第 $gameNumber 局 · 已填 $cells 格';
  }

  @override
  String get homeContinueDescription => '从上次暂停的地方继续解题。';

  @override
  String get homeContinueSameAsSpotlightSupporting => '继续今天的题目';

  @override
  String get homeContinueActionButton => '继续';

  @override
  String homeProgressPercent(int percent) {
    return '进度 $percent%';
  }

  @override
  String get homeQuickStartSectionTitle => '快速开始';

  @override
  String get homeBrowseLevelsTitle => '浏览难度';

  @override
  String get homeStreakTodayDoneLine => '今天的挑战也完成了。';

  @override
  String get homeStreakTodayPendingLine => '完成今天的挑战即可延续连续记录。';

  @override
  String get homeBadgeProgressTitle => '徽章进度';

  @override
  String get homeCatalogPreparingTitle => '正在准备题库';

  @override
  String homeCatalogProgressDetail(int generated, int target, int remaining) {
    return '已准备 $generated/$target 题 · 还剩 $remaining 题';
  }

  @override
  String get levelPickDifficultyTitle => '选择难度';

  @override
  String get levelPickDifficultySubtitle => '选择一个难度开始游戏。';

  @override
  String get levelPickGameSubtitle => '选择一道题开始游戏。';

  @override
  String levelGamesScreenTitle(String levelName) {
    return '$levelName 题目';
  }

  @override
  String get levelLoadingGames => '正在加载题目…';

  @override
  String get levelTapToStart => '立即开始';

  @override
  String get levelClearedBadge => '已通关';

  @override
  String get levelOverviewTitle => '难度概览';

  @override
  String get levelPuzzlesSectionTitle => '题目列表';

  @override
  String get levelProgressLabel => '进度';

  @override
  String get levelNoRecordYet => '暂无记录';

  @override
  String get levelStatusReady => '全新题目';

  @override
  String get levelStatusCleared => '已完成题目';

  @override
  String levelEmptyCellsLabel(int count) {
    return '$count 个空格';
  }

  @override
  String levelPuzzleCountSummary(int count) {
    return '共 $count 题';
  }

  @override
  String levelCatalogPreparingShort(int done, int total) {
    return '正在准备更多题目 · $done/$total';
  }

  @override
  String get commonSave => '保存';

  @override
  String get settingsDisplaySection => '显示';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSystem => '系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get profileEditorTitle => '编辑资料';

  @override
  String get profileEditorRemovePhoto => '移除照片';

  @override
  String get profileEditorNameLabel => '昵称';

  @override
  String get profileEditorDefaultProfile => '默认头像';

  @override
  String get profileEditorDefaultProfileDesc => '使用应用自带的默认图片';

  @override
  String get profileEditorPickFromAlbum => '从相册选择';

  @override
  String get profileEditorPickFromAlbumDesc => '使用自己的照片作为头像';

  @override
  String get homeTodayLabel => '今天';

  @override
  String get homeTodayPuzzleTitle => '静下心来，专注片刻。';

  @override
  String get homeChallengeStartButton => '开始挑战';

  @override
  String get homeChallengeReplayButton => '再玩一次';

  @override
  String get homeChallengeNotStarted => '尚未开始';

  @override
  String get homeChallengeFirstLine => '第一次挑战从初级开始';

  @override
  String homeChallengePromotedLine(String level) {
    return '今天来挑战$level吧？';
  }

  @override
  String homeChallengeProgress(int percent) {
    return '已完成 $percent%';
  }

  @override
  String get homeChallengeDoneLine => '今日挑战已完成！';

  @override
  String homeChallengeStreak(num days) {
    return '挑战连续 $days 天';
  }

  @override
  String get homeChallengeLoadErrorTitle => '无法加载今日挑战';

  @override
  String get homeChallengeLoadErrorBody => '请稍后再试。';

  @override
  String get homeTodayChallengeDateChanged => '日期已变更，已刷新今日挑战。';

  @override
  String get homeFirstStartTitle => '开始你的第一道谜题';

  @override
  String get homeNewPuzzleTitle => '开始一道新谜题';

  @override
  String get homeChooseLevelBody => '请选择难度。进度会自动保存。';

  @override
  String get homeChooseLevelButton => '选择难度';

  @override
  String homeViewAllInProgress(int count) {
    return '查看全部进行中的游戏 ($count)';
  }

  @override
  String get homeNewGameSectionTitle => '新游戏 · 选择难度';

  @override
  String homeLevelBlankCells(int count) {
    return '$count 个空格';
  }

  @override
  String get homeSavedGamesTitle => '进行中的游戏';

  @override
  String get homeSavedGamesDescription => '选择要继续的游戏。删除只会移除已保存的进度，不影响完成记录。';

  @override
  String get homeSavedGameDeleteTooltip => '删除已保存的进度';

  @override
  String get homeSavedGameDeleteTitle => '删除已保存的进度？';

  @override
  String get homeSavedGameDeleteBody => '该谜题的输入和笔记将被删除。完成记录会保留。';

  @override
  String get homeSavedGameDeleteConfirm => '删除';

  @override
  String get homeLoadError => '无法加载游戏信息。';

  @override
  String get homeCatalogFirstTitle => '正在准备第一批题目';

  @override
  String get homeCatalogFirstBody => '首次启动时，数独题目会保存到你的设备上。之后应用会打开得快很多。';

  @override
  String get homeCatalogFirstNote => '准备工作会在后台继续进行，你可以直接开始探索。';

  @override
  String get homeCatalogFirstContinue => '继续前往首页';

  @override
  String homeLevelProgressSolved(int cleared, int total) {
    return '$cleared / $total';
  }

  @override
  String get levelFilterAll => '全部';

  @override
  String get levelFilterNew => '全新';

  @override
  String get levelFilterInProgress => '进行中';

  @override
  String get levelFilterDone => '已完成';

  @override
  String levelPuzzleListTitle(int count) {
    return '谜题列表 · $count';
  }

  @override
  String get levelRecentBadge => '最近';

  @override
  String get levelStatusInProgress => '进行中';

  @override
  String get levelNoResults => '暂无结果。';

  @override
  String levelReplayTitle(int number) {
    return '要重新挑战第$number题吗？';
  }

  @override
  String get levelReplayBody => '已完成的记录会保留。若以更好成绩完成，只会更新最佳记录。';

  @override
  String get levelReplayConfirm => '重新挑战';

  @override
  String levelInProgressLimitTitle(int maxCount) {
    return '有 $maxCount 道谜题进行中';
  }

  @override
  String levelInProgressLimitBody(int maxCount) {
    return '最多可以同时进行 $maxCount 道题。\n请从下方选择一道继续挑战。';
  }

  @override
  String get levelInProgressLimitLater => '稍后再说';

  @override
  String get levelTryAgain => '再试一次';

  @override
  String get levelContinueButton => '继续解题';

  @override
  String levelStartNextNew(String number) {
    return '开始新谜题 · $number';
  }

  @override
  String get levelStartNewButton => '开始谜题';

  @override
  String levelPuzzleNumber(int number) {
    return '第$number道谜题';
  }

  @override
  String levelCompletedCount(num count) {
    return '已完成 $count 个';
  }

  @override
  String get levelCardFirstSub => '从第一道谜题开始吧';

  @override
  String get levelCardNextSub => '开始下一道谜题吧';

  @override
  String levelCardAllDoneTitle(String levelName) {
    return '已完成所有$levelName谜题';
  }

  @override
  String get levelCardAllDoneSub => '再玩一次已完成的谜题吧';

  @override
  String get levelCardViewCompleted => '查看已完成的谜题';

  @override
  String levelViewInProgress(int count) {
    return '查看 $count 个进行中';
  }

  @override
  String get levelNotesInProgress => '正在写笔记';

  @override
  String get levelEmptyInProgress => '还没有可以继续的谜题。';

  @override
  String get levelEmptyCompleted => '创建你的第一条完成记录。';

  @override
  String get levelEmptyFresh => '没有可开始的新谜题。';

  @override
  String get levelAllCompleted => '你已完成该难度的所有谜题。';

  @override
  String get levelActionShowNew => '查看新谜题';

  @override
  String get levelActionShowInProgress => '查看进行中';

  @override
  String get levelActionShowAll => '查看全部';

  @override
  String levelBestTime(String time) {
    return '最佳用时 $time';
  }

  @override
  String levelCellSemantics(String number, String status) {
    return '第 $number 题，$status';
  }

  @override
  String get gameRestartMenuTitle => '从头开始';

  @override
  String get gameRestartMenuDescription => '清除已输入的内容，回到初始状态';

  @override
  String get gameRestartDialogTitle => '要从头开始吗？';

  @override
  String get gameRestartDialogBody => '已输入的数字和笔记、用时、提示使用和错误次数都会重置。已有的完成记录会保留。';

  @override
  String get gameRestartConfirm => '重新开始';

  @override
  String get gameNumberInputLegend => '小数字表示剩余数量，打勾表示已完成的数字。';

  @override
  String get dialogSuggestedNextStep => '推荐下一步';

  @override
  String get dialogSetTomorrowReminder => '设置明天的提醒';

  @override
  String get dialogTryAnotherLevel => '试试其他难度';

  @override
  String get savedGamesSortRecent => '最近游玩';

  @override
  String get savedGamesSortProgress => '按进度';

  @override
  String get savedGamesSortPlayTime => '按游玩时长';

  @override
  String get savedGamesEmpty => '没有符合该筛选条件的存档。';

  @override
  String get savedGamesDeleteFailed => '删除失败,请重试。';

  @override
  String get recordsMyRecordTitle => '目前为止';

  @override
  String recordsSummaryHeroSentence(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '你已完成 $count 道谜题',
    );
    return '$_temp0';
  }

  @override
  String get recordsSummaryHeroFirst => '你完成了第一道谜题';

  @override
  String recordsSummaryHeroMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已突破 $count 道谜题',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryHeroGrowing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已经解开 $count 道谜题了',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryHeroStacked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 道谜题一点点积累起来',
    );
    return '$_temp0';
  }

  @override
  String get recordsLevelRingsTitle => '各难度进度';

  @override
  String recordsLevelRingSemantics(String level, int cleared, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total 道中已完成 $cleared 道',
    );
    return '$level，$_temp0';
  }

  @override
  String get recordsSummaryAllPerfect => '全部无失误完成';

  @override
  String recordsSummaryPartialPerfect(num count) {
    return '其中 $count 道无失误';
  }

  @override
  String recordsSummaryStreakPlaying(num days) {
    return '已连续玩了 $days 天';
  }

  @override
  String recordsSummaryPlayDays(num days) {
    return '游玩 $days 天';
  }

  @override
  String get recordsSummaryEmptyTitle => '来创建第一条记录吧';

  @override
  String get recordsSummaryEmptyBody => '完成谜题后，记录会在这里累积';

  @override
  String get challengeTodayEyebrow => '今日动态';

  @override
  String homeStreakChip(int count) {
    return '$count天';
  }

  @override
  String homeStreakActive(int count) {
    return '已连续 $count 天完成谜题';
  }

  @override
  String homeStreakAtRisk(int count) {
    return '已连续 $count 天。今天完成一局即可延续。';
  }

  @override
  String get hintStepLookTitle => '提示 · 看这里';

  @override
  String get hintLookCell => '看看高亮格子所在的行、列和宫。';

  @override
  String hintLookBox(int value) {
    return '在高亮的宫里找出 $value 的位置。';
  }

  @override
  String hintLookRow(int value) {
    return '在高亮的行里找出 $value 的位置。';
  }

  @override
  String hintLookCol(int value) {
    return '在高亮的列里找出 $value 的位置。';
  }

  @override
  String get hintMovedFromSelection => '有比所选格子更容易先解的位置。';

  @override
  String get hintTechniqueNakedSingle => '唯一候选数';

  @override
  String get hintTechniqueHiddenSingle => '隐性唯一数';

  @override
  String get hintTechniqueReveal => '答案';

  @override
  String hintExplainNakedSingle(int value) {
    return '这个格子所在的行、列和宫里已经有其他 8 个数字，只能填 $value。';
  }

  @override
  String hintExplainHiddenSingleBox(int value) {
    return '在这个宫里，$value 只能填在这里。其他空格都和高亮的 $value 在同一行或同一列。';
  }

  @override
  String hintExplainHiddenSingleRow(int value) {
    return '在这一行里，$value 只能填在这里。其他空格都和高亮的 $value 在同一列或同一宫。';
  }

  @override
  String hintExplainHiddenSingleCol(int value) {
    return '在这一列里，$value 只能填在这里。其他空格都和高亮的 $value 在同一行或同一宫。';
  }

  @override
  String get hintExplainReveal => '这个格子需要更高级的技巧。可以用下方按钮填入答案。';

  @override
  String get hintNextStep => '再提示一下';

  @override
  String get hintFillAnswer => '填入答案';

  @override
  String get hintClose => '关闭提示';

  @override
  String get notificationOptInTitle => '要每天提醒你解一局吗？';

  @override
  String get notificationOptInBody => '如果每天晚上 8 点还没有解谜题，我们会提醒你。你可以随时在设置中关闭。';

  @override
  String get notificationOptInAccept => '开启提醒';

  @override
  String get notificationOptInLater => '以后再说';

  @override
  String get notificationOptInDenied => '未获得通知权限。请在设备设置中允许后，再在设置中开启提醒。';

  @override
  String get notificationSetupFailed => '无法设置提醒。请稍后在设置中重试。';

  @override
  String get beginnerTutorialPromptTitle => '第一次玩数独吗?';

  @override
  String get beginnerTutorialPromptBody => '通过简短练习熟悉基本规则和操作吧。';

  @override
  String get beginnerTutorialStart => '开始练习';

  @override
  String get beginnerTutorialSkip => '跳过';

  @override
  String beginnerTutorialStepIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String get beginnerTutorialPracticeTitle => '练习题';

  @override
  String get beginnerTutorialStepRulesTitle => '基本规则';

  @override
  String get beginnerTutorialStepRulesBody =>
      '每一行、每一列和每个 3×3 宫格都必须包含 1 到 9 的数字，且不能重复。';

  @override
  String get beginnerTutorialRuleRow => '行';

  @override
  String get beginnerTutorialRuleColumn => '列';

  @override
  String get beginnerTutorialRuleBox => '3×3 宫格';

  @override
  String get beginnerTutorialStepInputTitle => '输入数字';

  @override
  String get beginnerTutorialStepInputBody => '点击高亮的格子，再选择合适的数字。';

  @override
  String get beginnerTutorialStepInputWrongHint => '同一行、列或 3×3 宫格里已有的数字不能再填。';

  @override
  String get beginnerTutorialStepMemoTitle => '记录候选数字';

  @override
  String get beginnerTutorialStepMemoAddBody => '打开笔记，在高亮的格子里记下候选数字。';

  @override
  String get beginnerTutorialStepMemoEraseBody => '再次点击同一个数字即可擦除笔记。';

  @override
  String get beginnerTutorialStepHintTitle => '使用提示';

  @override
  String get beginnerTutorialStepHintBody => '卡住时点击提示，会告诉你该看哪个格子以及原因。';

  @override
  String get beginnerTutorialStepDoneTitle => '准备好了！';

  @override
  String get beginnerTutorialStepDoneBody => '你已经学会输入数字、记笔记和使用提示。';

  @override
  String get beginnerTutorialFirstPuzzleButton => '开始我的第一道题';

  @override
  String get beginnerTutorialNextButton => '下一步';

  @override
  String get beginnerTutorialCloseButton => '完成';

  @override
  String get settingsHowToPlayTitle => '玩法说明';

  @override
  String get settingsHowToPlaySubtitle => '重新观看引导教程';

  @override
  String get autoNotesConfirmTitle => '重新填写所有笔记吗?';

  @override
  String get autoNotesConfirmBody => '这会用当前候选数字替换每个空白格子的笔记。你手动删除的候选数字可能会重新出现。';

  @override
  String get autoNotesConfirmApply => '重新填写笔记';

  @override
  String get autoNotesContradictionMessage =>
      '有些格子已经没有任何可能的数字，因此未能填写笔记。请检查你的输入内容后重试。';

  @override
  String get autoNotesTipMessage => '提示：长按笔记可以一次性填写所有候选数字。';

  @override
  String get gameNumberLockTipMessage => '长按数字即可锁定，并快速填入多个格子。';

  @override
  String gameNumberButtonLockedSemantics(int number) {
    return '$number，已锁定，长按解除';
  }

  @override
  String get gameNumberButtonLockHint => '长按锁定';

  @override
  String get gameMemoLongPressHint => '点击切换笔记模式，长按自动填写笔记。';

  @override
  String get homeGreetingMorning => '从一局轻松的谜题开始吧。';

  @override
  String get homeGreetingAfternoon => '现在适合专注解一局。';

  @override
  String get homeGreetingEvening => '静下心来，用一局谜题收尾吧。';

  @override
  String get levelNoPuzzlesAvailable => '此难度暂无可用题目。';

  @override
  String get levelLastPlayedToday => '今天';

  @override
  String get levelLastPlayedYesterday => '昨天';

  @override
  String levelLastPlayedDaysAgo(int count) {
    return '$count 天前';
  }
}
