import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_board_grid.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:sudoku159/widgets/progressive_blur_button.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class _NoopWakelockPlatform extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

/// 힌트는 사용자가 선택한 칸의 정답을 바로 채워 준다(설명 패널 없음).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  wakelockPlusPlatformInstance = _NoopWakelockPlatform();

  final level = SudokuLevel.levels.first;
  final solution = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];
  // (0,1)·(4,4)·(8,8)을 비운 보드. (4,4) 같은 칸도 기법과 무관하게 정답을 보여 준다.
  final board = solution.map((row) => List<int>.from(row)).toList()
    ..[0][1] = 0
    ..[4][4] = 0
    ..[8][8] = 0;

  Future<SudokuGamePresenter> pumpGame(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    int? restoredHints,
  }) async {
    SharedPreferences.setMockInitialValues({});
    if (restoredHints != null) {
      await GameStateService().saveSession(
        levelName: level.name,
        gameNumber: 1,
        board: board,
        notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
        elapsedSeconds: 30,
        hintsRemaining: restoredHints,
        wrongCount: 0,
        isMemoMode: false,
      );
    }
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: SudokuGameScreen(
          game: SudokuGame(
            board: board,
            solution: solution,
            emptyCells: level.emptyCells,
            levelName: level.name,
            gameNumber: 1,
          ),
          level: level,
          restoreSavedSession: restoredHints != null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    return tester
        .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
        .presenter;
  }

  Finder hintKey() => find.byKey(const ValueKey('game-action-hint'));

  bool hintEnabled(WidgetTester tester) =>
      tester.widget<ProgressiveBlurButton>(hintKey()).onPressed != null;

  Finder dimmedHint() => find.ancestor(
        of: hintKey(),
        matching:
            find.byWidgetPredicate((w) => w is Opacity && w.opacity < 1.0),
      );

  Future<void> select(
    WidgetTester tester,
    SudokuGamePresenter presenter,
    int row,
    int col,
  ) async {
    presenter.selectCell(row, col);
    await tester.pump();
  }

  testWidgets('no selection: the hint button is disabled and dimmed',
      (tester) async {
    final presenter = await pumpGame(tester);
    expect(hintEnabled(tester), isFalse);
    expect(dimmedHint(), findsWidgets);
    final hints = presenter.hintsRemaining;
    await tester.tap(hintKey(), warnIfMissed: false);
    await tester.pump();
    expect(presenter.hintsRemaining, hints);
    expect(presenter.getCellValue(0, 1), 0);
  });

  testWidgets(
      'selected empty cell: tapping hint fills the answer and spends one',
      (tester) async {
    final presenter = await pumpGame(tester);
    final hints = presenter.hintsRemaining;
    await select(tester, presenter, 0, 1);
    expect(hintEnabled(tester), isTrue);
    expect(dimmedHint(), findsNothing);

    await tester.tap(hintKey());
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 3);
    expect(presenter.isHintCell(0, 1), isTrue);
    expect(presenter.hintsRemaining, hints - 1);
    expect(find.text('${hints - 1}'), findsWidgets); // 개수 배지
    // 설명 패널은 없다.
    expect(find.text('Tell me more'), findsNothing);
    expect(find.text('Fill in answer'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('works for any cell, with no technique needed', (tester) async {
    final presenter = await pumpGame(tester);
    await select(tester, presenter, 4, 4);
    await tester.tap(hintKey());
    await tester.pump();
    expect(presenter.getCellValue(4, 4), 5);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a hint cell is locked: it cannot be erased or reused',
      (tester) async {
    final presenter = await pumpGame(tester);
    await select(tester, presenter, 0, 1);
    await tester.tap(hintKey());
    await tester.pump();
    expect(presenter.canEraseSelectedCell, isFalse);
    // 이미 정답이 들어간 칸에서는 힌트가 꺼진다(힌트를 낭비하지 않는다).
    expect(hintEnabled(tester), isFalse);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('fixed cells and already-correct cells do not enable the hint',
      (tester) async {
    final presenter = await pumpGame(tester);
    await select(tester, presenter, 0, 0); // 고정 칸
    expect(hintEnabled(tester), isFalse);
    await select(tester, presenter, 4, 4);
    presenter.setSelectedCellValue(5); // 직접 정답을 넣은 칸
    await tester.pump();
    expect(hintEnabled(tester), isFalse);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a wrong value in the selected cell is replaced by the answer',
      (tester) async {
    final presenter = await pumpGame(tester);
    await select(tester, presenter, 8, 8);
    presenter.setSelectedCellValue(2); // 오답(0.8초 뒤 자동 삭제 전)
    await tester.pump();
    expect(presenter.getCellValue(8, 8), 2);
    expect(hintEnabled(tester), isTrue);
    await tester.tap(hintKey());
    await tester.pump();
    expect(presenter.getCellValue(8, 8), 9);
    expect(presenter.isHintCell(8, 8), isTrue);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
      'the last hint keeps the same icon, drops the badge and disables it',
      (tester) async {
    final presenter = await pumpGame(tester, restoredHints: 1);
    expect(presenter.hintsRemaining, 1);
    await select(tester, presenter, 0, 1);
    await tester.tap(hintKey());
    await tester.pump();
    expect(presenter.hintsRemaining, 0);
    expect(
      find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName ==
              'assets/images/game_control_hint_flat.png'),
      findsOneWidget,
    );
    await select(tester, presenter, 4, 4);
    expect(hintEnabled(tester), isFalse);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('no overflow on a small phone', (tester) async {
    final presenter = await pumpGame(tester, size: const Size(320, 568));
    await select(tester, presenter, 0, 1);
    await tester.tap(hintKey());
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
  });
}
