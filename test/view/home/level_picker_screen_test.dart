import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/home/level_picker_screen.dart';
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

class _FakeDb implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  _FakeDb(
    this.games, {
    this.cleared = const {},
    this.gameEntryGate,
    this.failGameEntry = false,
  });
  final List<int> games;
  final Set<int> cleared;
  // 설정하면 getGameEntry가 이 Future가 끝날 때까지 대기한다(로딩 상태 테스트용).
  final Future<void>? gameEntryGate;
  // true면 getGameEntry가 null을 반환해 로딩 실패를 흉내낸다.
  final bool failGameEntry;

  @override
  Future<List<int>> getGameNumbersForLevel(String levelName) async => games;

  @override
  Future<List<int>> getClearedGameNumbersForLevel(String levelName) async =>
      cleared.toList();

  @override
  Future<List<Map<String, dynamic>>> getClearRecordsForLevel(
    String levelName,
  ) async =>
      [
        for (final n in cleared)
          {'game_number': n, 'clear_time': 125, 'level_name': levelName},
      ];

  @override
  Future<Map<String, dynamic>?> getGameEntry(
    String levelName,
    int gameNumber,
  ) async {
    if (gameEntryGate != null) await gameEntryGate;
    if (failGameEntry) return null;
    return {
      'game_number': gameNumber,
      'board': _puzzle(),
      'solution': _solution(),
    };
  }
}

/// [saved]: 게임 번호 → (플레이어가 채운 칸 수, 메모 여부, 몇 분 전)
class _FakeStates extends GameStateService {
  _FakeStates(this.saved, {this.gate});
  final Map<int, (int, bool, int)> saved;
  final Future<void>? gate;

