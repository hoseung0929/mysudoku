import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/model/sudoku_game_feature_policy.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

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
  late List<List<int>> board;
  late SudokuGamePresenter presenter;
  var boardChanges = 0;

  setUp(() {
    board = solution.map((r) => List<int>.from(r)).toList();
    board[0][1] = 0;
    board[0][2] = 0;
    board[8][8] = 0;
    boardChanges = 0;
    final level = SudokuLevel.levels.first;
    final policy = SudokuGameFeaturePolicy.forLevel(level);
    presenter = SudokuGamePresenter(
      level: level,
      puzzleBoard: board,
      initialBoard: board,
      solution: solution,
      maxHints: policy.maxHints,
      maxWrongCount: policy.maxWrongCount,
      onBoardChanged: (_) => boardChanges++,
      onFixedNumbersChanged: (_) {},
      onWrongNumbersChanged: (_) {},
      onTimeChanged: (_) {},
      onPauseStateChanged: (_) {},
      onGameCompleteChanged: (_) {},
      onWrongCountChanged: (_) {},
      onGameOver: () {},
    );
  });

  tearDown(() => presenter.dispose());

  test('erases only the selected cell user digit; counts stay unchanged', () {
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(4); // 오답 1회
    presenter.selectCell(0, 2);
    presenter.setSelectedCellValue(4);
    final wrongBefore = presenter.wrongCount;
    final hintsBefore = presenter.hintsRemaining;

    presenter.selectCell(0, 1);
    expect(presenter.canEraseSelectedCell, isTrue);
    presenter.eraseSelectedCell();

    expect(presenter.getCellValue(0, 1), 0);
    expect(presenter.getCellValue(0, 2), 4);
    expect(presenter.wrongCount, wrongBefore);
    expect(presenter.hintsRemaining, hintsBefore);
    expect(presenter.canEraseSelectedCell, isFalse);
  });

  test('erases only the selected cell notes', () {
    presenter.toggleMemoMode();
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(3);
    presenter.setSelectedCellValue(4);
    presenter.selectCell(0, 2);
    presenter.setSelectedCellValue(4);

    presenter.selectCell(0, 1);
    expect(presenter.canEraseSelectedCell, isTrue);
    presenter.eraseSelectedCell();

    expect(presenter.getCellNotes(0, 1), isEmpty);
    expect(presenter.getCellNotes(0, 2), {4});
    expect(presenter.canEraseSelectedCell, isFalse);
  });

  test('digit and notes never coexist: erased digit leaves no stale notes', () {
    presenter.toggleMemoMode();
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(3); // 메모
    presenter.toggleMemoMode();
    presenter.setSelectedCellValue(3); // 숫자 입력 → 그 칸 메모 제거
    presenter.eraseSelectedCell();
    expect(presenter.getCellValue(0, 1), 0);
    expect(presenter.getCellNotes(0, 1), isEmpty);
  });

  test('protects fixed cells and hint cells', () {
    presenter.selectCell(1, 1); // 고정 칸
    expect(presenter.canEraseSelectedCell, isFalse);
    presenter.eraseSelectedCell();
    expect(presenter.getCellValue(1, 1), 7);

    presenter.selectCell(0, 1);
    presenter.useHint();
    final hints = presenter.hintsRemaining;
    expect(presenter.getCellValue(0, 1), 3);
    expect(presenter.canEraseSelectedCell, isFalse);
    presenter.eraseSelectedCell();
    expect(presenter.getCellValue(0, 1), 3);
    expect(presenter.hintsRemaining, hints);
  });

  test('disabled with no selection or an empty cell, and does nothing', () {
    presenter.clearSelection();
    expect(presenter.canEraseSelectedCell, isFalse);
    presenter.selectCell(0, 2);
    expect(presenter.canEraseSelectedCell, isFalse);
    final changes = boardChanges;
    presenter.eraseSelectedCell();
    expect(boardChanges, changes);
  });
}
