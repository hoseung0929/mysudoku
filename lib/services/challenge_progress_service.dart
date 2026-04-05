import 'package:shared_preferences/shared_preferences.dart';

import 'package:mysudoku/database/daily_challenge_completion_repository.dart';
import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/model/sudoku_level.dart';

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
  ChallengeProgressService({
    DatabaseHelper? databaseHelper,
    DailyChallengeCompletionRepository? dailyChallengeCompletionRepository,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _dailyRepo =
            dailyChallengeCompletionRepository ?? DailyChallengeCompletionRepository();

  static const _backfillPrefsKey = 'daily_challenge_backfill_v1';

  final DatabaseHelper _databaseHelper;
  final DailyChallengeCompletionRepository _dailyRepo;

  static String formatLocalDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// 디버그·테스트용: 이미 내림차순인 완료일 문자열(YYYY-MM-DD)로 연속 일수를 계산합니다.
  static int calculateDailyChallengeStreakFromDates(
    List<String> datesDescendingYyyyMmDd,
  ) {
    if (datesDescendingYyyyMmDd.isEmpty) {
      return 0;
    }
    final uniqueDesc = <String>[];
    for (final raw in datesDescendingYyyyMmDd) {
      if (uniqueDesc.isEmpty || uniqueDesc.last != raw) {
        uniqueDesc.add(raw);
      }
    }
    final parsed = uniqueDesc.map(DateTime.parse).toList();
    final today = _dateOnly(DateTime.now());
    final latest = _dateOnly(parsed.first);

    if (latest.isBefore(today.subtract(const Duration(days: 1)))) {
      return 0;
    }

    int streak = 1;
    for (var i = 1; i < parsed.length; i++) {
      final previous = _dateOnly(parsed[i - 1]);
      final current = _dateOnly(parsed[i]);
      if (previous.difference(current).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  Future<ChallengeProgressSummary> load() async {
    await _ensureBackfillDailyCompletions();
    final challengeTarget = await getTodayChallengeTarget();
    final todayStr = formatLocalDate(DateTime.now());
    final isTodayCleared = await _dailyRepo.hasCompletionForDate(todayStr);
    final recent = await _databaseHelper.getRecentClearRecords(limit: 365);
    final completionDates = await _dailyRepo.getCompletionDatesDescending();
    final streak = calculateDailyChallengeStreakFromDates(completionDates);
    final weeklyClearCount = calculateWeeklyClearCount(recent);
    final perfectClearCount = calculatePerfectClearCount(recent);
    const weeklyGoalTarget = 5;

    return ChallengeProgressSummary(
      streakDays: streak,
      isTodayChallengeCleared: isTodayCleared,
      todayChallengeLevelName: challengeTarget.levelName,
      todayChallengeGameNumber: challengeTarget.gameNumber,
      lastClearDate: recent.isEmpty ? null : recent.first['clear_date'] as String?,
      weeklyClearCount: weeklyClearCount,
      weeklyGoalTarget: weeklyGoalTarget,
      perfectClearCount: perfectClearCount,
    );
  }

  Future<void> _ensureBackfillDailyCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_backfillPrefsKey) ?? false) {
      return;
    }
    final all = await _databaseHelper.getAllClearRecords();
    for (final row in all) {
      final dateStr = row['clear_date'] as String?;
      if (dateStr == null) {
        continue;
      }
      final day = DateTime.parse(dateStr);
      final target = await getChallengeTargetForCalendarDay(day);
      if (row['level_name'] == target.levelName &&
          row['game_number'] == target.gameNumber) {
        await _dailyRepo.addCompletionForDate(dateStr);
      }
    }
    await prefs.setBool(_backfillPrefsKey, true);
  }

  /// 로컬 달력 일 기준으로 그날의 오늘의 도전(레벨·게임 번호)을 반환합니다.
  Future<TodayChallengeTarget> getChallengeTargetForCalendarDay(
    DateTime calendarDay,
  ) async {
    final dayOnly = DateTime(calendarDay.year, calendarDay.month, calendarDay.day);
    final epoch = DateTime(2024, 1, 1);
    final daysSinceEpoch = dayOnly.difference(epoch).inDays;
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

  Future<TodayChallengeTarget> getTodayChallengeTarget() async {
    return getChallengeTargetForCalendarDay(DateTime.now());
  }

  Future<bool> isTodayChallenge({
    required String levelName,
    required int gameNumber,
  }) async {
    final target = await getTodayChallengeTarget();
    return target.levelName == levelName && target.gameNumber == gameNumber;
  }

  int calculateWeeklyClearCount(List<Map<String, dynamic>> recent) {
    final today = _dateOnly(DateTime.now());
    final earliest = today.subtract(const Duration(days: 6));

    return recent.where((record) {
      final rawDate = record['clear_date'] as String?;
      if (rawDate == null) {
        return false;
      }
      final clearDate = _dateOnly(DateTime.parse(rawDate));
      return !clearDate.isBefore(earliest) && !clearDate.isAfter(today);
    }).length;
  }

  int calculatePerfectClearCount(List<Map<String, dynamic>> recent) {
    final today = _dateOnly(DateTime.now());
    final earliest = today.subtract(const Duration(days: 6));

    return recent.where((record) {
      final rawDate = record['clear_date'] as String?;
      if (rawDate == null) {
        return false;
      }
      final clearDate = _dateOnly(DateTime.parse(rawDate));
      final wrongCount = record['wrong_count'] as int? ?? 0;
      return !clearDate.isBefore(earliest) &&
          !clearDate.isAfter(today) &&
          wrongCount == 0;
    }).length;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class TodayChallengeTarget {
  const TodayChallengeTarget({
    required this.levelName,
    required this.gameNumber,
  });

  final String levelName;
  final int gameNumber;
}
