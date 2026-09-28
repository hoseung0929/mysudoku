// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Sudoku159';

  @override
  String get navHome => 'ホーム';

  @override
  String get navChallenge => 'チャレンジ';

  @override
  String get navRecords => '記録';

  @override
  String get navSettings => '設定';

  @override
  String get recordsHeroImageSubtitle => '積み重なる解答の記録';

  @override
  String get settingsHeroSubtitle => '自分らしく整えましょう';

  @override
  String get recordsScreenTitle => '記録 · 統計';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsSectionLanguage => '言語';

  @override
  String get settingsSectionGame => 'ゲーム';

  @override
  String get settingsSectionInfo => '情報';

  @override
  String get settingsNotificationsTitle => '通知設定';

  @override
  String get settingsNotificationsSubtitle => '今日のチャレンジが未完了の場合にリマインドを送ります';

  @override
  String get settingsStreakReminderTitle => '連続プレイリマインド';

  @override
  String get settingsStreakReminderSubtitle => '連続記録がある場合にもう一度プレイを促します';

  @override
  String get settingsNotificationTimeTitle => '通知時間';

  @override
  String get settingsNotificationTimeSubtitle => 'リマインドを受け取る時間を設定します';

  @override
  String get settingsNotificationsPermissionDenied =>
      '通知権限が許可されていないため、リマインドをオンにできません。';

  @override
  String get settingsLanguageTitle => '言語設定';

  @override
  String get settingsLanguageSubtitle => 'アプリの言語を変更します';

  @override
  String get settingsLanguageSystem => 'システムに従う';

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
  String get settingsLanguagePickerTitle => '言語を選択';

  @override
  String get settingsVibrationTitle => '入力バイブ';

  @override
  String get settingsVibrationSubtitle => '数字入力時に振動フィードバックを使用します';

  @override
  String get settingsKeepScreenAwakeTitle => '画面をオンに保つ';

  @override
  String get settingsKeepScreenAwakeSubtitle => 'ゲーム画面が自動でスリープしないようにします';

  @override
  String get settingsOneHandModeTitle => '片手モード';

  @override
  String get settingsOneHandModeSubtitle => 'モバイルのゲーム画面でよりコンパクトなボタン配置を使用します';

  @override
  String get settingsMemoHighlightTitle => 'メモ候補のハイライト';

  @override
  String get settingsMemoHighlightSubtitle => 'メモのフォーカス、候補数字、唯一候補のハイライトを表示します';

  @override
  String get settingsSmartHintTitle => '入力可能マスのハイライト';

  @override
  String get settingsSmartHintSubtitle => 'ルール上すぐに入力できるマスを薄くハイライトします';

  @override
  String get settingsAppInfoTitle => 'アプリ情報';

  @override
  String get settingsAppInfoSubtitle => 'バージョンと開発者情報';

  @override
  String get settingsPrivacyTitle => 'プライバシーポリシー';

  @override
  String get settingsPrivacySubtitle => 'データの取り扱いについて';

  @override
  String get settingsTabletNotificationsHeader => '通知設定';

  @override
  String get settingsTabletNotificationsBody => 'ゲーム通知を管理・設定できます。';

  @override
  String get settingsGameCompleteNotifTitle => 'ゲーム完了通知';

  @override
  String get settingsGameCompleteNotifSubtitle => 'パズルを完了したときに通知を受け取ります';

  @override
  String get settingsDailyGoalNotifTitle => 'デイリー目標通知';

  @override
  String get settingsDailyGoalNotifSubtitle => '週間目標を達成した瞬間にお祝い通知を受け取ります';

  @override
  String get settingsHintNotifTitle => 'ヒント使用通知';

  @override
  String get settingsHintNotifSubtitle => 'ヒントを使用したときに通知を受け取ります';

  @override
  String get levelBeginner => '初級';

  @override
  String get levelIntermediate => '中級';

  @override
  String get levelAdvanced => '上級';

  @override
  String get levelExpert => 'エキスパート';

  @override
  String get levelMaster => 'マスター';

  @override
  String get levelDescBeginner => '数独を初めてプレイする方向けのレベル';

  @override
  String get levelDescIntermediate => '基本的なルールを知っている方向けのレベル';

  @override
  String get levelDescAdvanced => '数独に慣れている方向けのレベル';

  @override
  String get levelDescExpert => '数独マスター向けのレベル';

  @override
  String get levelDescMaster => '究極の数独チャレンジ';

  @override
  String gameNumberLabel(int number) {
    return 'ゲーム $number';
  }

  @override
  String get gameHintShort => 'ヒント';

  @override
  String get gameUndoShort => '元に戻す';

  @override
  String get gameRedoShort => 'やり直し';

  @override
  String get gameMemoShort => 'メモ';

  @override
  String gameCellLabel(int row, int col, String content) {
    return '$row行$col列: $content';
  }

  @override
  String get gameCellEmpty => '空欄';

  @override
  String gameCellNotes(String notes) {
    return 'メモ $notes';
  }

  @override
  String get gameCellGiven => '固定';

  @override
  String get gameCellHint => 'ヒント';

  @override
  String get gameCellWrong => '不正解';

  @override
  String get gameEraseShort => '消す';

  @override
  String get gameMoreOptions => 'その他';

  @override
  String get gameMemoOnShort => 'メモ ON';

  @override
  String get gameMemoStateOn => 'ON';

  @override
  String get gameMemoStateOff => 'OFF';

  @override
  String get gameMemoFocusShort => 'フォーカス';

  @override
  String get gameMemoFocusIdle => 'なし';

  @override
  String get gameWrongShort => 'ミス';

  @override
  String get gamePerfectShort => 'パーフェクト';

  @override
  String get gamePerfectReady => '継続中';

  @override
  String get gamePerfectMissed => '失敗';

  @override
  String get gameProgressShort => '進捗';

  @override
  String get gameTimeShort => 'タイム';

  @override
  String get gameNumberInputTitle => '数字入力';

  @override
  String gameRowsCompleted(int count) {
    return '$count行クリア';
  }

  @override
  String gameColsCompleted(int count) {
    return '$count列クリア';
  }

  @override
  String gameBoxesCompleted(int count) {
    return '$countブロッククリア';
  }

  @override
  String get gamePause => '一時停止';

  @override
  String get gameResume => '再開';

  @override
  String get gameAnswerPreview => '解答';

  @override
  String get challengeCompletedToday => '今日のチャレンジを完了しました！';

  @override
  String get shareCopySuccess => '結果をクリップボードにコピーしました。';

  @override
  String get shareSubject => 'Sudoku159 結果';

  @override
  String get shareClearHeader => 'Sudoku159 クリア';

  @override
  String shareClearLine(String level, int number) {
    return '$level · ゲーム $number';
  }

  @override
  String shareClearStats(String time, int wrong) {
    return '$time · ミス $wrong回';
  }

  @override
  String get shareClearTags => '#Sudoku159 #SudokuChallenge';

  @override
  String shareSummaryPattern(String time, int wrong) {
    return '$time · ミス $wrong回';
  }

  @override
  String get dialogCongratulations => 'おめでとうございます！';

  @override
  String get dialogNewBest => 'NEW BEST';

  @override
  String get dialogSudokuComplete => '数独を完成させました！';

  @override
  String get dialogNewBadges => '新しいバッジ獲得';

  @override
  String get dialogElapsedTime => 'タイム';

  @override
  String get dialogWrongCount => 'ミス回数';

  @override
  String dialogWrongCountValue(int count) {
    return '$count回';
  }

  @override
  String get dialogSharePreview => 'シェアテキスト';

  @override
  String get dialogCopyResult => 'コピー';

  @override
  String get dialogShare => 'シェア';

  @override
  String get dialogBackToLevels => 'パズル一覧へ';

  @override
  String get dialogPlayAgain => 'もう一度解く';

  @override
  String get dialogPuzzleCompleteTitle => 'パズル完了';

  @override
  String get dialogNewBestMessage => 'ベスト記録を更新しました';

  @override
  String dialogHintsUsed(int count) {
    return 'ヒント $count回使用';
  }

  @override
  String get dialogSolveSameAgain => '同じパズルをもう一度解く';

  @override
  String get dialogNextPuzzle => '次のパズル';

  @override
  String get updateRequiredTitle => 'アップデートが必要です';

  @override
  String get updateRequiredMessage =>
      '新しいバージョンが公開されました。\n続けてプレイするにはアップデートしてください。';

  @override
  String get updateNowButton => '今すぐアップデート';

  @override
  String get settingsNotificationsComingSoonTitle => '通知';

  @override
  String get settingsNotificationsComingSoonBody =>
      'プッシュ通知や詳細な通知設定は今後のアップデートで提供予定です。';

  @override
  String get settingsAboutDialogTitle => 'アプリ情報';

  @override
  String settingsAboutVersionLabel(String version) {
    return 'バージョン $version';
  }

  @override
  String get settingsAboutDeveloperNote => 'Sudoku159をお楽しみください！';

  @override
  String get settingsAboutSupportEmail => '· team929.support@gmail.com';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get gameOverTitle => 'ミスの上限に達しました';

  @override
  String get gameOverMessage => '最初からやり直すか、別のパズルを選べます。';

  @override
  String gameOverWrongLabel(int count, int maxCount) {
    return '今回: ミス $count回 / 上限 $maxCount回';
  }

  @override
  String get recordsFilterSectionTitle => 'フィルター';

  @override
  String get recordsFilterAllLevels => '全レベル';

  @override
  String get recordsPeriodLabel => '期間';

  @override
  String get recordsPeriodAll => '全期間';

  @override
  String recordsPeriodLastDays(int days) {
    return '直近 $days日';
  }

  @override
  String get recordsSummaryTitle => '直近7日間';

  @override
  String get recordsTrendTitle => '直近7日間の推移';

  @override
  String get recordsTrendEmpty => '7日間の推移を表示するための記録が足りません。';

  @override
  String get recordsTrendClears => 'クリア数';

  @override
  String get recordsTrendActiveDays => 'プレイ日数';

  @override
  String get recordsTrendWindowAvgTime => '平均タイム（同期間）';

  @override
  String get recordsTrendWindowAvgWrong => '平均ミス（同期間）';

  @override
  String get recordsHeroBadgeFlow => 'フロー';

  @override
  String get recordsHeroTitle => '積み上げてきた流れを 落ち着いて眺めてみましょう。';

  @override
  String get recordsHeroSubtitle =>
      '上のグラフは同じ7日間をなめらかに表現しています。日別クリア数は下のカードで確認できます。';

  @override
  String get recordsInsightThisWeekEyebrow => '今週の記録';

  @override
  String recordsInsightClearsValue(int count) {
    return '$count回';
  }

  @override
  String get recordsInsightAvgPaceEyebrow => '平均ペース';

  @override
  String get recordsTrendSectionSubtitle => '直近1週間の日別クリア数をまとめて確認できます。';

  @override
  String get recordsTrendLegendDailyClears => '日別クリア';

  @override
  String get recordsTrendTodayLabel => '今日';

  @override
  String get recordsPlayInsightsTitle => '今週の記録';

  @override
  String get recordsWeekSubtitle => '曜日をタップして記録を確認';

  @override
  String get recordsPlayCalendarTitle => '曜日別';

  @override
  String get recordsWeeklyReportTitle => '今週のレポート';

  @override
  String get recordsWeeklyReportBusiestDay => '最もプレイした曜日';

  @override
  String recordsWeeklyReportTopDayValue(String day, int count) {
    return '$day、$count回';
  }

  @override
  String get recordsWeeklyReportTopDayFallback => 'まだクリアがありません';

  @override
  String get recordsTimelineTitle => '最近のタイムライン';

  @override
  String get recordsTimelineEmpty => 'クリアした記録がここに表示されます。';

  @override
  String recordsTimelineMistakesValue(int count) {
    return 'ミス $count回';
  }

  @override
  String get recordsTimelinePerfect => 'パーフェクトクリア';

  @override
  String get recordsPaceTitle => 'ペースの変化';

  @override
  String get recordsPaceEmpty => '前の週と比較するにはもう少し記録が必要です。';

  @override
  String get recordsPaceRecentWindow => '直近7日';

  @override
  String get recordsPacePreviousWindow => '前の7日';

  @override
  String get recordsPaceDelta => '変化';

  @override
  String get recordsMetricClears => 'クリア（フィルター）';

  @override
  String get recordsMetricClearRate => 'パズル完了状況';

  @override
  String get recordsMetricPerfectRate => 'ミスなし完了の割合';

  @override
  String get recordsSummaryMetricsFootnote =>
      'パズルごとにベスト記録1件だけを数え、期間・レベルのフィルターを反映します。完了状況は同じ範囲の全パズル数との比較です。';

  @override
  String get recordsMetricAvgTime => '平均クリア時間';

  @override
  String get recordsMetricAvgWrong => '平均ミス';

  @override
  String get recordsByLevelTitle => 'レベル別の記録';

  @override
  String get recordsByLevelSubtitle => '難易度を選んで記録を比べてみましょう';

  @override
  String get recordsByLevelEmpty => '表示するレベル統計がありません。';

  @override
  String get recordsByLevelSectionSubtitle => '難易度別にどのレベルで成長を感じているか確認できます。';

  @override
  String get recordsLevelInfographicClearRate => 'パズル完了状況';

  @override
  String get recordsLevelMiniBest => 'ベスト';

  @override
  String get recordsLevelMiniPerfectRate => 'パーフェクト率';

  @override
  String get recordsLevelMiniAvgWrong => '平均ミス';

  @override
  String get recordsStatsLoadError => '統計データを読み込めませんでした。しばらくしてから再試行してください。';

  @override
  String get recordsRetry => '再試行';

  @override
  String get recordsEmptyTitle => '最初のパズルを完成させると記録がたまります。';

  @override
  String get recordsEmptyAction => 'パズルを始める';

  @override
  String get recordsLevelEmpty => 'このレベルの完了記録はまだありません。';

  @override
  String get recordsRowBestTime => 'ベスト記録';

  @override
  String get recordsAverageBasisNote => '平均はパズルごとのベスト記録が基準です。';

  @override
  String get recordsCalendarTitle => '全パズルの活動';

  @override
  String get recordsCalendarSubtitle => 'クリアした日とプレイ頻度を確認しましょう';

  @override
  String recordsCalendarPeriod(int weeks) {
    return '直近$weeks週';
  }

  @override
  String get recordsViewAchievements => '実績を見る';

  @override
  String recordsOverallNote(int cleared, int total) {
    return '全レベルで$total問中$cleared問を完了しました。';
  }

  @override
  String recordsWeekActiveDays(int count) {
    return '活動 $count日';
  }

  @override
  String recordsWeekCompletions(int count) {
    return '完了 $count回';
  }

  @override
  String recordsWeekDayDone(String day, int count) {
    return '$day: $count回完了';
  }

  @override
  String recordsWeekDayNone(String day) {
    return '$day: 完了なし';
  }

  @override
  String get recordsStatsPageSubtitle => 'クリアと平均タイムを一目で確認できます。';

  @override
  String get recordsKpiWeeklyClearsLabel => 'クリアしたパズル';

  @override
  String get recordsKpiAvgSolveTimeLabel => 'ベスト記録の平均';

  @override
  String get recordsActivityOverviewTitle => '積み上げた記録';

  @override
  String get recordsActivityHeatmapTitle => '最近のアクティビティ';

  @override
  String get recordsActivityHeatmapCaption => '完了したすべてのパズルの活動記録です。';

  @override
  String get recordsActivityTotalClearsLabel => '累計クリア回数';

  @override
  String get recordsActivityCurrentStreakLabel => 'クリア連続';

  @override
  String get recordsActivityBestStreakLabel => '最長クリア連続';

  @override
  String get recordsChallengeStreakLabel => '今日のチャレンジ連続';

  @override
  String recordsActivityDayCount(int count) {
    return '$count日';
  }

  @override
  String recordsActivityClearCount(int count) {
    return '$count回クリア';
  }

  @override
  String get recordsSectionBestRecordTitle => 'ベスト記録';

  @override
  String get recordsSectionDifficultyTitle => '難易度別記録';

  @override
  String get recordsSectionDetailStatsTitle => '詳細記録';

  @override
  String get recordsBestSingleEmpty => 'まだ表示できるベスト記録がありません。';

  @override
  String get recordsHintUsageLabel => 'ヒント使用記録';

  @override
  String get recordsHintUsageNoData => '記録なし';

  @override
  String get recordsDetailMistakesShort => '平均ミス';

  @override
  String get recordsDetailStreakShort => '連続プレイ日数';

  @override
  String recordsDetailStreakDays(int count) {
    return '$count日';
  }

  @override
  String recordsStatAverageWrongFormatted(String value) {
    return '$value回';
  }

  @override
  String get recordsDifficultySnapshotEmpty => 'まだ難易度別の記録がありません。';

  @override
  String get recordsLevelDoneShort => '完了';

  @override
  String get recordsStatsHeroEyebrow => '直近7日間の数独記録';

  @override
  String get recordsStatsHeroHeadline => '直近7日間の数独記録を 一目で確認しましょう。';

  @override
  String recordsTrendA11yMaxClears(int count) {
    return '最高 $count回';
  }

  @override
  String get recordsHeroChartEmptyHint => '直近7日間にパズルをクリアすると、フローグラフがここに表示されます。';

  @override
  String get recordsHeroSubtitleNoChart => '下のカードで直近7日間の日別クリアを確認できます。';

  @override
  String get recordsCalendarPlayedLabel => 'クリアした日';

  @override
  String get recordsCalendarEmptyLabel => 'クリアなし';

  @override
  String get recordsNoAverageTime => '記録なし';

  @override
  String get recordsStatsBasisFootnote => '統計はパズルごとのベストクリア記録をもとに計算されます。';

  @override
  String get recordsBestByLevelTitle => 'レベル別ベスト記録';

  @override
  String get recordsBestByLevelEmpty => '表示するレベル別ベスト記録がありません。';

  @override
  String recordsBestByLevelDetail(String time, int wrongCount) {
    return '$time · ミス $wrongCount回';
  }

  @override
  String get recordsPerfectBadge => 'パーフェクト';

  @override
  String recordsAvgTimeDetail(String time) {
    return '平均タイム $time';
  }

  @override
  String get recordsRecentTitle => '最近のクリア';

  @override
  String get recordsRecentEmpty => 'このフィルターに合うクリア記録がありません。';

  @override
  String get recordsBestTitle => 'ベストタイム Top 5';

  @override
  String get recordsBestEmpty => 'このフィルターのベスト記録がありません。';

  @override
  String recordsGameNumberTitle(String level, int number) {
    return '$level · ゲーム $number';
  }

  @override
  String recordsRecentDetail(String time, int wrongCount, String date) {
    return '$time · ミス $wrongCount回 · $date';
  }

  @override
  String recordsBestDetail(String time, int wrongCount) {
    return '$time · ミス $wrongCount回';
  }

  @override
  String get recordsGameLoadError => 'ゲームデータを読み込めません。';

  @override
  String get recordsChallengeTabHint => '週間目標と連続記録はチャレンジタブで確認できます。';

  @override
  String get recordsGoToChallengeTab => 'チャレンジタブへ';

  @override
  String get challengeTodaysChallengeTitle => '今日のチャレンジ';

  @override
  String get challengeTodayDoneHint => '今日のチャレンジは完了済みです。いつでも見直せます。';

  @override
  String get challengeTodayPendingHint => '今日のパズルでストリークを続けましょう。';

  @override
  String get challengeTodayReviewButton => '自分のペースで続ける';

  @override
  String get challengeTodayStartButton => '自分のペースで始める';

  @override
  String get myPaceNoPlayableTitle => 'プレイできるゲームがありません';

  @override
  String get myPaceNoPlayableMessage => '全レベルで新しくプレイできるパズルがありません。';

  @override
  String get challengeWeeklyGoalReachedBody =>
      'パーフェクトクリアを増やして、さらに良いリズムを作りましょう。';

  @override
  String get challengeWeeklyGoalCatchUpBody => 'いくつかのセッションで今週の目標を達成できます。';

  @override
  String challengePerfectThisWeek(int count) {
    return '今週 $count回のパーフェクトクリア';
  }

  @override
  String get challengePerfectThisWeekFirst => '今週初のパーフェクトクリアに挑戦しましょう';

  @override
  String get challengePerfectPositiveBody => 'ミスなしのクリアを続けると成長が見えやすくなります。';

  @override
  String get challengePerfectZeroBody => 'メモ機能を使うとミスなしクリアにぐっと近づけます。';

  @override
  String get challengeTabHeroHeadline => '今日のパズルと週間リズムを ひとつの画面で。';

  @override
  String get challengeOpenTodayOnHomeButton => 'ホームで今日のパズルを開く';

  @override
  String get challengeHeroDoneCaption => '今日のチャレンジを完了しました。明日も続けて記録を積み上げましょう。';

  @override
  String get challengeHeroPendingCaption =>
      '今日のチャレンジがまだ残っています。今すぐ始めてストリークを続けましょう。';

  @override
  String get homeGuestTitle => '旅行者';

  @override
  String get homeGuestSubtitle => 'ワンタップでゲームを始めましょう';

  @override
  String get homeContinueTitle => '続きから';

  @override
  String homeContinueSubtitle(String level, int gameNumber, int cells) {
    return '$level · ゲーム $gameNumber · $cellsマス入力済み';
  }

  @override
  String get homeContinueDescription => '中断したパズルをそのまま続けられます。';

  @override
  String get homeContinueSameAsSpotlightSupporting => '今日のパズルを続ける';

  @override
  String get homeContinueActionButton => '続ける';

  @override
  String homeProgressPercent(int percent) {
    return '進捗 $percent%';
  }

  @override
  String get homeTodayChallengeCardDoneBody => '今日のチャレンジを完了しました。ストリークを続けましょう！';

  @override
  String get homeTodayChallengeCardPendingBody => '毎日一問、気軽に実力を確かめましょう。';

  @override
  String homeTodayChallengeFooterDoneStreak(int days) {
    return '今日のチャレンジ完了 · $days日連続記録';
  }

  @override
  String get homeTodayChallengeFooterPending => '今日のパズルでストリークを作りましょう。';

  @override
  String get homeQuickStartSectionTitle => 'クイックスタート';

  @override
  String get homeBrowseLevelsTitle => '難易度を選ぶ';

  @override
  String get homeStreakTodayDoneLine => '今日のチャレンジも完了しました。';

  @override
  String get homeStreakTodayPendingLine => '今日のチャレンジを完了すると記録を続けられます。';

  @override
  String get homeBadgeProgressTitle => 'バッジの進捗';

  @override
  String get homeCatalogPreparingTitle => 'パズルカタログ準備中';

  @override
  String homeCatalogProgressDetail(int generated, int target, int remaining) {
    return '$generated/$target問準備完了 · 残り$remaining問';
  }

  @override
  String get levelPickDifficultyTitle => '難易度を選択';

  @override
  String get levelPickDifficultySubtitle => '難易度を選んでゲームを始めましょう。';

  @override
  String get levelPickGameSubtitle => 'プレイするパズルを選んでください。';

  @override
  String levelGamesScreenTitle(String levelName) {
    return '$levelName ゲーム';
  }

  @override
  String get levelLoadingGames => 'パズルを読み込み中…';

  @override
  String get levelTapToStart => '今すぐ始める';

  @override
  String get levelClearedBadge => 'クリア';

  @override
  String get levelOverviewTitle => 'レベル概要';

  @override
  String get levelPuzzlesSectionTitle => 'パズル一覧';

  @override
  String get levelProgressLabel => '進捗率';

  @override
  String get levelNoRecordYet => '記録なし';

  @override
  String get levelStatusReady => '新しいパズル';

  @override
  String get levelStatusCleared => 'クリア済みパズル';

  @override
  String levelEmptyCellsLabel(int count) {
    return '空きマス $count個';
  }

  @override
  String levelPuzzleCountSummary(int count) {
    return '全 $count問';
  }

  @override
  String levelCatalogPreparingShort(int done, int total) {
    return '追加パズル準備中 · $done/$total問';
  }

  @override
  String get achievementCollectionAppBarTitle => 'バッジコレクション';

  @override
  String get achievementLoadError => 'バッジ情報を読み込めません。';

  @override
  String get achievementViewSettings => '表示設定';

  @override
  String get achievementSortLabel => '並び替え';

  @override
  String get achievementFilterAll => '全て';

  @override
  String get achievementFilterUnlocked => '獲得済み';

  @override
  String get achievementFilterLocked => '挑戦中';

  @override
  String get achievementSectionAll => '全バッジ';

  @override
  String get achievementSectionUnlocked => '獲得したバッジ';

  @override
  String get achievementSectionLocked => '挑戦中のバッジ';

  @override
  String get achievementEmptyAll => '表示するバッジがありません。';

  @override
  String get achievementEmptyUnlocked => 'まだ獲得したバッジがありません。';

  @override
  String get achievementEmptyLocked => '全てのバッジを獲得しました。';

  @override
  String get achievementHeroTitle => '実績コレクション';

  @override
  String achievementHeroProgress(int unlocked, int total) {
    return '獲得 $unlocked / 全 $total';
  }

  @override
  String get achievementHeroAllUnlocked => '全バッジを集めました。素晴らしい！';

  @override
  String get achievementHeroKeepGoing => 'プレイを続けてバッジを解除しましょう。';

  @override
  String get achievementBadgeFirstClearTitle => '初クリア';

  @override
  String get achievementBadgeFirstClearDesc => '最初のパズルをクリアして数独の旅を始めましょう。';

  @override
  String get achievementBadgeStreakTitle => '3日連続';

  @override
  String get achievementBadgeStreakDesc => '3日連続でパズルをクリアしてリズムを作りましょう。';

  @override
  String get achievementBadgeWeeklyTitle => 'ウィークリーランナー';

  @override
  String get achievementBadgeWeeklyDesc => '直近7日間で5問クリアして継続を証明しましょう。';

  @override
  String get achievementBadgePerfectTitle => 'パーフェクトクリア';

  @override
  String get achievementBadgePerfectDesc => 'ミスなしで1問クリアすると獲得します。';

  @override
  String get achievementBadgeMasterTitle => 'マスター初勝利';

  @override
  String get achievementBadgeMasterDesc => 'マスター難易度を初めてクリアすると解除されます。';

  @override
  String achievementProgressFraction(int current, int max) {
    return '$current/$max';
  }

  @override
  String achievementProgressStreak(int current, int max) {
    return '$current/$max日';
  }

  @override
  String achievementProgressWeekly(int current, int max) {
    return '$current/$max回';
  }

  @override
  String get achievementStatusDone => '完了';

  @override
  String get achievementStatusNotMet => '未達成';

  @override
  String get achievementStatusTrying => '挑戦中';

  @override
  String achievementTileProgress(String label) {
    return '進捗: $label';
  }

  @override
  String achievementTileRarity(String label) {
    return 'レアリティ: $label';
  }

  @override
  String get achievementRarityCommon => 'コモン';

  @override
  String get achievementRarityRare => 'レア';

  @override
  String get achievementRarityEpic => 'エピック';

  @override
  String get achievementSortDefault => 'デフォルト順';

  @override
  String get achievementSortRarity => 'レアリティ順';

  @override
  String get commonSave => '保存';

  @override
  String get settingsDisplaySection => 'ディスプレイ';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeSystem => 'システム';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get profileEditorTitle => 'プロフィール編集';

  @override
  String get profileEditorRemovePhoto => '写真を削除';

  @override
  String get profileEditorNameLabel => '名前';

  @override
  String get profileEditorDefaultProfile => 'デフォルトプロフィール';

  @override
  String get profileEditorDefaultProfileDesc => 'アプリのデフォルト画像で開始';

  @override
  String get profileEditorPickFromAlbum => 'アルバムから選択';

  @override
  String get profileEditorPickFromAlbumDesc => '自分の写真をプロフィールに設定';

  @override
  String get homeTodayLabel => '今日';

  @override
  String get homeTodayPuzzleTitle => '静かに集中するひとときです。';

  @override
  String get homeTodayChallengeStartButton => '今日のチャレンジを始める';

  @override
  String get homeTodayChallengeResumeButton => '今日のチャレンジを続ける';

  @override
  String get homeTodayChallengeReviewButton => '今日のパズルをもう一度';

  @override
  String get homeTodayChallengeLoadError => '今日のパズルを読み込めませんでした。';

  @override
  String get homeTodayChallengeDateChanged => '日付が変わったため、今日のチャレンジを更新しました。';

  @override
  String get homeFirstStartTitle => '最初のパズルを始めましょう';

  @override
  String get homeNewPuzzleTitle => '新しいパズルを始めましょう';

  @override
  String get homeChooseLevelBody => 'レベルを選んでください。進行状況は自動で保存されます。';

  @override
  String get homeChooseLevelButton => 'レベルを選ぶ';

  @override
  String homeViewAllInProgress(int count) {
    return '進行中のゲームをすべて見る ($count)';
  }

  @override
  String get homeNewGameSectionTitle => '新しいゲーム · レベルを選択';

  @override
  String homeLevelBlankCells(int count) {
    return '空きマス $count個';
  }

  @override
  String get homeSavedGamesTitle => '進行中のゲーム';

  @override
  String get homeSavedGamesDescription =>
      '続きから解くゲームを選びます。削除してもクリア記録は残り、保存した途中経過のみ消えます。';

  @override
  String get homeSavedGameDeleteTooltip => '保存した途中経過を削除';

  @override
  String get homeSavedGameDeleteTitle => '保存した途中経過を削除しますか？';

  @override
  String get homeSavedGameDeleteBody => 'このパズルの入力とメモが削除されます。クリア記録は残ります。';

  @override
  String get homeSavedGameDeleteConfirm => '削除';

  @override
  String get homeLoadError => 'ゲーム情報を読み込めませんでした。';

  @override
  String get homeCatalogFirstTitle => '初めてのパズルセットを準備中です';

  @override
  String get homeCatalogFirstBody => '初回起動時にパズルをデバイスに保存します。次回からはずっと速く起動できます。';

  @override
  String get homeCatalogFirstNote => '準備はバックグラウンドで続きます。そのまま探索できます。';

  @override
  String get homeCatalogFirstContinue => 'ホームへ続ける';

  @override
  String homeLevelProgressSolved(int cleared, int total) {
    return '$cleared / $total';
  }

  @override
  String get levelFilterAll => '全て';

  @override
  String get levelFilterNew => '新規';

  @override
  String get levelFilterInProgress => '進行中';

  @override
  String get levelFilterDone => '完了';

  @override
  String levelProgressCardMessage(String levelName) {
    return '今日は$levelNameのパズルから始めましょう';
  }

  @override
  String levelProgressCompleted(int total) {
    return '/ $total クリア';
  }

  @override
  String levelPuzzleListTitle(int count) {
    return 'パズル一覧 · $count';
  }

  @override
  String get levelRecentBadge => '最近';

  @override
  String get levelStatusInProgress => '進行中';

  @override
  String get levelNoResults => '該当なし';

  @override
  String get levelReplayTitle => 'このパズルをもう一度解きますか？';

  @override
  String get levelReplayBody => '完了記録は保持され、より良い結果の場合のみ更新されます。';

  @override
  String get levelReplayConfirm => '再挑戦';

  @override
  String levelInProgressLimitTitle(int maxCount) {
    return '進行中のパズルが$maxCount件あります';
  }

  @override
  String levelInProgressLimitBody(int maxCount) {
    return '最大$maxCount個まで一緒に進められます。\n下から1つ選んで続きを解きましょうか？';
  }

  @override
  String get levelInProgressLimitLater => '後でする';

  @override
  String get levelTryAgain => 'もう一度';

  @override
  String get levelContinueButton => '続きから解く';

  @override
  String levelStartNextNew(String number) {
    return '次の新しいパズルを始める · $number';
  }

  @override
  String levelViewInProgress(int count) {
    return '進行中 $count件を見る';
  }

  @override
  String get levelNotesInProgress => 'メモ作成中';

  @override
  String get levelEmptyInProgress => '続きから解くパズルはありません。';

  @override
  String get levelEmptyCompleted => '最初のクリア記録を作りましょう。';

  @override
  String get levelEmptyFresh => '新しく始められるパズルはありません。';

  @override
  String get levelAllCompleted => 'このレベルのパズルをすべてクリアしました。';

  @override
  String get levelActionShowNew => '新しいパズルを見る';

  @override
  String get levelActionShowInProgress => '進行中を見る';

  @override
  String get levelActionShowAll => 'すべて見る';

  @override
  String levelBestTime(String time) {
    return 'ベスト $time';
  }

  @override
  String levelCellSemantics(String number, String status) {
    return 'パズル $number、$status';
  }

  @override
  String get gameResetDialogTitle => '最初からやり直す';

  @override
  String get gameResetDialogBody =>
      '入力した数字、メモ、ヒント、ミス回数、時間をすべて消して最初の状態に戻しますか？これまでのクリア記録は残ります。';

  @override
  String get gameResetConfirm => 'やり直す';

  @override
  String get gameNumberInputLegend => '小さい数字は残り個数、チェックは完了した数字です。';

  @override
  String get dialogSuggestedNextStep => '次のステップ';

  @override
  String get dialogSetTomorrowReminder => '明日のリマインドを設定';

  @override
  String get dialogTryAnotherLevel => '別の難易度を試す';

  @override
  String get savedGamesSortRecent => '最近';

  @override
  String get savedGamesSortProgress => '進捗順';

  @override
  String get savedGamesSortPlayTime => 'プレイ時間順';

  @override
  String get savedGamesEmpty => 'この条件に一致する保存済みゲームはありません。';

  @override
  String get savedGamesDeleteFailed => '削除できませんでした。もう一度お試しください。';

  @override
  String get recordsMyRecordTitle => '私の記録';

  @override
  String get recordsSummaryTotalCleared => 'クリアしたパズル';

  @override
  String get recordsSummaryPerfectClears => 'ミスなしクリア';

  @override
  String get challengeMonthlyDescription => '日付を選んで過去のチャレンジをもう一度プレイできます。';

  @override
  String get challengeTodayEyebrow => '今日の流れ';

  @override
  String get gamePausedTitle => '一時停止中';

  @override
  String get gamePausedBody => 'タイマーを止めて、盤面を隠しています。';

  @override
  String homeStreakChip(int count) {
    return '$count日';
  }

  @override
  String homeStreakActive(int count) {
    return '$count日連続でパズルをクリアしました';
  }

  @override
  String homeStreakAtRisk(int count) {
    return '$count日連続中です。今日1局クリアすると記録が続きます。';
  }

  @override
  String get hintStepLookTitle => 'ヒント・注目する場所';

  @override
  String get hintLookCell => '強調されたマスの行・列・ブロックを見てください。';

  @override
  String hintLookBox(int value) {
    return '強調されたブロックで $value が入る場所を探してください。';
  }

  @override
  String hintLookRow(int value) {
    return '強調された行で $value が入る場所を探してください。';
  }

  @override
  String hintLookCol(int value) {
    return '強調された列で $value が入る場所を探してください。';
  }

  @override
  String get hintMovedFromSelection => '選んだマスより先に解ける場所があります。';

  @override
  String get hintTechniqueNakedSingle => 'ネイキッドシングル';

  @override
  String get hintTechniqueHiddenSingle => 'ヒドゥンシングル';

  @override
  String get hintTechniqueReveal => '答え';

  @override
  String hintExplainNakedSingle(int value) {
    return 'このマスの行・列・ブロックには他の8つの数字がすべてあります。入るのは $value だけです。';
  }

  @override
  String hintExplainHiddenSingleBox(int value) {
    return 'このブロックで $value が入るのはこのマスだけです。他の空きマスは、強調された $value と同じ行か列にあります。';
  }

  @override
  String hintExplainHiddenSingleRow(int value) {
    return 'この行で $value が入るのはこのマスだけです。他の空きマスは、強調された $value と同じ列かブロックにあります。';
  }

  @override
  String hintExplainHiddenSingleCol(int value) {
    return 'この列で $value が入るのはこのマスだけです。他の空きマスは、強調された $value と同じ行かブロックにあります。';
  }

  @override
  String get hintExplainReveal => 'このマスにはより高度な手筋が必要です。下のボタンで答えを入れられます。';

  @override
  String get hintNextStep => 'もっと詳しく';

  @override
  String get hintFillAnswer => '答えを入れる';

  @override
  String get hintClose => 'ヒントを閉じる';

  @override
  String get notificationOptInTitle => '毎日1局をお知らせしましょうか？';

  @override
  String get notificationOptInBody =>
      '毎晩8時にまだパズルを解いていなければお知らせします。設定でいつでもオフにできます。';

  @override
  String get notificationOptInAccept => '通知を受け取る';

  @override
  String get notificationOptInLater => 'あとで';

  @override
  String get notificationOptInDenied =>
      '通知が許可されていません。端末の設定で許可してから、設定で通知をオンにできます。';

  @override
  String get notificationSetupFailed => '通知を設定できませんでした。しばらくしてから設定でもう一度お試しください。';

  @override
  String get beginnerTutorialPromptTitle => '数独は初めてですか?';

  @override
  String get beginnerTutorialPromptBody => '問題を解く前に短いガイド練習をしてみましょう。１分で終わります。';

  @override
  String get beginnerTutorialStart => 'ガイドを始める';

  @override
  String get beginnerTutorialSkip => 'スキップ';

  @override
  String beginnerTutorialStepIndicator(int current, int total) {
    return 'ステップ $current/$total';
  }

  @override
  String get beginnerTutorialStepRowTitle => 'ルール: 横の列';

  @override
  String get beginnerTutorialStepRowBody => '各横の列には1から9までの数字が1回ずつ入ります。';

  @override
  String get beginnerTutorialStepColumnTitle => 'ルール: 縦の列';

  @override
  String get beginnerTutorialStepColumnBody => '縦の列にも1から9までの数字が1回ずつ入ります。';

  @override
  String get beginnerTutorialStepBoxTitle => 'ルール: 3×3のブロック';

  @override
  String get beginnerTutorialStepBoxBody => '3×3のブロックにも1から9までの数字が1回ずつ入ります。';

  @override
  String get beginnerTutorialStepInputTitle => '数字を入力する';

  @override
  String get beginnerTutorialStepInputBody =>
      '強調されたマスに入る数字は1つだけです。マスをタップしてから正しい数字をタップしましょう。';

  @override
  String get beginnerTutorialStepInputWrongHint =>
      'その数字は同じ列やブロックにすでにあります。別の数字を試してください。';

  @override
  String get beginnerTutorialStepMemoTitle => 'メモと消去';

  @override
  String get beginnerTutorialStepMemoAddBody =>
      'メモモードをオンにしてこのマスをタップし、候補の数字をタップしてメモしましょう。';

  @override
  String get beginnerTutorialStepMemoEraseBody => '同じ数字をもう一度タップしてメモを消しましょう。';

  @override
  String get beginnerTutorialStepHintTitle => 'ヒント';

  @override
  String get beginnerTutorialStepHintBody =>
      'ヒントをタップすると、実際のヒント回数を消費せずに、どこを見るべきか教えてくれます。';

  @override
  String get beginnerTutorialStepHintButton => 'ヒントを開く';

  @override
  String get beginnerTutorialStepDoneTitle => '準備完了!';

  @override
  String get beginnerTutorialStepDoneBody =>
      '行・列・ブロックのルール、数字の入力、メモ、ヒントの基本を学びました。';

  @override
  String get beginnerTutorialFirstPuzzleButton => '最初の問題を始める';

  @override
  String get beginnerTutorialNextButton => '次へ';

  @override
  String get beginnerTutorialCloseButton => '完了';

  @override
  String get settingsHowToPlayTitle => '遊び方';

  @override
  String get settingsHowToPlaySubtitle => 'ガイドチュートリアルをもう一度見る';

  @override
  String get autoNotesConfirmTitle => 'すべてのメモを再計算しますか?';

  @override
  String get autoNotesConfirmBody =>
      '空白マスのメモが現在の候補ですべて置き換わります。手で削除した候補も再び表示されることがあります。';

  @override
  String get autoNotesConfirmApply => 'メモを再計算';

  @override
  String get autoNotesContradictionMessage =>
      '候補が一つも残らないマスがあるため、メモを入力できませんでした。入力内容を確認してもう一度試してください。';

  @override
  String get autoNotesTipMessage => 'ヒント: メモを長押しすると候補数字を一括で入力できます。';

  @override
  String get gameMemoLongPressHint => 'タップでメモモード切り替え、長押しで自動メモ。';

  @override
  String get challengeMonthlyTitle => 'チャレンジ履歴';

  @override
  String get challengePreviousMonth => '前の月';

  @override
  String get challengeBackToCurrentMonth => '今月';

  @override
  String get challengeStatusNotCompleted => '未完了';

  @override
  String get challengeStatusInProgress => '進行中';

  @override
  String get challengeStatusCompleted => '完了';

  @override
  String get challengeStatusPerfect => 'パーフェクトクリア';

  @override
  String get challengeStatusFuture => 'まだ利用できません';

  @override
  String get challengeMonthComplete => '月間完了';

  @override
  String get challengeStartPastChallenge => '過去のチャレンジを始める';

  @override
  String get challengeResumePastChallenge => '過去のチャレンジを再開';

  @override
  String get challengeRetryPastChallenge => '過去のチャレンジをもう一度解く';

  @override
  String get challengePuzzleLoadFailed => 'この問題を読み込めませんでした。';

  @override
  String get challengeCalendarLoadError => 'チャレンジカレンダーを読み込めません。';

  @override
  String get challengeStreakExcludedNote => '過去のチャレンジ完了は連続記録に含まれません';

  @override
  String challengeDayCellSemantics(String date, String status) {
    return '$date、$status';
  }

  @override
  String get homeGreetingMorning => 'さあ、一局始めましょう。';

  @override
  String get homeGreetingAfternoon => '集中して一局、いかがですか。';

  @override
  String get homeGreetingEvening => '静かにパズルで締めくくりましょう。';

  @override
  String get levelNoPuzzlesAvailable => 'このレベルのパズルはありません。';

  @override
  String get levelLastPlayedToday => '今日';

  @override
  String get levelLastPlayedYesterday => '昨日';

  @override
  String levelLastPlayedDaysAgo(int count) {
    return '$count日前';
  }
}
