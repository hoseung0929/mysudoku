import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/model/today_challenge_target.dart';
import 'package:sudoku159/navigation/root_nav_scope.dart';
import 'package:sudoku159/services/challenge/achievement_service.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/home/home_dashboard_service.dart';
import 'package:sudoku159/services/records/records_statistics_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/challenge/challenge_monthly_calendar_card.dart';
import 'package:sudoku159/view/records/records_statistics_screen.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:sudoku159/widgets/mascot_image.dart';
import 'package:sudoku159/widgets/sudoku_motif.dart';

class _FakeStats extends RecordsStatisticsService {
  _FakeStats(this.produce);
  final Future<RecordsStatisticsData> Function() produce;

  @override
  Future<RecordsStatisticsData> load({required int selectedPeriodDays}) =>
      produce();
}

/// 도전 달력 카드가 실제 DB를 건드리지 않게 하는 가짜. 필요한 항목만
/// 오버라이드하고, 오류 상황은 각 플래그로 만든다.
class _FakeChallengeProgressService extends ChallengeProgressService {
  _FakeChallengeProgressService({
    this.streakDays = 0,
    this.throwOnLoad = false,
    this.throwOnMonthCalendar = false,
    this.hasAnyCompletion = false,
    String? targetLevel,
    int? targetGameNumber,
  })  : targetLevel = targetLevel ?? SudokuLevel.levels.first.name,
        targetGameNumber = targetGameNumber ?? 7;

  final int streakDays;
  final bool throwOnLoad;
  final bool throwOnMonthCalendar;
  final bool hasAnyCompletion;
  final String targetLevel;
  final int targetGameNumber;

  @override
  Future<bool> hasCompletedAnyChallenge() async => hasAnyCompletion;

  @override
  Future<ChallengeProgressSummary> load({
    List<Map<String, dynamic>>? recentRecords,
    List<Map<String, dynamic>>? recentClearEvents,
  }) async {
    if (throwOnLoad) throw Exception('challenge streak load failed');
    return ChallengeProgressSummary(
      streakDays: streakDays,
      isTodayChallengeCleared: false,
      todayChallengeLevelName: targetLevel,
      todayChallengeGameNumber: targetGameNumber,
      challengeDate: ChallengeProgressService.formatLocalDate(DateTime.now()),
      lastClearDate: null,
      weeklyClearCount: 0,
      weeklyGoalTarget: 3,
      perfectClearCount: 0,
    );
  }

  @override
  Future<ChallengeMonthCalendar> loadMonthCalendar({
    required int year,
    required int month,
  }) async {
    if (throwOnMonthCalendar) throw Exception('calendar load failed');
    final now = DateTime.now();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return ChallengeMonthCalendar(
      year: year,
      month: month,
      statusByDate: {
        for (var d = 1; d <= daysInMonth; d++)
          '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}':
              DateTime(year, month, d).isAfter(
            DateTime(now.year, now.month, now.day),
          )
                  ? ChallengeDayStatus.future
                  : ChallengeDayStatus.notCompleted,
      },
      isMonthFullyCompleted: false,
    );
  }

  @override
  Future<TodayChallengeTarget> getChallengeTargetForCalendarDay(
    DateTime calendarDay,
  ) async {
    return TodayChallengeTarget(
      levelName: targetLevel,
      gameNumber: targetGameNumber,
      date: ChallengeProgressService.formatLocalDate(calendarDay),
    );
  }
}

class _FakeHomeDashboard extends HomeDashboardService {
  _FakeHomeDashboard(this.loadData);
  final Future<HomeDashboardData> Function() loadData;
  int loadCount = 0;

  @override
  Future<HomeDashboardData> load(
    AppLocalizations l10n, {
    int continueGamesLimit = 3,
  }) {
    loadCount++;
    return loadData();
  }
}

class _FakeDatabaseHelper implements DatabaseHelper {
  _FakeDatabaseHelper({this.failGameEntry = false});
  final bool failGameEntry;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  Future<Map<String, dynamic>?> getGameEntry(
    String levelName,
    int gameNumber,
  ) async {
    if (failGameEntry) return null;
    return {
      'game_number': gameNumber,
      'board': _puzzle(),
      'solution': _solution(),
    };
  }
}

List<List<int>> _solution() => List.generate(
      9,
      (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1),
    );

