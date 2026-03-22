import 'dart:math';

/// 스도쿠 게임 데이터를 생성하는 유틸리티 클래스
class SudokuGenerator {
  /// 주어진 빈 칸의 개수에 맞는 스도쿠 보드를 생성합니다.
  /// [emptyCells] 비워둘 셀의 개수
  static List<List<int>> generateSudoku(int emptyCells) {
    final random = Random();
    const maxAttempts = 8;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // 완성된 스도쿠 보드 생성
      final solutionBoard = List.generate(9, (_) => List.filled(9, 0));
      _fillDiagonal(solutionBoard, random);
      _solveSudoku(solutionBoard, random: random);

      final puzzle = List.generate(
        9,
        (row) => List<int>.from(solutionBoard[row]),
      );

      final positions = List.generate(81, (index) => index);
      positions.shuffle(random);

      int removed = 0;
      for (final pos in positions) {
        if (removed >= emptyCells) {
          break;
        }

        final row = pos ~/ 9;
        final col = pos % 9;
        final backup = puzzle[row][col];
        puzzle[row][col] = 0;

        if (hasUniqueSolution(puzzle)) {
          removed++;
        } else {
          puzzle[row][col] = backup;
        }
      }

      if (removed == emptyCells) {
        return puzzle;
      }
    }

    // 유일해 조건을 맞추지 못한 드문 경우 마지막 시도의 결과를 반환합니다.
    final fallback = List.generate(9, (_) => List.filled(9, 0));
    _fillDiagonal(fallback, random);
    _solveSudoku(fallback, random: random);
    return fallback;
  }

  /// 대각선 3x3 박스를 채웁니다.
  static void _fillDiagonal(List<List<int>> board, Random random) {
    for (int i = 0; i < 9; i += 3) {
      _fillBox(board, i, i, random);
    }
  }

  /// 3x3 박스를 채웁니다.
  static void _fillBox(List<List<int>> board, int row, int col, Random random) {
    final numbers = List.generate(9, (i) => i + 1)..shuffle(random);
    int index = 0;

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        board[row + i][col + j] = numbers[index++];
      }
    }
  }

  /// 스도쿠 보드를 해결합니다.
  static bool _solveSudoku(List<List<int>> board, {Random? random}) {
    final nextCell = _findBestEmptyCell(board, randomize: random != null);
    if (nextCell == null) {
      return true;
    }

    final row = nextCell.row;
    final col = nextCell.col;
    final candidates = List<int>.from(nextCell.candidates);
    if (random != null) {
      candidates.shuffle(random);
    }

    for (final num in candidates) {
      board[row][col] = num;

      if (_solveSudoku(board, random: random)) {
        return true;
      }

      board[row][col] = 0;
    }
    return false;
  }

  /// 주어진 위치에 숫자를 놓을 수 있는지 확인합니다.
  static bool _isValid(List<List<int>> board, int row, int col, int num) {
    // 행 검사
    for (int x = 0; x < 9; x++) {
      if (board[row][x] == num) return false;
    }

    // 열 검사
    for (int x = 0; x < 9; x++) {
      if (board[x][col] == num) return false;
    }

    // 3x3 박스 검사
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i + startRow][j + startCol] == num) return false;
      }
    }

    return true;
  }

  /// 고정된 숫자의 위치를 반환합니다.
  static List<List<bool>> getFixedNumbers(List<List<int>> board) {
    return List.generate(9, (row) {
      return List.generate(9, (col) {
        return board[row][col] != 0;
      });
    });
  }

  /// 스도쿠 보드의 해답을 반환합니다.
  static List<List<int>> getSolution(List<List<int>> board) {
    final solution = List.generate(9, (i) => List<int>.from(board[i]));
    _solveSudoku(solution);
    return solution;
  }

  static bool hasUniqueSolution(List<List<int>> board) {
    return countSolutions(board, limit: 2) == 1;
  }

  static int countSolutions(List<List<int>> board, {int limit = 2}) {
    final boardCopy = List.generate(9, (i) => List<int>.from(board[i]));
    return _countSolutions(boardCopy, limit);
  }

  static int _countSolutions(List<List<int>> board, int limit) {
    final nextCell = _findBestEmptyCell(board);
    if (nextCell == null) {
      return 1;
    }

    int solutions = 0;
    for (final num in nextCell.candidates) {
      board[nextCell.row][nextCell.col] = num;
      solutions += _countSolutions(board, limit - solutions);
      board[nextCell.row][nextCell.col] = 0;

      if (solutions >= limit) {
        return solutions;
      }
    }

    return solutions;
  }

  /// 주어진 위치에 대한 힌트를 반환합니다.
  static int? getHint(List<List<int>> board, int row, int col) {
    // 이미 숫자가 있는 경우 힌트를 제공하지 않음
    if (board[row][col] != 0) return null;

    // 현재 보드의 복사본 생성
    final boardCopy = List.generate(9, (i) => List<int>.from(board[i]));

    final candidates = _getCandidates(boardCopy, row, col);
    for (final num in candidates) {
      boardCopy[row][col] = num;
      if (_solveSudoku(boardCopy)) {
        return num;
      }
      boardCopy[row][col] = 0;
    }

    return null;
  }

  static _EmptyCellCandidate? _findBestEmptyCell(
    List<List<int>> board, {
    bool randomize = false,
  }) {
    _EmptyCellCandidate? bestCell;

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] != 0) {
          continue;
        }

        final candidates = _getCandidates(board, row, col);
        if (candidates.isEmpty) {
          return _EmptyCellCandidate(row: row, col: col, candidates: const []);
        }

        if (bestCell == null || candidates.length < bestCell.candidates.length) {
          bestCell = _EmptyCellCandidate(
            row: row,
            col: col,
            candidates: candidates,
          );
          if (bestCell.candidates.length == 1 && !randomize) {
            return bestCell;
          }
        }
      }
    }

    return bestCell;
  }

  static List<int> _getCandidates(List<List<int>> board, int row, int col) {
    final candidates = <int>[];
    for (int num = 1; num <= 9; num++) {
      if (_isValid(board, row, col, num)) {
        candidates.add(num);
      }
    }
    return candidates;
  }
}

class _EmptyCellCandidate {
  const _EmptyCellCandidate({
    required this.row,
    required this.col,
    required this.candidates,
  });

  final int row;
  final int col;
  final List<int> candidates;
}
