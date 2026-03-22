import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/presenter/sudoku_board_controller.dart';
import 'package:mysudoku/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);

  group('SudokuBoardController', () {
    late List<List<int>> board;
    late List<List<int>> solution;
    late SudokuBoardController controller;

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

      controller = SudokuBoardController(
        initialBoard: board,
        solution: solution,
      );
    });

    test('tracks selected, related, and same-number cells', () {
      controller.selectCell(0, 0);

      expect(controller.isCellSelected(0, 0), isTrue);
      expect(controller.isRelated(0, 4), isTrue);
      expect(controller.isRelated(4, 0), isTrue);
      expect(controller.isRelated(1, 1), isTrue);
      expect(controller.isRelated(4, 4), isFalse);

      controller.setCellValue(0, 1, 5);
      expect(controller.isSameNumber(0, 1), isTrue);
      expect(controller.isSameNumber(0, 2), isFalse);
    });

    test('applies hints and clears hint flag after manual overwrite', () {
      controller.applyHint(0, 1);

      expect(controller.getCellValue(0, 1), 3);
      expect(controller.isHintNumber(0, 1), isTrue);

      controller.setCellValue(0, 1, 4);

      expect(controller.isHintNumber(0, 1), isFalse);
    });

    test('updates wrong-number status from solution', () {
      controller.setCellValue(0, 1, 4);
      controller.updateWrongStatus(0, 1);

      expect(controller.wrongNumbers[0][1], isTrue);
      expect(controller.isWrongNumber(0, 1), isTrue);
      expect(controller.hasError(0, 1), isTrue);
    });

    test('computes progress from non-fixed filled cells', () {
      expect(controller.progress, closeTo(0.0, 0.0001));

      controller.setCellValue(0, 1, 3);
      controller.setCellValue(0, 2, 4);

      expect(controller.progress, closeTo(1.0, 0.0001));
    });

    test('toggles candidate notes only for empty editable cells', () {
      controller.toggleNote(0, 1, 3);
      controller.toggleNote(0, 1, 7);

      expect(controller.hasNote(0, 1, 3), isTrue);
      expect(controller.hasNote(0, 1, 7), isTrue);
      expect(controller.getCellNotes(0, 1), equals({3, 7}));

      controller.toggleNote(0, 1, 3);

      expect(controller.hasNote(0, 1, 3), isFalse);
      expect(controller.getCellNotes(0, 1), equals({7}));

      controller.toggleNote(0, 0, 2);
      expect(controller.getCellNotes(0, 0), isEmpty);
    });

    test('clears candidate notes when a value or hint is applied', () {
      controller.toggleNote(0, 1, 3);
      controller.toggleNote(0, 1, 7);

      controller.setCellValue(0, 1, 4);
      expect(controller.getCellNotes(0, 1), isEmpty);

      controller.toggleNote(0, 2, 4);
      controller.applyHint(0, 2);
      expect(controller.getCellNotes(0, 2), isEmpty);
    });
  });
}
