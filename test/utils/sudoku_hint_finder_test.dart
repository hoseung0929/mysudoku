import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/utils/sudoku_hint_finder.dart';

import 'hint_finder_sample_puzzles.dart';

List<List<int>> _parse(String encoded) => encoded
    .split(';')
    .map((row) => row.split(',').map(int.parse).toList())
    .toList();

List<List<int>> _copy(List<List<int>> grid) =>
    grid.map((row) => List<int>.from(row)).toList();

void main() {
  final solution = _parse(
    '5,3,4,6,7,8,9,1,2;6,7,2,1,9,5,3,4,8;1,9,8,3,4,2,5,6,7;'
    '8,5,9,7,6,1,4,2,3;4,2,6,8,5,3,7,9,1;7,1,3,9,2,4,8,5,6;'
    '9,6,1,5,3,7,2,8,4;2,8,7,4,1,9,6,3,5;3,4,5,2,8,6,1,7,9',
  );

  test('returns null when the board is complete', () {
    expect(
      SudokuHintFinder.find(board: solution, solution: solution),
      isNull,
    );
  });

  test('naked single: the only number left for a cell', () {
    final board = _copy(solution);
    board[4][4] = 0;
    final hint = SudokuHintFinder.find(
      board: board,
      solution: solution,
      selectedRow: 4,
      selectedCol: 4,
    )!;
    expect((hint.row, hint.col, hint.value), (4, 4, 5));
    expect(hint.technique, isNot(SudokuHintTechnique.reveal));
    expect(hint.regionCells, contains(4 * 9 + 4));
    expect(hint.movedFromSelection, isFalse);
  });

  test('hidden single in a box explains which digits block the others', () {
    // 왼쪽 위 박스에서 5만 비우고, 같은 박스의 다른 칸도 비워서 유일 후보가
    // 아니라 숨은 싱글로만 찾을 수 있게 만든다.
    final board = _copy(solution);
    board[0][0] = 0; // 5
    board[1][1] = 0; // 7
    board[2][2] = 0; // 8
    board[0][1] = 0; // 3
    final hint = SudokuHintFinder.find(
      board: board,
      solution: solution,
      selectedRow: 0,
      selectedCol: 0,
    )!;
    expect((hint.row, hint.col, hint.value), (0, 0, 5));
    expect(hint.technique, SudokuHintTechnique.hiddenSingleBox);
    expect(hint.regionCells.length, 9);
    // 다른 빈칸마다 5가 있는 같은 줄의 칸이 이유로 붙는다.
    for (final blocker in hint.blockerCells) {
      expect(solution[blocker ~/ 9][blocker % 9], 5);
    }
    expect(hint.blockerCells, isNotEmpty);
  });

  test('wrong digits are treated as empty cells', () {
    final board = _copy(solution);
    board[4][4] = 0;
    board[0][0] = 9; // 정답(5)과 다른 입력
    final hint = SudokuHintFinder.find(board: board, solution: solution)!;
    expect(hint.value, solution[hint.row][hint.col]);
  });

  test('moves to an easier cell when the selection has no single', () {
    final puzzle = hintFinderSamplePuzzles.firstWhere((p) => p.level == '전문가');
    final board = _parse(puzzle.board);
    final sol = _parse(puzzle.solution);
    // 후보가 가장 많은 빈칸을 선택한 상태로 힌트를 요청한다.
    var selected = (0, 0);
    var most = -1;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final n = SudokuHintFinder.candidatesAt(board, r, c).length;
        if (board[r][c] == 0 && n > most) {
          most = n;
          selected = (r, c);
        }
      }
    }
    final hint = SudokuHintFinder.find(
      board: board,
      solution: sol,
      selectedRow: selected.$1,
      selectedCol: selected.$2,
    )!;
    expect(hint.value, sol[hint.row][hint.col]);
    if ((hint.row, hint.col) != selected) {
      expect(hint.movedFromSelection, isTrue);
    }
  });

  group('solves bundled puzzles hint by hint', () {
    for (final puzzle in hintFinderSamplePuzzles) {
      test('${puzzle.level} #${puzzle.number}', () {
        final board = _parse(puzzle.board);
        final sol = _parse(puzzle.solution);
        var reveals = 0;
        var steps = 0;
        while (true) {
          final hint = SudokuHintFinder.find(board: board, solution: sol);
          if (hint == null) break;
          expect(board[hint.row][hint.col], 0);
          expect(hint.value, sol[hint.row][hint.col]);
          if (hint.technique == SudokuHintTechnique.reveal) reveals++;
          board[hint.row][hint.col] = hint.value;
          steps++;
          expect(steps, lessThanOrEqualTo(81));
        }
        expect(board, sol);
        // 초급·중급은 싱글 기법만으로 끝까지 설명할 수 있어야 한다.
        if (puzzle.level == '초급' || puzzle.level == '중급') {
          expect(reveals, 0);
        }
      });
    }
  });
}
