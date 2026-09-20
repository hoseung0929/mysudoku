import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/navigation/root_nav_scope.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/records/records_statistics_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/records/records_statistics_screen.dart';
import 'package:sudoku159/widgets/mascot_image.dart';
import 'package:sudoku159/widgets/sudoku_motif.dart';

class _FakeStats extends RecordsStatisticsService {
  _FakeStats(this.produce);
  final Future<RecordsStatisticsData> Function() produce;

  @override
  Future<RecordsStatisticsData> load({required int selectedPeriodDays}) =>
      produce();
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

  final today = DateTime.now();

  Future<void> pumpRecords(
    WidgetTester tester,
    Future<RecordsStatisticsData> Function() produce, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    ThemeData? theme,
    Locale? locale,
    ValueChanged<int>? onTab,
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
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: RootNavScope(
          goToTab: onTab ?? (_) {},
          child: Scaffold(
            body: RecordsStatisticsScreen(
              key: UniqueKey(),
              statisticsService: _FakeStats(produce),
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
    expect(find.text('Records'), findsOneWidget);
    expect(
        find.text(
            'Your records will build up once you finish your first puzzle.'),
        findsOneWidget);
    expect(find.text('00:00'), findsNothing);
    expect(find.text('Records by level'), findsNothing);
    expect(find.text('Activity calendar'), findsNothing);

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
    expect(y('Records'), lessThan(y('This week')));
    expect(y('This week'), lessThan(y('Records by level')));
    expect(y('Records by level'), lessThan(y('Activity calendar')));
    expect(y('Activity calendar'), lessThan(y('View achievements')));

    // 이번 주 요약: 오늘 이벤트 2건 → 활동 1일 · 완료 2판(반복 포함 횟수)
    expect(find.text('Active days: 1'), findsOneWidget);
    expect(find.text('Completed: 2'), findsOneWidget);

    // 난이도별: 초급 2 / 159, 최고 기록 = 최소 시간, 평균은 저장된 최고 기록 기준
    expect(find.text('2 / 159'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget); // best
    expect(find.text('06:50'), findsOneWidget); // (520+300)/2 = 410s
    expect(find.text('Puzzle completion'), findsOneWidget);
    expect(find.text('Avg. best time'), findsOneWidget);
    expect(find.textContaining("Averages use each puzzle's best record"),
        findsOneWidget);
    // 대형 전체 요약 카드 대신 보조 문장
    expect(find.text('2 of 636 puzzles completed across all levels.'),
        findsOneWidget);
    // 활동 달기 기간 표기 + 연속 요약 행
    expect(find.text('Last 26 weeks'), findsOneWidget);
    expect(find.textContaining('Current daily streak'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a level without records shows a message and dashes, not zeros',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    await tester.tap(find.text('Intermediate'));
    await tester.pump();
    expect(
        find.text('No completed puzzles at this level yet.'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(3));
    expect(find.text('00:00'), findsNothing);
    // 다른 섹션은 유지
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Activity calendar'), findsOneWidget);
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
    await tester.pump();
    expect(find.textContaining(': 2 completed'), findsWidgets);
    expect(find.text('Active days: 1'), findsNothing);
    await tester.tap(dayFinder);
    await tester.pump();
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
      expect(find.text('View achievements'), findsOneWidget);
    });
  }

  testWidgets('tablet landscape uses two columns capped at 960 wide',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
      size: const Size(1280, 800),
    );
    final weekLeft = tester.getTopLeft(find.text('This week')).dx;
    final calendarLeft = tester.getTopLeft(find.text('Activity calendar')).dx;
    expect(calendarLeft, greaterThan(weekLeft + 300)); // 오른쪽 칼럼
    final width = tester.getSize(find.text('View achievements')).width;
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

  testWidgets('mascot graphic only in the true empty state', (tester) async {
    await pumpRecords(tester, () async => _data());
    expect(find.byType(MascotImage), findsOneWidget);
    expect(find.byType(SudokuMotif), findsOneWidget);

    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    expect(find.byType(MascotImage), findsNothing);
    expect(find.byType(SudokuMotif), findsNothing);
  });

  testWidgets('no graphic while loading or on load failure', (tester) async {
    await pumpRecords(tester, () async => throw StateError('db down'));
    expect(find.byType(MascotImage), findsNothing);
  });
}
