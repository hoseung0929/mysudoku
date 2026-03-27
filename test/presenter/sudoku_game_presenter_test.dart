import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/presenter/sudoku_game_presenter.dart';
import 'package:mysudoku/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  group('SudokuGamePresenter', () {
    late List<List<int>> board;
    late List<List<int>> solution;
    late SudokuGamePresenter presenter;
    int gameOverCount = 0;
    final incorrectAnswers = <String>[];

    setUp(() {
      board = [
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

      solution = [
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

      gameOverCount = 0;
      incorrectAnswers.clear();
      presenter = SudokuGamePresenter(
        level: SudokuLevel.levels.first,
        initialBoard: board,
        solution: solution,
        onBoardChanged: (_) {},
        onFixedNumbersChanged: (_) {},
        onWrongNumbersChanged: (_) {},
        onTimeChanged: (_) {},
        onHintsChanged: (_) {},
        onPauseStateChanged: (_) {},
        onGameCompleteChanged: (_) {},
        onWrongCountChanged: (_) {},
        onGameOver: () {
          gameOverCount++;
        },
        onIncorrectAnswer: (row, col) {
          incorrectAnswers.add('$row,$col');
        },
      );
    });

    test('marks hinted cells and clears hint mark after manual input', () {
      presenter.selectCell(0, 1);

      presenter.useHint();

      expect(presenter.getCellValue(0, 1), 3);
      expect(presenter.isHintNumber(0, 1), isTrue);

      presenter.selectCell(0, 1);
      presenter.setSelectedCellValue(4);

      expect(presenter.isHintNumber(0, 1), isFalse);
    });

    test('ends game after three wrong inputs', () {
      presenter.dispose();
      final boardWithThreeEditableCells =
          board.map((row) => List<int>.from(row)).toList();
      boardWithThreeEditableCells[1][0] = 0;
      presenter = SudokuGamePresenter(
        level: SudokuLevel.levels.first,
        initialBoard: boardWithThreeEditableCells,
        solution: solution,
        onBoardChanged: (_) {},
        onFixedNumbersChanged: (_) {},
        onWrongNumbersChanged: (_) {},
        onTimeChanged: (_) {},
        onHintsChanged: (_) {},
        onPauseStateChanged: (_) {},
        onGameCompleteChanged: (_) {},
        onWrongCountChanged: (_) {},
        onGameOver: () {
          gameOverCount++;
        },
      );

      presenter.selectCell(0, 1);
      presenter.setSelectedCellValue(4);

      presenter.selectCell(0, 2);
      presenter.setSelectedCellValue(5);

      presenter.selectCell(1, 0);
      presenter.setSelectedCellValue(5);

      expect(presenter.wrongCount, 3);
      expect(presenter.isGameOver, isTrue);
      expect(gameOverCount, 1);
    });

    test('does not increase wrong count repeatedly on same already-wrong cell', () {
      presenter.selectCell(0, 1);
      presenter.setSelectedCellValue(4);

      expect(presenter.wrongCount, 1);

      presenter.selectCell(0, 1);
      presenter.setSelectedCellValue(6);

      expect(presenter.wrongCount, 1);
      expect(presenter.isGameOver, isFalse);
    });

    test('emits incorrect-answer callback for wrong inputs', () {
      presenter.selectCell(0, 1);

      presenter.setSelectedCellValue(4);

      expect(incorrectAnswers, equals(['0,1']));
    });

    test('toggles memo mode and writes notes instead of board values', () {
      presenter.selectCell(0, 1);
      presenter.toggleMemoMode();
      presenter.setSelectedCellValue(3);
      presenter.setSelectedCellValue(7);

      expect(presenter.isMemoMode, isTrue);
      expect(presenter.getCellValue(0, 1), 0);
      expect(presenter.getCellNotes(0, 1), equals({3, 7}));

      presenter.setSelectedCellValue(3);

      expect(presenter.getCellNotes(0, 1), equals({7}));

      presenter.toggleMemoMode();
      presenter.setSelectedCellValue(3);

      expect(presenter.isMemoMode, isFalse);
      expect(presenter.getCellValue(0, 1), 3);
      expect(presenter.getCellNotes(0, 1), isEmpty);
    });

    test('clears selected editable cell without increasing wrong count', () {
      presenter.selectCell(0, 1);
      presenter.setSelectedCellValue(4);

      expect(presenter.getCellValue(0, 1), 4);
      expect(presenter.wrongCount, 1);

      presenter.clearSelectedCell();

      expect(presenter.getCellValue(0, 1), 0);
      expect(presenter.isWrongNumber(0, 1), isFalse);
      expect(presenter.wrongCount, 1);
    });

    test('restores timer, memo mode, notes, hints, and wrong count', () {
      final restoredBoard = board.map((row) => List<int>.from(row)).toList();
      restoredBoard[0][2] = 4;

      presenter.dispose();
      presenter = SudokuGamePresenter(
        level: SudokuLevel.levels.first,
        initialBoard: restoredBoard,
        solution: solution,
        initialElapsedSeconds: 125,
        initialHintsRemaining: 1,
        initialWrongCount: 2,
        initialMemoMode: true,
        initialNotes: List.generate(
          9,
          (row) => List.generate(
            9,
            (col) => row == 0 && col == 1 ? <int>{3, 8} : <int>{},
          ),
        ),
        initialHintCells: const {'0,2'},
        onBoardChanged: (_) {},
        onFixedNumbersChanged: (_) {},
        onWrongNumbersChanged: (_) {},
        onTimeChanged: (_) {},
        onHintsChanged: (_) {},
        onPauseStateChanged: (_) {},
        onGameCompleteChanged: (_) {},
        onWrongCountChanged: (_) {},
        onGameOver: () {
          gameOverCount++;
        },
      );

      expect(presenter.seconds, 125);
      expect(presenter.formattedTime, '02:05');
      expect(presenter.hintsRemaining, 1);
      expect(presenter.wrongCount, 2);
      expect(presenter.isMemoMode, isTrue);
      expect(presenter.getCellNotes(0, 1), equals({3, 8}));
      expect(presenter.isHintNumber(0, 2), isTrue);
    });
  });
}
