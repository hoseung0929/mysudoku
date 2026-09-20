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

  // 셀 탭 자체는 기존 화면 테스트가 다루므로, 선택은 프레젠터로 직접 한다.
  Future<void> selectCell(
    WidgetTester tester,
    SudokuGamePresenter presenter,
    int index,
  ) async {
    presenter.selectCell(index ~/ 9, index % 9);
    await tester.pump();
  }

  ProgressiveBlurButton buttonWithLabel(WidgetTester tester, String label) {
    return tester.widget<ProgressiveBlurButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(ProgressiveBlurButton),
      ),
    );
  }

  Future<void> openRestartDialog(WidgetTester tester) async {
    await tester.tap(find.byTooltip('More options'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Restart from the beginning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  const sizes = {
    'phone': Size(390, 844),
    'tablet landscape': Size(1024, 768),
  };

  for (final entry in sizes.entries) {
    group(entry.key, () {
      testWidgets(
          'erase button is labeled, disabled without something to erase',
          (tester) async {
        final presenter = await pumpGame(tester, entry.value);
        expect(find.text('Erase'), findsOneWidget);
        expect(find.text('Memo'), findsOneWidget);
        expect(buttonWithLabel(tester, 'Erase').onPressed, isNull);

        await selectCell(tester, presenter, 1); // 빈 칸이지만 지울 내용 없음
        expect(buttonWithLabel(tester, 'Erase').onPressed, isNull);
        await selectCell(tester, presenter, 0); // 고정 칸
        expect(buttonWithLabel(tester, 'Erase').onPressed, isNull);
        expect(tester.takeException(), isNull);
      });

      testWidgets('erase clears the digit without dialog, counts, or restart',
          (tester) async {
        final presenter = await pumpGame(tester, entry.value);
        await selectCell(tester, presenter, 1);
        presenter.setSelectedCellValue(4); // 오답
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final wrong = presenter.wrongCount;
        final hints = presenter.hintsRemaining;
        expect(wrong, 1);

        await selectCell(tester, presenter, 1);
        // 오답 자동삭제 전에 지우기 (800ms 타이머 취소 확인)
        expect(buttonWithLabel(tester, 'Erase').onPressed, isNotNull);
        await tester.tap(find.text('Erase'));
        await tester.pump();

        expect(find.byType(AlertDialog), findsNothing);
        expect(presenter.getCellValue(0, 1), 0);
        expect(presenter.wrongCount, wrong);
        expect(presenter.hintsRemaining, hints);
        await tester.pump(const Duration(milliseconds: 1000));
        expect(tester.takeException(), isNull);
      });

      testWidgets('erase clears notes only of the selected cell and persists',
          (tester) async {
        final presenter = await pumpGame(tester, entry.value);
        await tester.tap(find.text('Memo'));
        await tester.pump();
        expect(find.text('Memo ON'), findsOneWidget); // 색상 외 텍스트로 구분
        await selectCell(tester, presenter, 1);
        presenter.setSelectedCellValue(3);
        presenter.setSelectedCellValue(4);
        await selectCell(tester, presenter, 2);
        presenter.setSelectedCellValue(4);
        await selectCell(tester, presenter, 1);

        await tester.tap(find.text('Erase'));
        await tester.pump();
        expect(presenter.getCellNotes(0, 1), isEmpty);
        expect(presenter.getCellNotes(0, 2), {4});

        // 디바운스(800ms) 저장 타이머를 발화시킨 뒤 실제 저장 결과를 읽는다.
        await tester.pump(const Duration(milliseconds: 900));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          final saved = await GameStateService()
              .loadSession(levelName: level.name, gameNumber: 1);
          expect(saved!.notes[0][1], isEmpty);
          expect(saved.notes[0][2], {4});
        });
        await tester.pump(const Duration(milliseconds: 1000));
      });

      testWidgets('restart: cancel keeps state, confirm resets',
          (tester) async {
        final presenter = await pumpGame(tester, entry.value);
        await selectCell(tester, presenter, 1);
        presenter.setSelectedCellValue(3);
        await tester.pump();

        await openRestartDialog(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(presenter.getCellValue(0, 1), 3);

        await openRestartDialog(tester);
        await tester.tap(find.text('Restart'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(presenter.getCellValue(0, 1), 0);
        expect(presenter.wrongCount, 0);
        expect(find.byType(AlertDialog), findsNothing);
      });
    });
  }

  testWidgets('large text and narrow width do not overflow action labels',
      (tester) async {
    await pumpGame(tester, const Size(320, 568), textScale: 2.0);
    expect(find.text('Erase'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('OVERFLOWED'), findsNothing);
  });

  testWidgets(
      'board and keypad digits keep a fixed size under large system text',
      (tester) async {
    await pumpGame(tester, const Size(390, 844), textScale: 2.3);
    double scaled(Element e) => MediaQuery.textScalerOf(e).scale(10);

    final boardDigit = find
        .descendant(
          of: find.byType(SudokuBoardGrid),
          matching: find.text('5'),
        )
        .first;
    expect(scaled(tester.element(boardDigit)), 10);

    final keypadDigit = find
        .descendant(
          of: find.byType(ProgressiveBlurButton),
          matching: find.text('5'),
        )
        .first;
    expect(scaled(tester.element(keypadDigit)), 10);
    expect(tester.takeException(), isNull);
  });
}
