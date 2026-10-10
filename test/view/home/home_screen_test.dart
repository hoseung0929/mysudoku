import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/home/home_dashboard_service.dart';
import 'package:sudoku159/services/home/level_progress_service.dart';
import 'package:sudoku159/navigation/root_nav_scope.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/home/home_screen.dart';
import 'package:sudoku159/view/home/saved_games_screen.dart';
import 'package:sudoku159/widgets/sudoku_motif.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class _NoopWakelockPlatform extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

final _level = SudokuLevel.levels.first;

List<List<int>> _solution() => List.generate(
      9,
      (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1),
    );

List<List<int>> _puzzle() {
  final b = _solution();
  for (var i = 0; i < _level.emptyCells; i++) {
    b[i ~/ 9][i % 9] = 0;
  }
  return b;
}

SudokuGame _game(String levelName, int number) => SudokuGame(
      board: _puzzle(),
      solution: _solution(),
      emptyCells: _level.emptyCells,
      levelName: levelName,
      gameNumber: number,
    );

ContinueGameSummary _summary(int number,
    {double progress = 0.4, int notes = 0, String levelName = '초급'}) {
  final level = SudokuLevel.levels.firstWhere((l) => l.name == levelName);
  return ContinueGameSummary(
    level: level,
    game: _game(levelName, number),
    progress: progress,
    elapsedFilledCells: 10,
    lastPlayedAtMillis: DateTime.now().millisecondsSinceEpoch,
    elapsedSeconds: 60,
    wrongCount: 0,
    isMemoMode: false,
    noteCount: notes,
  );
}

class _FakeDashboard extends HomeDashboardService {
  _FakeDashboard(this.produce);
  final Future<HomeDashboardData> Function() produce;
  List<ContinueGameSummary> all = const [];
  int loadCount = 0;

  @override
  Future<HomeDashboardData> load(AppLocalizations l10n,
      {int continueGamesLimit = 3}) {
    loadCount++;
    return produce();
  }

  @override
  Future<List<ContinueGameSummary>> loadContinueGames({int? limit}) async =>
      all;
}

HomeDashboardData _data({
  List<ContinueGameSummary> continues = const [],
  int challengeNumber = 7,
  bool challengeDone = false,
  bool challengeHasSession = false,
  double challengeProgressValue = 0.36,
  int challengeNotes = 0,
  int streakDays = 0,
  String? lastClearDate,
  SudokuGame? challenge,
  bool noChallenge = false,
  ChallengeRecommendationEvent? recommendationEvent,
}) {
  final date = ChallengeProgressService.formatLocalDate(DateTime.now());
  return HomeDashboardData(
    continueGame: continues.isEmpty ? null : continues.first,
    continueGames: continues,
    totalContinueCount: continues.length,
    todayChallenge:
        noChallenge ? null : (challenge ?? _game('초급', challengeNumber)),
    todayChallengeContinueGame: challengeHasSession
        ? _summary(challengeNumber,
            progress: challengeProgressValue, notes: challengeNotes)
        : null,
    challengeProgress: ChallengeProgressSummary(
      streakDays: streakDays,
      isTodayChallengeCleared: challengeDone,
      todayChallengeLevelName: '초급',
      todayChallengeGameNumber: challengeNumber,
      challengeDate: date,
      recommendationEvent: recommendationEvent,
      lastClearDate: lastClearDate,
      weeklyClearCount: 0,
      weeklyGoalTarget: 3,
      perfectClearCount: 0,
    ),
    averageClearTimeSeconds: 0,
  );
}

