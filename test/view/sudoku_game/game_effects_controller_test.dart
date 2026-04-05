import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/view/sudoku_game/game_effects_controller.dart';

void main() {
  group('GameEffectsController', () {
    test('detects newly completed row, column, and box', () {
      final board = [
        [5, 3, 0, 6, 7, 8, 9, 1, 2],
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
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
      ];
      final controller = GameEffectsController();

      controller.initializeCompletedLineState(board: board, solution: solution);
      board[0][2] = 4;

      final delta = controller.handleBoardChanged(
        board: board,
        solution: solution,
        setState: (fn) => fn(),
        isMounted: () => true,
      );

      expect(delta.completedRows, 1);
      expect(delta.completedCols, 1);
      expect(delta.completedBoxes, 1);
      expect(delta.hasNewCompletion, isTrue);
      expect(controller.lineCompleteActive['0,0'], isTrue);
      expect(controller.lineCompleteActive['0,2'], isTrue);
      expect(controller.lineCompleteActive['8,2'], isTrue);
      expect(controller.lineCompleteActive['1,1'], isTrue);
    });

    test('triggers temporary error effect for a wrong cell', () async {
      final controller = GameEffectsController();

      controller.triggerErrorEffect(
        row: 2,
        col: 4,
        setState: (fn) => fn(),
        isMounted: () => true,
      );

      await Future<void>.delayed(Duration.zero);
      expect(controller.errorActive['2,4'], isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 320));
      expect(controller.errorActive['2,4'], isFalse);
    });

    test('ignores stale delayed effects after board reset', () async {
      final controller = GameEffectsController();
      final board = List.generate(9, (_) => List.filled(9, 0));

      controller.resetForBoard(board: board, solution: board);
      controller.triggerErrorEffect(
        row: 2,
        col: 4,
        setState: (fn) => fn(),
        isMounted: () => true,
      );
      controller.triggerWaveEffect(
        row: 2,
        col: 4,
        setState: (fn) => fn(),
        isMounted: () => true,
      );

      controller.resetForBoard(board: board, solution: board);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 320));

      expect(controller.errorActive, isEmpty);
      expect(controller.waveActive, isEmpty);
      expect(controller.lineCompleteActive, isEmpty);
    });
  });
}
