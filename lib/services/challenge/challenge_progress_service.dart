import 'package:shared_preferences/shared_preferences.dart';

import 'package:sudoku159/database/daily_challenge_completion_repository.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/database/database_manager.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/model/today_challenge_target.dart';
import 'package:sudoku159/services/catalog/remote_puzzle_service.dart';
import 'package:sudoku159/services/game/game_state_service.dart';

enum ChallengeDayStatus {
  future,
  notCompleted,
  inProgress,
  completed,
  perfectCompleted,
}

class ChallengeMonthCalendar {
  const ChallengeMonthCalendar({
    required this.year,
    required this.month,
    required this.statusByDate,
    required this.isMonthFullyCompleted,
  });

  final int year;
  final int month;

  /// 날짜(YYYY-MM-DD) → 그날의 상태. 그 달의 실제 날짜 수만큼 들어 있다.
  final Map<String, ChallengeDayStatus> statusByDate;

  /// 그 달의 모든(미래 제외) 날짜가 완료 상태여야 하고, 현재 달이면 마지막
  /// 날까지 지나 있어야 true가 된다(미래 날짜가 하나라도 있으면 자동으로
  /// false).
  final bool isMonthFullyCompleted;
}

class ChallengeProgressSummary {
  const ChallengeProgressSummary({
    required this.streakDays,
    this.activityStreakDays = 0,
    required this.isTodayChallengeCleared,
    required this.todayChallengeLevelName,
    required this.todayChallengeGameNumber,
    this.challengeDate,
    required this.lastClearDate,
    required this.weeklyClearCount,
    required this.weeklyGoalTarget,
    required this.perfectClearCount,
  });

  /// 오늘의 도전 완료 날짜 기준 연속 일수.
  final int streakDays;

  /// 일반 퍼즐을 포함해 하루 1판 이상 완료한 날의 연속 일수(기록 화면과 같은 기준).
  final int activityStreakDays;
  final bool isTodayChallengeCleared;
  final String todayChallengeLevelName;
  final int todayChallengeGameNumber;

  /// 위 타깃이 정해진 로컬 일자(YYYY-MM-DD).
  final String? challengeDate;
  final String? lastClearDate;
  final int weeklyClearCount;
  final int weeklyGoalTarget;
  final int perfectClearCount;

  bool get isWeeklyGoalAchieved => weeklyClearCount >= weeklyGoalTarget;
  int get remainingWeeklyGoal => weeklyGoalTarget > weeklyClearCount
      ? weeklyGoalTarget - weeklyClearCount
      : 0;
}

class ChallengeProgressService {
  ChallengeProgressService({
    DatabaseHelper? databaseHelper,
    DailyChallengeCompletionRepository? dailyChallengeCompletionRepository,
    Future<List<int>> Function(String levelName)? loadGameNumbersForLevel,
    Future<List<Map<String, dynamic>>> Function({int limit})?
        loadRecentClearEvents,
    RemotePuzzleService? remotePuzzleService,
    Future<bool> Function()? shouldUseRemoteDailyChallenge,
    GameStateService? gameStateService,
  })  : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _gameStateService = gameStateService ?? GameStateService(),
        _dailyRepo = dailyChallengeCompletionRepository ??
            DailyChallengeCompletionRepository(),
        _loadGameNumbersForLevel = loadGameNumbersForLevel ??
            (databaseHelper ?? DatabaseHelper()).getGameNumbersForLevel,
        _loadRecentClearEvents = loadRecentClearEvents ??
            (databaseHelper ?? DatabaseHelper()).getRecentClearEvents,
        _remotePuzzleService = remotePuzzleService ?? RemotePuzzleService(),
        _shouldUseRemoteDailyChallenge = shouldUseRemoteDailyChallenge ??
            (() async {
              try {
                return await DatabaseManager().isRemoteCatalogActive();
              } catch (_) {
                return false;
              }
            });

  static const _backfillPrefsKey = 'daily_challenge_backfill_v1';

  final DatabaseHelper _databaseHelper;
  final GameStateService _gameStateService;
  final DailyChallengeCompletionRepository _dailyRepo;
  final Future<List<int>> Function(String levelName) _loadGameNumbersForLevel;
  final Future<List<Map<String, dynamic>>> Function({int limit})
      _loadRecentClearEvents;
  final RemotePuzzleService _remotePuzzleService;
  final Future<bool> Function() _shouldUseRemoteDailyChallenge;

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
    final parsed = <DateTime>[];
    for (final raw in uniqueDesc) {
      final parsedDate = _tryParseDateOnly(raw);
      if (parsedDate != null) {
        parsed.add(parsedDate);
      }
    }
    if (parsed.isEmpty) {
      return 0;
    }
    final today = _dateOnly(DateTime.now());
    final latest = parsed.first;

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