class _FakeDb implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  @override
  Future<int> getGameCount(String levelName) async => 159;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  wakelockPlusPlatformInstance = _NoopWakelockPlatform();
  EditableText.debugDeterministicCursor = true;

  Future<void> pumpHome(
    WidgetTester tester,
    _FakeDashboard dashboard, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    ThemeData? theme,
    Locale? locale,
    bool reduceMotion = false,
    ValueChanged<int>? onGoToTab,
  }) async {
    SharedPreferences.setMockInitialValues({});
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
          goToTab: onGoToTab ?? (_) {},
          child: Scaffold(
            body: HomeScreen(
              key: UniqueKey(),
              homeDashboardService: dashboard,
              levelProgressService: LevelProgressService(
                loadClearedGameCount: (_) async => 12,
              ),
              databaseHelper: _FakeDb(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('first-time user: one start action, no zero-stat cards',
      (tester) async {
    await pumpHome(tester, _FakeDashboard(() async => _data()));
    expect(find.text('Start your first puzzle'), findsOneWidget);
    expect(find.text('Choose a level'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('New game · choose a level'), findsOneWidget);
    // 검증되지 않은 시간·기법 주장 없이 사실(빈칸 수)만 표시.
    expect(find.text('${_level.emptyCells} blanks'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('user with history but nothing in progress', (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(lastClearDate: '2026-09-01')),
    );
    expect(find.text('Start a new puzzle'), findsOneWidget);
    expect(find.text('Start your first puzzle'), findsNothing);
  });

  testWidgets('recommendation events replace the not-started line',
      (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(
            lastClearDate: '2026-09-01',
            recommendationEvent: ChallengeRecommendationEvent.firstChallenge,
          )),
    );
    expect(
        find.text('Your first challenge starts at Beginner'), findsOneWidget);
    expect(find.text('Not started yet'), findsNothing);

    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(
            lastClearDate: '2026-09-01',
            recommendationEvent: ChallengeRecommendationEvent.promoted,
          )),
    );
    expect(find.text('Try Beginner today?'), findsOneWidget);
  });

  testWidgets('one in-progress game: continue is the primary action',
      (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(continues: [_summary(12)])),
    );
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Beginner\u00A0· Puzzle\u00A012'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.textContaining('View all in-progress'), findsNothing);
    // 오늘의 도전은 별도 카드
    expect(find.text("Today's challenge"), findsOneWidget);
    expect(find.text('Beginner\u00A0· Puzzle\u00A07'), findsOneWidget);
    expect(find.text('Start challenge'), findsOneWidget);
    expect(find.text('Not started yet'), findsOneWidget);
    // 시작 전에는 진행바가 없다.
    expect(find.byKey(const Key('home_challenge_progress')), findsNothing);
  });

  testWidgets(
      "no 'view past challenges' button on the today's-challenge card "
      '(removed)', (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(continues: [_summary(12)])),
    );
    expect(find.text('View past challenges'), findsNothing);
    expect(find.byIcon(Icons.calendar_month_outlined), findsNothing);
  });

  testWidgets('notes-only game is described, several games link to the list',
      (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(
        () async => _data(continues: [
          _summary(5, progress: 0, notes: 3),
          _summary(6),
          _summary(9),
        ]),
      ),
    );
    expect(find.text('Writing notes'), findsOneWidget);
    expect(find.text('View all in-progress games (3)'), findsOneWidget);
  });

  testWidgets('same puzzle for continue and challenge is shown once',
      (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(
        () async => _data(
          continues: [_summary(7)],
          challengeNumber: 7,
          challengeHasSession: true,
        ),
      ),
    );
    // 병합: 이어하기 카드가 도전 카드 역할 — 라벨 '오늘의 도전', 상태+진행바.
    expect(find.text('Beginner\u00A0· Puzzle\u00A07'), findsOneWidget);
    expect(find.text("Today's challenge"), findsOneWidget);
    expect(find.text('Continue today\'s challenge'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('40% done'), findsOneWidget);
    expect(find.byKey(const Key('home_challenge_progress')), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  group('challenge card / merged card policy', () {
    SudokuGameScreen openedScreen(WidgetTester tester) =>
        tester.widget<SudokuGameScreen>(find.byType(SudokuGameScreen));

    testWidgets(
        'after the challenge is done, a leftover retry session is NOT merged: '
        'continue card + completion card, no "Play again"', (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(
          () async => _data(
            continues: [_summary(7)],
            challengeNumber: 7,
            challengeDone: true,
            challengeHasSession: true,
          ),
        ),
      );
      // 이어하기 카드(재도전 진행) + 도전 카드(완료)가 따로 보인다.
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text("Today's challenge complete!"), findsOneWidget);
      expect(find.text('Beginner\u00A0· Puzzle\u00A07'), findsNWidgets(2));
      // 병합 카드의 도전 라벨/진행바는 없다(완료 상태가 우선).
      expect(find.byKey(const Key('home_challenge_progress')), findsNothing);
      // 완료 카드에는 "오늘의 도전" 머리줄이 없다(제목이 완료 문구).
      expect(find.text("Today's challenge"), findsNothing);
      // 새로 시작하면 재도전 세션이 지워지므로 '다시 풀기'는 숨긴다.
      expect(find.text('Play again'), findsNothing);
    });

    testWidgets('continue card resumes the saved retry session',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(
          () async => _data(
            continues: [_summary(7)],
            challengeNumber: 7,
            challengeDone: true,
            challengeHasSession: true,
          ),
        ),
      );
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(openedScreen(tester).game.gameNumber, 7);
    });

    testWidgets('done without a saved session has no "Play again" either',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data(challengeDone: true)),
      );
      expect(find.text('Play again'), findsNothing);
      expect(find.byType(SudokuGameScreen), findsNothing);
    });

    testWidgets('merged card with notes only: notes text, no progress bar',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(
          () async => _data(
            continues: [_summary(7, progress: 0, notes: 3)],
            challengeNumber: 7,
            challengeHasSession: true,
          ),
        ),
      );
      expect(find.text("Today's challenge"), findsOneWidget);
      expect(find.text('Writing notes'), findsOneWidget);
      expect(find.byKey(const Key('home_challenge_progress')), findsNothing);
    });

    testWidgets('standalone in-progress card: tapping the card resumes',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data(challengeHasSession: true)),
      );
      await tester.tap(find.text('36% done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final screen = openedScreen(tester);
      expect(screen.game.gameNumber, 7);
      expect(screen.restoreSavedSession, isTrue);
    });

    testWidgets(
        'merged card: card tap and button open the game screen only once',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(
          () async => _data(
            continues: [_summary(7)],
            challengeNumber: 7,
            challengeHasSession: true,
          ),
        ),
      );
      await tester.tap(find.text('Beginner\u00A0· Puzzle\u00A07'));
      await tester.tap(find.text('Continue'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SudokuGameScreen), findsOneWidget);
    });

    testWidgets(
        'error card: card tap does nothing, retry reloads only once '
        'even when tapped repeatedly', (tester) async {
      final gate = Completer<HomeDashboardData>();
      var calls = 0;
      final dashboard = _FakeDashboard(() {
        calls++;
        if (calls == 1) return Future.value(_data(noChallenge: true));
        return gate.future;
      });
      await pumpHome(tester, dashboard);
      expect(find.text("Couldn't load today's challenge"), findsOneWidget);

      // 카드 빈 영역(제목) 탭은 재조회를 일으키지 않는다.
      await tester.tap(find.text("Couldn't load today's challenge"));
      await tester.pump();
      expect(dashboard.loadCount, 1);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.tap(find.byType(CircularProgressIndicator).last,
          warnIfMissed: false);
      await tester.pump();
      expect(dashboard.loadCount, 2); // 재조회 중 연타해도 한 번만

      gate.complete(_data());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // 재조회 성공 → 시작 전 상태로 교체.
      expect(find.text('Start challenge'), findsOneWidget);
      expect(dashboard.loadCount, 2);
    });

    testWidgets('reduce motion: progress bar and state switch are instant',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data(challengeHasSession: true)),
        reduceMotion: true,
      );
      final bar = find.byKey(const Key('home_challenge_progress'));
      expect(bar, findsOneWidget);
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(find.descendant(
                of: bar, matching: find.byType(TweenAnimationBuilder<double>)))
            .duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<AnimatedSwitcher>(find
                .ancestor(of: bar, matching: find.byType(AnimatedSwitcher))
                .first)
            .duration,
        Duration.zero,
      );
    });

    testWidgets('motion on: bar fills over 300ms, switch is short',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data(challengeHasSession: true)),
      );
      final bar = find.byKey(const Key('home_challenge_progress'));
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(find.descendant(
                of: bar, matching: find.byType(TweenAnimationBuilder<double>)))
            .duration,
        const Duration(milliseconds: 300),
      );
    });

    for (final entry in {
      'done': () => _data(challengeDone: true, streakDays: 4),
      'error': () => _data(noChallenge: true),
      'in progress': () => _data(challengeHasSession: true),
    }.entries) {
      testWidgets('no overflow at 2x text on a small phone: ${entry.key}',
          (tester) async {
        await pumpHome(
          tester,
          _FakeDashboard(() async => entry.value()),
          size: const Size(320, 568),
          textScale: 2.0,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('challenge states: not started / in progress / done',
      (tester) async {
    await pumpHome(tester, _FakeDashboard(() async => _data()));
    expect(find.text('Start challenge'), findsOneWidget);
    expect(find.text('Not started yet'), findsOneWidget);

    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(challengeHasSession: true)),
    );
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('36% done'), findsOneWidget);
    expect(find.byKey(const Key('home_challenge_progress')), findsOneWidget);

    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(challengeDone: true)),
    );
    expect(find.text("Today's challenge complete!"), findsOneWidget);
    expect(find.text('Beginner\u00A0· Puzzle\u00A07'), findsOneWidget);
    expect(find.byKey(const Key('home_challenge_progress')), findsNothing);
    // 완료 카드에는 재도전 버튼이 없다.
    expect(find.text('Play again'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Start challenge'), findsNothing);
  });

  testWidgets(
      'the done challenge card is 20-30pt shorter than the not-started card',
      (tester) async {
    Future<Rect> measure(bool done) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data(challengeDone: done)),
      );
      return tester.getRect(
        find.byKey(const Key('home_today_challenge_artwork')),
      );
    }

    final start = await measure(false);
    final done = await measure(true);
    expect(start.height - done.height, inInclusiveRange(20, 30));
    expect(done.top, start.top);
    expect(find.text('Beginner\u00A0· Puzzle\u00A07'), findsOneWidget);
    expect(find.text("Today's challenge"), findsNothing);
  });

  testWidgets('done card exposes status and puzzle without button semantics',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(challengeDone: true)),
    );
    final node = tester.getSemantics(
      find.bySemanticsLabel(
          "Today's challenge complete! Beginner\u00A0· Puzzle\u00A07"),
    );
    final data = node.getSemanticsData();
    expect(data.flagsCollection.isButton, isFalse);
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });

  testWidgets('challenge card tap: starts from anywhere on the card',
      (tester) async {
    await pumpHome(tester, _FakeDashboard(() async => _data()));
    await tester.tap(find.text('Not started yet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SudokuGameScreen), findsOneWidget);
  });

  testWidgets('finished challenge card is not tappable as a whole',
      (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(challengeDone: true)),
    );
    await tester.tap(find.text("Today's challenge complete!"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SudokuGameScreen), findsNothing);
  });

  testWidgets('challenge check fades in only on a real not-done -> done change',
      (tester) async {
    var done = false;
    final dashboard = _FakeDashboard(() async => _data(challengeDone: done));
    final key = GlobalKey();
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpApp() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeScreen(
              key: key,
              homeDashboardService: dashboard,
              levelProgressService: LevelProgressService(
                loadClearedGameCount: (_) async => 12,
              ),
              databaseHelper: _FakeDb(),
            ),
          ),
        ),
      );
    }

    Finder fading() =>
        find.byWidgetPredicate((w) => w is FadeInOnce && w.enabled);

    await pumpApp();
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(fading(), findsNothing);

    // 실제 미완료 → 완료 전환: 체크가 나타나는 동안만 효과가 켜진다.
    done = true;
    await pumpApp();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(fading(), findsWidgets);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(fading(), findsNothing);
    expect(find.text("Today's challenge complete!"), findsOneWidget);

    // 이후 다시 그려져도(탭 복귀 등) 이미 완료된 카드는 효과 없이 완료 상태.
    await pumpApp();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(fading(), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('loading is not shown as empty; failure offers retry',
      (tester) async {
    final gate = Completer<HomeDashboardData>();
    var calls = 0;
    final dashboard = _FakeDashboard(() {
      calls++;
      if (calls == 1) return gate.future;
      return Future.value(_data(continues: [_summary(3)]));
    });
    await pumpHome(tester, dashboard);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Start a new puzzle'), findsNothing);
    expect(find.text('Start your first puzzle'), findsNothing);

    gate.completeError(StateError('db down'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("Couldn't load your games."), findsOneWidget);
    expect(find.text('Start a new puzzle'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('challenge puzzle load failure shows retry, never another puzzle',
      (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(noChallenge: true)),
    );
    expect(find.text("Couldn't load today's challenge"), findsOneWidget);
    expect(find.text('Please try again in a moment.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    // 실패 상태에는 난이도·번호를 보이지 않는다.
    expect(find.textContaining('Puzzle '), findsNothing);
  });

  testWidgets('view-all list restores the picked game; delete asks first',
      (tester) async {
    final all = [_summary(5, progress: 0, notes: 2), _summary(6), _summary(9)];
    final dashboard = _FakeDashboard(() async => _data(continues: all))
      ..all = all;
    await pumpHome(tester, dashboard);

    await tester.tap(find.text('View all in-progress games (3)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SavedGamesScreen), findsOneWidget);
    Finder inList(String text) => find.descendant(
        of: find.byType(SavedGamesScreen), matching: find.text(text));
    expect(inList('Beginner\u00A0· Puzzle\u00A05'), findsOneWidget);

    // 삭제는 확인창을 먼저 보여주고, 취소하면 목록이 그대로다.
    await tester.tap(find.byTooltip('Delete saved progress').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete saved progress?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(inList('Beginner\u00A0· Puzzle\u00A05'), findsOneWidget);

    // 항목을 고르면 그 게임이 저장된 상태로 복원된다.
    await tester.tap(inList('Beginner\u00A0· Puzzle\u00A09'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    final screen =
        tester.widget<SudokuGameScreen>(find.byType(SudokuGameScreen));
    expect(screen.game.gameNumber, 9);
    expect(screen.restoreSavedSession, isTrue);
  });

  testWidgets('rapid taps on continue open a single game screen',
      (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(continues: [_summary(12)])),
    );
    final continueButton = find.text('Continue');
    await tester.tap(continueButton);
    await tester.tap(continueButton, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SudokuGameScreen), findsOneWidget);
  });

  for (final entry in {
    'narrow + large text': (const Size(320, 568), 2.0, false),
    'phone dark': (const Size(390, 844), 1.0, true),
    'tablet landscape': (const Size(1024, 768), 1.0, false),
    'ipad 11 landscape 1.3x': (const Size(1194, 834), 1.3, false),
    'ipad 13 landscape dark': (const Size(1366, 1024), 1.0, true),
    'tablet portrait dark': (const Size(768, 1024), 1.0, true),
  }.entries) {
    testWidgets('renders without overflow: ${entry.key}', (tester) async {
      final (size, scale, dark) = entry.value;
      await pumpHome(
        tester,
        _FakeDashboard(
          () async => _data(
            continues: [_summary(5, progress: 0, notes: 2), _summary(6)],
            challengeHasSession: true,
          ),
        ),
        size: size,
        textScale: scale,
        theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
      );
      expect(tester.takeException(), isNull);
      // 이어하기 카드 + 진행 중인 오늘의 도전 카드
      expect(find.text('Continue'), findsNWidgets(2));
    });
  }

  for (final entry in {
    // 폭이 600을 넘으면(가로 모드 폰 포함) 기존 관례대로 태블릿 레이아웃을
    // 쓰므로, 히어로 높이도 태블릿 값(300)이 적용된다.
    'phone portrait': (const Size(390, 844), 236.0),
    'phone landscape': (const Size(844, 390), 276.0),
    // 아이패드: 폭/2(이미지 전체), 상한 min(420, 높이의 40%).
    'tablet portrait': (const Size(768, 1024), 384.0),
    'tablet landscape': (const Size(1024, 768), 307.2),
  }.entries) {
    testWidgets(
        'hero header keeps its fixed height with no overflow: ${entry.key}',
        (tester) async {
      final (size, expectedHeight) = entry.value;
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data()),
        size: size,
      );
      final headerSize =
          tester.getSize(find.byKey(const Key('home_hero_header')));
      expect(headerSize.height, closeTo(expectedHeight, 0.01));
      expect(tester.takeException(), isNull);
    });
  }

  for (final lang in ['ko', 'ja', 'es', 'zh']) {
    testWidgets('long translations do not overflow at 2x text: $lang',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(
          () async => _data(
            continues: [_summary(5, progress: 0, notes: 2), _summary(6)],
            challengeHasSession: true,
          ),
        ),
        size: const Size(320, 568),
        textScale: 2.0,
        locale: Locale(lang),
      );
      expect(tester.takeException(), isNull);
    });
  }

  // 아이패드: 글자를 키운(제목 22 · 설명 15) 카드가 모든 언어에서 넘치지 않는다.
  for (final lang in ['en', 'ko', 'ja', 'es', 'zh']) {
    for (final textScale in [1.0, 1.3]) {
      for (final size in [const Size(834, 1194), const Size(1194, 834)]) {
        testWidgets(
            'tablet bigger card text does not overflow: $lang x$textScale '
            '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
          await pumpHome(
            tester,
            _FakeDashboard(
              () async => _data(
                continues: [_summary(5, progress: 0, notes: 2), _summary(6)],
                challengeHasSession: true,
              ),
            ),
            size: size,
            textScale: textScale,
            locale: Locale(lang),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  // 가로형: 본문 외곽 최대 1120(가장자리 최소 32), 시작 카드는 설명+버튼 가로 배치.
  testWidgets('wide landscape home: 1120 body, start button capped at 360',
      (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(() async => _data()),
      size: const Size(1366, 1024),
    );
    final button = find.widgetWithText(FilledButton, 'Choose a level');
    expect(button, findsOneWidget);
    expect(tester.getSize(button).width, lessThanOrEqualTo(360));
    final card =
        tester.getRect(find.byKey(const Key('home_today_challenge_artwork')));
    // 오늘의 도전 카드: 가장자리 최소 32, 폭은 1072 이하.
    expect(card.left, greaterThanOrEqualTo(32));
    expect(card.width, lessThanOrEqualTo(1072));
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow tablet keeps the stacked start button', (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(() async => _data()),
      size: const Size(700, 1000),
    );
    final button = find.widgetWithText(FilledButton, 'Choose a level');
    expect(tester.getSize(button).width, greaterThan(400));
    expect(tester.takeException(), isNull);
  });

  group('decorative images', () {
    testWidgets(
        'start card has no mascot (avoids duplicating the hero header character); challenge card shows the motif',
        (tester) async {
      await pumpHome(tester, _FakeDashboard(() async => _data()));
      // 캐릭터는 최상단 히어로 이미지에 이미 나오므로, 시작 카드에는 더 이상
      // 별도 마스코트를 넣지 않는다(캐릭터 중복 제거).
      expect(find.text('Start your first puzzle'), findsOneWidget);
      final artwork = find.byKey(const Key('home_today_challenge_artwork'));
      expect(artwork, findsOneWidget);
      // 장식은 스크린 리더에서 제외된다.
      expect(
        find.ancestor(
          of: artwork,
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });

    testWidgets('no motif when the challenge puzzle could not be loaded',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data(noChallenge: true)),
      );
      expect(
        find.byKey(const Key('home_today_challenge_artwork')),
        findsNothing,
      );
    });

    testWidgets('merged continue+challenge card does not repeat decoration',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(
          () async => _data(continues: [_summary(7)], challengeNumber: 7),
        ),
      );
      expect(
        find.byKey(const Key('home_today_challenge_artwork')),
        findsNothing,
      );
      expect(find.text('Continue'), findsOneWidget);
    });
  });

  group('difficulty list', () {
    testWidgets(
        'shows the 4 released difficulty levels; Master stays hidden for now',
        (tester) async {
      await pumpHome(tester, _FakeDashboard(() async => _data()));
      await tester.pumpAndSettle();

      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Expert'), findsOneWidget);
      // 마스터는 아직 준비 중이라 홈 화면에서는 우선 숨긴다.
      expect(find.text('Master'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('content padding (hero stays full width)', () {
    testWidgets('mobile body content has 16px horizontal padding',
        (tester) async {
      await pumpHome(tester, _FakeDashboard(() async => _data()));
      await tester.pumpAndSettle();

      final heroLeft =
          tester.getTopLeft(find.byKey(const Key('home_hero_header'))).dx;
      final heroWidth =
          tester.getSize(find.byKey(const Key('home_hero_header'))).width;
      // 히어로는 좌우 여백 없이 화면 전체 너비를 그대로 쓴다.
      expect(heroLeft, 0);
      expect(heroWidth, 390);

      final sectionTitleLeft =
          tester.getTopLeft(find.text('New game · choose a level')).dx;
      expect(sectionTitleLeft, 16);
    });

    testWidgets('tablet body content has 24px horizontal padding',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data()),
        size: const Size(768, 1024),
      );
      await tester.pumpAndSettle();

      final heroLeft =
          tester.getTopLeft(find.byKey(const Key('home_hero_header'))).dx;
      final heroWidth =
          tester.getSize(find.byKey(const Key('home_hero_header'))).width;
      expect(heroLeft, 0);
      expect(heroWidth, 768);

      final sectionTitleLeft =
          tester.getTopLeft(find.text('New game · choose a level')).dx;
      expect(sectionTitleLeft, 24);
    });
  });

  group('collapsing app bar', () {
    testWidgets(
        'hero scrolls away with the body instead of staying pinned; app bar collapses once the hero passes',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data()),
        size: const Size(390, 700),
      );

      // 처음에는 히어로가 사진 위 투명 오버레이(흰 글자)로 겹쳐 있다.
      Text nameText() => tester.widget<Text>(find.text('Traveler'));
      expect((nameText().style?.color), Colors.white);

      // 히어로 높이(236)를 완전히 넘어갈 만큼 스크롤한다 -> 더 이상 고정되어
      // 있지 않고 본문과 함께 위로 스크롤되어 사라져야 한다.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final heroRect =
          tester.getRect(find.byKey(const Key('home_hero_header')));
      expect(heroRect.bottom, lessThanOrEqualTo(0));

      // 축소 앱바는 이제 불투명 배경 + 테마 글자색으로 전환된다.
      expect((nameText().style?.color), isNot(Colors.white));

      // 다시 맨 위로 스크롤하면 투명 오버레이 상태로 되돌아온다.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect((nameText().style?.color), Colors.white);
    });
  });

  group('header and start action', () {
    testWidgets('first card is never hidden behind the pinned header',
        (tester) async {
      for (final scale in [1.0, 1.6, 2.3]) {
        await pumpHome(
          tester,
          _FakeDashboard(() async => _data()),
          textScale: scale,
        );
        await tester.pump(const Duration(milliseconds: 100));
        final headerBottom =
            tester.getRect(find.byKey(const Key('home_hero_header'))).bottom;
        final cardTop =
            tester.getTopLeft(find.text('Start your first puzzle')).dy;
        expect(cardTop, greaterThanOrEqualTo(headerBottom), reason: '$scale');
      }
    });

    testWidgets('"Choose a level" scrolls to the level list, starts nothing',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data()),
        size: const Size(390, 700),
      );
      await tester.tap(find.text('Choose a level'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final headerBottom =
          tester.getRect(find.byKey(const Key('home_hero_header'))).bottom;
      final title =
          tester.getTopLeft(find.text('New game · choose a level')).dy;
      expect(title, greaterThanOrEqualTo(headerBottom));
      expect(title, lessThan(700));
      expect(find.byType(SudokuGameScreen), findsNothing);
    });

    testWidgets('no settings button in the header (moved to bottom tab)',
        (tester) async {
      await pumpHome(tester, _FakeDashboard(() async => _data()));
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      expect(find.byTooltip('Settings'), findsNothing);
    });

    testWidgets(
        'reduce motion: "Choose a level" jumps to the level section instantly',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data()),
        size: const Size(390, 700),
        reduceMotion: true,
      );
      await tester.tap(find.text('Choose a level'));
      // 동작 줄이기에서는 jumpTo()라 한 프레임만으로 최종 위치에 도달한다.
      await tester.pump();
      final headerBottom =
          tester.getRect(find.byKey(const Key('home_hero_header'))).bottom;
      final title =
          tester.getTopLeft(find.text('New game · choose a level')).dy;
      expect(title, greaterThanOrEqualTo(headerBottom));
      expect(title, lessThan(700));
    });

    testWidgets(
        'without reduce motion: "Choose a level" still animates over time',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data()),
        size: const Size(390, 700),
      );
      await tester.tap(find.text('Choose a level'));
      // animateTo() 직후 첫 프레임에서는 아직 이동이 끝나지 않은 상태다.
      await tester.pump();
      final titleRightAfterTap =
          tester.getTopLeft(find.text('New game · choose a level')).dy;

      await tester.pump(const Duration(milliseconds: 500));
      final headerBottom =
          tester.getRect(find.byKey(const Key('home_hero_header'))).bottom;
      final titleSettled =
          tester.getTopLeft(find.text('New game · choose a level')).dy;
      expect(titleSettled, greaterThanOrEqualTo(headerBottom));
      expect(titleSettled, lessThan(700));
      // 애니메이션이 진행 중이었다면 첫 프레임과 정착 위치가 달라야 한다.
      expect(titleRightAfterTap, isNot(closeTo(titleSettled, 0.5)));
    });

    testWidgets('difficulty card opacity transition follows reduce motion',
        (tester) async {
      await pumpHome(tester, _FakeDashboard(() async => _data()));
      AnimatedOpacity cardOpacity() => tester.widget<AnimatedOpacity>(
            find.ancestor(
              of: find.text('Beginner'),
              matching: find.byType(AnimatedOpacity),
            ),
          );
      expect(cardOpacity().duration, const Duration(milliseconds: 140));

      await pumpHome(
        tester,
        _FakeDashboard(() async => _data()),
        reduceMotion: true,
      );
      expect(cardOpacity().duration, Duration.zero);
    });

    testWidgets(
        'level list scroll area reserves extra bottom space so the last card clears the floating bottom nav',
        (tester) async {
      await pumpHome(tester, _FakeDashboard(() async => _data()));
      final scrollView = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      final bottomPad = scrollView.padding!.resolve(TextDirection.ltr).bottom;
      // 이 화면 단독 테스트에는 실제 플로팅 하단 탭이 없어 겹침 자체를 직접
      // 재현할 수는 없지만, 예약된 하단 여백이 실측 탭 높이(약 86)보다
      // 넉넉한지는 확인할 수 있다.
      expect(bottomPad, greaterThanOrEqualTo(100));
    });

    testWidgets(
        "'Choose a level' stays the solid black primary button; 'Start today's challenge' becomes a light-purple secondary button",
        (tester) async {
      await pumpHome(tester, _FakeDashboard(() async => _data()));

      final chooseLevelButton = tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Choose a level'),
              matching: find.byType(FilledButton),
            ),
          )
          .style;
      final todayChallengeButton = tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Start challenge'),
              matching: find.byType(FilledButton),
            ),
          )
          .style;

      // '난이도 선택'은 배경색을 따로 지정하지 않아 테마 기본(검은색 계열)을
      // 그대로 쓰고, '오늘의 도전 시작'만 반투명 흰 유리 버튼으로 구분한다.
      expect(chooseLevelButton?.backgroundColor?.resolve({}), isNull);
      expect(
        todayChallengeButton?.backgroundColor?.resolve({}),
        const Color(0x8CFFFFFF),
      );
      expect(
        todayChallengeButton?.foregroundColor?.resolve({}),
        const Color(0xFF4A3F9A),
      );
    });

    for (final dark in [false, true]) {
      testWidgets(
          'status bar icons stay light over the hero, then follow the theme once collapsed (dark=$dark)',
          (tester) async {
        await pumpHome(
          tester,
          _FakeDashboard(() async => _data()),
          theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
          size: const Size(390, 700),
        );

        SystemUiOverlayStyle currentStyle() => tester
            .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .value;

        // 히어로가 보이는 동안은 앱 테마의 밝기와 무관하게 항상 밝은 상태바
        // 아이콘을 강제한다(사진 위라 가독성을 위해).
        expect(currentStyle().statusBarIconBrightness, Brightness.light);
        expect(currentStyle().statusBarBrightness, Brightness.dark);

        // 히어로 높이를 완전히 넘어 축소 앱바로 바뀌면 현재 테마를 따른다:
        // 라이트 모드는 검은색 아이콘, 다크 모드는 흰색 아이콘.
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -400),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          currentStyle().statusBarIconBrightness,
          dark ? Brightness.light : Brightness.dark,
        );
        expect(
          currentStyle().statusBarBrightness,
          dark ? Brightness.dark : Brightness.light,
        );
      });
    }
  });
}