  @override
  Future<List<SavedGameState>> getSavedGames() async {
    if (gate != null) await gate;
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      for (final e in saved.entries)
        () {
          final board = List.generate(
            9,
            (r) => List.generate(9, (c) {
              final i = r * 9 + c;
              return i < _level.emptyCells ? (i < e.value.$1 ? 1 : 0) : 1;
            }),
          );
          final notes =
              List.generate(9, (_) => List.generate(9, (_) => <int>{}));
          if (e.value.$2) notes[0][0] = {2, 3};
          return SavedGameState(
            levelName: _level.name,
            gameNumber: e.key,
            board: board,
            lastPlayedAtMillis: now - e.value.$3 * 60000,
            session: GameSessionState(
              board: board,
              notes: notes,
              elapsedSeconds: 60,
              hintsRemaining: 3,
              wrongCount: 0,
              isMemoMode: false,
              hintCells: const {},
              isGameComplete: false,
              isGameOver: false,
            ),
          );
        }(),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  wakelockPlusPlatformInstance = _NoopWakelockPlatform();

  setUp(() => SharedPreferences.setMockInitialValues({
        'beginner_tutorial_state_v1': 'completed',
      }));

  Future<void> pumpPicker(
    WidgetTester tester, {
    required List<int> games,
    Set<int> cleared = const {},
    Map<int, (int, bool, int)> saved = const {},
    Future<void>? gate,
    Size size = const Size(390, 844),
    double textScale = 1.0,
    ThemeData? theme,
    Locale? locale,
    bool reduceMotion = false,
    Future<void>? gameEntryGate,
    bool failGameEntry = false,
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
        home: LevelPickerScreen(
          level: _level,
          databaseHelper: _FakeDb(
            games,
            cleared: cleared,
            gameEntryGate: gameEntryGate,
            failGameEntry: failGameEntry,
          ),
          gameStateService: _FakeStates(saved, gate: gate),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  final games = List.generate(12, (i) => i + 1);

  testWidgets('no in-progress: start-new is the primary action, no continue',
      (tester) async {
    await pumpPicker(tester, games: games, cleared: {1});
    expect(find.text('Continue'), findsNothing);
    // 새 퍼즐: 미완료·세션 없음 중 가장 앞선 번호 = 2. 진행 카드 안에
    // "2번 퍼즐"과 주 버튼으로 들어가고, 별도 보조 버튼은 없다.
    expect(find.text('Puzzle 2'), findsOneWidget);
    expect(find.text('Start the next puzzle'), findsOneWidget);
    expect(find.text('1 completed'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Start puzzle'), findsOneWidget);
    expect(find.textContaining('Start new puzzle ·'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('several in-progress: one continue card, link selects filter',
      (tester) async {
    await pumpPicker(
      tester,
      games: games,
      saved: {3: (2, false, 30), 4: (5, false, 10), 5: (1, false, 90)},
    );
    // 대표 이어하기는 가장 최근(4) 한 개만.
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Puzzle 4'), findsOneWidget);
    // 이어할 퍼즐이 있으면 별도의 새 퍼즐 시작 버튼은 없다(그리드·필터에서 선택).
    expect(find.textContaining('Start puzzle'), findsNothing);

    await tester.tap(find.text('View 3 in progress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // 진행 중 필터 3개만 그리드에 (카드 3개 + 대표 카드 '#004' 별도)
    expect(find.text('In progress 3'), findsOneWidget);
    expect(find.text('003'), findsOneWidget);
    expect(find.text('001'), findsNothing);
  });

  testWidgets(
      'continue lives inside the progress card; tapping the card resumes',
      (tester) async {
    await pumpPicker(
      tester,
      games: games,
      cleared: {1},
      saved: {4: (5, false, 10)},
    );
    // 완료 개수 배지("1 completed")와 현재 퍼즐("Puzzle 4", 진행바)이 같은 카드 안에 있다.
    final cardFinder = find.byKey(const Key('level_progress_card'));
    expect(cardFinder, findsOneWidget);
    expect(
      find.descendant(of: cardFinder, matching: find.text('Continue')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: cardFinder,
        matching: find.text('Puzzle 4'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: cardFinder,
        matching: find.text('1 completed'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: cardFinder,
        matching: find.byKey(const Key('level_card_puzzle_progress')),
      ),
      findsOneWidget,
    );
    // 기존의 별도 이어하기 카드(주황 테두리)는 더 이상 없다.
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final saved in [
    <int, (int, bool, int)>{4: (5, false, 10), 5: (1, false, 90)},
    <int, (int, bool, int)>{},
  ]) {
    testWidgets(
        'progress card action does not overflow on small/large text '
        '(${saved.isEmpty ? 'no progress' : 'continue'})', (tester) async {
      await pumpPicker(
        tester,
        games: games,
        saved: saved,
        size: const Size(320, 568),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text(saved.isEmpty ? 'Start puzzle' : 'Continue'),
        findsOneWidget,
      );
    });
  }

  testWidgets('notes-only game is in progress and shows notes state',
      (tester) async {
    await pumpPicker(tester, games: games, saved: {6: (0, true, 5)});
    expect(find.text('Continue'), findsOneWidget);
    expect(find.textContaining('Writing notes'), findsOneWidget);
    expect(find.text('In progress 1'), findsOneWidget);
    expect(find.text('Memo'), findsOneWidget); // 그리드 카드
  });

  testWidgets('opened-only saved session stays a new puzzle', (tester) async {
    await pumpPicker(tester, games: games, saved: {2: (0, false, 1)});
    expect(find.text('Continue'), findsNothing);
    expect(find.text('In progress 0'), findsOneWidget);
    // 완료 0개 = 첫 방문 상태: 배지 없이 첫 퍼즐 안내.
    expect(find.text('Puzzle 1'), findsOneWidget);
    expect(find.text('Shall we start with the first puzzle?'), findsOneWidget);
    expect(find.byKey(const Key('level_completed_badge')), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Start puzzle'), findsOneWidget);
  });

  testWidgets('retry session on a cleared puzzle is continued, record kept',
      (tester) async {
    await pumpPicker(
      tester,
      games: games,
      cleared: {1, 2},
      saved: {2: (3, false, 2)},
    );
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Puzzle 2'), findsOneWidget);
    // 완료 필터: 2는 재도전 중이라 진행 중으로, 1만 완료. 완료 기록 자체는 2개.
    expect(find.text('Done 1'), findsOneWidget);
    expect(find.text('In progress 1'), findsOneWidget);
    expect(find.text('2 completed'), findsOneWidget);
  });

  testWidgets('all completed is distinct from no-new-puzzles', (tester) async {
    await pumpPicker(tester, games: [1, 2, 3], cleared: {1, 2, 3});
    expect(find.textContaining('Start puzzle'), findsNothing);
    // 전부 완료: 카드 안에서 축하 + 완료한 퍼즐 보기.
    expect(find.text('You completed every Beginner puzzle'), findsOneWidget);
    expect(find.text('View completed puzzles'), findsOneWidget);
    await tester.tap(find.text('New 0'));
    await tester.pump();
    expect(find.text("You've completed every puzzle at this level."),
        findsWidgets);
  });

  testWidgets('no fresh left but not all done says no new puzzles',
      (tester) async {
    await pumpPicker(
      tester,
      games: [1, 2, 3],
      cleared: {1},
      saved: {2: (2, false, 3), 3: (1, false, 8)},
    );
    expect(find.textContaining('Start puzzle'), findsNothing);
    await tester.tap(find.text('New 0'));
    await tester.pump();
    expect(find.text('No new puzzles to start.'), findsOneWidget);
    expect(find.text('Show in progress'), findsOneWidget);
  });

  testWidgets('empty in-progress filter offers real actions', (tester) async {
    await pumpPicker(tester, games: games, cleared: {1});
    await tester.tap(find.text('In progress 0'));
    await tester.pump();
    expect(
        find.text("You don't have a puzzle to continue yet."), findsOneWidget);
    expect(find.text('Start new puzzle · 002'), findsWidgets);
    await tester.tap(find.text('Show new puzzles'));
    await tester.pump();
    expect(find.text('New 11'), findsOneWidget);
  });

  testWidgets('does not confirm state while saved games are still loading',
      (tester) async {
    final gate = Completer<void>();
    await pumpPicker(tester, games: games, gate: gate.future);
    expect(find.text('Loading puzzles…'), findsOneWidget);
    expect(find.textContaining('Start puzzle'), findsNothing);
    expect(find.text('In progress 0'), findsNothing);
    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Start puzzle'), findsOneWidget);
  });

  testWidgets('filter counts match the visible grid', (tester) async {
    await pumpPicker(
      tester,
      games: games,
      cleared: {1, 2},
      saved: {5: (3, false, 4)},
    );
    for (final entry in {
      'All 12': 12,
      'New 9': 9,
      'In progress 1': 1,
      'Done 2': 2,
    }.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pump();
      final cells = find.byWidgetPredicate((w) =>
          w is Semantics && (w.properties.label ?? '').startsWith('Puzzle '));
      expect(cells, findsNWidgets(entry.value), reason: entry.key);
    }
  });

  testWidgets('narrow screen with large text does not overflow',
      (tester) async {
    await pumpPicker(
      tester,
      games: games,
      cleared: {1},
      saved: {3: (2, false, 5), 4: (0, true, 9)},
      size: const Size(320, 568),
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('OVERFLOWED'), findsNothing);
  });

  testWidgets('dark mode and tablet landscape render without errors',
      (tester) async {
    await pumpPicker(
      tester,
      games: games,
      cleared: {1},
      saved: {3: (2, false, 5)},
      theme: AppTheme.darkTheme(),
    );
    expect(tester.takeException(), isNull);
    await pumpPicker(
      tester,
      games: games,
      cleared: {1},
      saved: {3: (2, false, 5)},
      size: const Size(1024, 768),
    );
    expect(tester.takeException(), isNull);
  });

  for (final lang in ['ko', 'ja', 'es', 'zh']) {
    testWidgets('long translations do not overflow at 2x text: $lang',
        (tester) async {
      await pumpPicker(
        tester,
        games: games,
        cleared: {1},
        saved: {3: (2, false, 5), 4: (0, true, 9)},
        size: const Size(320, 568),
        textScale: 2.0,
        locale: Locale(lang),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('filter chips sit side by side instead of one per row',
      (tester) async {
    await pumpPicker(tester, games: games);
    final ys = [
      for (final label in ['All 12', 'New 12', 'In progress 0', 'Done 0'])
        tester.getTopLeft(find.text(label)).dy,
    ];
    expect(ys.toSet().length, lessThanOrEqualTo(2)); // 한 줄(길면 두 줄)
  });

  testWidgets('filter chip transition duration follows reduce motion',
      (tester) async {
    await pumpPicker(tester, games: games);
    AnimatedContainer chipContainer() => tester.widget<AnimatedContainer>(
          find.ancestor(
            of: find.text('All 12'),
            matching: find.byType(AnimatedContainer),
          ),
        );
    expect(chipContainer().duration, const Duration(milliseconds: 150));

    await pumpPicker(tester, games: games, reduceMotion: true);
    expect(chipContainer().duration, Duration.zero);
  });

  group('card loading feedback', () {
    testWidgets('loading indicator shows only on the tapped card; others dim',
        (tester) async {
      final gate = Completer<void>();
      await pumpPicker(
        tester,
        games: [1, 2, 3],
        gameEntryGate: gate.future,
      );

      await tester.tap(find.text('002'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final openingOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('002'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(openingOpacity.opacity, 1.0);
      final otherOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('003'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(otherOpacity.opacity, lessThan(1.0));
      expect(otherOpacity.opacity, greaterThanOrEqualTo(0.72));

      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'confirm dialog for a completed puzzle does not start loading until confirmed',
        (tester) async {
      final gate = Completer<void>();
      await pumpPicker(
        tester,
        games: [1, 2, 3],
        cleared: {1},
        gameEntryGate: gate.future,
      );

      await tester.tap(find.text('001').first);
      await tester.pump();
      // 확인 대화상자가 떠 있는 동안에는 로딩이 시작되지 않는다.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Replay'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('in-progress limit dialog cancel leaves no stray loading state',
        (tester) async {
      await pumpPicker(
        tester,
        games: [1, 2, 3, 4, 5, 6, 7],
        saved: {
          1: (2, false, 5),
          2: (2, false, 5),
          3: (2, false, 5),
          4: (2, false, 5),
          5: (2, false, 5),
        },
      );

      await tester.tap(find.text('006'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Later'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('007'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('rapid taps on the same fresh card do not double-launch',
        (tester) async {
      final gate = Completer<void>();
      await pumpPicker(
        tester,
        games: [1, 2, 3],
        gameEntryGate: gate.future,
      );

      await tester.tap(find.text('002'));
      await tester.tap(find.text('002'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(SudokuGameScreen), findsOneWidget);
    });

    testWidgets('a failed load clears the loading state and re-enables cards',
        (tester) async {
      await pumpPicker(
        tester,
        games: [1, 2, 3],
        failGameEntry: true,
      );

      await tester.tap(find.text('002'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('003'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('returning from the game screen leaves no stray loading state',
        (tester) async {
      await pumpPicker(tester, games: [1, 2, 3]);

      await tester.tap(find.text('002'));
      await tester.pumpAndSettle();
      expect(find.byType(SudokuGameScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('002'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('reduce motion: dimmed opacity applies with zero duration',
        (tester) async {
      final gate = Completer<void>();
      await pumpPicker(
        tester,
        games: [1, 2, 3],
        gameEntryGate: gate.future,
        reduceMotion: true,
      );

      await tester.tap(find.text('002'));
      await tester.pump();
      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('003'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.duration, Duration.zero);

      gate.complete();
      await tester.pumpAndSettle();
    });
  });
}
