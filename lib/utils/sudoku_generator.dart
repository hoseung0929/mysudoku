import 'dart:math';

/// 스도쿠 게임 데이터를 생성하는 유틸리티 클래스
class SudokuGenerator {
  /// 주어진 빈 칸의 개수에 맞는 스도쿠 보드를 생성합니다.
  /// [emptyCells] 비워둘 셀의 개수
  static List<List<int>> generateSudoku(int emptyCells) {
    // 완성된 스도쿠 보드 생성
    final board = List.generate(9, (_) => List.filled(9, 0));
    _fillDiagonal(board);
    _solveSudoku(board);

    // 빈 칸 만들기
    final random = Random();
    final positions = List.generate(81, (index) => index);
    positions.shuffle(random);

    for (int i = 0; i < emptyCells; i++) {
      final pos = positions[i];
      final row = pos ~/ 9;
      final col = pos % 9;
      board[row][col] = 0;
    }

    return board;
  }

  /// 대각선 3x3 박스를 채웁니다.
  static void _fillDiagonal(List<List<int>> board) {
    for (int i = 0; i < 9; i += 3) {
      _fillBox(board, i, i);
    }
  }

  /// 3x3 박스를 채웁니다.
  static void _fillBox(List<List<int>> board, int row, int col) {
    final numbers = List.generate(9, (i) => i + 1)..shuffle();
    int index = 0;

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        board[row + i][col + j] = numbers[index++];
      }
    }
  }

  /// 스도쿠 보드를 해결합니다.
  static bool _solveSudoku(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          for (int num = 1; num <= 9; num++) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;

              if (_solveSudoku(board)) {
                return true;
              }

              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
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

  /// 주어진 위치에 대한 힌트를 반환합니다.
  static int? getHint(List<List<int>> board, int row, int col) {
    // 이미 숫자가 있는 경우 힌트를 제공하지 않음
    if (board[row][col] != 0) return null;

    // 현재 보드의 복사본 생성
    final boardCopy = List.generate(9, (i) => List<int>.from(board[i]));

    // 1부터 9까지의 숫자 중 유효한 숫자 찾기
    for (int num = 1; num <= 9; num++) {
      if (_isValid(boardCopy, row, col, num)) {
        // 해당 숫자가 유효한지 확인
        boardCopy[row][col] = num;
        if (_solveSudoku(boardCopy)) {
          return num;
        }
        boardCopy[row][col] = 0;
      }
    }

    return null;
  }
}
