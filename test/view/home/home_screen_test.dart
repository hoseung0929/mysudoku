import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/challenge/achievement_service.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/home/home_dashboard_service.dart';
import 'package:sudoku159/services/home/level_progress_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/home/home_screen.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';
import 'package:sudoku159/view/home/saved_games_screen.dart';
import 'package:sudoku159/widgets/mascot_image.dart';
import 'package:sudoku159/widgets/profile_glass_header.dart';
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

  @override
  Future<HomeDashboardData> load(AppLocalizations l10n,
          {int continueGamesLimit = 3}) =>
      produce();

  @override
  Future<List<ContinueGameSummary>> loadContinueGames({int? limit}) async =>
      all;
}

HomeDashboardData _data({
  List<ContinueGameSummary> continues = const [],
  int challengeNumber = 7,
  bool challengeDone = false,
  bool challengeHasSession = false,
  String? lastClearDate,
  SudokuGame? challenge,
  bool noChallenge = false,
}) {
  final date = ChallengeProgressService.formatLocalDate(DateTime.now());
  return HomeDashboardData(
    continueGame: continues.isEmpty ? null : continues.first,
    continueGames: continues,
    totalContinueCount: continues.length,
    todayChallenge:
        noChallenge ? null : (challenge ?? _game('초급', challengeNumber)),
    todayChallengeHasSession: challengeHasSession,
    challengeProgress: ChallengeProgressSummary(
      streakDays: 0,
      isTodayChallengeCleared: challengeDone,
      todayChallengeLevelName: '초급',
      todayChallengeGameNumber: challengeNumber,
      challengeDate: date,
      lastClearDate: lastClearDate,
      weeklyClearCount: 0,
      weeklyGoalTarget: 3,
      perfectClearCount: 0,
    ),
    achievementSummary: const AchievementSummary(badges: []),
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
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
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

  testWidgets('one in-progress game: continue is the primary action',
      (tester) async {
    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(continues: [_summary(12)])),
    );
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Beginner · #012'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.textContaining('View all in-progress'), findsNothing);
    // 오늘의 도전은 별도 카드
    expect(find.text("Today's challenge"), findsOneWidget);
    expect(find.text('Beginner · #007'), findsOneWidget);
    expect(find.text("Start today's challenge"), findsOneWidget);
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
    expect(find.text('Beginner · #007'), findsOneWidget);
    expect(find.text("Today's challenge"), findsOneWidget); // 칩 하나만
    expect(find.text('Resume today\'s challenge'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('challenge states: not started / in progress / done',
      (tester) async {
    await pumpHome(tester, _FakeDashboard(() async => _data()));
    expect(find.text("Start today's challenge"), findsOneWidget);

    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(challengeHasSession: true)),
    );
    expect(find.text("Resume today's challenge"), findsOneWidget);
    expect(find.text('In progress', findRichText: true), findsOneWidget);

    await pumpHome(
      tester,
      _FakeDashboard(() async => _data(challengeDone: true)),
    );
    expect(find.textContaining('Done', findRichText: true), findsOneWidget);
    // 완료 시에는 강조 버튼이 아니라 보조 버튼.
    expect(
      find.widgetWithText(OutlinedButton, "Play today's puzzle again"),
      findsOneWidget,
    );
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
    expect(find.textContaining('Done', findRichText: true), findsOneWidget);

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
    expect(find.text("Couldn't load today's puzzle."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
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
    expect(inList('Beginner · #005'), findsOneWidget);

    // 삭제는 확인창을 먼저 보여주고, 취소하면 목록이 그대로다.
    await tester.tap(find.byTooltip('Delete saved progress').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete saved progress?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(inList('Beginner · #005'), findsOneWidget);

    // 항목을 고르면 그 게임이 저장된 상태로 복원된다.
    await tester.tap(inList('Beginner · #009'));
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
      expect(find.text('Continue'), findsOneWidget);
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

  group('decorative images', () {
    testWidgets('start card shows the mascot; challenge card shows the motif',
        (tester) async {
      await pumpHome(tester, _FakeDashboard(() async => _data()));
      expect(find.byType(MascotImage), findsWidgets);
      expect(find.byType(SudokuMotif), findsOneWidget);
      // 장식은 스크린 리더에서 제외된다.
      expect(
        find.descendant(
          of: find.byType(SudokuMotif),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });

    testWidgets('above 1.3x text the welcome decoration is dropped',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data()),
        size: const Size(390, 844),
        textScale: 1.6,
      );
      expect(find.byType(MascotImage), findsNothing);
      // 장식이 사라져도 제목·설명·버튼은 그대로 있다.
      expect(find.text('Start your first puzzle'), findsOneWidget);
      expect(
        find.text('Choose a level. Your progress is saved automatically.'),
        findsOneWidget,
      );
      expect(find.text('Choose a level'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow width at normal text keeps a smaller mascot on top',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data()),
        size: const Size(320, 568),
      );
      final mascot = tester.getTopLeft(find.byType(MascotImage).first).dy;
      final title = tester.getTopLeft(find.text('Start your first puzzle')).dy;
      expect(mascot, lessThan(title));
      expect(
        tester.getSize(find.byType(MascotImage).first).height,
        lessThanOrEqualTo(80),
      );
    });

    testWidgets('no motif when the challenge puzzle could not be loaded',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(() async => _data(noChallenge: true)),
      );
      expect(find.byType(SudokuMotif), findsNothing);
    });

    testWidgets('merged continue+challenge card does not repeat decoration',
        (tester) async {
      await pumpHome(
        tester,
        _FakeDashboard(
          () async => _data(continues: [_summary(7)], challengeNumber: 7),
        ),
      );
      expect(find.byType(SudokuMotif), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
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
            tester.getRect(find.byType(ProfileGlassHeader)).bottom;
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
          tester.getRect(find.byType(ProfileGlassHeader)).bottom;
      final title =
          tester.getTopLeft(find.text('New game · choose a level')).dy;
      expect(title, greaterThanOrEqualTo(headerBottom));
      expect(title, lessThan(700));
      expect(find.byType(SudokuGameScreen), findsNothing);
    });

    testWidgets('settings and profile buttons still work', (tester) async {
      await pumpHome(tester, _FakeDashboard(() async => _data()));
      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    for (final dark in [false, true]) {
      testWidgets('status bar style follows the theme (dark=$dark)',
          (tester) async {
        await pumpHome(
          tester,
          _FakeDashboard(() async => _data()),
          theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
        );
        final style = tester
            .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
              find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .value;
        expect(style.statusBarIconBrightness,
            dark ? Brightness.light : Brightness.dark);
        expect(style.statusBarBrightness,
            dark ? Brightness.dark : Brightness.light);
      });
    }
  });
}
