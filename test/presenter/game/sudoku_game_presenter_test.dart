import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/model/sudoku_game_feature_policy.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  group('SudokuGamePresenter', () {
    late List<List<int>> board;
    late List<List<int>> solution;
    late SudokuGamePresenter presenter;
    late SudokuGameFeaturePolicy policy;
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
      policy = SudokuGameFeaturePolicy.forLevel(SudokuLevel.levels.first);
      presenter = SudokuGamePresenter(
        level: SudokuLevel.levels.first,
        puzzleBoard: board,
        initialBoard: board,
        solution: solution,
        maxHints: policy.maxHints,
        maxWrongCount: policy.maxWrongCount,
        onBoardChanged: (_) {},
        onFixedNumbersChanged: (_) {},
        onWrongNumbersChanged: (_) {},
        onTimeChanged: (_) {},
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

    test('ends game after three wrong inputs', () {
      presenter.dispose();
      final boardWithThreeEditableCells =
          board.map((row) => List<int>.from(row)).toList();
      boardWithThreeEditableCells[1][0] = 0;
      presenter = SudokuGamePresenter(
        level: SudokuLevel.levels.first,
        puzzleBoard: boardWithThreeEditableCells,
        initialBoard: boardWithThreeEditableCells,
        solution: solution,
        maxHints: policy.maxHints,
        maxWrongCount: 3,
        onBoardChanged: (_) {},
        onFixedNumbersChanged: (_) {},
        onWrongNumbersChanged: (_) {},
        onTimeChanged: (_) {},
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

    test(
        'increases wrong count when an already-wrong cell changes to another wrong value',
        () {
      presenter.selectCell(0, 1);
      presenter.setSelectedCellValue(4);

      expect(presenter.wrongCount, 1);

      presenter.selectCell(0, 1);
      presenter.setSelectedCellValue(6);

      expect(presenter.wrongCount, 2);
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

    test('restores timer, memo mode, notes, and wrong count', () {
      final restoredBoard = board.map((row) => List<int>.from(row)).toList();
      restoredBoard[0][2] = 4;

      presenter.dispose();
      presenter = SudokuGamePresenter(
        level: SudokuLevel.levels.first,
        puzzleBoard: board,
        initialBoard: restoredBoard,
        solution: solution,
        maxHints: policy.maxHints,
        maxWrongCount: policy.maxWrongCount,
        initialElapsedSeconds: 125,
        initialWrongCount: 2,
        initialMemoMode: true,
        initialNotes: List.generate(
          9,
          (row) => List.generate(
            9,
            (col) => row == 0 && col == 1 ? <int>{3, 8} : <int>{},
          ),
        ),
        onBoardChanged: (_) {},
        onFixedNumbersChanged: (_) {},
        onWrongNumbersChanged: (_) {},
        onTimeChanged: (_) {},
        onPauseStateChanged: (_) {},
        onGameCompleteChanged: (_) {},
        onWrongCountChanged: (_) {},
        onGameOver: () {
          gameOverCount++;
        },
      );

      expect(presenter.seconds, 125);
      expect(presenter.formattedTime, '00:02:05');
      expect(presenter.wrongCount, 2);
      expect(presenter.isMemoMode, isTrue);
      expect(presenter.isCellFixed(0, 2), isFalse);
      expect(presenter.getCellNotes(0, 1), equals({3, 8}));
    });

    test(
        'recomputes restored conflict markers and keeps restored cells editable',
        () {
      final restoredBoard = board.map((row) => List<int>.from(row)).toList();
      restoredBoard[0][2] = 5;

      presenter.dispose();
      presenter = SudokuGamePresenter(
        level: SudokuLevel.levels.first,
        puzzleBoard: board,
        initialBoard: restoredBoard,
        solution: solution,
        maxHints: policy.maxHints,
        maxWrongCount: policy.maxWrongCount,
        initialWrongCount: 1,
        onBoardChanged: (_) {},
        onFixedNumbersChanged: (_) {},
        onWrongNumbersChanged: (_) {},
        onTimeChanged: (_) {},
        onPauseStateChanged: (_) {},
        onGameCompleteChanged: (_) {},
        onWrongCountChanged: (_) {},
        onGameOver: () {
          gameOverCount++;
        },
      );

      expect(presenter.isCellFixed(0, 2), isFalse);
      expect(presenter.isWrongNumber(0, 2), isTrue);
    });

    test('ignores invalid restored hint cells so empty cells stay editable',
        () {
      presenter.dispose();
      presenter = SudokuGamePresenter(
        level: SudokuLevel.levels.first,
        puzzleBoard: board,
        initialBoard: board,
        solution: solution,
        maxHints: policy.maxHints,
        maxWrongCount: policy.maxWrongCount,
        initialHintCells: const {'0,1', '99,99', 'bad-data'},
        onBoardChanged: (_) {},
        onFixedNumbersChanged: (_) {},
        onWrongNumbersChanged: (_) {},
        onTimeChanged: (_) {},
        onPauseStateChanged: (_) {},
        onGameCompleteChanged: (_) {},
        onWrongCountChanged: (_) {},
        onGameOver: () {
          gameOverCount++;
        },
      );

      presenter.selectCell(0, 1);
      presenter.setSelectedCellValue(3);

      expect(presenter.isHintCell(0, 1), isFalse);
      expect(presenter.getCellValue(0, 1), 3);
    });

    test('clearCellValue removes a wrong input without changing wrong count', () {
      presenter.selectCell(0, 1);
      presenter.setSelectedCellValue(4);

      expect(presenter.wrongCount, 1);
      expect(presenter.getCellValue(0, 1), 4);

      presenter.clearCellValue(0, 1);

      expect(presenter.getCellValue(0, 1), 0);
      expect(presenter.wrongCount, 1);
    });

    test('clearCellValue respects game state locks', () {
      presenter.selectCell(0, 1);
      presenter.setSelectedCellValue(3);
      expect(presenter.getCellValue(0, 1), 3);

      presenter.togglePause();
      presenter.clearCellValue(0, 1);
      expect(presenter.getCellValue(0, 1), 3);

      presenter.togglePause();
      presenter.clearCellValue(0, 1);
      expect(presenter.getCellValue(0, 1), 0);
    });

    test('useHint fills the selected cell with the correct value', () {
      presenter.selectCell(0, 1);
      presenter.useHint();

      expect(presenter.getCellValue(0, 1), 3);
      expect(presenter.isHintCell(0, 1), isTrue);
      expect(presenter.hintsRemaining, policy.maxHints - 1);
    });

    test('useHint does nothing when no hints remain', () {
      presenter.dispose();
      final boardWith4Empties =
          board.map((row) => List<int>.from(row)).toList();
      boardWith4Empties[1][0] = 0;
      boardWith4Empties[2][0] = 0;
      presenter = SudokuGamePresenter(
        level: SudokuLevel.levels.first,
        puzzleBoard: boardWith4Empties,
        initialBoard: boardWith4Empties,
        solution: solution,
        maxHints: 3,
        maxWrongCount: policy.maxWrongCount,
        onBoardChanged: (_) {},
        onFixedNumbersChanged: (_) {},
        onWrongNumbersChanged: (_) {},
        onTimeChanged: (_) {},
        onPauseStateChanged: (_) {},
        onGameCompleteChanged: (_) {},
        onWrongCountChanged: (_) {},
        onGameOver: () {},
      );

      presenter.selectCell(0, 1);
      presenter.useHint();
      presenter.selectCell(0, 2);
      presenter.useHint();
      presenter.selectCell(1, 0);
      presenter.useHint();
      expect(presenter.hintsRemaining, 0);

      presenter.selectCell(2, 0);
      presenter.useHint();
      expect(presenter.getCellValue(2, 0), 0);
      expect(presenter.hintsRemaining, 0);
    });

    test('useHint requires an empty selected cell', () {
      presenter.selectCell(0, 1);
      presenter.setSelectedCellValue(4);
      final hintsBefore = presenter.hintsRemaining;

      presenter.useHint();
      expect(presenter.hintsRemaining, hintsBefore);
    });

    test('hint cell blocks clearCellValue as well as manual input', () {
      presenter.selectCell(0, 1);
      presenter.useHint();
      expect(presenter.hintsRemaining, policy.maxHints - 1);
      expect(presenter.isHintCell(0, 1), isTrue);

      presenter.clearCellValue(0, 1);
      expect(presenter.getCellValue(0, 1), 3);
      expect(presenter.hintsRemaining, policy.maxHints - 1);
    });

    test('hint cell blocks manual value input', () {
      presenter.selectCell(0, 1);
      presenter.useHint();
      expect(presenter.getCellValue(0, 1), 3);

      presenter.setSelectedCellValue(4);
      expect(presenter.getCellValue(0, 1), 3);
      expect(presenter.hintsRemaining, policy.maxHints - 1);
    });

    test('clears selection on pause and blocks selection changes while paused',
        () {
      presenter.selectCell(0, 1);

      expect(presenter.selectedRow, 0);
      expect(presenter.selectedCol, 1);

      presenter.togglePause();

      expect(presenter.isPaused, isTrue);
      expect(presenter.selectedRow, isNull);
      expect(presenter.selectedCol, isNull);

      presenter.selectCell(0, 2);

      expect(presenter.selectedRow, isNull);
      expect(presenter.selectedCol, isNull);

      presenter.togglePause();
      presenter.selectCell(0, 2);

      expect(presenter.isPaused, isFalse);
      expect(presenter.selectedRow, 0);
      expect(presenter.selectedCol, 2);
    });
  });
}