  Future<ChallengeProgressSummary> load({
    List<Map<String, dynamic>>? recentRecords,
    List<Map<String, dynamic>>? recentClearEvents,
  }) async {
    await _ensureBackfillDailyCompletions();
    final challengeTarget = await getTodayChallengeTarget();
    final todayStr = formatLocalDate(DateTime.now());
    final isTodayCleared = await _dailyRepo.hasCompletionForDate(todayStr);
    final recent = recentRecords ??
        await _databaseHelper.getRecentClearRecords(limit: 365);
    final clearEvents =
        recentClearEvents ?? await _loadRecentClearEvents(limit: 365);
    final completionDates = await _dailyRepo.getStreakEligibleDatesDescending();
    final streak = calculateDailyChallengeStreakFromDates(completionDates);
    final activityDates = clearEvents
        .map((event) => event['clear_date']?.toString())
        .whereType<String>()
        .where((date) => date.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final activityStreak =
        calculateDailyChallengeStreakFromDates(activityDates);
    final weeklyClearCount = calculateWeeklyClearCount(clearEvents);
    final perfectClearCount = calculatePerfectClearCount(clearEvents);
    final weeklyGoalTarget = calculateWeeklyGoalTarget(clearEvents);

    return ChallengeProgressSummary(
      streakDays: streak,
      activityStreakDays: activityStreak,
      isTodayChallengeCleared: isTodayCleared,
      todayChallengeLevelName: challengeTarget.levelName,
      todayChallengeGameNumber: challengeTarget.gameNumber,
      challengeDate: challengeTarget.date,
      lastClearDate: _firstClearDate(clearEvents) ?? _firstClearDate(recent),
      weeklyClearCount: weeklyClearCount,
      weeklyGoalTarget: weeklyGoalTarget,
      perfectClearCount: perfectClearCount,
    );
  }

  int calculateWeeklyGoalTarget(List<Map<String, dynamic>> recent) {
    final today = _dateOnly(DateTime.now());
    final earliest = today.subtract(const Duration(days: 13));
    final recentTwoWeekClears = recent.where((record) {
      final rawDate = record['clear_date'] as String?;
      if (rawDate == null) {
        return false;
      }
      final clearDate = _tryParseDateOnly(rawDate);
      if (clearDate == null) {
        return false;
      }
      return !clearDate.isBefore(earliest) && !clearDate.isAfter(today);
    }).length;

    if (recentTwoWeekClears <= 4) {
      return 3;
    }
    if (recentTwoWeekClears >= 15) {
      return 7;
    }
    return 5;
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
      final day = _tryParseDateOnly(dateStr);
      if (day == null) {
        continue;
      }
      // 백필은 기존 로컬 규칙만 사용해 초기 로드 시 원격 왕복 비용을 줄인다.
      final target = await _getLocalChallengeTargetForCalendarDay(day);
      if (row['level_name'] == target.levelName &&
          row['game_number'] == target.gameNumber) {
        await _dailyRepo.addCompletionForDate(dateStr);
      }
    }
    await prefs.setBool(_backfillPrefsKey, true);
  }

  static const _targetCachePrefix = 'daily_challenge_target_v1_';

  /// 로컬 달력 일 기준으로 그날의 오늘의 도전(레벨·게임 번호)을 반환합니다.
  ///
  /// 그날 처음 확정된 타깃을 로컬에 고정한다. 이후 네트워크 상태가 바뀌어도
  /// 같은 날에는 표시·시작·완료 판정이 같은 타깃을 쓴다.
  Future<TodayChallengeTarget> getChallengeTargetForCalendarDay(
    DateTime calendarDay,
  ) async {
    final dateKey = formatLocalDate(calendarDay);
    final cacheKey = '$_targetCachePrefix$dateKey';
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }
    final cached = prefs?.getString(cacheKey)?.split('|');
    final cachedNumber =
        cached != null && cached.length == 2 ? int.tryParse(cached[1]) : null;
    if (cached != null && cachedNumber != null) {
      return TodayChallengeTarget(
        levelName: cached[0],
        gameNumber: cachedNumber,
        date: dateKey,
      );
    }

