// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Sudoku159';

  @override
  String get navHome => '홈';

  @override
  String get navChallenge => '챌린지';

  @override
  String get navRecords => '기록';

  @override
  String get navSettings => '설정';

  @override
  String get recordsHeroImageSubtitle => '차곡차곡 쌓이는 나의 기록';

  @override
  String get settingsHeroSubtitle => '나에게 맞게 설정해요';

  @override
  String get recordsScreenTitle => '기록 · 통계';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionNotifications => '알림';

  @override
  String get settingsSectionLanguage => '언어';

  @override
  String get settingsSectionGame => '게임';

  @override
  String get settingsSectionInfo => '정보';

  @override
  String get settingsNotificationsTitle => '알림 설정';

  @override
  String get settingsNotificationsSubtitle => '오늘의 도전을 아직 끝내지 않았을 때 리마인드를 보냅니다';

  @override
  String get settingsStreakReminderTitle => '연속 플레이 리마인드';

  @override
  String get settingsStreakReminderSubtitle =>
      '연속 기록이 있을 때 한 번 더 이어서 플레이를 알려줍니다';

  @override
  String get settingsNotificationTimeTitle => '알림 시간';

  @override
  String get settingsNotificationTimeSubtitle => '알림을 받을 시간을 설정합니다';

  @override
  String get settingsNotificationsPermissionDenied =>
      '알림 권한이 허용되지 않아 리마인드를 켤 수 없어요.';

  @override
  String get settingsLanguageTitle => '언어 설정';

  @override
  String get settingsLanguageSubtitle => '앱 언어를 변경합니다';

  @override
  String get settingsLanguageSystem => '시스템 따라가기';

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
  String get settingsLanguagePickerTitle => '언어 선택';

  @override
  String get settingsVibrationTitle => '입력 진동';

  @override
  String get settingsVibrationSubtitle => '숫자 입력 시 진동 피드백을 사용합니다';

  @override
  String get settingsKeepScreenAwakeTitle => '화면 깨우기 유지';

  @override
  String get settingsKeepScreenAwakeSubtitle => '게임 화면이 자동으로 꺼지지 않도록 유지합니다';

  @override
  String get settingsOneHandModeTitle => '한 손 모드';

  @override
  String get settingsOneHandModeSubtitle => '모바일 게임 화면의 버튼과 간격을 더 조밀하게 표시합니다';

  @override
  String get settingsMemoHighlightTitle => '메모 탐색 강조';

  @override
  String get settingsMemoHighlightSubtitle => '메모 후보, 포커스 숫자, 유일 후보 강조를 표시합니다';

  @override
  String get settingsSmartHintTitle => '완성 가능 칸 강조';

  @override
  String get settingsSmartHintSubtitle => '규칙상 바로 넣을 수 있는 칸을 약하게 강조합니다';

  @override
  String get settingsAppInfoTitle => '앱 정보';

  @override
  String get settingsAppInfoSubtitle => '앱 버전 및 개발자 정보';

  @override
  String get settingsPrivacyTitle => '개인정보처리방침';

  @override
  String get settingsPrivacySubtitle => '개인정보 수집 및 이용에 관한 안내';

  @override
  String get settingsTabletNotificationsHeader => '알림 설정';

  @override
  String get settingsTabletNotificationsBody => '게임 알림을 관리하고 설정할 수 있습니다.';

  @override
  String get settingsGameCompleteNotifTitle => '게임 완료 알림';

  @override
  String get settingsGameCompleteNotifSubtitle => '게임을 완료했을 때 알림을 받습니다';

  @override
  String get settingsDailyGoalNotifTitle => '일일 목표 알림';

  @override
  String get settingsDailyGoalNotifSubtitle => '주간 목표를 막 달성했을 때 축하 알림을 받습니다';

  @override
  String get settingsHintNotifTitle => '힌트 사용 알림';

  @override
  String get settingsHintNotifSubtitle => '힌트를 사용할 때 알림을 받습니다';

  @override
  String get levelBeginner => '초급';

  @override
  String get levelIntermediate => '중급';

  @override
  String get levelAdvanced => '고급';

  @override
  String get levelExpert => '전문가';

  @override
  String get levelMaster => '마스터';

  @override
  String get levelDescBeginner => '스도쿠를 처음 시작하는 분들을 위한 레벨';

  @override
  String get levelDescIntermediate => '기본적인 스도쿠 규칙을 아는 분들을 위한 레벨';

  @override
  String get levelDescAdvanced => '스도쿠에 익숙한 분들을 위한 레벨';

  @override
  String get levelDescExpert => '스도쿠 마스터를 위한 레벨';

  @override
  String get levelDescMaster => '최고의 스도쿠 도전';

  @override
  String gameNumberLabel(int number) {
    return '게임 $number';
  }

  @override
  String get gameHintShort => '힌트';

  @override
  String get gameUndoShort => '되돌리기';

  @override
  String get gameRedoShort => '다시실행';

  @override
  String get gameMemoShort => '메모';

  @override
  String gameCellLabel(int row, int col, String content) {
    return '$row행 $col열: $content';
  }

  @override
  String get gameCellEmpty => '비어 있음';

  @override
  String gameCellNotes(String notes) {
    return '메모 $notes';
  }

  @override
  String get gameCellGiven => '고정 숫자';

  @override
  String get gameCellHint => '힌트';

  @override
  String get gameCellWrong => '오답';

  @override
  String get gameEraseShort => '지우기';

  @override
  String get gameMoreOptions => '더보기';

  @override
  String get gameMemoOnShort => '메모 ON';

  @override
  String get gameMemoStateOn => 'ON';

  @override
  String get gameMemoStateOff => 'OFF';

  @override
  String get gameMemoFocusShort => '탐색';

  @override
  String get gameMemoFocusIdle => '없음';

  @override
  String get gameWrongShort => '오답';

  @override
  String get gamePerfectShort => '퍼펙트';

  @override
  String get gamePerfectReady => '유지 중';

  @override
  String get gamePerfectMissed => '깨짐';

  @override
  String get gameProgressShort => '진행률';

  @override
  String get gameTimeShort => '시간';

  @override
  String get gameNumberInputTitle => '숫자 입력';

  @override
  String get gameLineWaveRowLabel => '가로줄';

  @override
  String get gameLineWaveColLabel => '세로줄';

  @override
  String get gameLineWaveBoxLabel => '3×3 박스';

  @override
  String gameLineWaveAnnounce(String parts) {
    return '$parts 완성';
  }

  @override
  String get gameLineWaveRowSentence => '가로줄을 완성했어요';

  @override
  String get gameLineWaveColSentence => '세로줄을 완성했어요';

  @override
  String get gameLineWaveBoxSentence => '3×3 박스를 완성했어요';

  @override
  String gameDigitCompleteSentence(int number) {
    return '숫자 $number를 모두 채웠어요';
  }

  @override
  String get gamePause => '일시정지';

  @override
  String get gameResume => '계속';

  @override
  String get gameAnswerPreview => '정답';

  @override
  String get challengeCompletedToday => '오늘의 도전을 완료했어요.';

  @override
  String get shareCopySuccess => '결과 문구를 복사했어요.';

  @override
  String get shareSubject => 'Sudoku159 결과';

  @override
  String get shareClearHeader => 'Sudoku159 완료';

  @override
  String shareClearLine(String level, int number) {
    return '$level · 게임 $number';
  }

  @override
  String shareClearStats(String time, int wrong) {
    return '기록 $time · 오답 $wrong회';
  }

  @override
  String get shareClearTags => '#Sudoku159 #SudokuChallenge';

  @override
  String shareSummaryPattern(String time, int wrong) {
    return '$time · 오답 $wrong회';
  }

  @override
  String get dialogCongratulations => '축하합니다!';

  @override
  String get dialogNewBest => 'NEW BEST';

  @override
  String get dialogSudokuComplete => '스도쿠를 완성했습니다!';

  @override
  String get dialogNewBadges => '새 배지 획득';

  @override
  String get dialogElapsedTime => '소요 시간';

  @override
  String get dialogWrongCount => '오답 횟수';

  @override
  String dialogWrongCountValue(int count) {
    return '$count회';
  }

  @override
  String get dialogSharePreview => '공유용 결과';

  @override
  String get dialogCopyResult => '결과 복사';

  @override
  String get dialogShare => '공유하기';

  @override
  String get dialogBackToLevels => '퍼즐 목록으로';

  @override
  String get dialogPlayAgain => '다시 풀기';

  @override
  String get dialogPuzzleCompleteTitle => '퍼즐을 완성했어요';

  @override
  String get dialogNewBestMessage => '새로운 최고 기록이에요';

  @override
  String dialogHintsUsed(int count) {
    return '힌트 $count회 사용';
  }

  @override
  String dialogCompletionTimeSentenceMinutes(int minutes, int seconds) {
    return '$minutes분 $seconds초 만에 풀었어요';
  }

  @override
  String dialogCompletionTimeSentenceSeconds(int seconds) {
    return '$seconds초 만에 풀었어요';
  }

  @override
  String get dialogCompletionNoMistakes => '실수 없이 마무리했어요';

  @override
  String dialogCompletionMistakeCount(num count) {
    return '실수는 $count번 있었어요';
  }

  @override
  String get dialogSolveSameAgain => '같은 퍼즐 다시 풀기';

  @override
  String get dialogNextPuzzle => '다음 퍼즐';

  @override
  String get updateRequiredTitle => '업데이트가 필요합니다';

  @override
  String get updateRequiredMessage => '새로운 버전이 출시되었습니다.\n계속 플레이하려면 업데이트해 주세요.';

  @override
  String get updateNowButton => '지금 업데이트';

  @override
  String get settingsNotificationsComingSoonTitle => '알림';

  @override
  String get settingsNotificationsComingSoonBody =>
      '푸시 알림 및 알림 세부 설정은 이후 업데이트에서 제공될 예정입니다.';

  @override
  String get settingsAboutDialogTitle => '앱 정보';

  @override
  String settingsAboutVersionLabel(String version) {
    return '버전 $version';
  }

  @override
  String get settingsAboutDeveloperNote => 'Sudoku159를 즐겨 주세요!';

  @override
  String get settingsAboutSupportEmail => '· team929.support@gmail.com';

  @override
  String get commonOk => '확인';

  @override
  String get commonCancel => '취소';

  @override
  String get gameOverTitle => '실수 한도에 도달했어요';

  @override
  String get gameOverMessage => '처음부터 다시 풀거나 다른 퍼즐을 선택할 수 있어요.';

  @override
  String gameOverWrongLabel(int count, int maxCount) {
    return '이번 게임: 실수 $count회 / 한도 $maxCount회';
  }

  @override
  String get recordsFilterSectionTitle => '필터';

  @override
  String get recordsFilterAllLevels => '전체';

  @override
  String get recordsPeriodLabel => '기간';

  @override
  String get recordsPeriodAll => '전체 기간';

  @override
  String recordsPeriodLastDays(int days) {
    return '최근 $days일';
  }

  @override
  String get recordsSummaryTitle => '지난 7일';

  @override
  String get recordsTrendTitle => '최근 7일 추세';

  @override
  String get recordsTrendEmpty => '최근 7일 추세를 만들 기록이 없습니다.';

  @override
  String get recordsTrendClears => '클리어 수';

  @override
  String get recordsTrendWindowAvgTime => '평균 시간 (같은 기간)';

  @override
  String get recordsTrendWindowAvgWrong => '평균 실수 (같은 기간)';

  @override
  String get recordsHeroBadgeFlow => '흐름';

  @override
  String get recordsHeroTitle => '차분하게 쌓인 흐름을 먼저 살펴보세요.';

  @override
  String get recordsHeroSubtitle =>
      '위에는 같은 7일을 부드럽게 표현했어요. 아래 카드에서 날짜별 클리어 수를 확인할 수 있어요.';

  @override
  String get recordsInsightThisWeekEyebrow => '이번 주의 발자국';

  @override
  String recordsInsightClearsValue(int count) {
    return '$count회';
  }

  @override
  String get recordsInsightAvgPaceEyebrow => '평균 호흡';

  @override
  String get recordsTrendSectionSubtitle =>
      '최근 일주일 동안 날짜별 클리어 수를 한눈에 보는 요약이에요.';

  @override
  String get recordsTrendLegendDailyClears => '일별 클리어';

  @override
  String get recordsTrendTodayLabel => '오늘';

  @override
  String get recordsPlayInsightsTitle => '이번 주 활동';

  @override
  String get recordsWeekSubtitle => '요일을 눌러 기록을 확인하세요';

  @override
  String get recordsWeeklyGoalLabel => '이번 주 목표';

  @override
  String recordsWeeklyGoalProgress(int done, int goal) {
    String _temp0 = intl.Intl.pluralLogic(
      goal,
      locale: localeName,
      other: '$done / $goal판',
    );
    return '$_temp0';
  }

  @override
  String get recordsWeeklyGoalStart => '이번 주 첫 퍼즐을 시작해보세요';

  @override
  String recordsWeeklyGoalRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count판만 더 완료하면 목표를 달성해요',
    );
    return '$_temp0';
  }

  @override
  String get recordsWeeklyGoalAchieved => '이번 주 목표를 달성했어요';

  @override
  String get gameResultWeeklyGoalAchieved => '이번 주 목표를 달성했어요';

  @override
  String get recordsPlayCalendarTitle => '요일별';

  @override
  String get recordsWeeklyReportTitle => '이번 주 리포트';

  @override
  String get recordsWeeklyReportBusiestDay => '가장 많이 플레이한 날';

  @override
  String recordsWeeklyReportTopDayValue(String day, int count) {
    return '$day, $count회';
  }

  @override
  String get recordsWeeklyReportTopDayFallback => '아직 클리어가 없어요';

  @override
  String get recordsTimelineTitle => '최근 플레이 타임라인';

  @override
  String get recordsTimelineEmpty => '최근 클리어가 생기면 여기에 차곡차곡 보여드릴게요.';

  @override
  String recordsTimelineMistakesValue(int count) {
    return '실수 $count회';
  }

  @override
  String get recordsTimelinePerfect => '퍼펙트 클리어';

  @override
  String get recordsPaceTitle => '나의 페이스 변화';

  @override
  String get recordsPaceEmpty => '이전 일주일과 비교하려면 기록이 조금 더 쌓여야 해요.';

  @override
  String get recordsPaceRecentWindow => '최근 7일';

  @override
  String get recordsPacePreviousWindow => '이전 7일';

  @override
  String get recordsPaceDelta => '변화';

  @override
  String get recordsMetricClears => '클리어 (필터)';

  @override
  String get recordsMetricClearRate => '완료한 퍼즐';

  @override
  String get recordsMetricPerfectRate => '실수 없이 완료한 비율';

  @override
  String get recordsSummaryMetricsFootnote =>
      '퍼즐마다 최고 기록 한 건만 세고, 기간·난이도 필터를 반영해요. 완료 현황은 같은 범위의 전체 퍼즐 수와 비교한 값이에요.';

  @override
  String get recordsMetricAvgTime => '평균 완료 시간';

  @override
  String get recordsMetricAvgWrong => '평균 실수';

  @override
  String get recordsByLevelTitle => '난이도별 기록';

  @override
  String get recordsByLevelSubtitle => '난이도를 선택해 기록을 비교해보세요';

  @override
  String get recordsByLevelEmpty => '표시할 레벨 통계가 없습니다.';

  @override
  String get recordsByLevelSectionSubtitle =>
      '난이도별로 어느 구간에서 가장 편안해졌는지 볼 수 있어요.';

  @override
  String get recordsLevelInfographicClearRate => '퍼즐 완료 현황';

  @override
  String get recordsLevelMiniBest => '베스트';

  @override
  String get recordsLevelMiniPerfectRate => '퍼펙트율';

  @override
  String get recordsLevelMiniAvgWrong => '평균 실수';

  @override
  String get recordsStatsLoadError => '통계 데이터를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get recordsRetry => '다시 시도';

  @override
  String get recordsEmptyAction => '퍼즐 시작하기';

  @override
  String get recordsLevelEmpty => '이 난이도에서 완료한 퍼즐이 아직 없어요.';

  @override
  String get recordsRowBestTime => '가장 빠른 기록';

  @override
  String get recordsAverageBasisNote => '평균은 퍼즐별 최고 기록 기준이에요.';

  @override
  String recordsCalendarTitle(int weeks) {
    return '최근 $weeks주 활동';
  }

  @override
  String get recordsCalendarSubtitle => '완료한 날짜와 플레이 빈도를 확인하세요';

  @override
  String recordsOverallNote(int cleared, int total) {
    return '전체 난이도에서 $total개 중 $cleared개를 완료했어요.';
  }

  @override
  String recordsWeekActiveDays(int count) {
    return '활동 $count일';
  }

  @override
  String recordsWeekCompletions(int count) {
    return '완료 $count판';
  }

  @override
  String recordsWeekDayDone(String day, int count) {
    return '$day: $count판 완료';
  }

  @override
  String recordsWeekDayNone(String day) {
    return '$day: 완료 없음';
  }

  @override
  String get recordsStatsPageSubtitle => '클리어와 평균 시간을 한눈에 봐요.';

  @override
  String get recordsKpiWeeklyClearsLabel => '완료한 퍼즐';

  @override
  String get recordsKpiAvgSolveTimeLabel => '최고 기록 평균';

  @override
  String get recordsActivityOverviewTitle => '누적 활동';

  @override
  String get recordsActivityHeatmapTitle => '최근 활동 히트맵';

  @override
  String get recordsActivityHeatmapCaption => '칸이 진할수록 그날 더 많이 완료했어요.';

  @override
  String get recordsActivityTotalClearsLabel => '누적 완료 횟수';

  @override
  String get recordsActivityCurrentStreakLabel => '현재 연속';

  @override
  String get recordsActivityBestStreakLabel => '최장 연속';

  @override
  String recordsActivityDayCount(int count) {
    return '$count일';
  }

  @override
  String recordsActivityClearCount(int count) {
    return '$count회 클리어';
  }

  @override
  String get recordsSectionBestRecordTitle => '최고 기록';

  @override
  String get recordsSectionDifficultyTitle => '난이도별 기록';

  @override
  String get recordsSectionDetailStatsTitle => '세부 기록';

  @override
  String get recordsBestSingleEmpty => '아직 최고 기록을 표시할 데이터가 없어요.';

  @override
  String get recordsHintUsageLabel => '힌트 사용 기록';

  @override
  String get recordsHintUsageNoData => '기록 없음';

  @override
  String get recordsDetailMistakesShort => '실수 기록';

  @override
  String get recordsDetailStreakShort => '연속 플레이 일수';

  @override
  String recordsDetailStreakDays(int count) {
    return '$count일';
  }

  @override
  String recordsStatAverageWrongFormatted(String value) {
    return '$value회';
  }

  @override
  String get recordsDifficultySnapshotEmpty => '아직 난이도별 기록이 없어요.';

  @override
  String get recordsLevelDoneShort => '완료';

  @override
  String get recordsStatsHeroEyebrow => '최근 7일 스도쿠 기록';

  @override
  String get recordsStatsHeroHeadline => '최근 7일 스도쿠 기록을 한눈에 확인하세요.';

  @override
  String recordsTrendA11yMaxClears(int count) {
    return '최고 $count회';
  }

  @override
  String get recordsHeroChartEmptyHint =>
      '최근 7일 안에 퍼즐을 클리어하면 흐름 그래프가 여기에 나타나요.';

  @override
  String get recordsHeroSubtitleNoChart => '아래 카드에서 최근 7일 일별 클리어를 확인할 수 있어요.';

  @override
  String get recordsCalendarPlayedLabel => '클리어한 날';

  @override
  String get recordsCalendarEmptyLabel => '클리어 없음';

  @override
  String get recordsNoAverageTime => '기록 없음';

  @override
  String get recordsStatsBasisFootnote => '통계는 퍼즐별 최고 클리어 기록을 기준으로 계산됩니다.';

  @override
  String get recordsBestByLevelTitle => '난이도별 최고 기록';

  @override
  String get recordsBestByLevelEmpty => '표시할 난이도별 최고 기록이 없습니다.';

  @override
  String recordsBestByLevelDetail(String time, int wrongCount) {
    return '$time · 실수 $wrongCount';
  }

  @override
  String get recordsPerfectBadge => '퍼펙트';

  @override
  String recordsAvgTimeDetail(String time) {
    return '평균 시간 $time';
  }

  @override
  String get recordsRecentTitle => '최근 클리어';

  @override
  String get recordsRecentEmpty => '선택한 조건의 클리어 기록이 없습니다.';

  @override
  String get recordsBestTitle => '최고기록 Top 5';

  @override
  String get recordsBestEmpty => '선택한 조건의 최고기록이 없습니다.';

  @override
  String recordsGameNumberTitle(String level, int number) {
    return '$level · 게임 $number';
  }

  @override
  String recordsRecentDetail(String time, int wrongCount, String date) {
    return '$time · 실수 $wrongCount · $date';
  }

  @override
  String recordsBestDetail(String time, int wrongCount) {
    return '$time · 실수 $wrongCount';
  }

  @override
  String get recordsGameLoadError => '게임 데이터를 불러올 수 없습니다.';

  @override
  String get recordsChallengeTabHint => '주간 목표·연속 기록은 챌린지 탭에서 확인할 수 있어요.';

  @override
  String get recordsGoToChallengeTab => '챌린지 탭으로 이동';

  @override
  String get challengeTodaysChallengeTitle => '오늘의 도전';

  @override
  String get challengeTodayDoneHint => '오늘 도전은 이미 완료했어요. 기록을 다시 확인해보세요.';

  @override
  String get challengeTodayPendingHint => '오늘의 대표 퍼즐로 연속 플레이를 이어가세요.';

  @override
  String get challengeTodayReviewButton => '나만의 속도로 계속';

  @override
  String get challengeTodayStartButton => '나만의 속도로 몰입';

  @override
  String get myPaceNoPlayableTitle => '플레이할 게임이 없어요';

  @override
  String get myPaceNoPlayableMessage => '전체 레벨에서 새로 플레이할 퍼즐이 없어요.';

  @override
  String get challengeWeeklyGoalReachedBody =>
      '이제 퍼펙트 클리어를 늘려서 더 좋은 리듬을 만들어보세요.';

  @override
  String get challengeWeeklyGoalCatchUpBody =>
      '빠른 시작으로 몇 판만 더 하면 이번 주 목표를 채울 수 있어요.';

  @override
  String challengePerfectThisWeek(int count) {
    return '이번 주 퍼펙트 클리어 $count회';
  }

  @override
  String get challengePerfectThisWeekFirst => '이번 주 첫 퍼펙트 클리어에 도전해보세요';

  @override
  String get challengePerfectPositiveBody => '오답 없는 클리어를 이어가면 실력 성장이 더 잘 보입니다.';

  @override
  String get challengePerfectZeroBody => '메모 기능을 활용하면 오답 없는 클리어에 훨씬 가까워집니다.';

  @override
  String get challengeTabHeroHeadline => '오늘의 퍼즐과 주간 리듬을 한곳에서 살펴보세요.';

  @override
  String get challengeOpenTodayOnHomeButton => '홈에서 오늘 퍼즐 열기';

  @override
  String get challengeHeroDoneCaption => '오늘의 도전을 완료했습니다. 내일도 이어서 기록을 쌓아보세요.';

  @override
  String get challengeHeroPendingCaption =>
      '오늘의 도전이 아직 남아 있어요. 지금 시작하면 스트릭을 이어갈 수 있어요.';

  @override
  String get homeGuestTitle => '여행자 159';

  @override
  String get homeGuestSubtitle => '지금 바로 한 판 시작해보세요';

  @override
  String get homeContinueTitle => '이어하기';

  @override
  String homeContinueSubtitle(String level, int gameNumber, int cells) {
    return '$level · 게임 $gameNumber · $cells칸 진행';
  }

  @override
  String get homeContinueDescription => '중단한 퍼즐을 바로 이어서 플레이할 수 있어요.';

  @override
  String get homeContinueSameAsSpotlightSupporting => '오늘 퍼즐 이어하기';

  @override
  String get homeContinueActionButton => '계속하기';

  @override
  String homeProgressPercent(int percent) {
    return '진행률 $percent%';
  }

  @override
  String get homeQuickStartSectionTitle => '빠른 시작';

  @override
  String get homeBrowseLevelsTitle => '난이도 탐색';

  @override
  String get homeStreakTodayDoneLine => '오늘의 도전도 완료했어요.';

  @override
  String get homeStreakTodayPendingLine => '오늘의 도전을 완료하면 기록을 이어갈 수 있어요.';

  @override
  String get homeBadgeProgressTitle => '배지 진행';

  @override
  String get homeCatalogPreparingTitle => '퍼즐 카탈로그 준비 중';

  @override
  String homeCatalogProgressDetail(int generated, int target, int remaining) {
    return '$generated/$target판 준비됨 · 남은 $remaining판';
  }

  @override
  String get levelPickDifficultyTitle => '난이도 선택';

  @override
  String get levelPickDifficultySubtitle => '원하는 난이도를 선택하여 게임을 시작하세요';

  @override
  String get levelPickGameSubtitle => '원하는 게임을 선택하여 시작하세요';

  @override
  String levelGamesScreenTitle(String levelName) {
    return '$levelName 게임';
  }

  @override
  String get levelLoadingGames => '게임을 불러오는 중...';

  @override
  String get levelTapToStart => '바로 시작';

  @override
  String get levelClearedBadge => '클리어';

  @override
  String get levelOverviewTitle => '레벨 개요';

  @override
  String get levelPuzzlesSectionTitle => '퍼즐 목록';

  @override
  String get levelProgressLabel => '진행률';

  @override
  String get levelNoRecordYet => '기록 없음';

  @override
  String get levelStatusReady => '새 퍼즐';

  @override
  String get levelStatusCleared => '완료한 퍼즐';

  @override
  String levelEmptyCellsLabel(int count) {
    return '빈칸 $count개';
  }

  @override
  String levelPuzzleCountSummary(int count) {
    return '총 $count개의 퍼즐';
  }

  @override
  String levelCatalogPreparingShort(int done, int total) {
    return '추가 퍼즐 준비 중 · $done/$total판';
  }

  @override
  String get commonSave => '저장';

  @override
  String get settingsDisplaySection => '화면';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsThemeSystem => '시스템';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get profileEditorTitle => '프로필 편집';

  @override
  String get profileEditorRemovePhoto => '사진 제거';

  @override
  String get profileEditorNameLabel => '이름';

  @override
  String get profileEditorDefaultProfile => '기본 프로필';

  @override
  String get profileEditorDefaultProfileDesc => '앱에서 제공하는 기본 이미지로 시작';

  @override
  String get profileEditorPickFromAlbum => '사진앨범에서 선택';

  @override
  String get profileEditorPickFromAlbumDesc => '내 사진으로 프로필을 설정';

  @override
  String get homeTodayLabel => '오늘의 퍼즐';

  @override
  String get homeTodayPuzzleTitle => '조용히 집중해볼 시간이에요.';

  @override
  String get homeChallengeStartButton => '도전 시작';

  @override
  String get homeChallengeReplayButton => '다시 풀기';

  @override
  String get homeChallengeNotStarted => '아직 시작 전';

  @override
  String homeChallengeProgress(int percent) {
    return '$percent% 진행';
  }

  @override
  String get homeChallengeCompleteTitle => '오늘의 도전 완료!';

  @override
  String homeChallengeStreak(num days) {
    return '도전 $days일 연속';
  }

  @override
  String get homeChallengeLoadErrorTitle => '오늘의 도전을 불러오지 못했어요';

  @override
  String get homeChallengeLoadErrorBody => '잠시 후 다시 시도해주세요.';

  @override
  String get homeTodayChallengeDateChanged => '날짜가 바뀌어 오늘의 도전을 새로 불러왔어요.';

  @override
  String get homeFirstStartTitle => '첫 퍼즐을 시작해보세요';

  @override
  String get homeNewPuzzleTitle => '새 퍼즐을 시작해보세요';

  @override
  String get homeChooseLevelBody => '난이도를 선택하세요. 진행 상황은 자동 저장됩니다.';

  @override
  String get homeChooseLevelButton => '난이도 선택';

  @override
  String homeViewAllInProgress(int count) {
    return '진행 중인 게임 모두 보기 ($count)';
  }

  @override
  String get homeNewGameSectionTitle => '새 게임 · 난이도 선택';

  @override
  String homeLevelBlankCells(int count) {
    return '빈칸 $count개';
  }

  @override
  String get homeSavedGamesTitle => '진행 중인 게임';

  @override
  String get homeSavedGamesDescription =>
      '이어서 풀 게임을 고르세요. 삭제해도 저장된 풀이만 지워지고 완료 기록은 남아요.';

  @override
  String get homeSavedGameDeleteTooltip => '저장된 풀이 삭제';

  @override
  String get homeSavedGameDeleteTitle => '저장된 풀이를 삭제할까요?';

  @override
  String get homeSavedGameDeleteBody => '이 퍼즐의 입력과 메모가 삭제돼요. 완료 기록은 유지돼요.';

  @override
  String get homeSavedGameDeleteConfirm => '삭제';

  @override
  String get homeLoadError => '게임 정보를 불러오지 못했어요.';

  @override
  String get homeCatalogFirstTitle => '첫 퍼즐 세트를 준비하고 있어요';

  @override
  String get homeCatalogFirstBody =>
      '처음 실행에서는 스도쿠 문제를 기기에 저장해요. 잠시만 기다리면 이후부터는 훨씬 빠르게 열려요.';

  @override
  String get homeCatalogFirstNote => '준비는 백그라운드에서도 계속돼요. 지금 바로 둘러봐도 괜찮아요.';

  @override
  String get homeCatalogFirstContinue => '홈으로 계속';

  @override
  String homeLevelProgressSolved(int cleared, int total) {
    return '$cleared / $total';
  }

  @override
  String get levelFilterAll => '전체';

  @override
  String get levelFilterNew => '새 퍼즐';

  @override
  String get levelFilterInProgress => '진행 중';

  @override
  String get levelFilterDone => '완료';

  @override
  String levelPuzzleListTitle(int count) {
    return '퍼즐 목록 · $count';
  }

  @override
  String get levelRecentBadge => '최근';

  @override
  String get levelStatusInProgress => '진행 중';

  @override
  String get levelNoResults => '해당 항목이 없습니다.';

  @override
  String get levelReplayTitle => '완료한 퍼즐을 다시 풀까요?';

  @override
  String get levelReplayBody => '완료 기록은 유지되고, 더 좋은 결과일 때만 업데이트돼요.';

  @override
  String get levelReplayConfirm => '다시 풀기';

  @override
  String levelInProgressLimitTitle(int maxCount) {
    return '진행 중인 퍼즐이 $maxCount개예요';
  }

  @override
  String levelInProgressLimitBody(int maxCount) {
    return '최대 $maxCount개까지 함께 진행할 수 있어요.\n하나를 골라 이어서 풀어볼까요?';
  }

  @override
  String get levelInProgressLimitLater => '나중에 하기';

  @override
  String get levelTryAgain => '다시 시도';

  @override
  String get levelContinueButton => '이어서 풀기';

  @override
  String levelStartNextNew(String number) {
    return '다음 새 퍼즐 시작 · $number';
  }

  @override
  String get levelStartNewButton => '퍼즐 시작';

  @override
  String levelPuzzleNumber(int number) {
    return '$number번 퍼즐';
  }

  @override
  String levelCompletedCount(num count) {
    return '$count개 완료';
  }

  @override
  String get levelCardFirstSub => '첫 퍼즐부터 시작해볼까요?';

  @override
  String get levelCardNextSub => '다음 퍼즐을 시작해보세요';

  @override
  String levelCardAllDoneTitle(String levelName) {
    return '$levelName 퍼즐을 모두 완료했어요';
  }

  @override
  String get levelCardAllDoneSub => '완료한 퍼즐을 다시 풀어보세요';

  @override
  String get levelCardViewCompleted => '완료한 퍼즐 보기';

  @override
  String levelViewInProgress(int count) {
    return '진행 중 $count개 보기';
  }

  @override
  String get levelNotesInProgress => '메모 작성 중';

  @override
  String get levelEmptyInProgress => '이어갈 퍼즐이 아직 없어요.';

  @override
  String get levelEmptyCompleted => '첫 완료 기록을 만들어보세요.';

  @override
  String get levelEmptyFresh => '새로 시작할 퍼즐이 없어요.';

  @override
  String get levelAllCompleted => '이 난이도의 모든 퍼즐을 완료했어요.';

  @override
  String get levelActionShowNew => '새 퍼즐 보기';

  @override
  String get levelActionShowInProgress => '진행 중 보기';

  @override
  String get levelActionShowAll => '전체 보기';

  @override
  String levelBestTime(String time) {
    return '최고 기록 $time';
  }

  @override
  String levelCellSemantics(String number, String status) {
    return '$number번 퍼즐, $status';
  }

  @override
  String get gameResetDialogTitle => '처음부터 다시 풀기';

  @override
  String get gameResetDialogBody =>
      '입력한 숫자, 메모, 힌트, 오답 횟수와 시간을 모두 지우고 처음 상태로 돌아갈까요? 이전 완료 기록은 유지돼요.';

  @override
  String get gameResetConfirm => '다시 풀기';

  @override
  String get gameNumberInputLegend => '작은 숫자는 남은 개수, 체크는 완료된 숫자예요.';

  @override
  String get dialogSuggestedNextStep => '다음 행동 추천';

  @override
  String get dialogSetTomorrowReminder => '내일 알림 설정';

  @override
  String get dialogTryAnotherLevel => '다른 난이도 보기';

  @override
  String get savedGamesSortRecent => '최근 플레이순';

  @override
  String get savedGamesSortProgress => '진행률순';

  @override
  String get savedGamesSortPlayTime => '플레이 시간순';

  @override
  String get savedGamesEmpty => '선택한 조건에 맞는 저장 게임이 없어요.';

  @override
  String get savedGamesDeleteFailed => '삭제하지 못했어요. 다시 시도해 주세요.';

  @override
  String get recordsMyRecordTitle => '지금까지';

  @override
  String recordsSummaryHeroSentence(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 퍼즐을 완성했어요',
    );
    return '$_temp0';
  }

  @override
  String get recordsSummaryHeroFirst => '첫 퍼즐을 완성했어요';

  @override
  String recordsSummaryHeroMilestone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 돌파! 꾸준히 쌓고 있어요',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryHeroGrowing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '벌써 $count개의 퍼즐을 풀었어요',
    );
    return '$_temp0';
  }

  @override
  String recordsSummaryHeroStacked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개의 퍼즐이 차곡차곡 쌓였어요',
    );
    return '$_temp0';
  }

  @override
  String get recordsLevelRingsTitle => '난이도별 진행';

  @override
  String recordsLevelRingSemantics(String level, int cleared, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total개 중 $cleared개 완료',
    );
    return '$level, $_temp0';
  }

  @override
  String get recordsSummaryAllPerfect => '모두 실수 없이 풀었어요';

  @override
  String recordsSummaryPartialPerfect(num count) {
    return '그중 $count개는 실수 없이 풀었어요';
  }

  @override
  String recordsSummaryStreakPlaying(num days) {
    return '$days일 연속 플레이 중';
  }

  @override
  String recordsSummaryPlayDays(num days) {
    return '플레이 $days일';
  }

  @override
  String get recordsSummaryEmptyTitle => '첫 기록을 만들어볼까요?';

  @override
  String get recordsSummaryEmptyBody => '퍼즐을 완성하면 이곳에 기록이 쌓여요';

  @override
  String get challengeTodayEyebrow => '오늘의 흐름';

  @override
  String get gamePausedTitle => '일시정지됨';

  @override
  String get gamePausedBody => '타이머가 멈추고 보드는 잠시 가려져요.';

  @override
  String homeStreakChip(int count) {
    return '$count일';
  }

  @override
  String homeStreakActive(int count) {
    return '$count일 연속 퍼즐을 완료했어요';
  }

  @override
  String homeStreakAtRisk(int count) {
    return '$count일 연속 중이에요. 오늘 한 판을 완료하면 이어져요.';
  }

  @override
  String get hintStepLookTitle => '힌트 · 살펴볼 곳';

  @override
  String get hintLookCell => '강조된 칸의 가로줄·세로줄·박스를 살펴보세요.';

  @override
  String hintLookBox(int value) {
    return '강조된 박스에서 숫자 $value의 자리를 찾아보세요.';
  }

  @override
  String hintLookRow(int value) {
    return '강조된 가로줄에서 숫자 $value의 자리를 찾아보세요.';
  }

  @override
  String hintLookCol(int value) {
    return '강조된 세로줄에서 숫자 $value의 자리를 찾아보세요.';
  }

  @override
  String get hintMovedFromSelection => '선택한 칸보다 먼저 풀 수 있는 곳이 있어요.';

  @override
  String get hintTechniqueNakedSingle => '네이키드 싱글';

  @override
  String get hintTechniqueHiddenSingle => '히든 싱글';

  @override
  String get hintTechniqueReveal => '정답 알려주기';

  @override
  String hintExplainNakedSingle(int value) {
    return '이 칸의 가로줄·세로줄·박스에 다른 숫자 8개가 모두 있어요. 들어갈 수 있는 숫자는 $value뿐이에요.';
  }

  @override
  String hintExplainHiddenSingleBox(int value) {
    return '이 박스에서 숫자 $value의 자리는 이 칸뿐이에요. 다른 빈칸은 모두 표시된 칸과 같은 가로줄이나 세로줄에 있어요.';
  }

  @override
  String hintExplainHiddenSingleRow(int value) {
    return '이 가로줄에서 숫자 $value의 자리는 이 칸뿐이에요. 다른 빈칸은 모두 표시된 칸과 같은 세로줄이나 박스에 있어요.';
  }

  @override
  String hintExplainHiddenSingleCol(int value) {
    return '이 세로줄에서 숫자 $value의 자리는 이 칸뿐이에요. 다른 빈칸은 모두 표시된 칸과 같은 가로줄이나 박스에 있어요.';
  }

  @override
  String get hintExplainReveal => '이 칸은 더 어려운 기법이 필요해요. 아래 버튼으로 정답을 넣을 수 있어요.';

  @override
  String get hintNextStep => '더 알려주기';

  @override
  String get hintFillAnswer => '정답 넣기';

  @override
  String get hintClose => '힌트 닫기';

  @override
  String get notificationOptInTitle => '매일 한 판을 알려드릴까요?';

  @override
  String get notificationOptInBody =>
      '매일 저녁 8시에 아직 퍼즐을 풀지 않았다면 알려드려요. 설정에서 언제든 끌 수 있어요.';

  @override
  String get notificationOptInAccept => '알림 받기';

  @override
  String get notificationOptInLater => '나중에';

  @override
  String get notificationOptInDenied =>
      '알림 권한이 허용되지 않았어요. 기기 설정에서 허용한 뒤 설정에서 알림을 켤 수 있어요.';

  @override
  String get notificationSetupFailed => '알림을 설정하지 못했어요. 잠시 후 설정에서 다시 시도해 주세요.';

  @override
  String get beginnerTutorialPromptTitle => '스도쿠가 처음이신가요?';

  @override
  String get beginnerTutorialPromptBody =>
      '문제를 풀기 전에 짧은 안내 연습을 해볼까요? 1분이면 충분해요.';

  @override
  String get beginnerTutorialStart => '가이드 시작';

  @override
  String get beginnerTutorialSkip => '건너뛰기';

  @override
  String beginnerTutorialStepIndicator(int current, int total) {
    return '$current / $total 단계';
  }

  @override
  String get beginnerTutorialStepRowTitle => '규칙: 가로줄';

  @override
  String get beginnerTutorialStepRowBody => '한 가로줄에는 1부터 9까지 숫자가 한 번씩만 들어가요.';

  @override
  String get beginnerTutorialStepColumnTitle => '규칙: 세로줄';

  @override
  String get beginnerTutorialStepColumnBody =>
      '세로줄도 마찬가지로 1부터 9까지 숫자가 한 번씩만 들어가요.';

  @override
  String get beginnerTutorialStepBoxTitle => '규칙: 3×3 박스';

  @override
  String get beginnerTutorialStepBoxBody =>
      '3×3 박스 안에도 1부터 9까지 숫자가 한 번씩만 들어가요.';

  @override
  String get beginnerTutorialStepInputTitle => '숫자 입력하기';

  @override
  String get beginnerTutorialStepInputBody =>
      '강조된 칸에는 들어갈 수 있는 숫자가 하나뿐이에요. 칸을 누르고 정답 숫자를 눌러보세요.';

  @override
  String get beginnerTutorialStepInputWrongHint =>
      '그 숫자는 이미 같은 줄이나 박스에 있어요. 다른 숫자를 눌러보세요.';

  @override
  String get beginnerTutorialStepMemoTitle => '메모와 지우기';

  @override
  String get beginnerTutorialStepMemoAddBody =>
      '메모 모드를 켜고 이 칸을 누른 뒤 후보 숫자를 눌러 메모해보세요.';

  @override
  String get beginnerTutorialStepMemoEraseBody => '이번엔 같은 숫자를 다시 눌러 메모를 지워보세요.';

  @override
  String get beginnerTutorialStepHintTitle => '힌트';

  @override
  String get beginnerTutorialStepHintBody =>
      '힌트를 누르면 실제 힌트를 차감하지 않고 어디를 봐야 하는지 알려줘요.';

  @override
  String get beginnerTutorialStepHintButton => '힌트 열기';

  @override
  String get beginnerTutorialStepDoneTitle => '준비 완료!';

  @override
  String get beginnerTutorialStepDoneBody =>
      '가로줄, 세로줄, 박스 규칙과 숫자 입력, 메모, 힌트까지 모두 배웠어요.';

  @override
  String get beginnerTutorialFirstPuzzleButton => '첫 문제 시작';

  @override
  String get beginnerTutorialNextButton => '다음';

  @override
  String get beginnerTutorialCloseButton => '완료';

  @override
  String get settingsHowToPlayTitle => '게임 방법';

  @override
  String get settingsHowToPlaySubtitle => '안내 튜토리얼 다시 보기';

  @override
  String get autoNotesConfirmTitle => '모든 메모를 다시 채울까요?';

  @override
  String get autoNotesConfirmBody =>
      '빈 칸의 메모가 현재 후보 숫자로 모두 바뀌어요. 직접 지운 후보도 다시 나타날 수 있어요.';

  @override
  String get autoNotesConfirmApply => '메모 다시 채우기';

  @override
  String get autoNotesContradictionMessage =>
      '후보가 하나도 남지 않는 칸이 있어 메모를 채우지 못했어요. 입력을 확인하고 다시 시도해 주세요.';

  @override
  String get autoNotesTipMessage => '팁: 메모를 길게 누르면 후보 숫자를 한 번에 채워줘요.';

  @override
  String gameNumberLockedMessage(int number) {
    return '$number 고정 · 칸을 눌러 연속 입력';
  }

  @override
  String get gameNumberLockTipMessage =>
      '숫자를 길게 누르면 같은 숫자를 여러 칸에 빠르게 입력할 수 있어요.';

  @override
  String gameNumberButtonLockedSemantics(int number) {
    return '$number, 고정됨, 길게 눌러 해제';
  }

  @override
  String get gameNumberButtonLockHint => '길게 눌러 고정';

  @override
  String get gameMemoLongPressHint => '탭하여 메모 모드 전환, 길게 눌러 자동 메모.';

  @override
  String get homeGreetingMorning => '가볍게 한 판 시작해볼까요?';

  @override
  String get homeGreetingAfternoon => '집중 퍼즐 한 판, 딱 좋아요.';

  @override
  String get homeGreetingEvening => '차분하게 퍼즐로 마무리해요.';

  @override
  String get levelNoPuzzlesAvailable => '이 난이도에는 선택 가능한 퍼즐이 없어요.';

  @override
  String get levelLastPlayedToday => '오늘';

  @override
  String get levelLastPlayedYesterday => '어제';

  @override
  String levelLastPlayedDaysAgo(int count) {
    return '$count일 전';
  }
}