List<List<int>> _puzzle() {
  final b = _solution();
  for (var i = 0; i < 30; i++) {
    b[i ~/ 9][i % 9] = 0;
  }
  return b;
}

HomeDashboardData _dashboardData({
  SudokuGame? todayChallenge,
  bool noChallenge = false,
  bool hasTodaySession = false,
  String? challengeDate,
}) {
  final level = SudokuLevel.levels.first;
  final defaultGame = SudokuGame(
    board: _puzzle(),
    solution: _solution(),
    emptyCells: level.emptyCells,
    levelName: level.name,
    gameNumber: 7,
  );
  final game = noChallenge ? null : (todayChallenge ?? defaultGame);
  final targetForSummary = game ?? defaultGame;
  return HomeDashboardData(
    continueGame: null,
    continueGames: const [],
    totalContinueCount: 0,
    todayChallenge: game,
    todayChallengeHasSession: hasTodaySession,
    challengeProgress: ChallengeProgressSummary(
      streakDays: 0,
      isTodayChallengeCleared: false,
      todayChallengeLevelName: targetForSummary.levelName,
      todayChallengeGameNumber: targetForSummary.gameNumber,
      challengeDate: challengeDate ??
          ChallengeProgressService.formatLocalDate(
            DateTime.now(),
          ),
      lastClearDate: null,
      weeklyClearCount: 0,
      weeklyGoalTarget: 3,
      perfectClearCount: 0,
    ),
    achievementSummary: const AchievementSummary(badges: []),
    averageClearTimeSeconds: 0,
  );
}

String _date(DateTime d) => ChallengeProgressService.formatLocalDate(d);

RecordsStatisticsData _data({
  List<Map<String, dynamic>> recent = const [],
  List<Map<String, dynamic>> events = const [],
}) {
  return RecordsStatisticsData(
    overall: {'total_cleared': recent.length, 'total_games': 636},
    levels: [
      for (final n in ['초급', '중급', '고급', '전문가', '마스터'])
        {'level_name': n, 'total_count': 159},
    ],
    recent: recent,
    activitySummary: const {
      'total_clears': 3,
      'current_streak_days': 2,
      'best_streak_days': 5,
    },
    events: events,
  );
}

