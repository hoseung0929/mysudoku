import '../database/database_helper.dart';
import '../model/sudoku_level.dart';

class ChallengeProgressSummary {
  const ChallengeProgressSummary({
    required this.streakDays,
    required this.isTodayChallengeCleared,
    required this.todayChallengeLevelName,
    required this.todayChallengeGameNumber,
    required this.lastClearDate,
    required this.weeklyClearCount,
    required this.weeklyGoalTarget,
    required this.perfectClearCount,
  });

  final int streakDays;
  final bool isTodayChallengeCleared;
  final String todayChallengeLevelName;
  final int todayChallengeGameNumber;
  final String? lastClearDate;
  final int weeklyClearCount;
  final int weeklyGoalTarget;
  final int perfectClearCount;

  bool get isWeeklyGoalAchieved => weeklyClearCount >= weeklyGoalTarget;
  int get remainingWeeklyGoal =>
      weeklyGoalTarget > weeklyClearCount ? weeklyGoalTarget - weeklyClearCount : 0;
}

class ChallengeProgressService {
  ChallengeProgressService({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;

  Future<ChallengeProgressSummary> load() async {
    final challengeTarget = await getTodayChallengeTarget();
    final todayRecord = await _databaseHelper.getClearRecord(
      challengeTarget.levelName,
      challengeTarget.gameNumber,
    );
    final recent = await _databaseHelper.getRecentClearRecords(limit: 365);
    final streak = _calculateStreak(recent);
    final weeklyClearCount = calculateWeeklyClearCount(recent);
    final perfectClearCount = calculatePerfectClearCount(recent);
    const weeklyGoalTarget = 5;

    return ChallengeProgressSummary(
      streakDays: streak,
      isTodayChallengeCleared: todayRecord != null,
      todayChallengeLevelName: challengeTarget.levelName,
      todayChallengeGameNumber: challengeTarget.gameNumber,
      lastClearDate: recent.isEmpty ? null : recent.first['clear_date'] as String?,
      weeklyClearCount: weeklyClearCount,
      weeklyGoalTarget: weeklyGoalTarget,
      perfectClearCount: perfectClearCount,
    );
  }

  Future<TodayChallengeTarget> getTodayChallengeTarget() async {
    final daysSinceEpoch = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    final levelIndex = daysSinceEpoch % SudokuLevel.levels.length;
    final level = SudokuLevel.levels[levelIndex];
    final gameCount = await _databaseHelper.getGameCount(level.name);
    final safeGameCount = gameCount == 0 ? 1 : gameCount;
    final gameNumber = (daysSinceEpoch % safeGameCount) + 1;

    return TodayChallengeTarget(
      levelName: level.name,
      gameNumber: gameNumber,
    );
  }

  Future<bool> isTodayChallenge({
    required String levelName,
    required int gameNumber,
  }) async {
    final target = await getTodayChallengeTarget();
    return target.levelName == levelName && target.gameNumber == gameNumber;
  }

  int calculateStreakFromRecords(List<Map<String, dynamic>> recent) {
    return _calculateStreak(recent);
  }

  int calculateWeeklyClearCount(List<Map<String, dynamic>> recent) {
    final today = _dateOnly(DateTime.now());
    final earliest = today.subtract(const Duration(days: 6));

    return recent.where((record) {
      final rawDate = record['clear_date'] as String?;
      if (rawDate == null) return false;
      final clearDate = _dateOnly(DateTime.parse(rawDate));
      return !clearDate.isBefore(earliest) && !clearDate.isAfter(today);
    }).length;
  }

  int calculatePerfectClearCount(List<Map<String, dynamic>> recent) {
    final today = _dateOnly(DateTime.now());
    final earliest = today.subtract(const Duration(days: 6));

    return recent.where((record) {
      final rawDate = record['clear_date'] as String?;
      if (rawDate == null) return false;
      final clearDate = _dateOnly(DateTime.parse(rawDate));
      final wrongCount = record['wrong_count'] as int? ?? 0;
      return !clearDate.isBefore(earliest) &&
          !clearDate.isAfter(today) &&
          wrongCount == 0;
    }).length;
  }

  int _calculateStreak(List<Map<String, dynamic>> recent) {
    if (recent.isEmpty) {
      return 0;
    }

    final uniqueDates = <DateTime>[];
    final seen = <String>{};
    for (final record in recent) {
      final rawDate = record['clear_date'] as String?;
      if (rawDate == null || seen.contains(rawDate)) {
        continue;
      }
      seen.add(rawDate);
      uniqueDates.add(DateTime.parse(rawDate));
    }

    if (uniqueDates.isEmpty) {
      return 0;
    }

    uniqueDates.sort((a, b) => b.compareTo(a));
    final today = _dateOnly(DateTime.now());
    final latest = _dateOnly(uniqueDates.first);

    if (latest.isBefore(today.subtract(const Duration(days: 1)))) {
      return 0;
    }

    int streak = 1;
    for (int i = 1; i < uniqueDates.length; i++) {
      final previous = _dateOnly(uniqueDates[i - 1]);
      final current = _dateOnly(uniqueDates[i]);
      if (previous.difference(current).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
}

class TodayChallengeTarget {
  const TodayChallengeTarget({
    required this.levelName,
    required this.gameNumber,
  });

  final String levelName;
  final int gameNumber;
}
