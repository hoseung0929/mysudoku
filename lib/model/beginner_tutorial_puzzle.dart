/// 초보자 가이드 전용 고정 연습 퍼즐. 유일해를 갖는 보드이며 일반 퍼즐 DB
/// 번호와는 무관하다. 빈칸은 정확히 3개:
/// - (0, 0): 단계 4(숫자 입력)에서 채운다. 가로줄·세로줄·박스 모두 이 칸만
///   비어 있어 후보가 하나뿐인(naked single) 칸이다.
/// - (4, 4): 단계 5(메모)에서 후보를 적었다 지운다. 끝까지 빈칸으로 남는다.
/// - (8, 8): 단계 6(힌트)에서 힌트로 채운다.
/// 세 칸은 서로 다른 가로줄·세로줄·3x3박스에 있어 서로 간섭하지 않는다.
class BeginnerTutorialPuzzle {
  const BeginnerTutorialPuzzle._();

  static const int inputRow = 0;
  static const int inputCol = 0;
  static const int inputAnswer = 5;

  static const int memoRow = 4;
  static const int memoCol = 4;

  static const int hintRow = 8;
  static const int hintCol = 8;

  static final List<List<int>> solution = [
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

  static List<List<int>> get board {
    final b = List.generate(9, (r) => List<int>.from(solution[r]));
    b[inputRow][inputCol] = 0;
    b[memoRow][memoCol] = 0;
    b[hintRow][hintCol] = 0;
    return b;
  }
}
