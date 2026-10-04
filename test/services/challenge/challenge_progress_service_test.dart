import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/database/daily_challenge_completion_repository.dart';
import 'package:sudoku159/model/daily_challenge_completion_detail.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/model/today_challenge_target.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/challenge/weekly_goal_service.dart';
import 'package:sudoku159/services/catalog/remote_puzzle_service.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  group('ChallengeProgressService', () {
    test('calculates consecutive streak from daily completion dates', () {
      final today = DateTime.now();
      String format(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

      final streak =
          ChallengeProgressService.calculateDailyChallengeStreakFromDates([
        format(today),
        format(today.subtract(const Duration(days: 1))),
        format(today.subtract(const Duration(days: 2))),
        format(today.subtract(const Duration(days: 4))),
      ]);

      expect(streak, 3);
    });

    test('returns zero when latest completion is stale', () {
      final today = DateTime.now();
      String format(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

      final streak =
          ChallengeProgressService.calculateDailyChallengeStreakFromDates([
        format(today.subtract(const Duration(days: 3))),
        format(today.subtract(const Duration(days: 4))),
      ]);

      expect(streak, 0);
    });

    test('counts weekly clears from Monday of the current week', () {
      final service = ChallengeProgressService();
      final today = DateTime.now();
      final monday = WeeklyGoalService.weekStartOf(today);
      String format(DateTime value) => WeeklyGoalService.formatDate(value);

      final count = service.calculateWeeklyClearCount([
        {'clear_date': format(today), 'wrong_count': 1},
        // 이번 주 월요일(재도전으로 같은 날 두 번 완료해도 각각 센다).
        {'clear_date': format(monday), 'wrong_count': 0},
        {'clear_date': format(monday), 'wrong_count': 2},
        // 지난주 일요일은 이번 주가 아니다.
        {
          'clear_date':
              format(DateTime(monday.year, monday.month, monday.day - 1)),
          'wrong_count': 0,
        },
      ]);

      expect(count, 3);
    });

    test('counts only perfect clears inside the weekly window', () {
      final service = ChallengeProgressService();
      final today = DateTime.now();
      String format(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

      final perfectCount = service.calculatePerfectClearCount([
        {'clear_date': format(today), 'wrong_count': 0},
        {
          'clear_date': format(today.subtract(const Duration(days: 2))),
          'wrong_count': 0
        },
        {
          'clear_date': format(today.subtract(const Duration(days: 4))),
          'wrong_count': 2
        },
        {
          'clear_date': format(today.subtract(const Duration(days: 8))),
          'wrong_count': 0
        },
      ]);

      expect(perfectCount, 2);
    });

    test('weekly goal target uses the two previous weeks, not this week', () {
      final service = ChallengeProgressService();
      final monday = WeeklyGoalService.weekStartOf(DateTime.now());
      String dayBefore(int n) => WeeklyGoalService.formatDate(
          DateTime(monday.year, monday.month, monday.day - n));
      List<Map<String, dynamic>> previousClears(int count) => [
            for (var i = 0; i < count; i++)
              {'clear_date': dayBefore(1 + i % 14), 'wrong_count': 1},
          ];
      // 이번 주(월요일 이후)의 플레이는 아무리 많아도 목표에 영향이 없다.
      final thisWeek = [
        for (var i = 0; i < 20; i++)
          {
            'clear_date': WeeklyGoalService.formatDate(monday),
            'wrong_count': 0
          },
      ];

      expect(service.calculateWeeklyGoalTarget(previousClears(2)), 3);
      expect(service.calculateWeeklyGoalTarget(previousClears(4)), 3);
      expect(service.calculateWeeklyGoalTarget(previousClears(5)), 5);
      expect(service.calculateWeeklyGoalTarget(previousClears(14)), 5);
      expect(service.calculateWeeklyGoalTarget(previousClears(15)), 7);
      expect(
        service.calculateWeeklyGoalTarget([...previousClears(2), ...thisWeek]),
        3,
      );
    });

    test('handles non-int wrong_count values safely', () {
      final service = ChallengeProgressService();
      final today = DateTime.now();
      String format(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

      final perfectCount = service.calculatePerfectClearCount([
        {'clear_date': format(today), 'wrong_count': 0.0},
        {
          'clear_date': format(today.subtract(const Duration(days: 1))),
          'wrong_count': '0'
        },
        {
          'clear_date': format(today.subtract(const Duration(days: 2))),
          'wrong_count': 1.0
        },
      ]);

      expect(perfectCount, 2);
    });

    test('ignores malformed clear_date values', () {
      final service = ChallengeProgressService();
      final today = DateTime.now();
      String format(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

      final count = service.calculateWeeklyClearCount([
        {'clear_date': format(today), 'wrong_count': 1},
        {'clear_date': 'not-a-date', 'wrong_count': 0},
      ]);

      expect(count, 1);
    });

    test('selects an existing challenge game number when numbering has holes',
        () async {
      // 어떤 날짜가 어느 난이도로 매핑되는지는 서비스의 날짜 기반 정책이
      // 정하므로 고정하지 않는다. 모든 난이도에 같은 구멍 뚫린 번호 목록을
      // 줘서, 그날 선택된 난이도가 무엇이든 구멍을 건너뛰고 실제 존재하는
      // 번호 중 하나가 선택되는지만 검증한다.
      const holeyGameNumbers = [1, 3, 7];
      final service = ChallengeProgressService(
        loadGameNumbersForLevel: (levelName) async => holeyGameNumbers,
      );

      final target = await service.getChallengeTargetForCalendarDay(
        DateTime(2026, 4, 10),
      );

      final activeLevelNames = SudokuLevel.levels
          .where((level) => !level.isMasterLevel)
          .map((level) => level.name);
      expect(activeLevelNames, contains(target.levelName));
      expect(holeyGameNumbers, contains(target.gameNumber));
    });

    test('pins the first resolved target for the day (offline then online)',
        () async {
      SharedPreferences.setMockInitialValues({});
      var online = false;
      final service = ChallengeProgressService(
        loadGameNumbersForLevel: (_) async => [1, 2, 3],
        remotePuzzleService: _FakeRemotePuzzleService(
          target: const TodayChallengeTarget(levelName: '마스터', gameNumber: 42),
          onFetch: () => online,
        ),
        shouldUseRemoteDailyChallenge: () async => true,
      );
      final day = DateTime(2026, 4, 12);

      final offline = await service.getChallengeTargetForCalendarDay(day);
      online = true;
      final later = await service.getChallengeTargetForCalendarDay(day);

      expect(offline.date, '2026-04-12');
      expect(later.levelName, offline.levelName);
      expect(later.gameNumber, offline.gameNumber);
      expect(later.levelName, isNot('마스터'));
    });

    test('completion is attributed to the started day, not the finish day',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = ChallengeProgressService(
        loadGameNumbersForLevel: (_) async => [1, 2, 3, 4, 5],
        shouldUseRemoteDailyChallenge: () async => false,
      );
      final started = DateTime(2026, 4, 12);
      final target = await service.getChallengeTargetForCalendarDay(started);

      // 4/12 도전으로 시작해 자정을 넘겨 완료 → 4/12에 귀속.
      final day = await service.resolveCompletionDay(
        levelName: target.levelName,
        gameNumber: target.gameNumber,
        challengeDate: '2026-04-12',
        now: DateTime(2026, 4, 13, 0, 5),
      );
      expect(day, DateTime(2026, 4, 12));

      // 같은 날짜로 시작했어도 다른 문제를 완료하면 도전 완료가 아니다.
      final other = await service.resolveCompletionDay(
        levelName: target.levelName,
        gameNumber: target.gameNumber + 100,
        challengeDate: '2026-04-12',
      );
      expect(other, isNull);
    });

    test('uses remote daily challenge when remote catalog is active', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ChallengeProgressService(
        remotePuzzleService: _FakeRemotePuzzleService(
          target: const TodayChallengeTarget(levelName: '마스터', gameNumber: 42),
        ),
        shouldUseRemoteDailyChallenge: () async => true,
      );

      final target = await service.getChallengeTargetForCalendarDay(
        DateTime(2026, 4, 12),
      );

      expect(target.levelName, '마스터');
      expect(target.gameNumber, 42);
    });

    test('activity streak counts every completed day, not only challenges',
        () async {
      SharedPreferences.setMockInitialValues({
        'daily_challenge_backfill_v1': true,
      });
      final service = ChallengeProgressService(
        dailyChallengeCompletionRepository:
            _FakeDailyChallengeCompletionRepository(),
        loadGameNumbersForLevel: (_) async => [1],
        shouldUseRemoteDailyChallenge: () async => false,
      );
      final today = DateTime.now();
      String format(DateTime value) =>
          ChallengeProgressService.formatLocalDate(value);
      final summary = await service.load(
        recentRecords: const [],
        recentClearEvents: [
          for (var i = 0; i < 3; i++)
            {
              'clear_date': format(today.subtract(Duration(days: i))),
              'wrong_count': 0,
            },
          // 같은 날 반복 완료는 하루로 센다.
          {'clear_date': format(today), 'wrong_count': 1},
        ],
      );
      expect(summary.activityStreakDays, 3);
      expect(summary.streakDays, 0); // 도전 완료 기록은 없음
    });

    test('load uses clear events for weekly and perfect counts', () async {
      SharedPreferences.setMockInitialValues({
        'daily_challenge_backfill_v1': true,
      });
      final service = ChallengeProgressService(
        dailyChallengeCompletionRepository:
            _FakeDailyChallengeCompletionRepository(),
        loadGameNumbersForLevel: (_) async => [1],
        shouldUseRemoteDailyChallenge: () async => false,
      );
      final today = DateTime.now();
      String format(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

      final summary = await service.load(
        recentRecords: const [],
        recentClearEvents: [
          {'clear_date': format(today), 'wrong_count': 0},
          {
            'clear_date': format(WeeklyGoalService.weekStartOf(today)),
            'wrong_count': 2
          },
        ],
      );

      expect(summary.weeklyClearCount, 2);
      expect(summary.weeklyGoalTarget, 3);
      expect(summary.perfectClearCount, 1);
      expect(summary.lastClearDate, format(today));
    });
  });
}

class _FakeRemotePuzzleService extends RemotePuzzleService {
  _FakeRemotePuzzleService({required this.target, this.onFetch})
      : super(baseUrl: 'https://example.com');

  final TodayChallengeTarget target;
  final bool Function()? onFetch;

  @override
  Future<TodayChallengeTarget?> fetchDailyChallengeTarget({
    required DateTime date,
  }) async {
    if (onFetch != null && !onFetch!()) return null;
    return target;
  }
}

class _FakeDailyChallengeCompletionRepository
    extends DailyChallengeCompletionRepository {
  @override
  Future<void> addCompletionForDate(
    String yyyyMmDd, {
    String? levelName,
    int? gameNumber,
    int? clearTime,
    int? wrongCount,
    int? hintsUsed,
    bool autoNotesUsed = false,
    bool streakEligible = true,
  }) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<List<String>> getCompletionDatesDescending({int limit = 400}) async =>
      const [];

  @override
  Future<List<String>> getStreakEligibleDatesDescending({
    int limit = 400,
  }) async =>
      const [];

  @override
  Future<Map<String, DailyChallengeCompletionDetail>> getCompletionsForMonth(
    int year,
    int month,
  ) async =>
      const {};

  @override
  Future<bool> hasCompletionForDate(String yyyyMmDd) async => false;
}
