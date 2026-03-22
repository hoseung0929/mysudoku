import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/utils/sudoku_generator.dart';

void main() {
  AppLogger.setMuted(true);

  group('SudokuGenerator', () {
    test('counts one solution for a known valid puzzle', () {
      final puzzle = [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9],
      ];

      expect(SudokuGenerator.countSolutions(puzzle), 1);
      expect(SudokuGenerator.hasUniqueSolution(puzzle), isTrue);
    });

    test('detects multiple solutions for an ambiguous puzzle', () {
      final ambiguous = [
        [0, 0, 0, 0, 0, 0, 0, 1, 2],
        [0, 0, 0, 0, 0, 0, 0, 3, 4],
        [0, 0, 0, 0, 0, 0, 0, 5, 6],
        [0, 0, 0, 0, 0, 0, 0, 7, 8],
        [0, 0, 0, 0, 0, 0, 0, 9, 1],
        [0, 0, 0, 0, 0, 0, 0, 2, 3],
        [0, 0, 0, 0, 0, 0, 0, 4, 5],
        [0, 0, 0, 0, 0, 0, 0, 6, 7],
        [0, 0, 0, 0, 0, 0, 0, 8, 9],
      ];

      expect(SudokuGenerator.countSolutions(ambiguous), greaterThan(1));
      expect(SudokuGenerator.hasUniqueSolution(ambiguous), isFalse);
    });
  });
}