    TodayChallengeTarget? resolved;
    if (await _shouldUseRemoteDailyChallenge() &&
        _remotePuzzleService.isConfigured) {
      resolved = await _remotePuzzleService.fetchDailyChallengeTarget(
        date: calendarDay,
      );
    }
    resolved ??= await _getLocalChallengeTargetForCalendarDay(calendarDay);
    final target = TodayChallengeTarget(
      levelName: resolved.levelName,
      gameNumber: resolved.gameNumber,
      date: dateKey,
    );
    await prefs?.setString(
        cacheKey, '${target.levelName}|${target.gameNumber}');
    return target;
  }

  Future<TodayChallengeTarget> _getLocalChallengeTargetForCalendarDay(
    DateTime calendarDay,
  ) async {
    final dayOnly =
        DateTime(calendarDay.year, calendarDay.month, calendarDay.day);
    final epoch = DateTime(2024, 1, 1);
    final daysSinceEpoch = dayOnly.difference(epoch).inDays;
    final activeLevels =
        SudokuLevel.levels.where((l) => !l.isMasterLevel).toList();
    final levelIndex = daysSinceEpoch % activeLevels.length;
    final level = activeLevels[levelIndex];
    final gameNumbers = await _loadGameNumbersForLevel(level.name);
    final safeGameNumbers =
        gameNumbers.where((gameNumber) => gameNumber > 0).toList()..sort();
    final gameNumber = safeGameNumbers.isEmpty
        ? 1
        : safeGameNumbers[daysSinceEpoch % safeGameNumbers.length];

    return TodayChallengeTarget(
      levelName: level.name,
      gameNumber: gameNumber,
    );
  }

  Future<TodayChallengeTarget> getTodayChallengeTarget() async {
    return getChallengeTargetForCalendarDay(DateTime.now());
  }

  /// 이번 달의 하루하루 상태를 한 번에 계산한다(달력 셀 개수만큼 DB·원격을
  /// 반복 호출하지 않도록, 완료 세부 기록은 배치 조회 한 번, 진행 중 판정은
  /// 저장된 세션 목록 한 번으로 처리한다). 각 날짜의 실제 퍼즐은 사용자가
  /// 그 날짜를 눌렀을 때만 별도로 불러온다.
  Future<ChallengeMonthCalendar> loadMonthCalendar({
    required int year,
    required int month,
  }) async {
    final completions =
        await _databaseHelper.getDailyChallengeCompletionsForMonth(
      year,
      month,
    );
    final savedGames = await _gameStateService.getSavedGames();
    final inProgressDates = <String>{
      for (final saved in savedGames)
        if (saved.session.challengeDate != null &&
            _looksInProgress(saved.session))
          saved.session.challengeDate!,
    };

    final today = _dateOnly(DateTime.now());
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final statusByDate = <String, ChallengeDayStatus>{};
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dateStr = formatLocalDate(date);
      if (date.isAfter(today)) {
        statusByDate[dateStr] = ChallengeDayStatus.future;
        continue;
      }
      final detail = completions[dateStr];
      if (detail != null) {
        statusByDate[dateStr] = detail.isPerfect
            ? ChallengeDayStatus.perfectCompleted
            : ChallengeDayStatus.completed;
      } else if (inProgressDates.contains(dateStr)) {
        statusByDate[dateStr] = ChallengeDayStatus.inProgress;
      } else {
        statusByDate[dateStr] = ChallengeDayStatus.notCompleted;
      }
    }

    final isMonthFullyCompleted = statusByDate.values.every(
      (status) =>
          status == ChallengeDayStatus.completed ||
          status == ChallengeDayStatus.perfectCompleted,
    );

    return ChallengeMonthCalendar(
      year: year,
      month: month,
      statusByDate: statusByDate,
      isMonthFullyCompleted: isMonthFullyCompleted,
    );
  }

  /// 세션 저장 시점에 계산돼 함께 저장된 [GameSessionState.userFilledCells]를
  /// 쓰므로, 퍼즐마다 원본 보드를 다시 불러오지 않고도(달력 셀 31개를 한
  /// 번에 계산해야 하므로) 정답 숫자만 채운 세션까지 정확히 판정한다.
  bool _looksInProgress(GameSessionState session) {
    if (session.isGameComplete || session.isGameOver) return false;
    return session.userFilledCells > 0 ||
        session.hasNotes ||
        session.wrongCount > 0 ||
        session.hasUsedHint;
  }

  /// 완료한 게임이 어느 날의 오늘의 도전 완료로 귀속되는지 반환한다(해당 없으면 null).
  ///
  /// 오늘의 도전으로 시작한 게임([challengeDate] 있음)은 시작한 도전 날짜에
  /// 귀속한다. 자정을 넘겨 완료해도 다른 날 타깃으로 재판정하지 않는다. 일반
  /// 경로로 푼 경우는 지정 문제와 일치할 때만 완료 시점의 오늘로 처리한다.
  Future<DateTime?> resolveCompletionDay({
    required String levelName,
    required int gameNumber,
    String? challengeDate,
    DateTime? now,
  }) async {
    if (challengeDate == null) {
      final isToday = await isTodayChallenge(
        levelName: levelName,
        gameNumber: gameNumber,
      );
      return isToday ? (now ?? DateTime.now()) : null;
    }
    final day = DateTime.tryParse(challengeDate);
    if (day == null) return null;
    final target = await getChallengeTargetForCalendarDay(day);
    final matches =
        target.levelName == levelName && target.gameNumber == gameNumber;
    return matches ? day : null;
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
      final clearDate = _tryParseDateOnly(rawDate);
      if (clearDate == null) {
        return false;
      }
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
      final clearDate = _tryParseDateOnly(rawDate);
      if (clearDate == null) {
        return false;
      }
      final wrongCount = _recordInt(record, 'wrong_count');
      return !clearDate.isBefore(earliest) &&
          !clearDate.isAfter(today) &&
          wrongCount == 0;
    }).length;
  }

  static int _recordInt(Map<String, dynamic> record, String field) {
    final value = record[field];
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _tryParseDateOnly(String raw) {
    try {
      return _dateOnly(DateTime.parse(raw));
    } catch (_) {
      return null;
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String? _firstClearDate(List<Map<String, dynamic>> records) {
    for (final record in records) {
      final rawDate = record['clear_date'];
      if (rawDate is String && rawDate.isNotEmpty) {
        return rawDate;
      }
    }
    return null;
  }
}
