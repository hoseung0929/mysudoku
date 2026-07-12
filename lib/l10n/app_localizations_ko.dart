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
  String get recordsScreenTitle => '기록 · 통계';

  @override
  String get challengeScreenTitle => '챌린지';

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
  String get gameProgressShort => '진행율';

  @override
  String get gameTimeShort => '시간';

  @override
  String get gameNumberInputTitle => '숫자 입력';

  @override
  String gameRowsCompleted(int count) {
    return '행 $count개 완성';
  }

  @override
  String gameColsCompleted(int count) {
    return '열 $count개 완성';
  }

  @override
  String gameBoxesCompleted(int count) {
    return '박스 $count개 완성';
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
  String get dialogBackToLevels => '레벨 선택으로';

  @override
  String get dialogPlayAgain => '다시 시작';

  @override
  String get dialogNextPuzzle => '다음 퍼즐';

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
  String get settingsPrivacyDialogTitle => '개인정보 안내';

  @override
  String get settingsPrivacyDialogBody =>
      '이 앱은 게임 진행, 기록, 프로필 정보, 앱 설정을 이 기기에만 저장합니다. 계정은 필요하지 않으며, 당사 서버로 개인정보를 수집하지 않습니다. 프로필 이미지를 선택하는 경우 사진 보관함 권한은 기기에서 이미지를 선택하고 저장하는 용도로만 사용됩니다. 알림 설정도 기기에만 저장됩니다. 앱을 삭제하면 기기 백업이 없는 한 로컬 데이터가 함께 삭제될 수 있습니다.';

  @override
  String get commonOk => '확인';

  @override
  String get commonCancel => '취소';

  @override
  String get gameOverTitle => '게임 오버';

  @override
  String get gameOverMessage => '오답 한도를 초과했습니다.';

  @override
  String gameOverWrongLabel(int count, int maxCount) {
    return '오답: $count/$maxCount';
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
  String get recordsTrendActiveDays => '플레이 일수';

  @override
  String get recordsTrendWindowAvgTime => '평균 시간 (같은 기간)';

  @override
  String get recordsTrendWindowAvgWrong => '평균 오답 (같은 기간)';

  @override
  String get recordsHeroBadgeFlow => '흐름';

  @override
  String get recordsHeroTitle => '차분하게 쌓인 흐름을\n먼저 살펴보세요.';

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
  String get recordsPlayInsightsTitle => '이번 주 기록';

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
    return '오답 $count회';
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
  String get recordsMetricClearRate => '전체 완료율';

  @override
  String get recordsMetricPerfectRate => '퍼펙트율';

  @override
  String get recordsSummaryMetricsFootnote =>
      '클리어 수는 기간과 난이도 필터를 반영해요. 전체 완료율은 같은 범위에서 푼 퍼즐 수를 전체 퍼즐 수와 비교한 값이에요.';

  @override
  String get recordsMetricAvgTime => '평균 시간';

  @override
  String get recordsMetricAvgWrong => '평균 오답';

  @override
  String get recordsByLevelTitle => '레벨별 통계';

  @override
  String get recordsByLevelEmpty => '표시할 레벨 통계가 없습니다.';

  @override
  String get recordsByLevelSectionSubtitle =>
      '난이도별로 어느 구간에서 가장 편안해졌는지 볼 수 있어요.';

  @override
  String get recordsLevelInfographicClearRate => '완료율';

  @override
  String get recordsLevelMiniBest => '베스트';

  @override
  String get recordsLevelMiniPerfectRate => '퍼펙트율';

  @override
  String get recordsLevelMiniAvgWrong => '평균 오답';

  @override
  String get recordsStatsLoadError => '통계 데이터를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get recordsRetry => '다시 시도';

  @override
  String get recordsStatsPageSubtitle => '클리어와 평균 시간을 한눈에 봐요.';

  @override
  String get recordsKpiWeeklyClearsLabel => '클리어';

  @override
  String get recordsKpiAvgSolveTimeLabel => '평균 시간';

  @override
  String get recordsActivityOverviewTitle => '누적 활동';

  @override
  String get recordsActivityHeatmapTitle => '최근 활동 히트맵';

  @override
  String get recordsActivityHeatmapCaption => '칸이 진할수록 그날 더 많이 클리어했어요.';

  @override
  String get recordsActivityTotalClearsLabel => '누적 클리어';

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
  String get recordsStatsHeroHeadline => '최근 7일 스도쿠 기록을\n한눈에 확인하세요.';

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
    return '$time · 오답 $wrongCount';
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
    return '$time · 오답 $wrongCount · $date';
  }

  @override
  String recordsBestDetail(String time, int wrongCount) {
    return '$time · 오답 $wrongCount';
  }

  @override
  String get recordsGameLoadError => '게임 데이터를 불러올 수 없습니다.';

  @override
  String get recordsChallengeTabHint => '주간 목표·연속 기록은 챌린지 탭에서 확인할 수 있어요.';

  @override
  String get recordsGoToChallengeTab => '챌린지 탭으로 이동';

  @override
  String get challengeLoadError => '챌린지 정보를 불러올 수 없습니다.';

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
  String get challengeWeeklyGoalReachedTitle => '이번 주 목표를 달성했어요';

  @override
  String challengeWeeklyGoalRemainingTitle(int count) {
    return '주간 목표까지 $count판 남았어요';
  }

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
  String get challengeWeeklyGoalHeading => '주간 목표';

  @override
  String challengeWeeklyClearsLine(int count) {
    return '이번 주 $count판 클리어';
  }

  @override
  String challengeWeeklyProgressShort(int done, int target) {
    return '$done/$target 완료';
  }

  @override
  String challengeWeeklyPerfectShort(int count) {
    return '퍼펙트 $count회';
  }

  @override
  String get challengeWeeklyCongratsFooter =>
      '이번 주 목표를 달성했습니다. 기록을 더 멋지게 쌓아보세요.';

  @override
  String challengeWeeklyAlmostFooter(int count) {
    return '지금 흐름이면 이번 주 목표까지 $count판 남았습니다.';
  }

  @override
  String get challengeAchievementsHeading => '업적 · 배지';

  @override
  String challengeBadgesCollected(int unlocked, int total) {
    return '획득 $unlocked/$total';
  }

  @override
  String get challengeViewAllBadges => '전체 보기';

  @override
  String get challengeEarnedBadgesHeading => '획득한 배지';

  @override
  String get challengeNextBadgeTargets => '다음 목표';

  @override
  String challengeBadgeProgressLine(String desc, String progress) {
    return '$desc 현재 진행: $progress';
  }

  @override
  String challengeStreakDays(int days) {
    return '$days일 연속 클리어';
  }

  @override
  String get challengeStreakStartToday => '오늘 첫 클리어 도전';

  @override
  String get challengeTabHeroHeadline => '오늘의 퍼즐과 주간 리듬을\n한곳에서 살펴보세요.';

  @override
  String get challengeHeroPendingDetail => '플레이는 홈 상단 카드에서 시작할 수 있어요.';

  @override
  String get challengeHeroDoneDetail => '오늘 도전은 끝났어요. 배지와 주간 진행은 이 탭에 모아두었어요.';

  @override
  String get challengeOpenTodayOnHomeButton => '홈에서 오늘 퍼즐 열기';

  @override
  String get challengeHeroDoneCaption => '오늘의 도전을 완료했습니다. 내일도 이어서 기록을 쌓아보세요.';

  @override
  String get challengeHeroPendingCaption =>
      '오늘의 도전이 아직 남아 있어요. 지금 시작하면 스트릭을 이어갈 수 있어요.';

  @override
  String get homeGuestTitle => '여행자';

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
  String get homeTodayChallengeCardDoneBody =>
      '오늘의 도전을 완료했어요. 연속 기록을 이어가고 있어요.';

  @override
  String get homeTodayChallengeCardPendingBody => '매일 한 판, 가볍게 실력을 확인해보세요.';

  @override
  String homeTodayChallengeFooterDoneStreak(int days) {
    return '오늘 도전 완료 · 현재 $days일 연속 기록';
  }

  @override
  String get homeTodayChallengeFooterPending => '오늘의 공통 퍼즐로 연속 도전 흐름을 만들어보세요.';

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
  String get achievementCollectionAppBarTitle => '배지 컬렉션';

  @override
  String get achievementLoadError => '배지 정보를 불러올 수 없습니다.';

  @override
  String get achievementViewSettings => '보기 설정';

  @override
  String get achievementSortLabel => '정렬';

  @override
  String get achievementFilterAll => '전체';

  @override
  String get achievementFilterUnlocked => '획득';

  @override
  String get achievementFilterLocked => '도전 중';

  @override
  String get achievementSectionAll => '전체 배지';

  @override
  String get achievementSectionUnlocked => '획득한 배지';

  @override
  String get achievementSectionLocked => '도전 중인 배지';

  @override
  String get achievementEmptyAll => '표시할 배지가 없습니다.';

  @override
  String get achievementEmptyUnlocked => '아직 획득한 배지가 없습니다.';

  @override
  String get achievementEmptyLocked => '모든 배지를 획득했어요.';

  @override
  String get achievementHeroTitle => '성취 컬렉션';

  @override
  String achievementHeroProgress(int unlocked, int total) {
    return '획득 $unlocked / 전체 $total';
  }

  @override
  String get achievementHeroAllUnlocked => '모든 배지를 모았어요. 정말 멋집니다.';

  @override
  String get achievementHeroKeepGoing => '남은 배지를 하나씩 열면서 플레이 기록을 쌓아보세요.';

  @override
  String get achievementBadgeFirstClearTitle => '첫 클리어';

  @override
  String get achievementBadgeFirstClearDesc => '첫 퍼즐을 완주해 스도쿠 여정을 시작했어요.';

  @override
  String get achievementBadgeStreakTitle => '3일 연속';

  @override
  String get achievementBadgeStreakDesc => '3일 연속으로 퍼즐을 클리어해 리듬을 만들어요.';

  @override
  String get achievementBadgeWeeklyTitle => '주간 러너';

  @override
  String get achievementBadgeWeeklyDesc => '최근 7일 동안 5판을 클리어해 꾸준함을 보여주세요.';

  @override
  String get achievementBadgePerfectTitle => '퍼펙트 클리어';

  @override
  String get achievementBadgePerfectDesc => '오답 없이 한 판을 끝내면 획득합니다.';

  @override
  String get achievementBadgeMasterTitle => '마스터 첫 승리';

  @override
  String get achievementBadgeMasterDesc => '마스터 난이도를 처음 클리어하면 해금됩니다.';

  @override
  String achievementProgressFraction(int current, int max) {
    return '$current/$max';
  }

  @override
  String achievementProgressStreak(int current, int max) {
    return '$current/$max일';
  }

  @override
  String achievementProgressWeekly(int current, int max) {
    return '$current/$max판';
  }

  @override
  String get achievementStatusDone => '완료';

  @override
  String get achievementStatusNotMet => '미달성';

  @override
  String get achievementStatusTrying => '도전 중';

  @override
  String achievementTileProgress(String label) {
    return '진행: $label';
  }

  @override
  String achievementTileRarity(String label) {
    return '희귀도: $label';
  }

  @override
  String get achievementRarityCommon => '기본';

  @override
  String get achievementRarityRare => '희귀';

  @override
  String get achievementRarityEpic => '에픽';

  @override
  String get achievementSortDefault => '기본순';

  @override
  String get achievementSortRarity => '희귀도순';

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
  String get profileEditorBioLabel => '자기소개';

  @override
  String get profileEditorBioHint => '나를 소개하는 한 줄을 입력해주세요';

  @override
  String get profileEditorBioFooter => '자기소개와 프로필 사진은 프로필 화면에 표시됩니다.';

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
  String levelProgressCardMessage(String levelName) {
    return '오늘은 $levelName 퍼즐부터 시작해보세요';
  }

  @override
  String levelProgressCompleted(int total) {
    return '/ $total 완료';
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
    return '퍼즐을 $maxCount개나 진행 중이네요!';
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
  String get gameResetDialogTitle => '현재 게임 초기화';

  @override
  String get gameResetDialogBody =>
      '입력한 숫자, 메모, 힌트, 오답 횟수와 시간을 모두 지우고 처음 상태로 돌아갈까요?';

  @override
  String get gameResetConfirm => '초기화';

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
  String get challengeMetricBasisTitle => '챌린지 지표 기준';

  @override
  String get challengeMetricBasisWeekly =>
      '주간 진행도: 최근 7일의 완료 이벤트 수를 기준으로 계산됩니다.';

  @override
  String get challengeMetricBasisStreak => '연속 기록: 오늘의 도전을 완료한 날짜 연속성으로 계산됩니다.';
}
