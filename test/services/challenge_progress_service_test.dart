import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/model/today_challenge_target.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/services/remote_puzzle_service.dart';
import 'package:mysudoku/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  group('ChallengeProgressService', () {
    test('calculates consecutive streak from daily completion dates', () {
      final today = DateTime.now();
      String format(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

      final streak = ChallengeProgressService.calculateDailyChallengeStreakFromDates([
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

      final streak = ChallengeProgressService.calculateDailyChallengeStreakFromDates([
        format(today.subtract(const Duration(days: 3))),
        format(today.subtract(const Duration(days: 4))),
      ]);

      expect(streak, 0);
    });

    test('counts weekly clears within the recent seven-day window', () {
      final service = ChallengeProgressService();
      final today = DateTime.now();
      String format(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

      final count = service.calculateWeeklyClearCount([
        {'clear_date': format(today), 'wrong_count': 1},
        {'clear_date': format(today.subtract(const Duration(days: 1))), 'wrong_count': 0},
        {'clear_date': format(today.subtract(const Duration(days: 6))), 'wrong_count': 2},
        {'clear_date': format(today.subtract(const Duration(days: 7))), 'wrong_count': 0},
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
        {'clear_date': format(today.subtract(const Duration(days: 2))), 'wrong_count': 0},
        {'clear_date': format(today.subtract(const Duration(days: 4))), 'wrong_count': 2},
        {'clear_date': format(today.subtract(const Duration(days: 8))), 'wrong_count': 0},
      ]);

      expect(perfectCount, 2);
    });

    test('selects an existing challenge game number when numbering has holes', () async {
      final service = ChallengeProgressService(
        loadGameNumbersForLevel: (levelName) async {
          if (levelName == '초급') {
            return [1, 3, 7];
          }
          return [1];
        },
      );

      final target = await service.getChallengeTargetForCalendarDay(
        DateTime(2026, 4, 10),
      );

      expect(target.levelName, '초급');
      expect([1, 3, 7], contains(target.gameNumber));
    });

    test('uses remote daily challenge when remote catalog is active', () async {
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
  });
}

class _FakeRemotePuzzleService extends RemotePuzzleService {
  _FakeRemotePuzzleService({required this.target}) : super(baseUrl: 'https://example.com');

  final TodayChallengeTarget target;

  @override
  Future<TodayChallengeTarget?> fetchDailyChallengeTarget({
    required DateTime date,
  }) async {
    return target;
  }
}
