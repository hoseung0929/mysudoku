import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/services/challenge/weekly_goal_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String fmt(DateTime d) => WeeklyGoalService.formatDate(d);
  Map<String, dynamic> clear(DateTime d) => {'clear_date': fmt(d)};
  List<Map<String, dynamic>> clears(DateTime d, int n) =>
      [for (var i = 0; i < n; i++) clear(d)];

  // 2026-10-05는 월요일이다.
  final monday = DateTime(2026, 10, 5);
  final sunday = DateTime(2026, 10, 11, 23, 59);
  final prevMonday = DateTime(2026, 9, 28);
  final nextMonday = DateTime(2026, 10, 12);

  Future<WeeklyGoalService> service(
    DateTime Function() now, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    return WeeklyGoalService(
      prefs: await SharedPreferences.getInstance(),
      now: now,
    );
  }

  /// 같은 저장소를 쓰는 새 서비스(앱 재실행).
  WeeklyGoalService restarted(WeeklyGoalService old, DateTime Function() now) =>
      WeeklyGoalService(prefs: old.debugPrefs, now: now);

  group('week boundaries', () {
    test('weekStartOf is the Monday of that week', () {
      for (var i = 0; i < 7; i++) {
        expect(
            WeeklyGoalService.weekStartOf(DateTime(2026, 10, 5 + i)), monday);
      }
      expect(WeeklyGoalService.weekStartOf(nextMonday), nextMonday);
      expect(WeeklyGoalService.weekStartOf(DateTime(2026, 10, 4)), prevMonday);
    });

    test('Monday 00:00 starts a week and Sunday 23:59 still belongs to it',
        () async {
      final events = [
        clear(DateTime(2026, 10, 4)), // 지난주 일요일
        clear(monday), // 이번 주 월요일
        clear(DateTime(2026, 10, 11)), // 이번 주 일요일
        clear(nextMonday), // 다음 주 월요일
      ];
      final atMonday = await service(() => monday);
      expect((await atMonday.resolve(events)).completed, 2);
      final atSunday = await service(() => sunday);
      expect((await atSunday.resolve(events)).completed, 2);
    });

    test('year end and year start weeks', () async {
      // 2026-12-28(월) ~ 2027-01-03(일)은 한 주다.
      expect(WeeklyGoalService.weekStartOf(DateTime(2027, 1, 1)),
          DateTime(2026, 12, 28));
      expect(WeeklyGoalService.weekStartOf(DateTime(2027, 1, 3)),
          DateTime(2026, 12, 28));
      expect(WeeklyGoalService.weekStartOf(DateTime(2027, 1, 4)),
          DateTime(2027, 1, 4));
      final s = await service(() => DateTime(2027, 1, 2));
      final state = await s.resolve([
        clear(DateTime(2026, 12, 28)),
        clear(DateTime(2026, 12, 31)),
        clear(DateTime(2027, 1, 2)),
        clear(DateTime(2026, 12, 27)), // 지난주
      ]);
      expect(state.weekStart, DateTime(2026, 12, 28));
      expect(state.completed, 3);
    });
  });

  group('target', () {
    test('low, medium and high activity map to 3, 5 and 7', () {
      expect(WeeklyGoalService.targetForPreviousTwoWeeks(0), 3);
      expect(WeeklyGoalService.targetForPreviousTwoWeeks(4), 3);
      expect(WeeklyGoalService.targetForPreviousTwoWeeks(5), 5);
      expect(WeeklyGoalService.targetForPreviousTwoWeeks(14), 5);
      expect(WeeklyGoalService.targetForPreviousTwoWeeks(15), 7);
      expect(WeeklyGoalService.targetForPreviousTwoWeeks(40), 7);
    });

    test('is decided from the two previous full weeks only', () async {
      final previous = [
        ...clears(DateTime(2026, 9, 29), 3),
        ...clears(DateTime(2026, 9, 22), 2), // 직전 2주 안(9/21~10/4)
        ...clears(DateTime(2026, 9, 20), 40), // 2주보다 오래됨: 무시
      ];
      final s = await service(() => monday);
      expect((await s.resolve(previous)).target, 5);
    });

    test('this week plays never raise the goal (3 -> 5 -> 7)', () async {
      final s = await service(() => monday);
      final first = await s.resolve(clears(DateTime(2026, 9, 29), 1));
      expect(first.target, 3);

      // 같은 주에 판수가 늘어도 목표는 그대로다.
      for (final n in [5, 15, 40]) {
        final later = restarted(s, () => DateTime(2026, 10, 8));
        final state = await later.resolve([
          ...clears(DateTime(2026, 9, 29), 1),
          ...clears(DateTime(2026, 10, 7), n),
        ]);
        expect(state.target, 3);
        expect(state.completed, n);
      }
    });

    test('stays the same after an app restart', () async {
      final s = await service(() => monday);
      await s.resolve(clears(DateTime(2026, 9, 29), 10)); // 5판 목표
      final reopened = restarted(s, () => DateTime(2026, 10, 9));
      // 이전 활동 기록이 사라졌다고 가정해도 같은 주 목표는 유지된다.
      expect((await reopened.resolve(const [])).target, 5);
    });

    test('stays the same after a time zone change within the week', () async {
      final s = await service(() => monday);
      await s.resolve(clears(DateTime(2026, 9, 29), 10)); // 5판 목표
      // 서쪽으로 이동해 로컬 날짜가 일요일(지난주 날짜)로 보여도 같은 주다.
      final shifted = restarted(s, () => DateTime(2026, 10, 4, 22));
      final state = await shifted.resolve([clear(monday)]);
      expect(state.target, 5);
      expect(state.weekStart, monday);
      expect(state.completed, 1);
    });

    test('a clock moved far into the past does not keep a future week',
        () async {
      final s = await service(() => DateTime(2026, 10, 19));
      await s.resolve(clears(DateTime(2026, 10, 14), 10)); // 10/19 주: 5판
      // 한 주 이상 과거로 돌아가면 미래 주의 목표를 유지하지 않는다.
      final past = restarted(s, () => DateTime(2026, 10, 7));
      final state = await past.resolve(const []);
      expect(state.weekStart, monday);
      expect(state.target, 3);
    });

    test('an invalid stored target is recalculated', () async {
      final s = await service(
        () => monday,
        prefs: {
          WeeklyGoalService.weekStartKey: '2026-10-05',
          WeeklyGoalService.targetKey: 4,
        },
      );
      expect((await s.resolve(const [])).target, 3);
    });
  });

  group('completions', () {
    test('retries on the same day each count as a completed puzzle', () async {
      final s = await service(() => DateTime(2026, 10, 7));
      final state = await s.resolve(clears(DateTime(2026, 10, 7), 3));
      expect(state.completed, 3);
      expect(state.isAchieved, isTrue); // 목표 3
    });

    test('remaining and progress', () async {
      final s = await service(() => DateTime(2026, 10, 7));
      final state = await s.resolve(clears(DateTime(2026, 10, 7), 2));
      expect(state.target, 3);
      expect(state.remaining, 1);
      expect(state.progress, closeTo(2 / 3, 1e-9));
      expect(state.isAchieved, isFalse);
    });
  });

  group('next week', () {
    test('resets the goal and progress and re-decides from the last two weeks',
        () async {
      final s = await service(() => DateTime(2026, 10, 9));
      final thisWeek = [
        ...clears(DateTime(2026, 10, 6), 8),
        ...clears(DateTime(2026, 9, 29), 8),
      ];
      final before = await s.resolve(thisWeek);
      expect(before.target, 5); // 직전 2주(9/21~10/4)에 8판

      final nextWeek = restarted(s, () => nextMonday);
      final after = await nextWeek.resolve(thisWeek);
      expect(after.weekStart, nextMonday);
      expect(after.completed, 0);
      // 지난 두 주(9/28~10/11)에 16판 → 높음.
      expect(after.target, 7);
    });
  });

  group('celebration', () {
    test('fires once, on the clear that reaches the goal', () async {
      final s = await service(() => DateTime(2026, 10, 7));
      await s.resolve(const []); // 3판 목표 확정
      expect(await s.consumeCelebration(clears(DateTime(2026, 10, 7), 2)),
          isFalse);
      expect(
          await s.consumeCelebration(clears(DateTime(2026, 10, 7), 3)), isTrue);
      // 같은 주 재도전·재실행으로 반복되지 않는다.
      expect(await s.consumeCelebration(clears(DateTime(2026, 10, 7), 4)),
          isFalse);
      final reopened = restarted(s, () => DateTime(2026, 10, 8));
      expect(
          await reopened.consumeCelebration(clears(DateTime(2026, 10, 7), 3)),
          isFalse);
    });

    test('does not celebrate a goal that was already passed', () async {
      final s = await service(() => DateTime(2026, 10, 7));
      await s.resolve(const []);
      expect(await s.consumeCelebration(clears(DateTime(2026, 10, 7), 5)),
          isFalse);
    });

    test('can fire again in the next week', () async {
      final s = await service(() => DateTime(2026, 10, 7));
      await s.resolve(const []);
      expect(
          await s.consumeCelebration(clears(DateTime(2026, 10, 7), 3)), isTrue);

      final nextWeek = restarted(s, () => DateTime(2026, 10, 14));
      final events = [
        ...clears(DateTime(2026, 10, 7), 3),
        ...clears(DateTime(2026, 10, 14), 3),
      ];
      expect(await nextWeek.consumeCelebration(events), isTrue);
    });
  });
}
