import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/utils/app_logger.dart';

const _solution = [
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

void main() {
  AppLogger.setMuted(true);

  late SudokuGamePresenter presenter;

  SudokuGamePresenter buildPresenter({int maxWrongCount = 5}) {
    final board = _solution.map((row) => List<int>.from(row)).toList();
    // 빈칸: (0,1)=3, (0,2)=4, (1,0)=6, (1,1)=7
    board[0][1] = 0;
    board[0][2] = 0;
    board[1][0] = 0;
    board[1][1] = 0;
    return SudokuGamePresenter(
      level: SudokuLevel.levels.first,
      puzzleBoard: board,
      initialBoard: board,
      solution: _solution.map((row) => List<int>.from(row)).toList(),
      maxHints: 3,
      maxWrongCount: maxWrongCount,
      onBoardChanged: (_) {},
      onFixedNumbersChanged: (_) {},
      onWrongNumbersChanged: (_) {},
      onTimeChanged: (_) {},
      onPauseStateChanged: (_) {},
      onGameCompleteChanged: (_) {},
      onWrongCountChanged: (_) {},
      onGameOver: () {},
    );
  }

  setUp(() => presenter = buildPresenter());
  tearDown(() => presenter.dispose());

  test('nothing to undo on a fresh board', () {
    expect(presenter.canUndo, isFalse);
  });

  test('undo reverts the last number input and selects that cell', () {
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(3);
    presenter.selectCell(1, 0);
    presenter.setSelectedCellValue(6);

    presenter.undo();
    expect(presenter.getCellValue(1, 0), 0);
    expect(presenter.getCellValue(0, 1), 3);
    expect((presenter.selectedRow, presenter.selectedCol), (1, 0));

    presenter.undo();
    expect(presenter.getCellValue(0, 1), 0);
    expect((presenter.selectedRow, presenter.selectedCol), (0, 1));
    expect(presenter.canUndo, isFalse);
  });

  test('undo restores notes cleared by a number input', () {
    presenter.toggleMemoMode();
    presenter.selectCell(0, 2);
    presenter.setSelectedCellValue(3);
    presenter.setSelectedCellValue(4);
    presenter.toggleMemoMode();

    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(3);
    expect(presenter.getCellNotes(0, 2), {4});

    presenter.undo();
    expect(presenter.getCellValue(0, 1), 0);
    expect(presenter.getCellNotes(0, 2), {3, 4});

    presenter.undo();
    expect(presenter.getCellNotes(0, 2), {3});
  });

  test('undo reverts erase', () {
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(3);
    presenter.eraseSelectedCell();
    expect(presenter.getCellValue(0, 1), 0);

    presenter.undo();
    expect(presenter.getCellValue(0, 1), 3);
  });

  test('undo never refunds the mistake count', () {
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(9);
    expect(presenter.wrongCount, 1);

    presenter.undo();
    expect(presenter.getCellValue(0, 1), 0);
    expect(presenter.wrongCount, 1);
  });

  test('a wrong value that was auto-cleared leaves no empty undo step', () {
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(3);
    presenter.selectCell(1, 0);
    presenter.setSelectedCellValue(9);
    presenter.clearCellValue(1, 0);

    presenter.undo();
    expect(presenter.getCellValue(0, 1), 0);
    expect(presenter.canUndo, isFalse);
  });

  test('hint cells survive undo and hints are not refunded', () {
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(3);
    presenter.selectCell(0, 2);
    presenter.useHint();
    expect(presenter.hintsRemaining, 2);

    presenter.undo();
    expect(presenter.getCellValue(0, 2), 4);
    expect(presenter.isHintCell(0, 2), isTrue);
    expect(presenter.getCellValue(0, 1), 0);
    expect(presenter.hintsRemaining, 2);
  });

  test('undo is unavailable while paused and cleared on restart', () {
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(3);

    presenter.togglePause();
    expect(presenter.canUndo, isFalse);
    presenter.undo();
    expect(presenter.getCellValue(0, 1), 3);
    presenter.togglePause();
    expect(presenter.canUndo, isTrue);

    presenter.restartGame();
    expect(presenter.canUndo, isFalse);
  });

  test('re-entering the same value does not add an undo step', () {
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(3);
    presenter.setSelectedCellValue(3);

    presenter.undo();
    expect(presenter.getCellValue(0, 1), 0);
    expect(presenter.canUndo, isFalse);
  });
}
