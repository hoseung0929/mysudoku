import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sudoku159/widgets/keep_words_text.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/navigation/root_nav_scope.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/challenge/weekly_goal_service.dart';
import 'package:sudoku159/services/records/records_statistics_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/records/records_statistics_screen.dart';
import 'package:sudoku159/widgets/mascot_image.dart';

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
  int currentStreak = 2,
  int perfectClears = 0,
  int activeDays = 12,
  WeeklyGoalState? weeklyGoal,
}) {
  return RecordsStatisticsData(
    overall: {
      'total_cleared': recent.length,
      'total_games': 636,
      'perfect_clears': perfectClears,
    },
    levels: [
      for (final n in ['초급', '중급', '고급', '전문가', '마스터'])
        {'level_name': n, 'total_count': 159},
    ],
    recent: recent,
    activitySummary: {
      'total_clears': 3,
      'active_days': activeDays,
      'current_streak_days': currentStreak,
      'best_streak_days': 5,
    },
    events: events,
    weeklyGoal: weeklyGoal,
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

  // 난이도 이름은 진행 링과 상세 필터에 모두 나오므로, 전역 텍스트 검색 대신
  // 항상 해당 영역의 descendant로 한정해서 찾는다.
  Finder chip(String label) => find.descendant(
        of: find.byKey(const Key('records_level_filter')),
        matching: find.text(label),
      );

  testWidgets(
      'no records at all: one summary-card empty state with the start '
      'button, no zero stats', (tester) async {
    var tab = -1;
    await pumpRecords(tester, () async => _data(), onTab: (i) => tab = i);
    expect(find.byKey(const Key('records_hero_header')), findsOneWidget);
    final card = find.byKey(const Key('records_summary_card'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(
          of: card, matching: find.text('Ready to make your first record?')),
      findsOneWidget,
    );
    expect(
      find.descendant(
          of: card,
          matching: find.byWidgetPredicate((w) =>
              w is KeepWordsText &&
              w.text == 'Finish a puzzle and your records will build up here')),
      findsOneWidget,
    );
    // 0개를 크게 보이지 않고, 별도 빈 상태 카드도 없다(시작 버튼은 한 곳).
    expect(find.textContaining("You've completed"), findsNothing);
    expect(find.text('Start a puzzle'), findsOneWidget);
    expect(find.text('00:00'), findsNothing);
    expect(find.text('Records by level'), findsNothing);
    expect(find.text('Last 26 weeks of activity'), findsNothing);

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
    expect(heroY, lessThan(y("This week's activity")));
    expect(y("This week's activity"), lessThan(y('Records by level')));
    expect(y('Records by level'), lessThan(y('Last 26 weeks of activity')));

    // 이번 주 요약: 오늘 이벤트 2건 → 활동 1일 · 완료 2판(반복 포함 횟수)
    expect(find.text('Active days: 1'), findsOneWidget);
    expect(find.text('Completed: 2'), findsOneWidget);

    // 난이도별: 초급 2 / 159, 최고 기록 = 최소 시간, 평균은 저장된 최고 기록 기준
    expect(find.text('2 / 159'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget); // best
    expect(find.text('06:50'), findsOneWidget); // (520+300)/2 = 410s
    expect(find.text('Puzzles completed'), findsOneWidget);
    expect(find.text('Average solve time'), findsOneWidget);
    expect(
        find.textContaining("Averages are based on each puzzle's best record"),
        findsOneWidget);
    // 요약 카드: "지금까지" 라벨 아래 한 문장(recent.length=2).
    expect(find.text('So far'), findsOneWidget);
    expect(find.text("You've completed 2 puzzles"), findsOneWidget);
    // 활동 달력 기간은 제목("Last 26 weeks of activity")에 있고 별도 줄은 없다.
    expect(find.text('Last 26 weeks'), findsNothing);
    // 연속은 요약 카드에 한 번, 활동 달력 하단은 최고 연속만(중복 제거).
    expect(find.text('Playing 2 days in a row'), findsOneWidget);
    expect(find.textContaining('Longest streak'), findsOneWidget);
    expect(find.byKey(const Key('records_week_artwork')), findsOneWidget);
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
    expect(chip('Beginner'), findsOneWidget);
    expect(chip('Expert'), findsOneWidget);
    expect(find.byKey(const Key('records_level_ring_마스터')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a level without records shows a message and dashes, not zeros',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    await tester.ensureVisible(chip('Intermediate'));
    await tester.pumpAndSettle();
    await tester.tap(chip('Intermediate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // 크로스페이드 종료
    expect(
        find.text('No completed puzzles at this level yet.'), findsOneWidget);
    // 기록이 없으면 "—" 행과 집계 기준 안내는 숨긴다.
    expect(find.text('—'), findsNothing);
    expect(find.text('00:00'), findsNothing);
    expect(find.textContaining('Averages are based'), findsNothing);
    expect(find.text('Fastest time'), findsNothing);
    // 다른 섹션은 유지
    expect(find.text("This week's activity"), findsOneWidget);
    expect(find.text('Last 26 weeks of activity'), findsOneWidget);
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
    expect(find.text("This week's activity"), findsOneWidget);
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
      expect(find.text('So far'), findsOneWidget);
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
      'level filter uses the level-status palette (selected purple + bold, '
      'unselected gray, white highlight) in light and dark', (tester) async {
    for (final dark in [false, true]) {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
      );
      final palette = dark ? LevelStatusPalette.dark : LevelStatusPalette.light;
      final filter = find.byKey(const Key('records_level_filter'));
      TextStyle styleOf(String label) => tester
          .widget<AnimatedDefaultTextStyle>(find
              .ancestor(
                of: find.descendant(of: filter, matching: find.text(label)),
                matching: find.byType(AnimatedDefaultTextStyle),
              )
              .first)
          .style;

      expect(styleOf('Beginner').color, palette.primaryPurple);
      expect(styleOf('Beginner').fontWeight, FontWeight.w700);
      expect(styleOf('Intermediate').color, palette.filterUnselectedText);
      expect(styleOf('Intermediate').fontWeight, FontWeight.w500);
      final container = tester.widget<Container>(filter);
      expect(
        (container.decoration as BoxDecoration).color,
        palette.filterSelectedBackground,
      );
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
    // 대표 문장 안의 숫자(2)가 레벨 상태 팔레트의 강조색이다.
    final sentence = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('records_summary_card')),
        matching: find.text("You've completed 2 puzzles"),
      ),
    );
    final numberSpan = (sentence.textSpan! as TextSpan)
        .children!
        .whereType<TextSpan>()
        .firstWhere((t) => t.text == '2');
    expect(numberSpan.style?.color, palette.primaryPurple);

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
    // 제목 아래에 대표 문장이 있고, 글은 카드 왼쪽 55% 안에 있다.
    final card = find.byKey(const Key('records_summary_card'));
    final titleY = tester.getTopLeft(find.text('So far')).dy;
    final sentence = find.text("You've completed 2 puzzles");
    expect(tester.getTopLeft(sentence).dy, greaterThan(titleY));
    final cardRect = tester.getRect(card);
    expect(
      tester.getRect(sentence).right,
      lessThanOrEqualTo(cardRect.left + 16 + (cardRect.width - 32) * 0.55 + 1),
    );
  });

  testWidgets(
      'summary card keeps a faint image and uses the full width on narrow '
      'screens and large text', (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
      size: const Size(375, 700),
      textScale: 1.4,
    );
    // 큰 글씨에서도 이미지는 숨기지 않고 옅게 남긴다.
    expect(
      find.descendant(
        of: find.byKey(const Key('records_summary_card')),
        matching: find.byKey(const Key('records_summary_card_bg')),
      ),
      findsOneWidget,
    );
    expect(find.text('So far'), findsOneWidget);
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

    completer.complete(_data(recent: recent, events: events));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('records_initial_skeleton')), findsNothing);
    expect(find.text('So far'), findsOneWidget);
  });

  group('summary card sentence and support line', () {
    Finder inSummary(Finder f) => find.descendant(
        of: find.byKey(const Key('records_summary_card')), matching: f);

    testWidgets('all solved without mistakes + streak', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(
          recent: recent,
          events: events,
          perfectClears: recent.length,
          currentStreak: 4,
        ),
      );
      expect(
          inSummary(find.text('All solved without mistakes')), findsOneWidget);
      expect(inSummary(find.text('Playing 4 days in a row')), findsOneWidget);
      expect(inSummary(find.textContaining('days played')), findsNothing);
    });

    testWidgets('some without mistakes + play days when there is no streak',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(
          recent: recent,
          events: events,
          perfectClears: 1,
          currentStreak: 1,
          activeDays: 5,
        ),
      );
      expect(
          inSummary(find.text('1 of them without mistakes')), findsOneWidget);
      expect(inSummary(find.text('5 days played')), findsOneWidget);
    });

    testWidgets('no mistake-free puzzle: that line is omitted', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(
          recent: recent,
          events: events,
          perfectClears: 0,
          currentStreak: 0,
          activeDays: 1,
        ),
      );
      expect(inSummary(find.textContaining('without mistakes')), findsNothing);
      expect(inSummary(find.text('1 day played')), findsOneWidget);
    });

    testWidgets('support items are separate texts, no dot, no pill',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(
          recent: recent,
          events: events,
          perfectClears: 1,
          activeDays: 5,
        ),
      );
      expect(inSummary(find.textContaining('·')), findsNothing);
      expect(inSummary(find.byType(Chip)), findsNothing);
    });

    testWidgets('streak of 1 never claims "playing in a row"', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(
          recent: recent,
          events: events,
          currentStreak: 1,
          activeDays: 3,
        ),
      );
      expect(find.textContaining('in a row'), findsNothing);
      expect(inSummary(find.text('3 days played')), findsOneWidget);
    });

    testWidgets('singular count in the hero sentence', (tester) async {
      final one = [recent.first];
      await pumpRecords(
        tester,
        () async => _data(recent: one, events: events),
      );
      expect(inSummary(find.text('You completed your first puzzle')),
          findsOneWidget);
    });

    testWidgets('no image or text overlap: the text stays in the left 55%',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events, perfectClears: 1),
      );
      final card =
          tester.getRect(find.byKey(const Key('records_summary_card')));
      final limit = card.left + 16 + (card.width - 32) * 0.55 + 1;
      expect(
        tester.getRect(find.text("You've completed 2 puzzles")).right,
        lessThanOrEqualTo(limit),
      );
    });

    for (final lang in ['en', 'ko', 'ja', 'es', 'zh']) {
      for (final size in [const Size(390, 844), const Size(320, 568)]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          testWidgets('no overflow: $lang ${size.width.toInt()}w ${scale}x',
              (tester) async {
            await pumpRecords(
              tester,
              () async => _data(
                recent: recent,
                events: events,
                perfectClears: 1,
                activeDays: 123,
                currentStreak: 12,
              ),
              size: size,
              textScale: scale,
              locale: Locale(lang),
            );
            expect(tester.takeException(), isNull);
            expect(
                find.byKey(const Key('records_summary_card')), findsOneWidget);
          });
        }
      }
    }

    testWidgets('reduce motion: no fade transition', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        reduceMotion: true,
      );
      final switcher = tester.widget<AnimatedSwitcher>(find.descendant(
        of: find.byKey(const Key('records_summary_card')),
        matching: find.byType(AnimatedSwitcher),
      ));
      expect(switcher.duration, Duration.zero);
    });
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
    expect(find.text('Playing 2 days in a row'), findsOneWidget);
    expect(find.textContaining('Longest streak'), findsOneWidget);
  });

  testWidgets('tablet landscape uses two columns capped at 960 wide',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
      size: const Size(1280, 800),
    );
    final weekLeft = tester.getTopLeft(find.text("This week's activity")).dx;
    final calendarLeft =
        tester.getTopLeft(find.text('Last 26 weeks of activity')).dx;
    expect(calendarLeft, greaterThan(weekLeft + 300)); // 오른쪽 칼럼
    final width = tester.getSize(find.text('Last 26 weeks of activity')).width;
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

  testWidgets('the summary card is the only card with the background image',
      (tester) async {
    await pumpRecords(tester, () async => _data());
    // 빈 상태도 같은 요약 카드(배경 이미지 포함)이며, 마스코트 카드는 없다.
    expect(find.byKey(const Key('records_summary_card_bg')), findsOneWidget);

    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    expect(find.byKey(const Key('records_summary_card_bg')), findsOneWidget);
  });

  testWidgets('no graphic while loading or on load failure', (tester) async {
    await pumpRecords(tester, () async => throw StateError('db down'));
    expect(find.byType(MascotImage), findsNothing);
  });

  group('weekly goal inside the week card', () {
    WeeklyGoalState goalOf(int completed, {int target = 3}) => WeeklyGoalState(
          weekStart: WeeklyGoalService.weekStartOf(today),
          target: target,
          completed: completed,
        );
    Finder goal() => find.byKey(const Key('records_weekly_goal'));
    Finder message() => find.byKey(const Key('records_weekly_goal_message'));

    testWidgets('in progress: label, "2 / 3 puzzles", bar and next step',
        (tester) async {
      await pumpRecords(
        tester,
        () async =>
            _data(recent: recent, events: events, weeklyGoal: goalOf(2)),
      );
      expect(goal(), findsOneWidget);
      expect(find.text("This week's goal"), findsOneWidget);
      expect(find.text('2 / 3 puzzles'), findsOneWidget);
      expect(find.byKey(const Key('records_weekly_goal_bar')), findsOneWidget);
      expect(
          find.text('Just 1 more puzzle to reach your goal'), findsOneWidget);
      expect(find.byKey(const Key('records_weekly_goal_check')), findsNothing);
      final bar = tester.widget<LinearProgressIndicator>(
          find.byKey(const Key('records_weekly_goal_bar')));
      expect(bar.value, closeTo(2 / 3, 0.01));
    });

    testWidgets('before the first puzzle: an invitation to start',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(
            recent: recent, events: events, weeklyGoal: goalOf(0, target: 5)),
      );
      expect(find.text('0 / 5 puzzles'), findsOneWidget);
      expect(find.text('Start your first puzzle this week'), findsOneWidget);
    });

    testWidgets('achieved: full bar, check mark and the achieved message',
        (tester) async {
      await pumpRecords(
        tester,
        () async =>
            _data(recent: recent, events: events, weeklyGoal: goalOf(3)),
      );
      expect(find.text("You reached this week's goal"), findsOneWidget);
      expect(
          find.byKey(const Key('records_weekly_goal_check')), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
          find.byKey(const Key('records_weekly_goal_bar')));
      expect(bar.value, 1.0);
      // 목표를 넘겨도 완료 상태가 유지된다.
      await pumpRecords(
        tester,
        () async =>
            _data(recent: recent, events: events, weeklyGoal: goalOf(5)),
      );
      expect(find.text("You reached this week's goal"), findsOneWidget);
      expect(find.text('5 / 3 puzzles'), findsOneWidget);
    });

    testWidgets('lives in the existing week card, not a separate card',
        (tester) async {
      await pumpRecords(
        tester,
        () async =>
            _data(recent: recent, events: events, weeklyGoal: goalOf(2)),
      );
      double top(Finder f) => tester.getTopLeft(f).dy;
      expect(top(find.text("This week's activity")), lessThan(top(goal())));
      expect(top(find.text('Active days: 1')), lessThan(top(goal())));
      expect(top(goal()), lessThan(top(find.text('Records by level'))));
      // 같은 카드 안: 목표 영역이 주간 카드의 가로 범위 안에 있다.
      final cardRect = tester.getRect(find
          .ancestor(
            of: find.text("This week's activity"),
            matching: find.byType(Container),
          )
          .last);
      expect(cardRect.contains(tester.getCenter(goal())), isTrue);
    });

    testWidgets('hidden when no goal could be loaded', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
      );
      expect(goal(), findsNothing);
    });

    testWidgets('reduce motion fills the bar without animation',
        (tester) async {
      await pumpRecords(
        tester,
        () async =>
            _data(recent: recent, events: events, weeklyGoal: goalOf(2)),
        reduceMotion: true,
      );
      final builder = tester.widget<TweenAnimationBuilder<double>>(
        find.ancestor(
          of: find.byKey(const Key('records_weekly_goal_bar')),
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
      );
      expect(builder.duration, Duration.zero);
    });

    for (final lang in ['en', 'ko', 'ja', 'es', 'zh']) {
      for (final size in [const Size(390, 844), const Size(320, 568)]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets('no overflow: $lang ${size.width.toInt()}w ${scale}x',
              (tester) async {
            for (final done in [0, 2, 3]) {
              await pumpRecords(
                tester,
                () async => _data(
                    recent: recent, events: events, weeklyGoal: goalOf(done)),
                size: size,
                textScale: scale,
                locale: Locale(lang),
              );
              expect(goal(), findsOneWidget);
              expect(tester.takeException(), isNull);
              final rect = tester.getRect(goal());
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(size.width));
              expect(
                tester.getRect(message()).right,
                lessThanOrEqualTo(size.width),
              );
            }
          });
        }
      }
    }
  });

  group('summary hero sentence by completed count', () {
    List<Map<String, dynamic>> clears(int n) => [
          for (var i = 0; i < n; i++) _clear('초급', i + 1, 300, 0, today),
        ];
    final cases = <int, String>{
      1: 'You completed your first puzzle',
      2: "You've completed 2 puzzles",
      9: "You've completed 9 puzzles",
      10: "You've reached 10 puzzles — steady progress!",
      11: "You've already solved 11 puzzles",
      19: "You've already solved 19 puzzles",
      20: "You've reached 20 puzzles — steady progress!",
      29: "You've already solved 29 puzzles",
      30: "You've reached 30 puzzles — steady progress!",
      31: '31 puzzles solved, and your record keeps growing',
      57: '57 puzzles solved, and your record keeps growing',
    };
    for (final entry in cases.entries) {
      testWidgets('${entry.key} cleared shows "${entry.value}"',
          (tester) async {
        await pumpRecords(
          tester,
          () async => _data(recent: clears(entry.key)),
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('records_summary_card')),
            matching: find.text(entry.value),
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('the same count always shows the same sentence',
        (tester) async {
      await pumpRecords(tester, () async => _data(recent: clears(13)));
      expect(find.text("You've already solved 13 puzzles"), findsOneWidget);
      await pumpRecords(tester, () async => _data(recent: clears(13)));
      expect(find.text("You've already solved 13 puzzles"), findsOneWidget);
    });
  });

  group('level progress rings (static summary)', () {
    final data = [
      ...recentFor('초급', [(1, 520, 1, 0), (2, 300, 0, 40)]),
      ...recentFor('중급', [(10, 100, 0, 0)]),
    ];
    final levelKeys = ['초급', '중급', '고급', '전문가'];
    Finder rings() => find.byKey(const Key('records_level_rings'));
    Finder ring(String level) => find.byKey(Key('records_level_ring_$level'));
    Finder inRing(String level, Finder f) =>
        find.descendant(of: ring(level), matching: f);

    testWidgets('shows the four difficulties with the completed count inside',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: data),
        locale: const Locale('ko'),
      );
      expect(rings(), findsOneWidget);
      for (final level in levelKeys) {
        expect(ring(level), findsOneWidget);
      }
      expect(ring('마스터'), findsNothing);
      expect(inRing('초급', find.text('2')), findsOneWidget);
      expect(inRing('중급', find.text('1')), findsOneWidget);
      expect(inRing('고급', find.text('0')), findsOneWidget);
      expect(inRing('전문가', find.text('0')), findsOneWidget);
      // 이름은 링 아래에 한 번만, 보조 라벨("완료" 등)은 없다.
      expect(inRing('초급', find.text('초급')), findsOneWidget);
      expect(inRing('초급', find.text('완료')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no percentage and no "2/159" style total in the card',
        (tester) async {
      await pumpRecords(tester, () async => _data(recent: data));
      expect(find.descendant(of: rings(), matching: find.textContaining('%')),
          findsNothing);
      expect(find.descendant(of: rings(), matching: find.textContaining('/')),
          findsNothing);
      expect(find.descendant(of: rings(), matching: find.text('159')),
          findsNothing);
    });

    testWidgets('rings are static: no tap handler, no selection state',
        (tester) async {
      await pumpRecords(tester, () async => _data(recent: data));
      for (final type in [GestureDetector, InkWell, InkResponse]) {
        expect(
          find.descendant(of: rings(), matching: find.byType(type)),
          findsNothing,
        );
      }
      expect(
        find.descendant(of: rings(), matching: find.byType(AnimatedContainer)),
        findsNothing,
      );
      final handle = tester.ensureSemantics();
      for (final label in [
        'Beginner, 2 of 159 completed',
        'Intermediate, 1 of 159 completed',
      ]) {
        final node = find.bySemanticsLabel(label);
        expect(node, findsOneWidget);
        expect(
          tester.getSemantics(node),
          isNot(isSemantics(isButton: true)),
        );
        expect(
          tester.getSemantics(node),
          isNot(isSemantics(isSelected: true)),
        );
      }

      // 눌러도 아래 난이도별 기록의 선택은 바뀌지 않는다.
      await tester.ensureVisible(ring('중급'));
      await tester.pumpAndSettle();
      await tester.tap(ring('중급'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2 / 159'), findsOneWidget);
      expect(find.text('1 / 159'), findsNothing);
      handle.dispose();
    });

    testWidgets('ring animation is skipped with reduce motion', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: data),
        reduceMotion: true,
      );
      final builder = tester.widget<TweenAnimationBuilder<double>>(
        find.descendant(
          of: ring('초급'),
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
      );
      expect(builder.duration, Duration.zero);
    });

    testWidgets('ring animation keeps 600ms with motion', (tester) async {
      await pumpRecords(tester, () async => _data(recent: data));
      final builder = tester.widget<TweenAnimationBuilder<double>>(
        find.descendant(
          of: ring('초급'),
          matching: find.byType(TweenAnimationBuilder<double>),
        ),
      );
      expect(builder.duration, const Duration(milliseconds: 600));
    });

    testWidgets('narrow screen with large text uses a 2x2 layout',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: data),
        size: const Size(320, 568),
        textScale: 2.0,
        locale: const Locale('en'),
      );
      final tops = [for (final l in levelKeys) tester.getTopLeft(ring(l))];
      expect(tops[0].dy, tops[1].dy);
      expect(tops[2].dy, tops[3].dy);
      expect(tops[2].dy, greaterThan(tops[0].dy));
      expect(tops[0].dx, lessThan(tops[1].dx));
      expect(tops[0].dx, tops[2].dx);
      expect(tester.takeException(), isNull);
    });

    testWidgets('roomy screen keeps all four in one row', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: data),
        locale: const Locale('ko'),
      );
      final tops = [for (final l in levelKeys) tester.getTopLeft(ring(l))];
      expect(tops.map((o) => o.dy).toSet().length, 1);
    });

    for (final lang in ['en', 'ko', 'ja', 'es', 'zh']) {
      for (final size in [const Size(390, 844), const Size(320, 568)]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
              'no overflow, labels not shrunk or clipped: $lang '
              '${size.width.toInt()}w ${scale}x', (tester) async {
            await pumpRecords(
              tester,
              () async => _data(recent: data),
              size: size,
              textScale: scale,
              locale: Locale(lang),
            );
            final l10n = lookupAppLocalizations(Locale(lang));
            final labels = [
              l10n.levelBeginner,
              l10n.levelIntermediate,
              l10n.levelAdvanced,
              l10n.levelExpert,
            ];
            for (var i = 0; i < labels.length; i++) {
              final label = inRing(levelKeys[i], find.text(labels[i]));
              expect(label, findsOneWidget);
              final paragraph = tester.renderObject<RenderParagraph>(label);
              expect(paragraph.didExceedMaxLines, isFalse);
              expect(paragraph.textScaler, TextScaler.linear(scale));
              expect(paragraph.text.style?.fontSize, 13);
            }
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
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
      await tester.pumpAndSettle();
      await tester.tap(chip('Intermediate'));
      await tester.pump(); // 아직 전환 중
      await tester.ensureVisible(chip('Advanced'));
      await tester.pumpAndSettle();
      await tester.tap(chip('Advanced'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('No completed puzzles at this level yet.'),
        findsOneWidget,
      );
      expect(find.text('1 / 159'), findsNothing);
    });

    group('segmented level filter', () {
      Finder highlight() =>
          find.byKey(const Key('records_level_filter_highlight'));
      double highlightLeft(WidgetTester tester) =>
          tester.getTopLeft(highlight()).dx;

      testWidgets('the highlight moves to the tapped difficulty',
          (tester) async {
        await pumpRecords(
          tester,
          () async => _data(recent: twoLevelRecent, events: events),
          locale: const Locale('ko'),
        );
        final before = highlightLeft(tester);
        await tester.ensureVisible(chip('중급'));
        await tester.pumpAndSettle();
        await tester.tap(chip('중급'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(highlightLeft(tester), greaterThan(before));
      });

      testWidgets('reduce motion: highlight and label change are instant',
          (tester) async {
        await pumpRecords(
          tester,
          () async => _data(recent: twoLevelRecent, events: events),
          reduceMotion: true,
        );
        expect(
          tester.widget<AnimatedPositioned>(highlight()).duration,
          Duration.zero,
        );
      });

      testWidgets('with motion, the highlight takes 220ms', (tester) async {
        await pumpRecords(
          tester,
          () async => _data(recent: twoLevelRecent, events: events),
        );
        expect(
          tester.widget<AnimatedPositioned>(highlight()).duration,
          const Duration(milliseconds: 220),
        );
      });

      testWidgets('selecting does not change any item width or position',
          (tester) async {
        await pumpRecords(
          tester,
          () async => _data(recent: twoLevelRecent, events: events),
        );
        final filter = find.byKey(const Key('records_level_filter'));
        await tester.ensureVisible(filter);
        await tester.pumpAndSettle();
        // 필터 좌상단 기준 상대 위치(페이지 스크롤과 무관).
        Offset rel(String label) =>
            tester.getCenter(chip(label)) - tester.getTopLeft(filter);
        final advancedBefore = rel('Advanced');
        final expertBefore = rel('Expert');
        await tester.tap(chip('Intermediate'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(rel('Advanced'), advancedBefore);
        expect(rel('Expert'), expertBefore);
      });

      testWidgets('re-selecting the same difficulty does nothing',
          (tester) async {
        await pumpRecords(
          tester,
          () async => _data(recent: twoLevelRecent, events: events),
        );
        await tester.ensureVisible(chip('Beginner'));
        await tester.pumpAndSettle();
        final before = highlightLeft(tester);
        await tester.tap(chip('Beginner'));
        await tester.pump();
        expect(highlightLeft(tester), before);
        expect(find.text('2 / 159'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      for (final lang in ['en', 'ja', 'ko', 'es', 'zh']) {
        for (final size in [const Size(390, 844), const Size(320, 568)]) {
          testWidgets(
              'no overflow, highlight still moves: $lang ${size.width.toInt()}w '
              '2x text', (tester) async {
            await pumpRecords(
              tester,
              () async => _data(recent: twoLevelRecent, events: events),
              size: size,
              textScale: 2.0,
              locale: Locale(lang),
            );
            expect(tester.takeException(), isNull);
            final filter = find.byKey(const Key('records_level_filter'));
            // 라벨이 긴 언어(en/ja/es)는 큰 글씨에서 가로 스크롤 모드가 된다.
            // 짧은 라벨(ko/zh)은 390폭에서는 2배에서도 들어가 스크롤이 없을 수 있다.
            final scrollable = find.descendant(
              of: filter,
              matching: find.byWidgetPredicate(
                (w) => w is Scrollable && w.axis == Axis.horizontal,
              ),
            );
            if (['en', 'ja', 'es'].contains(lang)) {
              expect(scrollable, findsOneWidget);
            }
            expect(highlight(), findsOneWidget);
          });
        }
      }

      testWidgets(
          'scroll mode reveals an off-screen selection horizontally only; '
          'the page does not scroll vertically', (tester) async {
        final expertClear = _clear('전문가', 1, 600, 0, today);
        await pumpRecords(
          tester,
          () async => _data(recent: [expertClear], events: [expertClear]),
          textScale: 2.0,
          locale: const Locale('en'),
        );
        await tester.pumpAndSettle();
        final filter = find.byKey(const Key('records_level_filter'));
        final horizontal = find.descendant(
          of: filter,
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axis == Axis.horizontal,
          ),
        );
        final hPosition = tester.state<ScrollableState>(horizontal).position;
        // 선택(전문가)이 가장 오른쪽이라 가로로 이동해 있다.
        expect(hPosition.pixels, greaterThan(0));
        // 페이지 세로 스크롤은 움직이지 않았다.
        final vertical = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axis == Axis.vertical,
        );
        final vPosition =
            tester.state<ScrollableState>(vertical.first).position;
        expect(vPosition.pixels, 0);
        expect(tester.takeException(), isNull);
      });

      testWidgets('an already visible selection does not scroll',
          (tester) async {
        await pumpRecords(
          tester,
          () async => _data(recent: twoLevelRecent, events: events),
          textScale: 2.0,
          locale: const Locale('en'),
        );
        await tester.pumpAndSettle();
        final horizontal = find.descendant(
          of: find.byKey(const Key('records_level_filter')),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axis == Axis.horizontal,
          ),
        );
        expect(tester.state<ScrollableState>(horizontal).position.pixels, 0);
      });
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

      final node = find.descendant(
        of: find.byKey(const Key('records_level_filter')),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Intermediate',
        ),
      );
      expect(tester.getSemantics(node), isSemantics(isSelected: true));
      expect(
        tester.getSemantics(node),
        isSemantics(isButton: true, label: 'Intermediate'),
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
      final weekLeftBefore =
          tester.getTopLeft(find.text("This week's activity")).dx;
      final calendarLeftBefore =
          tester.getTopLeft(find.text('Last 26 weeks of activity')).dx;

      await tester.ensureVisible(chip('Intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(chip('Intermediate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // 탭이 실제로 난이도를 바꿨는지 확인한다(중급 기록 1개).
      expect(find.text('1 / 159'), findsOneWidget);
      expect(find.text('2 / 159'), findsNothing);
      final handle = tester.ensureSemantics();
      final dayFinder = find.bySemanticsLabel(RegExp(r'completed, Today'));
      await tester.ensureVisible(dayFinder);
      await tester.pumpAndSettle();
      await tester.tap(dayFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      handle.dispose();

      expect(tester.getTopLeft(find.text("This week's activity")).dx,
          weekLeftBefore);
      expect(
        tester.getTopLeft(find.text('Last 26 weeks of activity')).dx,
        calendarLeftBefore,
      );
      expect(tester.takeException(), isNull);
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
