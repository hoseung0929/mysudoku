// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'マイ数独';

  @override
  String get navHome => 'ホーム';

  @override
  String get navChallenge => 'チャレンジ';

  @override
  String get navRecords => '記録';

  @override
  String get navSettings => '設定';

  @override
  String get recordsScreenTitle => '記録 · 統計';

  @override
  String get challengeScreenTitle => 'チャレンジ';

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
  String get shareSubject => 'My Sudoku 結果';

  @override
  String get shareClearHeader => 'My Sudoku クリア';

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
  String get dialogBackToLevels => 'レベル一覧';

  @override
  String get dialogPlayAgain => 'もう一度';

  @override
  String get dialogNextPuzzle => '次のパズル';

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
  String get settingsAboutDeveloperNote => 'マイ数独をお楽しみください！';

  @override
  String get settingsPrivacyDialogTitle => 'プライバシー';

  @override
  String get settingsPrivacyDialogBody =>
      'このアプリはゲームの進行、記録、プロフィール情報、アプリ設定をこのデバイスにのみ保存します。アカウントは不要で、サーバーへの個人情報の収集は行いません。プロフィール画像を選択する場合、写真ライブラリへのアクセスはデバイス上での画像の選択と保存にのみ使用されます。通知設定もローカルに保存されます。アプリをアンインストールすると、デバイスのバックアップがない限りローカルデータが削除される場合があります。';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get gameOverTitle => 'ゲームオーバー';

  @override
  String get gameOverMessage => 'ミスが3回を超えました。';

  @override
  String gameOverWrongLabel(int count) {
    return 'ミス: $count/3';
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
  String get recordsHeroTitle => '積み上げてきた流れを\n落ち着いて眺めてみましょう。';

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
  String get recordsMetricClearRate => '全体進捗率';

  @override
  String get recordsMetricPerfectRate => 'パーフェクト率';

  @override
  String get recordsSummaryMetricsFootnote =>
      'クリア数はフィルターを反映しています。全体進捗率は同じ範囲で解いたパズル数を全パズル数と比較した値です。';

  @override
  String get recordsMetricAvgTime => '平均タイム';

  @override
  String get recordsMetricAvgWrong => '平均ミス';

  @override
  String get recordsByLevelTitle => 'レベル別統計';

  @override
  String get recordsByLevelEmpty => '表示するレベル統計がありません。';

  @override
  String get recordsByLevelSectionSubtitle => '難易度別にどのレベルで成長を感じているか確認できます。';

  @override
  String get recordsLevelInfographicClearRate => 'クリア率';

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
  String get recordsStatsPageSubtitle => 'クリアと平均タイムを一目で確認できます。';

  @override
  String get recordsKpiWeeklyClearsLabel => 'クリア';

  @override
  String get recordsKpiAvgSolveTimeLabel => '平均タイム';

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
  String get recordsStatsHeroHeadline => '直近7日間の数独記録を\n一目で確認しましょう。';

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
  String get challengeLoadError => 'チャレンジ情報を読み込めません。';

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
  String get challengeWeeklyGoalReachedTitle => '今週の目標を達成しました';

  @override
  String challengeWeeklyGoalRemainingTitle(int count) {
    return '週間目標まであと $count回';
  }

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
  String get challengeWeeklyGoalHeading => '週間目標';

  @override
  String challengeWeeklyClearsLine(int count) {
    return '今週 $count回クリア';
  }

  @override
  String challengeWeeklyProgressShort(int done, int target) {
    return '$done/$target 完了';
  }

  @override
  String challengeWeeklyPerfectShort(int count) {
    return 'パーフェクト $count回';
  }

  @override
  String get challengeWeeklyCongratsFooter => '週間目標達成！引き続き記録を積み上げましょう！';

  @override
  String challengeWeeklyAlmostFooter(int count) {
    return '週間目標まであと $count回です。';
  }

  @override
  String get challengeAchievementsHeading => '実績 · バッジ';

  @override
  String challengeBadgesCollected(int unlocked, int total) {
    return '獲得 $unlocked/$total';
  }

  @override
  String get challengeViewAllBadges => '全て見る';

  @override
  String get challengeEarnedBadgesHeading => '獲得したバッジ';

  @override
  String get challengeNextBadgeTargets => '次の目標';

  @override
  String challengeBadgeProgressLine(String desc, String progress) {
    return '$desc 進捗: $progress';
  }

  @override
  String challengeStreakDays(int days) {
    return '$days日連続クリア';
  }

  @override
  String get challengeStreakStartToday => '今日の初クリアに挑戦';

  @override
  String get challengeTabHeroHeadline => '今日のパズルと週間リズムを\nひとつの画面で。';

  @override
  String get challengeHeroPendingDetail => 'ホームのカードからプレイを始められます。';

  @override
  String get challengeHeroDoneDetail =>
      '今日のチャレンジは完了しました。バッジと週間進捗はこのタブにまとめてあります。';

  @override
  String get challengeOpenTodayOnHomeButton => 'ホームで今日のパズルを開く';

  @override
  String get challengeHeroDoneCaption => '今日のチャレンジを完了しました。明日も続けて記録を積み上げましょう。';

  @override
  String get challengeHeroPendingCaption =>
      '今日のチャレンジがまだ残っています。今すぐ始めてストリークを続けましょう。';

  @override
  String get homeGuestTitle => 'ゲスト';

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
}
