import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sudoku159/widgets/keep_words_text.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/navigation/root_nav_scope.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/services/records/recent_completions_service.dart';
import 'package:sudoku159/services/records/records_statistics_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/records/recent_completions_screen.dart';
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
  List<RecentCompletion> recentCompletions = const [],
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
    recentCompletions: recentCompletions,
  );
}

/// 요약 카드 보조 문장 선택을 고정한다(0이면 첫 후보, 1이면 두 번째 후보).
/// 최근 완료 줄을 눌렀을 때 읽는 최고 기록만 돌려주는 저장소.
class _RecordOnlyDb implements DatabaseHelper {
  @override
  Future<Map<String, dynamic>?> getClearRecord(
          String levelName, int gameNumber) async =>
      {'clear_time': 202, 'wrong_count': 0, 'hints_used': 0};

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;

  @override
  int nextInt(int max) => value % max;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
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
    int supportPick = 0,
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
              random: _FixedRandom(supportPick),
              databaseHelper: databaseHelper,
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

  // 난이도 선택은 링 선택기가 맡는다. 테스트에서는 표시 이름으로 링을 찾는다.
  const levelKeyByLabel = {
    'Beginner': '초급',
    'Intermediate': '중급',
    'Advanced': '고급',
    'Expert': '전문가',
    '초급': '초급',
    '중급': '중급',
  };
  Finder levelRing(String label) =>
      find.byKey(Key('records_level_ring_${levelKeyByLabel[label]}'));

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

    // 이번 주 카드는 7칸만: 합계 줄·요일 선택 안내가 없다.
    expect(find.text('Active days: 1'), findsNothing);
    expect(find.text('Completed: 2'), findsNothing);
    expect(find.text('Tap a day to see your record'), findsNothing);

