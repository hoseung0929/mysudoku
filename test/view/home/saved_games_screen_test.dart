import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/home/home_dashboard_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/home/saved_games_screen.dart';

final _levelA = SudokuLevel.levels[0];
final _levelB = SudokuLevel.levels[1];

List<List<int>> _solution() => List.generate(
      9,
      (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1),
    );

List<List<int>> _puzzle(SudokuLevel level) {
  final b = _solution();
  for (var i = 0; i < level.emptyCells; i++) {
    b[i ~/ 9][i % 9] = 0;
  }
  return b;
}

SudokuGame _game(SudokuLevel level, int number) => SudokuGame(
      board: _puzzle(level),
      solution: _solution(),
      emptyCells: level.emptyCells,
      levelName: level.name,
      gameNumber: number,
    );

ContinueGameSummary _summary(
  SudokuLevel level,
  int number, {
  int lastPlayedAtMillis = 0,
}) =>
    ContinueGameSummary(
      level: level,
      game: _game(level, number),
      progress: 0.4,
      elapsedFilledCells: 10,
      lastPlayedAtMillis: lastPlayedAtMillis,
      elapsedSeconds: 60,
      wrongCount: 0,
      isMemoMode: false,
      noteCount: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<ContinueGameSummary> games,
    required Future<List<ContinueGameSummary>> Function(
      ContinueGameSummary summary,
    ) onDelete,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<ContinueGameSummary>(
                      builder: (context) => SavedGamesScreen(
                        initialGames: games,
                        title: 'Saved',
                        description: 'desc',
                        itemTitleBuilder: (s) =>
                            '${s.level.name} #${s.game.gameNumber}',
                        itemSubtitleBuilder: (s) => 'subtitle',
                        deleteTooltip: 'Delete',
                        onDelete: onDelete,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'loading indicator shows only on the tapped row; other rows stay usable',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    final gameB = _summary(_levelA, 2, lastPlayedAtMillis: 200);
    final gate = Completer<List<ContinueGameSummary>>();
    await pumpScreen(
      tester,
      games: [gameA, gameB],
      onDelete: (_) => gate.future,
    );

    // 최신순 정렬이라 gameB(200)가 위, gameA(100)가 아래.
    final deleteButtons = find.byIcon(Icons.delete_outline);
    expect(deleteButtons, findsNWidgets(2));
    await tester.tap(deleteButtons.first);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    final remainingIconButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.delete_outline),
        matching: find.byType(IconButton),
      ),
    );
    expect(remainingIconButton.onPressed, isNull);

    // 삭제 중이 아닌 행은 여전히 열 수 있다(대화상자 pop 트리거).
    final openTiles = find.byType(InkWell);
    final untouchedTile = tester.widget<InkWell>(openTiles.last);
    expect(untouchedTile.onTap, isNotNull);

    gate.complete([gameA, gameB]);
    await tester.pumpAndSettle();
  });

  testWidgets('row is removed from the list once deletion succeeds',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    final gameB = _summary(_levelA, 2, lastPlayedAtMillis: 200);
    await pumpScreen(
      tester,
      games: [gameA, gameB],
      onDelete: (s) async => [gameB],
    );

    expect(find.textContaining('#1'), findsOneWidget);
    expect(find.textContaining('#2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pump();
    // 제거 애니메이션(170ms) 진행 중에는 아직 남아 있다.
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.textContaining('#1'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.textContaining('#1'), findsNothing);
    expect(find.textContaining('#2'), findsOneWidget);
  });

  testWidgets('cancelling the confirm dialog keeps the row and restores icon',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    final gate = Completer<List<ContinueGameSummary>>();
    await pumpScreen(
      tester,
      games: [gameA],
      onDelete: (s) => gate.future,
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete([gameA]);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.textContaining('#1'), findsOneWidget);
  });

  testWidgets('deleting the last item closes the screen after the animation',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    await pumpScreen(
      tester,
      games: [gameA],
      onDelete: (s) async => [],
    );

    expect(find.text('Saved'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('reduce motion removes the row instantly, no lingering state',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    final gameB = _summary(_levelA, 2, lastPlayedAtMillis: 200);
    await pumpScreen(
      tester,
      games: [gameA, gameB],
      onDelete: (s) async => [gameB],
      reduceMotion: true,
    );

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pump();
    // 애니메이션 프레임을 더 기다리지 않아도 즉시 반영된다.
    expect(find.textContaining('#1'), findsNothing);
    expect(find.textContaining('#2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting under an active filter removes the correct puzzle',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 300);
    final gameB = _summary(_levelB, 5, lastPlayedAtMillis: 200);
    final gameC = _summary(_levelA, 3, lastPlayedAtMillis: 100);
    await pumpScreen(
      tester,
      games: [gameA, gameB, gameC],
      onDelete: (s) async => [gameA, gameB, gameC]..removeWhere((g) =>
          g.level.name == s.level.name &&
          g.game.gameNumber == s.game.gameNumber),
    );

    // levelA만 필터링: gameA(#1), gameC(#3)
    await tester.tap(find.text(_levelA.name));
    await tester.pump();
    expect(find.textContaining('#1'), findsOneWidget);
    expect(find.textContaining('#3'), findsOneWidget);
    expect(find.textContaining('#5'), findsNothing);

    // 필터 안에서 두 번째(#3, 더 오래된 것)를 삭제해도 정확히 그 항목만 사라진다.
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('#1'), findsOneWidget);
    expect(find.textContaining('#3'), findsNothing);
  });

  testWidgets(
      'a failed delete keeps the row, clears loading, re-enables buttons, and shows a SnackBar',
      (tester) async {
    final gameA = _summary(_levelA, 1, lastPlayedAtMillis: 100);
    final gameB = _summary(_levelA, 2, lastPlayedAtMillis: 200);
    var gate = Completer<List<ContinueGameSummary>>();
    await pumpScreen(
      tester,
      games: [gameA, gameB],
      onDelete: (s) => gate.future,
    );

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.completeError(Exception('boom'));
    await tester.pumpAndSettle();

    // 대상 행이 그대로 남아 있고, 로딩이 사라지고, 삭제 버튼이 다시 활성화된다.
    expect(find.textContaining('#1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    for (final button in tester.widgetList<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.delete_outline),
        matching: find.byType(IconButton),
      ),
    )) {
      expect(button.onPressed, isNotNull);
    }
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 실패 후 같은 항목을 다시 삭제할 수 있다.
    gate = Completer<List<ContinueGameSummary>>();
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete([gameB]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('#1'), findsNothing);
  });
}
