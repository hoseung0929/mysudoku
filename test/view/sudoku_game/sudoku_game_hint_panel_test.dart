import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  wakelockPlusPlatformInstance = _NoopWakelockPlatform();
  EditableText.debugDeterministicCursor = true;

  final level = SudokuLevel.levels.first;
  final puzzleBoard = [
    [5, 0, 0, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];
  final solution = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    ...puzzleBoard.sublist(1),
  ];

  Future<SudokuGamePresenter> pumpGame(
    WidgetTester tester,
    Size size, {
    double textScale = 1.0,
    Locale? locale,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = SudokuGame(
      board: puzzleBoard,
      solution: solution,
      emptyCells: level.emptyCells,
      levelName: level.name,
      gameNumber: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: SudokuGameScreen(game: game, level: level),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    return tester
        .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
        .presenter;
  }

  ProgressiveBlurButton buttonWithLabel(WidgetTester tester, String label) {
    return tester.widget<ProgressiveBlurButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(ProgressiveBlurButton),
      ),
    );
  }

  const sizes = {
    'phone': Size(390, 844),
    'phone SE': Size(320, 568),
    'tablet landscape': Size(1024, 768),
  };
  const panel = ValueKey('sudoku-hint-panel');

  for (final entry in sizes.entries) {
    group(entry.key, () {
      testWidgets('hint explains in two steps, then fills the answer',
          (tester) async {
        final presenter = await pumpGame(tester, entry.value);
        final maxHints = presenter.hintsRemaining;
        // 선택 없이도 힌트를 쓸 수 있다.
        expect(buttonWithLabel(tester, 'Hint').onPressed, isNotNull);

        await tester.tap(find.text('Hint'));
        await tester.pump();
        expect(find.byKey(panel), findsOneWidget);
        expect(find.text('Hint · Where to look'), findsOneWidget);
        expect(find.text('Find where 3 goes in the highlighted box.'),
            findsOneWidget);
        expect(presenter.hintsRemaining, maxHints - 1);
        expect(presenter.getCellValue(0, 1), 0);
        // 1단계에서는 정답 칸을 선택하지 않는다.
        expect(presenter.selectedRow, isNull);

        final grid =
            tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid));
        expect(grid.hintRegionCells, hasLength(9));
        expect(grid.hintTargetCell, isNull);

        await tester.tap(find.text('Tell me more'));
        await tester.pump();
        expect(find.text('Hidden single'), findsOneWidget);
        expect(
          tester
              .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
              .hintTargetCell,
          1,
        );

        await tester.tap(find.widgetWithText(FilledButton, 'Fill in answer'));
        await tester.pump();
        expect(find.byKey(panel), findsNothing);
        expect(presenter.getCellValue(0, 1), 3);
        expect(presenter.isHintCell(0, 1), isTrue);
        expect(presenter.hintsRemaining, maxHints - 1);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.textContaining('OVERFLOWED'), findsNothing);
      });

      testWidgets('closing a hint keeps it used and restores the keypad',
          (tester) async {
        final presenter = await pumpGame(tester, entry.value);
        final maxHints = presenter.hintsRemaining;
        await tester.tap(find.text('Hint'));
        await tester.pump();
        await tester.tap(find.byTooltip('Close hint'));
        await tester.pump();
        expect(find.byKey(panel), findsNothing);
        expect(presenter.hintsRemaining, maxHints - 1);
        expect(presenter.getCellValue(0, 1), 0);
        expect(buttonWithLabel(tester, 'Hint').onPressed, isNotNull);
      });
    });
  }

  testWidgets('answer can be filled straight from step one', (tester) async {
    final presenter = await pumpGame(tester, const Size(390, 844));
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Fill in answer'));
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 3);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('pausing closes an open hint', (tester) async {
    await pumpGame(tester, const Size(390, 844));
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.byKey(panel), findsNothing);
  });

  for (final locale in const [Locale('ko'), Locale('ja'), Locale('es')]) {
    testWidgets('hint panel fits a small phone with large text ($locale)',
        (tester) async {
      await pumpGame(
        tester,
        const Size(320, 568),
        textScale: 2.0,
        locale: locale,
      );
      final hintButton = find.ancestor(
        of: find.byIcon(Icons.lightbulb_outline),
        matching: find.byType(ProgressiveBlurButton),
      );
      await tester.tap(hintButton);
      await tester.pump();
      expect(find.byKey(panel), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('OVERFLOWED'), findsNothing);
    });
  }
}
