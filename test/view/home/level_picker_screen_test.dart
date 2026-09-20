import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/home/level_picker_screen.dart';

final _level = SudokuLevel.levels.first;

class _FakeDb implements DatabaseHelper {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  _FakeDb(this.games, {this.cleared = const {}});
  final List<int> games;
  final Set<int> cleared;

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
        home: LevelPickerScreen(
          level: _level,
          databaseHelper: _FakeDb(games, cleared: cleared),
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
    // 새 퍼즐: 미완료·세션 없음 중 가장 앞선 번호 = 2
    final start = find.widgetWithText(FilledButton, 'Start new puzzle · 002');
    expect(start, findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Start new puzzle · 002'),
        findsNothing);
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
    expect(find.text('#004'), findsOneWidget);
    // 새 퍼즐 시작은 보조 버튼, 번호는 진행 중을 건너뛴 1.
    expect(find.widgetWithText(OutlinedButton, 'Start new puzzle · 001'),
        findsOneWidget);

    await tester.tap(find.text('View 3 in progress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // 진행 중 필터 3개만 그리드에 (카드 3개 + 대표 카드 '#004' 별도)
    expect(find.text('In progress 3'), findsOneWidget);
    expect(find.text('003'), findsOneWidget);
    expect(find.text('001'), findsNothing);
  });

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
    expect(find.widgetWithText(FilledButton, 'Start new puzzle · 001'),
        findsOneWidget);
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
    expect(find.text('#002'), findsOneWidget);
    // 완료 필터: 2는 재도전 중이라 진행 중으로, 1만 완료. 완료 기록 자체는 2개.
    expect(find.text('Done 1'), findsOneWidget);
    expect(find.text('In progress 1'), findsOneWidget);
    expect(find.textContaining('2 /'), findsOneWidget);
  });

  testWidgets('all completed is distinct from no-new-puzzles', (tester) async {
    await pumpPicker(tester, games: [1, 2, 3], cleared: {1, 2, 3});
    expect(find.textContaining('Start new puzzle'), findsNothing);
    expect(find.text("You've completed every puzzle at this level."),
        findsOneWidget);
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
    expect(find.textContaining('Start new puzzle'), findsNothing);
    await tester.tap(find.text('New 0'));
    await tester.pump();
    expect(find.text('No new puzzles to start.'), findsOneWidget);
    expect(find.text('Show in progress'), findsOneWidget);
  });

  testWidgets('empty in-progress filter offers real actions', (tester) async {
    await pumpPicker(tester, games: games, cleared: {1});
    await tester.tap(find.text('In progress 0'));
    await tester.pump();
    expect(find.text('No puzzles to continue.'), findsOneWidget);
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
    expect(find.textContaining('Start new puzzle'), findsNothing);
    expect(find.text('In progress 0'), findsNothing);
    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Start new puzzle'), findsOneWidget);
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
}