    // 난이도별: 완료 수는 링에만 있고(중복된 "2 / 159" 행 없음), 최고 기록 =
    // 최소 시간, 평균은 저장된 최고 기록 기준
    expect(
      find.descendant(of: levelRing('Beginner'), matching: find.text('2')),
      findsOneWidget,
    );
    expect(find.text('2 / 159'), findsNothing);
    expect(find.text('Puzzles completed'), findsNothing);
    expect(find.text('Progress by level'), findsNothing);
    // 난이도별 세 값: 힌트 없이(초급 2판 모두) · 실수 없이(1판) · 보통 시간
    // (520초·300초의 중앙값 410초 → 약 7분). 빠른 기록·평균 실수는 없다.
    expect(find.text('Solved without hints'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Solved without mistakes'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Typical time per puzzle'), findsOneWidget);
    expect(find.text('About 7 min'), findsOneWidget);
    expect(find.text('Fastest time'), findsNothing);
    expect(find.text('Average mistakes'), findsNothing);
    // 값은 카드 안쪽 오른쪽 끝(패딩 16)에 붙는다.
    final levelCardRight = tester
        .getRect(find
            .ancestor(
              of: find.text('Records by level'),
              matching: find.byType(Container),
            )
            .last)
        .right;
    for (final value in ['2 / 2', '1 / 2', 'About 7 min']) {
      expect(tester.getRect(find.text(value)).right,
          moreOrLessEquals(levelCardRight - 16, epsilon: 1.5),
          reason: value);
    }
    expect(find.textContaining('Averages are based'), findsNothing);
    // 요약 카드: "지금까지" 라벨 아래 한 문장(recent.length=2).
    expect(find.text('So far'), findsOneWidget);
    expect(find.text("You've completed 2 puzzles"), findsOneWidget);
    // 활동 달력 기간은 제목("Last 26 weeks of activity")에 있고 별도 줄은 없다.
    expect(find.text('Last 26 weeks'), findsNothing);
    // 연속은 요약 카드에 한 번, 활동 달력 하단은 최고 연속만(중복 제거).
    expect(find.text("You've been playing 2 days in a row"), findsOneWidget);
    expect(find.textContaining('Longest streak'), findsOneWidget);
    expect(find.byKey(const Key('records_week_artwork')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the week card shows only the seven days: no goal, no summary, '
      'days are not buttons', (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    expect(find.text("This week's goal"), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    final handle = tester.ensureSemantics();
    // 오늘 2판 완료 → 체크와 "2" 배지, 화면 읽기에는 그날 요약이 그대로 있다.
    final today = find.bySemanticsLabel(RegExp(r'2 completed, Today'));
    expect(today, findsOneWidget);
    expect(tester.getSemantics(today), isNot(isSemantics(isButton: true)));
    await tester.tap(today, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining(': 2 completed'), findsNothing);
    handle.dispose();
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
    expect(levelRing('Beginner'), findsOneWidget);
    expect(levelRing('Expert'), findsOneWidget);
    expect(find.byKey(const Key('records_level_ring_마스터')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a level without records shows a message and dashes, not zeros',
      (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
    );
    await tester.ensureVisible(levelRing('Intermediate'));
    await tester.pumpAndSettle();
    await tester.tap(levelRing('Intermediate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // 크로스페이드 종료
    expect(
        find.text('No completed puzzles at this level yet.'), findsOneWidget);
    // 기록이 없으면 "—" 행과 집계 기준 안내는 숨긴다.
    expect(find.text('—'), findsNothing);
    expect(find.text('00:00'), findsNothing);
    expect(find.text('Solved without hints'), findsNothing);
    expect(find.text('Typical time per puzzle'), findsNothing);
    // 다른 섹션은 유지
    expect(find.text("This week's activity"), findsOneWidget);
    expect(find.text('Last 26 weeks of activity'), findsOneWidget);
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
    'ipad 11 landscape 1.3x': (const Size(1194, 834), 1.3, false),
    'ipad 13 landscape dark': (const Size(1366, 1024), 1.0, true),
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
      'level rings mark the selection with the filter background and a '
      'purple bold label in light and dark', (tester) async {
    for (final dark in [false, true]) {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
        theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
      );
      final palette = dark ? LevelStatusPalette.dark : LevelStatusPalette.light;
      TextStyle styleOf(String label) => tester
          .widget<Text>(
              find.descendant(of: levelRing(label), matching: find.text(label)))
          .style!;
      BoxDecoration backgroundOf(String label) => tester
          .widget<AnimatedContainer>(find.descendant(
              of: levelRing(label), matching: find.byType(AnimatedContainer)))
          .decoration! as BoxDecoration;

      expect(styleOf('Beginner').color, palette.primaryPurple);
      expect(styleOf('Beginner').fontWeight, FontWeight.w800);
      expect(styleOf('Intermediate').fontWeight, FontWeight.w600);
      expect(backgroundOf('Beginner').color, palette.filterSelectedBackground);
      expect(backgroundOf('Intermediate').color!.a, 0);
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

    testWidgets('one sentence at a time: all solved without mistakes or streak',
        (tester) async {
      for (final (pick, shown, hidden) in [
        (
          0,
          'You solved them all without mistakes',
          "You've been playing 4 days in a row"
        ),
        (
          1,
          "You've been playing 4 days in a row",
          'You solved them all without mistakes'
        ),
      ]) {
        await pumpRecords(
          tester,
          () async => _data(
            recent: recent,
            events: events,
            perfectClears: recent.length,
            currentStreak: 4,
          ),
          supportPick: pick,
        );
        expect(inSummary(find.text(shown)), findsOneWidget);
        expect(inSummary(find.text(hidden)), findsNothing);
        expect(inSummary(find.textContaining('played on')), findsNothing);
      }
    });

    testWidgets('some without mistakes, or play days when there is no streak',
        (tester) async {
      for (final (pick, shown) in [
        (0, 'You solved 1 of them without mistakes'),
        (1, "You've played on 5 days"),
      ]) {
        await pumpRecords(
          tester,
          () async => _data(
            recent: recent,
            events: events,
            perfectClears: 1,
            currentStreak: 1,
            activeDays: 5,
          ),
          supportPick: pick,
        );
        expect(inSummary(find.text(shown)), findsOneWidget);
      }
    });

    testWidgets('no mistake-free puzzle: only the play sentence is a candidate',
        (tester) async {
      for (final pick in [0, 1]) {
        await pumpRecords(
          tester,
          () async => _data(
            recent: recent,
            events: events,
            perfectClears: 0,
            currentStreak: 0,
            activeDays: 1,
          ),
          supportPick: pick,
        );
        expect(
            inSummary(find.textContaining('without mistakes')), findsNothing);
        expect(inSummary(find.text("You've played on 1 day")), findsOneWidget);
      }
    });

    testWidgets('the support line is a full sentence: no dot, no pill',
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
      expect(inSummary(find.text("You've played on 3 days")), findsOneWidget);
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
    expect(find.text("You've been playing 2 days in a row"), findsOneWidget);
    expect(find.textContaining('Longest streak'), findsOneWidget);
  });

  testWidgets('tablet landscape uses two columns capped at 1072 wide',
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
    expect(width, lessThan(1072));
    // 가로형(폭 > 900): 카드 영역은 min(1072, 폭 - 64), 가운데 정렬.
    // 1280 → 1072, 좌우 (1280 - 1072) / 2 = 104 (최소 32 이상).
    expect(weekLeft, greaterThanOrEqualTo(104));
    expect(weekLeft, lessThan(160));
  });

  testWidgets('phone and tablet portrait keep the 960 cap', (tester) async {
    await pumpRecords(
      tester,
      () async => _data(recent: recent, events: events),
      size: const Size(1024, 1366),
    );
    final weekLeft = tester.getTopLeft(find.text("This week's activity")).dx;
    // 폭 1024 > 900이므로 가로형 규칙(1072 → 폭 - 64 = 960)이 같은 값이 된다.
    expect(weekLeft, greaterThanOrEqualTo(32));
    expect(tester.takeException(), isNull);
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

    testWidgets('Korean sentence wraps only at spaces, never mid-word',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: clears(17)),
        locale: const Locale('ko'),
      );
      final finder = find.descendant(
        of: find.byKey(const Key('records_summary_card')),
        matching: find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().replaceAll('\u2060', '') ==
                '벌써 17개의 퍼즐을 풀었어요'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      final plain = paragraph.text.toPlainText();
      // 화면과 같은 글을 한 줄 폭보다 1px 좁게 배치해 반드시 줄바꿈이 일어나게
      // 하고, 줄이 시작되는 위치를 확인한다(글꼴과 무관하게 끝 단어가 넘어간다).
      final painter = TextPainter(
        text: paragraph.text,
        textDirection: TextDirection.ltr,
        textScaler: paragraph.textScaler,
      )..layout();
      addTearDown(painter.dispose);
      painter.layout(maxWidth: painter.width - 1);
      final lines = painter.computeLineMetrics();
      expect(lines.length, greaterThan(1));
      for (final line in lines.skip(1)) {
        final start = painter
            .getPositionForOffset(Offset(0, line.baseline - line.ascent / 2))
            .offset;
        expect(plain[start - 1], ' ', reason: 'line starts at offset $start');
      }
    });

    testWidgets('Japanese keeps a number with its counter (17問)',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: clears(17)),
        locale: const Locale('ja'),
      );
      final finder = find.descendant(
        of: find.byKey(const Key('records_summary_card')),
        matching: find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().replaceAll('\u2060', '') == 'もう17問のパズルを解きました'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      final plain = paragraph.text.toPlainText();
      final painter = TextPainter(
        text: paragraph.text,
        textDirection: TextDirection.ltr,
        textScaler: paragraph.textScaler,
      )..layout();
      addTearDown(painter.dispose);
      // 한 줄이 "17"에서 끝날 만한 폭으로 배치해도 "問"만 다음 줄로 가지 않는다.
      final afterNumber = plain.indexOf('17') + 2;
      final numberEnd = painter
          .getOffsetForCaret(TextPosition(offset: afterNumber), Rect.zero)
          .dx;
      painter.layout(maxWidth: numberEnd + 1);
      for (final line in painter.computeLineMetrics().skip(1)) {
        final start = painter
            .getPositionForOffset(Offset(0, line.baseline - line.ascent / 2))
            .offset;
        expect(RegExp(r'[0-9]').hasMatch(plain[start - 1]), isFalse,
            reason: 'line starts right after a digit at offset $start');
      }
    });

    testWidgets('the same count always shows the same sentence',
        (tester) async {
      await pumpRecords(tester, () async => _data(recent: clears(13)));
      expect(find.text("You've already solved 13 puzzles"), findsOneWidget);
      await pumpRecords(tester, () async => _data(recent: clears(13)));
      expect(find.text("You've already solved 13 puzzles"), findsOneWidget);
    });
  });

  group('level rings selector', () {
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

    testWidgets('rings are the level selector: buttons with selected state',
        (tester) async {
      await pumpRecords(tester, () async => _data(recent: data));
      final handle = tester.ensureSemantics();
      final beginner = find.bySemanticsLabel('Beginner, 2 of 159 completed');
      final intermediate =
          find.bySemanticsLabel('Intermediate, 1 of 159 completed');
      expect(tester.getSemantics(beginner),
          isSemantics(isButton: true, isSelected: true));
      expect(tester.getSemantics(intermediate),
          isNot(isSemantics(isSelected: true)));

      await tester.ensureVisible(ring('중급'));
      await tester.pumpAndSettle();
      await tester.tap(ring('중급'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getSemantics(intermediate),
          isSemantics(isButton: true, isSelected: true));
      expect(
          tester.getSemantics(beginner), isNot(isSemantics(isSelected: true)));
      // 아래 기록도 중급으로 바뀐다(중급 기록 하나, 100초 → 약 2분).
      expect(find.text('About 2 min'), findsOneWidget);
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

  group('recent completions section', () {
    List<RecentCompletion> completions(int n) => [
          for (var i = 1; i <= n; i++)
            RecentCompletion(
              levelName: '초급',
              gameNumber: i,
              clearDate: _date(today),
              clearTime: 200 + i,
              wrongCount: 0,
              hintsUsed: 0,
            ),
        ];
    Finder section() => find.byKey(const Key('records_recent'));
    Finder viewAll() => find.byKey(const Key('records_recent_view_all'));

    testWidgets('is the last section, below the activity calendar',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(
            recent: recent, events: events, recentCompletions: completions(2)),
      );
      double top(Finder f) => tester.getTopLeft(f).dy;
      expect(top(find.text('Records by level')),
          lessThan(top(find.text('Last 26 weeks of activity'))));
      expect(top(find.text('Last 26 weeks of activity')),
          lessThan(top(find.text('Recent completions'))));
      expect(find.text('Tap a puzzle to play it again'), findsOneWidget);
      expect(viewAll(), findsNothing);
    });

    testWidgets('shows at most five, with "View all (N)" when there are more',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(
            recent: recent, events: events, recentCompletions: completions(7)),
      );
      for (var i = 1; i <= 5; i++) {
        expect(
          find.descendant(
              of: section(),
              matching: find.text('Beginner ${i.toString().padLeft(3, '0')}')),
          findsOneWidget,
        );
      }
      expect(find.text('Beginner 006'), findsNothing);
      expect(find.text('View all (7)'), findsOneWidget);

      await tester.ensureVisible(viewAll());
      await tester.pumpAndSettle();
      await tester.tap(viewAll());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(RecentCompletionsScreen), findsOneWidget);
    });

    testWidgets('hidden when there is no completion history', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: recent, events: events),
      );
      expect(section(), findsNothing);
      expect(find.text('Records by level'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a row asks to replay that puzzle', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpRecords(
        tester,
        () async => _data(
            recent: recent, events: events, recentCompletions: completions(2)),
        databaseHelper: _RecordOnlyDb(),
      );
      final row =
          find.descendant(of: section(), matching: find.text('Beginner 002'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.text('Replay puzzle 2?'), findsOneWidget);
      // 확인창에 그 퍼즐의 최고 기록이 한 줄로 나온다.
      expect(find.text('Best run 03:22 · 0 mistakes'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Replay puzzle 2?'), findsNothing);
    });

    testWidgets('tablet two columns: recent completions on the right',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(
            recent: recent, events: events, recentCompletions: completions(2)),
        size: const Size(1280, 800),
      );
      final weekLeft = tester.getTopLeft(find.text("This week's activity")).dx;
      final recentLeft = tester.getTopLeft(find.text('Recent completions')).dx;
      final calendarLeft =
          tester.getTopLeft(find.text('Last 26 weeks of activity')).dx;
      expect(recentLeft, greaterThan(weekLeft));
      expect(recentLeft, calendarLeft);
      // 오른쪽 칼럼에서 활동 달력 아래.
      expect(tester.getTopLeft(find.text('Last 26 weeks of activity')).dy,
          lessThan(tester.getTopLeft(find.text('Recent completions')).dy));
      expect(tester.takeException(), isNull);
    });
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
        'switching between two levels with different records shows '
        'the correct numbers for each', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: twoLevelRecent, events: events),
      );
      // 기본 선택은 기록이 있는 첫 난이도(초급)라 별도로 탭하지 않아도 된다.
      expect(find.text('About 7 min'), findsOneWidget); // typical time of 초급

      await tester.ensureVisible(levelRing('Intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(levelRing('Intermediate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('About 2 min'), findsOneWidget);
      expect(find.text('About 7 min'), findsNothing);
    });

    testWidgets(
        'tapping a second difficulty before the first settles shows '
        'only the latest difficulty', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: twoLevelRecent, events: events),
      );
      await tester.ensureVisible(levelRing('Intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(levelRing('Intermediate'));
      await tester.pump(); // 아직 전환 중
      await tester.ensureVisible(levelRing('Advanced'));
      await tester.pumpAndSettle();
      await tester.tap(levelRing('Advanced'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('No completed puzzles at this level yet.'),
        findsOneWidget,
      );
      expect(find.text('About 2 min'), findsNothing);
    });

    group('ring selection highlight', () {
      Duration highlightDuration(WidgetTester tester, String label) => tester
          .widget<AnimatedContainer>(find.descendant(
              of: levelRing(label), matching: find.byType(AnimatedContainer)))
          .duration;

      testWidgets('reduce motion: the highlight change is instant',
          (tester) async {
        await pumpRecords(
          tester,
          () async => _data(recent: twoLevelRecent, events: events),
          reduceMotion: true,
        );
        expect(highlightDuration(tester, 'Beginner'), Duration.zero);
      });

      testWidgets('with motion, the highlight takes 180ms', (tester) async {
        await pumpRecords(
          tester,
          () async => _data(recent: twoLevelRecent, events: events),
        );
        expect(highlightDuration(tester, 'Beginner'),
            const Duration(milliseconds: 180));
      });

      testWidgets('selecting does not move any ring', (tester) async {
        await pumpRecords(
          tester,
          () async => _data(recent: twoLevelRecent, events: events),
        );
        await tester.ensureVisible(levelRing('Intermediate'));
        await tester.pumpAndSettle();
        final advancedBefore = tester.getRect(levelRing('Advanced'));
        final expertBefore = tester.getRect(levelRing('Expert'));
        await tester.tap(levelRing('Intermediate'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getRect(levelRing('Advanced')), advancedBefore);
        expect(tester.getRect(levelRing('Expert')), expertBefore);
      });

      testWidgets('re-selecting the same difficulty does nothing',
          (tester) async {
        await pumpRecords(
          tester,
          () async => _data(recent: twoLevelRecent, events: events),
        );
        await tester.ensureVisible(levelRing('Beginner'));
        await tester.pumpAndSettle();
        await tester.tap(levelRing('Beginner'));
        await tester.pump();
        expect(find.text('About 7 min'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets(
        'reduce motion swaps difficulty content in a single frame, no fade',
        (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: twoLevelRecent, events: events),
        reduceMotion: true,
      );
      expect(find.text('About 7 min'), findsOneWidget);

      await tester.ensureVisible(levelRing('Intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(levelRing('Intermediate'));
      // 동작 줄이기에서는 지속 시간이 0이라, 단 한 프레임 만에 이전 내용이
      // 완전히 사라지고 새 내용으로 바뀐다(애니메이션 중간 프레임이 없음).
      await tester.pump();
      expect(find.text('About 2 min'), findsOneWidget);
      expect(find.text('About 7 min'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'tablet two-column layout keeps its columns in place after '
        'switching level', (tester) async {
      await pumpRecords(
        tester,
        () async => _data(recent: twoLevelRecent, events: events),
        size: const Size(1280, 800),
      );
      final weekLeftBefore =
          tester.getTopLeft(find.text("This week's activity")).dx;
      final calendarLeftBefore =
          tester.getTopLeft(find.text('Last 26 weeks of activity')).dx;

      await tester.ensureVisible(levelRing('Intermediate'));
      await tester.pumpAndSettle();
      await tester.tap(levelRing('Intermediate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // 탭이 실제로 난이도를 바꿨는지 확인한다(중급 기록 1개).
      expect(find.text('About 2 min'), findsOneWidget);
      expect(find.text('About 7 min'), findsNothing);

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
