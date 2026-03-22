// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '마이 스도쿠';

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
  String get settingsSectionAppearance => '외관';

  @override
  String get settingsSectionLanguage => '언어';

  @override
  String get settingsSectionGame => '게임';

  @override
  String get settingsSectionInfo => '정보';

  @override
  String get settingsNotificationsTitle => '알림 설정';

  @override
  String get settingsNotificationsSubtitle => '게임 알림을 관리합니다';

  @override
  String get settingsNotificationTimeTitle => '알림 시간';

  @override
  String get settingsNotificationTimeSubtitle => '알림을 받을 시간을 설정합니다';

  @override
  String get settingsThemeTitle => '테마 설정';

  @override
  String get settingsThemeSubtitle => '라이트, 다크, 시스템 설정';

  @override
  String get settingsDarkModeTitle => '다크 모드';

  @override
  String get settingsDarkModeSubtitle => '다크 모드를 켜거나 끕니다';

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
  String get settingsLanguagePickerTitle => '언어 선택';

  @override
  String get settingsVibrationTitle => '입력 진동';

  @override
  String get settingsVibrationSubtitle => '숫자 입력 시 진동 피드백을 사용합니다';

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
  String get settingsDailyGoalNotifSubtitle => '일일 목표 달성 시 알림을 받습니다';

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
  String get gameGuideTitle => '게임 가이드';

  @override
  String get gameGuideTapCellTitle => '칸을 먼저 선택하세요';

  @override
  String get gameGuideTapCellBody => '비어 있는 칸을 누른 뒤 아래 숫자 버튼으로 입력합니다.';

  @override
  String get gameGuideMistakesTitle => '오답은 3번까지';

  @override
  String get gameGuideMistakesBody => '틀린 숫자를 3번 입력하면 해당 판은 종료됩니다.';

  @override
  String get gameGuideColorsTitle => '색상 힌트를 활용하세요';

  @override
  String get gameGuideColorsBody => '선택 칸, 같은 숫자, 관련 칸이 함께 강조되어 흐름을 읽기 쉽습니다.';

  @override
  String get gameGuidePlayButton => '바로 플레이';

  @override
  String gameNumberLabel(int number) {
    return '게임 $number';
  }

  @override
  String get gameHintShort => '힌트';

  @override
  String get gameMemoShort => '메모';

  @override
  String get gameMemoOnShort => '메모 ON';

  @override
  String get gameMemoStateOn => 'ON';

  @override
  String get gameMemoStateOff => 'OFF';

  @override
  String get gameWrongShort => '오답';

  @override
  String get gameProgressShort => '진행율';

  @override
  String get gameTimeShort => '시간';

  @override
  String get gameNumberInputTitle => '숫자 입력';

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
  String get shareSubject => 'My Sudoku 결과';

  @override
  String get shareClearHeader => 'My Sudoku 완료';

  @override
  String shareClearLine(String level, int number) {
    return '$level · 게임 $number';
  }

  @override
  String shareClearStats(String time, int wrong) {
    return '기록 $time · 오답 $wrong회';
  }

  @override
  String get shareClearTags => '#MySudoku #SudokuChallenge';

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
  String get settingsAppearancePickerTitle => '화면 모드';

  @override
  String get settingsThemeModeLight => '라이트';

  @override
  String get settingsThemeModeDark => '다크';

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
  String get settingsAboutDeveloperNote => '마이 스도쿠를 즐겨 주세요!';

  @override
  String get settingsPrivacyDialogTitle => '개인정보 안내';

  @override
  String get settingsPrivacyDialogBody =>
      '게임 진행 및 기록은 이 기기에만 저장됩니다. 계정이나 개인정보 수집은 하지 않습니다. 앱을 삭제하면 기기 백업이 없는 한 로컬 데이터가 함께 삭제될 수 있습니다.';

  @override
  String get commonOk => '확인';

  @override
  String get gameOverTitle => '게임 오버';

  @override
  String get gameOverMessage => '오답이 3개를 초과했습니다.';

  @override
  String gameOverWrongLabel(int count) {
    return '오답: $count/3';
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
  String get recordsSummaryTitle => '요약 통계';

  @override
  String get recordsMetricClears => '클리어';

  @override
  String get recordsMetricClearRate => '클리어율';

  @override
  String get recordsMetricAvgTime => '평균 시간';

  @override
  String get recordsMetricAvgWrong => '평균 오답';

  @override
  String get recordsByLevelTitle => '레벨별 통계';

  @override
  String get recordsByLevelEmpty => '표시할 레벨 통계가 없습니다.';

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
  String get challengeLoadError => '챌린지 정보를 불러올 수 없습니다.';

  @override
  String get challengeTodaysChallengeTitle => '오늘의 도전';

  @override
  String get challengeTodayDoneHint => '오늘 도전은 이미 완료했어요. 기록을 다시 확인해보세요.';

  @override
  String get challengeTodayPendingHint => '오늘의 대표 퍼즐로 연속 플레이를 이어가세요.';

  @override
  String get challengeTodayReviewButton => '다시 보기';

  @override
  String get challengeTodayStartButton => '도전 시작';

  @override
  String get challengeSuggestedActions => '추천 액션';

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
  String get challengeHeroDoneCaption => '오늘의 도전을 완료했습니다. 내일도 이어서 기록을 쌓아보세요.';

  @override
  String get challengeHeroPendingCaption =>
      '오늘의 도전이 아직 남아 있어요. 지금 시작하면 스트릭을 이어갈 수 있어요.';

  @override
  String get challengeHeroReviewAction => '기록 다시 보기';

  @override
  String get challengeHeroStartAction => '오늘의 도전 시작';

  @override
  String get challengeQuickStartRecommendedTitle => '빠른 시작';

  @override
  String challengeQuickStartRecommendedBody(String level) {
    return '$level 난이도 추천';
  }

  @override
  String get challengeQuickStartBeginnerTitle => '초급 시작';

  @override
  String get challengeQuickStartBeginnerBody => '부담 없이 한 판 시작';

  @override
  String get challengeQuickStartRandomTitle => '랜덤 도전';

  @override
  String get challengeQuickStartRandomBody => '오늘 기분대로 가볍게 플레이';

  @override
  String get homeOnboardingWelcomeTitle => '처음 오셨네요';

  @override
  String get homeOnboardingStepQuickTitle => '빠른 시작';

  @override
  String get homeOnboardingStepQuickBody => '추천 난이도로 바로 한 판 시작할 수 있어요.';

  @override
  String get homeOnboardingStepDailyTitle => '오늘의 도전';

  @override
  String get homeOnboardingStepDailyBody => '매일 바뀌는 대표 퍼즐로 가볍게 실력을 확인해보세요.';

  @override
  String get homeOnboardingStepResumeTitle => '이어하기';

  @override
  String get homeOnboardingStepResumeBody => '중단한 게임은 홈 상단 카드에서 곧바로 이어집니다.';

  @override
  String get homeOnboardingStartButton => '시작하기';

  @override
  String get homeGuestTitle => '게스트';

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
  String get levelTapToStart => '클릭하여 게임 시작';

  @override
  String get levelClearedBadge => '클리어';

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
}