Map<String, dynamic> _clear(
        String level, int number, int seconds, int wrong, DateTime day) =>
    {
      'level_name': level,
      'game_number': number,
      'clear_time': seconds,
      'wrong_count': wrong,
      'clear_date': _date(day),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  // 일부 실제 저장소 경로가 위젯 테스트에서 열려도 플랫폼 채널 예외가 나지
  // 않도록 ffi 구현을 사용한다.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final today = DateTime.now();

  late Directory originalCwd;
  late Directory isolatedCwd;

  setUp(() async {
    originalCwd = Directory.current;
    isolatedCwd = await Directory.systemTemp.createTemp(
      'records_statistics_screen_test_',
    );
    Directory.current = isolatedCwd;
  });

  tearDown(() async {
    Directory.current = originalCwd;
    try {
      await isolatedCwd.delete(recursive: true);
    } catch (_) {}
  });

  Future<void> pumpRecords(
    WidgetTester tester,
    Future<RecordsStatisticsData> Function() produce, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    ThemeData? theme,
    Locale? locale,
    ValueChanged<int>? onTab,
    bool reduceMotion = false,
    ChallengeProgressService? challengeProgressService,
    HomeDashboardService? homeDashboardService,
    DatabaseHelper? databaseHelper,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.lightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: RootNavScope(
          goToTab: onTab ?? (_) {},
          child: Scaffold(
            body: RecordsStatisticsScreen(
              key: UniqueKey(),
              statisticsService: _FakeStats(produce),
              challengeProgressService:
                  challengeProgressService ?? _FakeChallengeProgressService(),
              homeDashboardService: homeDashboardService ??
                  _FakeHomeDashboard(() async => _dashboardData()),
              databaseHelper: databaseHelper ?? _FakeDatabaseHelper(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  final recent = [
    _clear('초급', 1, 520, 1, today),
    _clear('초급', 2, 300, 0, today.subtract(const Duration(days: 40))),
  ];
  final events = [
    {'level_name': '초급', 'clear_date': _date(today)},
    {'level_name': '초급', 'clear_date': _date(today)},
  ];

  testWidgets('no records at all: message + start action, no zero stats',
      (tester) async {
    var tab = -1;
    await pumpRecords(tester, () async => _data(), onTab: (i) => tab = i);
    expect(find.byKey(const Key('records_hero_header')), findsOneWidget);
    expect(
        find.text(
            'Your records will build up once you finish your first puzzle.'),
        findsOneWidget);
    expect(find.text('00:00'), findsNothing);
    expect(find.text('Records by level'), findsNothing);
    expect(find.text('All puzzle activity'), findsNothing);
    // 일반 기록도, 도전 기록도 전혀 없으면 도전 달력도 함께 숨긴다.
    expect(find.text('Challenge history'), findsNothing);

    await tester.tap(find.text('Start a puzzle'));
    expect(tab, 0); // 홈 탭(실제 시작 경로)
  });

  testWidgets('sections follow the specified order with real numbers',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    final heroY =
        tester.getTopLeft(find.byKey(const Key('records_hero_header'))).dy;
    expect(heroY, lessThan(y('This week')));
    expect(y('This week'), lessThan(y('Records by level')));
    expect(y('Records by level'), lessThan(y('All puzzle activity')));
    expect(y('All puzzle activity'), lessThan(y('Challenge history')));
    expect(find.text('View achievements'), findsNothing);

    // 이번 주 요약: 오늘 이벤트 2건 → 활동 1일 · 완료 2판(반복 포함 횟수)
    expect(find.text('Active days: 1'), findsOneWidget);
    expect(find.text('Completed: 2'), findsOneWidget);

    // 난이도별: 초급 2 / 159, 최고 기록 = 최소 시간, 평균은 저장된 최고 기록 기준
    expect(find.text('2 / 159'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget); // best
    expect(find.text('06:50'), findsOneWidget); // (520+300)/2 = 410s
    expect(find.text('Puzzle completion'), findsOneWidget);
    expect(find.text('Avg. clear time'), findsOneWidget);
    expect(
        find.textContaining("Averages are based on each puzzle's best record"),
        findsOneWidget);
    // "나의 기록" 요약 카드: 완료 수가 가장 큰 대표 숫자, 무오답·연속은
    // 보조 칩으로 표시한다(recent.length=2, activitySummary 고정값들).
    expect(find.text('My record'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('records_summary_card')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(find.text('puzzles solved'), findsOneWidget);
    expect(find.text('0 mistake-free'), findsOneWidget);
    expect(find.text('2-day streak'), findsOneWidget);
    // 활동 달기 기간 표기 + 최고 연속 요약 행
    expect(find.text('Last 26 weeks'), findsOneWidget);
    // 현재 연속은 요약 카드에만, 활동 달력 하단은 최고 연속만 보여준다(중복 제거).
    expect(find.textContaining('Longest streak'), findsOneWidget);
    expect(find.byKey(const Key('records_week_artwork')), findsOneWidget);
    expect(find.byKey(const Key('records_challenge_artwork')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Master is hidden from the difficulty records', (tester) async {
    await pumpRecords(
      tester,
      () async => _data(
        recent: [
          ...recent,
          _clear('마스터', 1, 900, 0, today),
        ],
        events: events,
      ),
    );
    expect(find.text('Master'), findsNothing);
    expect(find.text('Beginner'), findsWidgets);
    expect(find.text('Expert'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a level without records shows a message and dashes, not zeros',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    await tester.ensureVisible(find.text('Intermediate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Intermediate'));
    await tester.pump();
    expect(
        find.text('No completed puzzles at this level yet.'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(3));
    expect(find.text('00:00'), findsNothing);
    // 다른 섹션은 유지
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('All puzzle activity'), findsOneWidget);
  });

  testWidgets('tapping a weekday shows that day; tapping again clears it',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    final dayFinder = find.bySemanticsLabel(RegExp(r'completed, Today'));
    final handle = tester.ensureSemantics();
    await tester.pump();
    expect(dayFinder, findsOneWidget);
    await tester.tap(dayFinder);
    // 선택 설명 전환(AnimatedSwitcher, 170ms)이 끝날 때까지 진행시킨다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining(': 2 completed'), findsWidgets);
    expect(find.text('Active days: 1'), findsNothing);
    await tester.tap(dayFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Active days: 1'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('load failure is not shown as "no records"; retry recovers',
      (tester) async {
    var calls = 0;
    await pumpRecords(tester, () async {
      calls++;
      if (calls == 1) throw StateError('db down');
      return _data(recent: recent, events: events);
    });
    expect(
        find.text(
            'Unable to load statistics right now. Please try again shortly.'),
        findsOneWidget);
    expect(
        find.text(
            'Your records will build up once you finish your first puzzle.'),
        findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('This week'), findsOneWidget);
  });

  for (final entry in {
    'small phone 2x': (const Size(320, 568), 2.0, false),
    'phone 1.3x dark': (const Size(390, 844), 1.3, true),
    'tablet portrait': (const Size(768, 1024), 1.0, false),
    'tablet landscape dark': (const Size(1024, 768), 1.0, true),
  }.entries) {
    testWidgets('renders without overflow: ${entry.key}', (tester) async {
      final (size, scale, dark) = entry.value;
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        size: size,
        textScale: scale,
        theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('My record'), findsOneWidget);
    });
  }

  testWidgets('mobile horizontal padding is 16px, tablet is 24px',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    final mobilePadding = tester
        .widget<Padding>(find.byKey(const Key('records_content_padding')))
        .padding as EdgeInsets;
    expect(mobilePadding.left, 16);
    expect(mobilePadding.right, 16);

    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
      size: const Size(768, 1024),
    );
    final tabletPadding = tester
        .widget<Padding>(find.byKey(const Key('records_content_padding')))
        .padding as EdgeInsets;
    expect(tabletPadding.left, 24);
    expect(tabletPadding.right, 24);
  });

  testWidgets(
      'selected vs unselected difficulty chips use the level-status palette '
      'in both light and dark mode', (tester) async {
    for (final dark in [false, true]) {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
      );
      final palette = dark ? LevelStatusPalette.dark : LevelStatusPalette.light;
      final cs = Theme.of(tester.element(find.byType(RecordsStatisticsScreen)))
          .colorScheme;

      final selected = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Beginner'));
      expect(selected.selectedColor, palette.completedBackground);
      expect(selected.checkmarkColor, palette.primaryPurple);
      expect(selected.side, BorderSide(color: palette.completedBorder));

      final unselected = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Intermediate'));
      expect(unselected.side, BorderSide(color: cs.outlineVariant));
      expect(unselected.backgroundColor, cs.surface);
    }
  });

  testWidgets('summary card uses the level-status palette accent in dark mode',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
      theme: AppTheme.darkTheme(),
    );
    const palette = LevelStatusPalette.dark;
    final valueText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('records_summary_card')),
        matching: find.text('2'),
      ),
    );
    expect(valueText.style?.color, palette.primaryPurple);

    final card = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const Key('records_summary_card')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = card.decoration as BoxDecoration;
    expect(decoration.color, palette.completedBackground);
    expect((decoration.border as Border).top.color, palette.completedBorder);
  });

  testWidgets(
      'summary card shows its background image behind the title and stats',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('records_summary_card')),
        matching: find.byKey(const Key('records_summary_card_bg')),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('puzzles solved')).dy,
      greaterThan(tester.getTopLeft(find.text('My record')).dy),
    );
  });

  testWidgets(
      'summary card falls back to a plain background on narrow screens and '
      'large text', (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
      size: const Size(375, 700),
      textScale: 1.4,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('records_summary_card')),
        matching: find.byKey(const Key('records_summary_card_bg')),
      ),
      findsNothing,
    );
    expect(find.text('My record'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first load shows skeletons, then replaces them with content',
      (tester) async {
    final completer = Completer<RecordsStatisticsData>();
    await pumpRecords(
      tester,
      () => completer.future,
      reduceMotion: true,
    );

    expect(find.byKey(const Key('records_initial_skeleton')), findsOneWidget);
    expect(find.byKey(const Key('records_skeleton_sample')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('View achievements'), findsNothing);

    completer.complete(_data(recent: recent, events: events));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('records_initial_skeleton')), findsNothing);
    expect(find.text('My record'), findsOneWidget);
  });

  testWidgets('challenge title is not repeated and its streak stays in card',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
      challengeProgressService: _FakeChallengeProgressService(streakDays: 4),
    );

    expect(find.text('Challenge history'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ChallengeMonthlyCalendarCard),
        matching: find.text("Today's challenge streak 4 days"),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'play activity does not repeat the current-streak label shown in the '
      'summary card', (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    // 현재 연속은 요약 카드의 보조 칩(2-day streak)에만 있고, 활동 달력
    // 쪽에는 최고 연속만 별도로 표시되어 중복되지 않는다.
    expect(find.text('2-day streak'), findsOneWidget);
    expect(find.textContaining('Longest streak'), findsOneWidget);
  });

  testWidgets('tablet landscape uses two columns capped at 960 wide',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
      size: const Size(1280, 800),
    );
    final weekLeft = tester.getTopLeft(find.text('This week')).dx;
    final calendarLeft = tester.getTopLeft(find.text('All puzzle activity')).dx;
    expect(calendarLeft, greaterThan(weekLeft + 300)); // 오른쪽 칼럼
    final width = tester.getSize(find.text('All puzzle activity')).width;
    expect(width, lessThan(960));
    // 콘텐츠 바깥 여백이 가운데 정렬을 반영 (1280 - 960)/2 = 160
    expect(weekLeft, greaterThanOrEqualTo(160));
  });

  for (final lang in ['ko', 'ja', 'es', 'zh']) {
    testWidgets('long translations do not overflow at 2x text: $lang',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        size: const Size(320, 568),
        textScale: 2.0,
        locale: Locale(lang),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'mascot is limited to empty state; summary uses its own background '
      'image', (tester) async {
    await pumpRecords(tester, () async => _data());
    expect(find.byType(MascotImage), findsOneWidget);
    expect(find.byType(SudokuMotif), findsOneWidget);
    expect(find.byKey(const Key('records_summary_card_bg')), findsNothing);

    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    expect(find.byType(MascotImage), findsNothing);
    expect(find.byKey(const Key('records_summary_card_bg')), findsOneWidget);
  });

  testWidgets('no graphic while loading or on load failure', (tester) async {
    await pumpRecords(tester, () async => throw StateError('db down'));
    expect(find.byType(MascotImage), findsNothing);
  });

  group('selection transitions', () {
    // 두 난이도 모두 기록이 있어, 칩을 바꿨을 때 값이 실제로 달라지는지
    // 확인할 수 있는 데이터.
    final twoLevelRecent = [
      ...recentFor('초급', [
        (1, 520, 1, 0),
        (2, 300, 0, 40),
      ]),
      ...recentFor('중급', [
        (10, 100, 0, 0),
      ]),
    ];

    testWidgets(
        'selecting a weekday updates its selected state and the '
        'description together', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
      );
      final handle = tester.ensureSemantics();
      final dayFinder = find.bySemanticsLabel(RegExp(r'completed, Today'));
      await tester.tap(dayFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        tester.getSemantics(dayFinder),
        isSemantics(isSelected: true),
      );
      expect(find.textContaining(': 2 completed'), findsWidgets);
      handle.dispose();
    });

    testWidgets(
        'tapping a second weekday before the first settles leaves '
        'only the latest day selected', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
      );
      final handle = tester.ensureSemantics();
      final todayFinder = find.bySemanticsLabel(RegExp(r'completed, Today'));
      final otherDayFinder = find.bySemanticsLabel(RegExp(r'no completions'));

      await tester.tap(todayFinder);
      await tester.pump(); // 아직 전환 중
      await tester.tap(otherDayFinder.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 마지막에 누른 요일만 선택 상태로 남는다(둘 다 선택된 채로 남지 않음).
      expect(
        tester.getSemantics(todayFinder),
        isNot(isSemantics(isSelected: true)),
      );
      handle.dispose();
    });

    Finder chip(String label) => find.widgetWithText(ChoiceChip, label);

    testWidgets(
        'switching between two levels with different records shows '
        'the correct numbers for each', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: twoLevelRecent, events: events),
      );
      // 기본 선택은 기록이 있는 첫 난이도(초급)라 별도로 탭하지 않아도 된다.
      expect(find.text('2 / 159'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget); // best of 초급

      await tester.ensureVisible(chip('Intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(chip('Intermediate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('1 / 159'), findsOneWidget);
      // 중급은 기록이 하나뿐이라 최고 기록과 평균이 같은 값(01:40)으로 두 줄
      // 모두에 나타난다.
      expect(find.text('01:40'), findsNWidgets(2));
      expect(find.text('2 / 159'), findsNothing);
    });

    testWidgets(
        'tapping a second difficulty before the first settles shows '
        'only the latest difficulty', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: twoLevelRecent, events: events),
      );
      await tester.ensureVisible(chip('Intermediate'));
      await tester.tap(chip('Intermediate'));
      await tester.pump(); // 아직 전환 중
      await tester.ensureVisible(chip('Advanced'));
      await tester.tap(chip('Advanced'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('No completed puzzles at this level yet.'),
        findsOneWidget,
      );
      expect(find.text('1 / 159'), findsNothing);
    });

    testWidgets('the selected difficulty chip reports itself as selected',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: twoLevelRecent, events: events),
      );
      final handle = tester.ensureSemantics();
      await tester.ensureVisible(chip('Intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(chip('Intermediate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        tester.getSemantics(chip('Intermediate')),
        isSemantics(isSelected: true),
      );
      handle.dispose();
    });

    testWidgets(
        'reduce motion swaps difficulty content in a single frame, no fade',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: twoLevelRecent, events: events),
        reduceMotion: true,
      );
      expect(find.text('2 / 159'), findsOneWidget);

      await tester.ensureVisible(chip('Intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(chip('Intermediate'));
      // 동작 줄이기에서는 지속 시간이 0이라, 단 한 프레임 만에 이전 내용이
      // 완전히 사라지고 새 내용으로 바뀐다(애니메이션 중간 프레임이 없음).
      await tester.pump();
      expect(find.text('1 / 159'), findsOneWidget);
      expect(find.text('2 / 159'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'tablet two-column layout keeps its columns in place after '
        'switching level and day', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: twoLevelRecent, events: events),
        size: const Size(1280, 800),
      );
      final weekLeftBefore = tester.getTopLeft(find.text('This week')).dx;
      final calendarLeftBefore =
          tester.getTopLeft(find.text('All puzzle activity')).dx;

      await tester.tap(find.text('Intermediate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final dayFinder = find.bySemanticsLabel(RegExp(r'completed, Today'));
      final handle = tester.ensureSemantics();
      await tester.tap(dayFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      handle.dispose();

      expect(tester.getTopLeft(find.text('This week')).dx, weekLeftBefore);
      expect(
        tester.getTopLeft(find.text('All puzzle activity')).dx,
        calendarLeftBefore,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('challenge history (merged from the removed ChallengeScreen)', () {
    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
    }

    testWidgets(
        'the challenge calendar stays hidden with no puzzle records and no '
        'challenge history', (tester) async {
      await pumpRecords(tester, () async => _data());
      expect(find.text('Challenge history'), findsNothing);
    });

    testWidgets(
        'the challenge calendar shows with no puzzle records but past '
        'challenge completions', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(),
        challengeProgressService: _FakeChallengeProgressService(
          hasAnyCompletion: true,
        ),
      );
      expect(find.text('Challenge history'), findsOneWidget);
      expect(find.text('View achievements'), findsNothing);
    });

    testWidgets(
        'with challenge history but no puzzle records, the empty message is '
        'distinct from the "nothing at all" message and the calendar still '
        'shows', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(),
        challengeProgressService: _FakeChallengeProgressService(
          hasAnyCompletion: true,
        ),
      );
      expect(
        find.text("You don't have any puzzle records yet."),
        findsOneWidget,
      );
      expect(
        find.text(
          'Finish a puzzle to see stats by difficulty and your activity '
          'history.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
            'Your records will build up once you finish your first puzzle.'),
        findsNothing,
      );
      expect(find.text('Start a puzzle'), findsOneWidget);
      expect(find.text('Challenge history'), findsOneWidget);
    });

    testWidgets(
        'a statistics load failure does not hide the challenge calendar',
        (tester) async {
      await pumpRecords(tester, () async => throw StateError('db down'));
      expect(
        find.text(
            'Unable to load statistics right now. Please try again shortly.'),
        findsOneWidget,
      );
      expect(find.text('Challenge history'), findsOneWidget);
      expect(find.text('View achievements'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a challenge-calendar load failure does not hide the regular '
        'statistics', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        challengeProgressService: _FakeChallengeProgressService(
          throwOnMonthCalendar: true,
        ),
      );
      expect(find.text('My record'), findsOneWidget);
      expect(find.text('Records by level'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'shows the challenge streak, labeled separately from puzzle '
        'streaks', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        challengeProgressService: _FakeChallengeProgressService(
          streakDays: 4,
        ),
      );
      expect(find.text("Today's challenge streak 4 days"), findsOneWidget);
    });

    testWidgets(
        'a challenge streak load failure is ignored quietly (shows 0, no '
        'crash, other stats unaffected)', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        challengeProgressService: _FakeChallengeProgressService(
          throwOnLoad: true,
        ),
      );
      expect(find.text("Today's challenge streak 0 days"), findsOneWidget);
      expect(find.text('My record'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selecting today opens the today challenge', (tester) async {
      final level = SudokuLevel.levels.first;
      final game = SudokuGame(
        board: _puzzle(),
        solution: _solution(),
        emptyCells: level.emptyCells,
        levelName: level.name,
        gameNumber: 42,
      );
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        homeDashboardService: _FakeHomeDashboard(
          () async => _dashboardData(todayChallenge: game),
        ),
      );
      await tapVisible(tester, find.text('${today.day}').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, "Start today's challenge"),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final screen =
          tester.widget<SudokuGameScreen>(find.byType(SudokuGameScreen));
      expect(screen.game.gameNumber, 42);
      expect(
        screen.challengeDate,
        ChallengeProgressService.formatLocalDate(today),
      );
    });

    testWidgets(
        'returning from a challenge puzzle refreshes stats and the '
        'challenge streak', (tester) async {
      var statsLoadCount = 0;
      final level = SudokuLevel.levels.first;
      final game = SudokuGame(
        board: _puzzle(),
        solution: _solution(),
        emptyCells: level.emptyCells,
        levelName: level.name,
        gameNumber: 42,
      );
      await pumpRecords(
        tester,
        () async {
          statsLoadCount++;
          return _data(recent: recent, events: events);
        },
        homeDashboardService: _FakeHomeDashboard(
          () async => _dashboardData(todayChallenge: game),
        ),
        challengeProgressService: _FakeChallengeProgressService(
          streakDays: 1,
        ),
      );
      final loadsBefore = statsLoadCount;

      await tapVisible(tester, find.text('${today.day}').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, "Start today's challenge"),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SudokuGameScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(statsLoadCount, greaterThan(loadsBefore));
    });

    testWidgets(
        'selecting a past date opens its exact target with '
        'challengeCountsForStreak false', (tester) async {
      final pastDate = today.subtract(const Duration(days: 5));
      final pastDateStr = ChallengeProgressService.formatLocalDate(pastDate);
      final level = SudokuLevel.levels.first;
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        challengeProgressService: _FakeChallengeProgressService(
          targetLevel: level.name,
          targetGameNumber: 9,
        ),
      );
      await tapVisible(tester, find.text('${pastDate.day}').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Start past challenge'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final screen =
          tester.widget<SudokuGameScreen>(find.byType(SudokuGameScreen));
      expect(screen.game.gameNumber, 9);
      expect(screen.level.name, level.name);
      expect(screen.challengeDate, pastDateStr);
      expect(screen.restoreSavedSession, isTrue);
      expect(screen.challengeCountsForStreak, isFalse);
    });

    testWidgets('a past puzzle load failure shows an error, opens nothing',
        (tester) async {
      final pastDate = today.subtract(const Duration(days: 5));
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        databaseHelper: _FakeDatabaseHelper(failGameEntry: true),
      );
      await tapVisible(tester, find.text('${pastDate.day}').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Start past challenge'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SudokuGameScreen), findsNothing);
      expect(find.text("Couldn't load this puzzle."), findsOneWidget);
    });
  });
}

/// (game_number, clear_time, wrong_count, days_ago) 튜플 목록을 이 파일의
/// `_clear()` 형식 기록 목록으로 바꾼다.
List<Map<String, dynamic>> recentFor(
  String level,
  List<(int, int, int, int)> entries,
) {
  final today = DateTime.now();
  return [
    for (final e in entries)
      _clear(level, e.$1, e.$2, e.$3, today.subtract(Duration(days: e.$4))),
  ];
}
