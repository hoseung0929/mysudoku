import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이번 주(월요일 00:00 ~ 일요일 23:59) 목표와 진행 상황.
class WeeklyGoalState {
  const WeeklyGoalState({
    required this.weekStart,
    required this.target,
    required this.completed,
  });

  /// 이번 주 월요일(로컬 날짜, 시간 없음).
  final DateTime weekStart;

  /// 이번 주 목표 판수(3·5·7 중 하나). 주가 시작될 때 정해 그 주 동안 고정된다.
  final int target;

  /// 이번 주 완료한 판수(재도전 완료도 한 판으로 센다).
  final int completed;

  bool get isAchieved => completed >= target;
  int get remaining => isAchieved ? 0 : target - completed;
  double get progress => target <= 0 ? 0 : (completed / target).clamp(0.0, 1.0);
}

/// 주간 목표 정책:
///  * 주는 월요일 시작이다.
///  * 목표는 3·5·7판 중 하나이며, 주가 시작될 때 **직전 완료된 2주**의 플레이량으로
///    정하고 그 주 동안 바꾸지 않는다(이번 주 플레이는 목표 산정에 넣지 않는다).
///  * 주 시작 날짜와 확정 목표를 로컬에 저장해 앱 재실행·시간대 변경 후에도
///    같은 주에는 같은 목표를 쓴다.
class WeeklyGoalService {
  WeeklyGoalService({SharedPreferences? prefs, DateTime Function()? now})
      : _prefs = prefs,
        _now = now ?? DateTime.now;

  static const String weekStartKey = 'weekly_goal_week_start_v1';
  static const String targetKey = 'weekly_goal_target_v1';
  static const String celebratedWeekKey = 'weekly_goal_celebrated_week_v1';

  /// 직전 2주 완료 수가 이 값 이하면 3판, [highActivityMinimum] 이상이면 7판.
  static const int lowActivityMaximum = 4;
  static const int highActivityMinimum = 15;

  SharedPreferences? _prefs;
  final DateTime Function() _now;

  Future<SharedPreferences> get _resolvedPrefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// 테스트에서 같은 저장소로 서비스를 다시 만들 때(앱 재실행) 쓴다.
  @visibleForTesting
  SharedPreferences get debugPrefs => _prefs!;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// [d]가 속한 주의 월요일(로컬 날짜).
  static DateTime weekStartOf(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));

  static String formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parse(String? raw) {
    if (raw == null) return null;
    try {
      return dateOnly(DateTime.parse(raw));
    } catch (_) {
      return null;
    }
  }

  /// 서머타임과 무관하게 달력상 날짜 차이를 센다.
  static int _daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays;

  /// 직전 2주 완료 수로 목표(3·5·7판)를 정한다.
  static int targetForPreviousTwoWeeks(int clears) {
    if (clears <= lowActivityMaximum) return 3;
    if (clears >= highActivityMinimum) return 7;
    return 5;
  }

  /// [from]~[to](양끝 포함) 사이 완료 이벤트 수. 재도전 완료도 센다.
  static int countClears(
    List<Map<String, dynamic>> events,
    DateTime from,
    DateTime to,
  ) {
    var count = 0;
    for (final event in events) {
      final date = _parse(event['clear_date']?.toString());
      if (date == null) continue;
      if (!date.isBefore(from) && !date.isAfter(to)) count++;
    }
    return count;
  }

  /// [weekStart] 직전 2주(14일)의 완료 수로 정한 목표.
  static int targetForWeek(
    List<Map<String, dynamic>> events,
    DateTime weekStart,
  ) {
    final from = DateTime(weekStart.year, weekStart.month, weekStart.day - 14);
    final to = DateTime(weekStart.year, weekStart.month, weekStart.day - 1);
    return targetForPreviousTwoWeeks(countClears(events, from, to));
  }

  /// 이번 주 목표와 진행을 구한다. 새 주가 시작됐으면 목표를 새로 정해 저장한다.
  Future<WeeklyGoalState> resolve(List<Map<String, dynamic>> events) async {
    final prefs = await _resolvedPrefs;
    final today = dateOnly(_now());
    final storedStart = _parse(prefs.getString(weekStartKey));
    final storedTarget = prefs.getInt(targetKey);
    final hasValidStored = storedStart != null &&
        (storedTarget == 3 || storedTarget == 5 || storedTarget == 7);

    // 저장된 주 시작부터 7일이 지나지 않았으면 같은 주다. 시간대 변경으로
    // 로컬 날짜가 하루 정도 뒤로 가 보이는 경우까지만 저장된 주를 유지하고,
    // 그보다 과거로 돌아가면(시계 변경 등) 새 주로 다시 정한다.
    final daysSinceStored =
        hasValidStored ? _daysBetween(storedStart, today) : 0;
    if (hasValidStored && daysSinceStored >= -1 && daysSinceStored < 7) {
      return WeeklyGoalState(
        weekStart: storedStart,
        target: storedTarget!,
        completed: _completedIn(events, storedStart),
      );
    }

    final weekStart = weekStartOf(today);
    final target = targetForWeek(events, weekStart);
    await prefs.setString(weekStartKey, formatDate(weekStart));
    await prefs.setInt(targetKey, target);
    return WeeklyGoalState(
      weekStart: weekStart,
      target: target,
      completed: _completedIn(events, weekStart),
    );
  }

  static int _completedIn(List<Map<String, dynamic>> events, DateTime start) =>
      countClears(
        events,
        start,
        DateTime(start.year, start.month, start.day + 6),
      );

  /// 방금 한 판으로 이번 주 목표를 **처음** 달성했는지 확인하고, 그렇다면 같은
  /// 주에는 다시 true를 돌려주지 않도록 기록한다. 완료 결과 화면에서 한 번만
  /// 축하하기 위한 것이다(앱 재실행·재도전으로 반복되지 않는다).
  Future<bool> consumeCelebration(List<Map<String, dynamic>> events) async {
    final state = await resolve(events);
    // 이번 판이 목표를 정확히 채운 판일 때만(이미 넘긴 주에는 축하하지 않는다).
    if (state.completed != state.target) return false;
    final prefs = await _resolvedPrefs;
    final weekKey = formatDate(state.weekStart);
    if (prefs.getString(celebratedWeekKey) == weekKey) return false;
    await prefs.setString(celebratedWeekKey, weekKey);
    return true;
  }
}
