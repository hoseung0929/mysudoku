import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/navigation/root_nav_scope.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
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
          matching:
              find.text('Finish a puzzle and your records will build up here')),
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
      expect(inSummary(find.text("You've completed 1 puzzle")), findsOneWidget);
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

    Finder chip(String label) => find.descendant(
          of: find.byKey(const Key('records_level_filter')),
          matching: find.text(label),
        );

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
        await tester.ensureVisible(find.text('중급'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('중급'));
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

      await tester.tap(find.text('Intermediate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final dayFinder = find.bySemanticsLabel(RegExp(r'completed, Today'));
      final handle = tester.ensureSemantics();
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
