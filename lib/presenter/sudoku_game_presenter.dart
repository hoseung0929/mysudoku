import '../model/sudoku_level.dart';
import '../utils/sudoku_generator.dart';

/// 스도쿠 게임의 비즈니스 로직을 처리하는 Presenter 클래스
/// MVP 패턴에서 View와 Model 사이의 중재자 역할을 수행
class SudokuGamePresenter {
  // View와의 통신을 위한 콜백 함수들
  final SudokuLevel level; // 현재 선택된 레벨
  final Function(List<List<int>>) onBoardChanged; // 보드 상태 변경 시 호출
  final Function(List<List<bool>>) onFixedNumbersChanged; // 고정 숫자 변경 시 호출
  final Function(List<List<bool>>) onWrongNumbersChanged; // 잘못된 숫자 변경 시 호출
  final Function(int) onTimeChanged; // 시간 변경 시 호출
  final Function(int) onHintsChanged; // 힌트 수 변경 시 호출
  final Function(bool) onPauseStateChanged; // 일시정지 상태 변경 시 호출
  final Function(bool) onGameCompleteChanged; // 게임 완료 상태 변경 시 호출

  // 게임 상태를 관리하는 private 변수들
  List<List<int>> _board;
  final List<List<int>> _solution;
  List<List<bool>> _fixedNumbers;
  List<List<bool>> _wrongNumbers = []; // 잘못된 숫자 표시
  int _seconds = 0; // 게임 진행 시간
  bool _isPaused = false; // 일시정지 상태
  int _hintsRemaining = 3; // 남은 힌트 수
  bool _isGameComplete = false; // 게임 완료 상태
  int? _selectedRow; // 현재 선택된 행
  int? _selectedCol; // 현재 선택된 열

  /// Presenter 생성자
  /// [level] 현재 선택된 레벨
  /// [onBoardChanged] 보드 상태 변경 콜백
  /// [onFixedNumbersChanged] 고정 숫자 변경 콜백
  /// [onWrongNumbersChanged] 잘못된 숫자 변경 콜백
  /// [onTimeChanged] 시간 변경 콜백
  /// [onHintsChanged] 힌트 수 변경 콜백
  /// [onPauseStateChanged] 일시정지 상태 변경 콜백
  /// [onGameCompleteChanged] 게임 완료 상태 변경 콜백
  SudokuGamePresenter({
    required this.level,
    required this.onBoardChanged,
    required this.onFixedNumbersChanged,
    required this.onWrongNumbersChanged,
    required this.onTimeChanged,
    required this.onHintsChanged,
    required this.onPauseStateChanged,
    required this.onGameCompleteChanged,
    required List<List<int>> initialBoard,
    required List<List<int>> solution,
  })  : _board = List.generate(
          9,
          (i) => List.generate(9, (j) => initialBoard[i][j]),
        ),
        _solution = List.generate(
          9,
          (i) => List.generate(9, (j) => solution[i][j]),
        ),
        _fixedNumbers = List.generate(
          9,
          (i) => List.generate(
            9,
            (j) => initialBoard[i][j] != 0,
          ),
        ) {
    _wrongNumbers = List.generate(9, (_) => List.filled(9, false));
  }

  /// 게임 보드 초기화
  /// 스도쿠 생성기를 사용하여 새로운 보드를 생성하고
  /// 고정 숫자와 잘못된 숫자 표시를 초기화
  void _initializeBoard([List<List<int>>? initialBoard]) {
    _board = initialBoard ?? SudokuGenerator.generateSudoku(level.emptyCells);
    _fixedNumbers = SudokuGenerator.getFixedNumbers(_board);
    _wrongNumbers = List.generate(9, (_) => List.filled(9, false));

    onBoardChanged(_board);
    onFixedNumbersChanged(_fixedNumbers);
    onWrongNumbersChanged(_wrongNumbers);
  }

  /// 셀 선택 처리
  /// [row] 선택된 행
  /// [col] 선택된 열
  void onCellSelected(int row, int col) {
    if (_fixedNumbers[row][col] || _isGameComplete || _isPaused) return;

    _selectedRow = row;
    _selectedCol = col;
  }

  /// 숫자 입력 처리
  /// [number] 입력된 숫자 (1-9)
  void onNumberSelected(int number) {
    if (_selectedRow == null ||
        _selectedCol == null ||
        _isGameComplete ||
        _isPaused) {
      return;
    }

    _board[_selectedRow!][_selectedCol!] = number;
    onBoardChanged(_board);
    _checkWrongNumbers();
    _checkGameComplete();
  }

  /// 잘못된 숫자 검사
  /// 행, 열, 3x3 박스 내에서 중복된 숫자가 있는지 확인
  void _checkWrongNumbers() {
    _wrongNumbers = List.generate(9, (_) => List.filled(9, false));

    // 행 검사
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_board[row][col] != 0) {
          for (int c = 0; c < 9; c++) {
            if (c != col && _board[row][c] == _board[row][col]) {
              _wrongNumbers[row][col] = true;
              _wrongNumbers[row][c] = true;
            }
          }
        }
      }
    }

    // 열 검사
    for (int col = 0; col < 9; col++) {
      for (int row = 0; row < 9; row++) {
        if (_board[row][col] != 0) {
          for (int r = 0; r < 9; r++) {
            if (r != row && _board[r][col] == _board[row][col]) {
              _wrongNumbers[row][col] = true;
              _wrongNumbers[r][col] = true;
            }
          }
        }
      }
    }

    // 3x3 박스 검사
    for (int boxRow = 0; boxRow < 9; boxRow += 3) {
      for (int boxCol = 0; boxCol < 9; boxCol += 3) {
        for (int row = boxRow; row < boxRow + 3; row++) {
          for (int col = boxCol; col < boxCol + 3; col++) {
            if (_board[row][col] != 0) {
              for (int r = boxRow; r < boxRow + 3; r++) {
                for (int c = boxCol; c < boxCol + 3; c++) {
                  if ((r != row || c != col) &&
                      _board[r][c] == _board[row][col]) {
                    _wrongNumbers[row][col] = true;
                    _wrongNumbers[r][c] = true;
                  }
                }
              }
            }
          }
        }
      }
    }

    onWrongNumbersChanged(_wrongNumbers);
  }

  /// 게임 완료 검사
  /// 모든 칸이 채워졌고 잘못된 숫자가 없는지 확인
  void _checkGameComplete() {
    // 모든 칸이 채워졌는지 확인
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_board[row][col] == 0) return;
      }
    }

    // 잘못된 숫자가 없는지 확인
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_wrongNumbers[row][col]) return;
      }
    }

    _isGameComplete = true;
    _isPaused = true;
    onGameCompleteChanged(_isGameComplete);
    onPauseStateChanged(_isPaused);
  }

  /// 힌트 사용
  /// 선택된 셀에 대한 힌트를 제공하고 남은 힌트 수를 감소
  void useHint() {
    if (_hintsRemaining <= 0 ||
        _selectedRow == null ||
        _selectedCol == null ||
        _isPaused) {
      return;
    }

    final hint = SudokuGenerator.getHint(_board, _selectedRow!, _selectedCol!);
    if (hint != null) {
      _hintsRemaining--;
      _board[_selectedRow!][_selectedCol!] = hint;

      onHintsChanged(_hintsRemaining);
      onBoardChanged(_board);
      _checkWrongNumbers();
      _checkGameComplete();
    }
  }

  /// 일시정지 토글
  /// 게임의 일시정지 상태를 전환
  void togglePause() {
    if (_isGameComplete) return;

    _isPaused = !_isPaused;
    onPauseStateChanged(_isPaused);
  }

  /// 시간 업데이트
  /// [seconds] 새로운 시간 값
  void updateTime(int seconds) {
    _seconds = seconds;
    onTimeChanged(_seconds);
  }

  /// 게임 재시작
  /// 모든 게임 상태를 초기화하고 새로운 보드 생성
  void restartGame() {
    _seconds = 0;
    _isPaused = false;
    _hintsRemaining = 3;
    _isGameComplete = false;
    _selectedRow = null;
    _selectedCol = null;

    onTimeChanged(_seconds);
    onPauseStateChanged(_isPaused);
    onHintsChanged(_hintsRemaining);
    onGameCompleteChanged(_isGameComplete);

    _initializeBoard();
  }

  // Getters
  int get seconds => _seconds;
  bool get isPaused => _isPaused;
  int get hintsRemaining => _hintsRemaining;
  bool get isGameComplete => _isGameComplete;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;

  int getCellValue(int row, int col) => _board[row][col];
  bool isCellFixed(int row, int col) => _fixedNumbers[row][col];
  bool isCellSelected(int row, int col) =>
      row == _selectedRow && col == _selectedCol;
  bool hasError(int row, int col) {
    if (_board[row][col] == 0) return false;
    return _board[row][col] != _solution[row][col];
  }

  void selectCell(int row, int col) {
    _selectedRow = row;
    _selectedCol = col;
  }

  void setSelectedCellValue(int value) {
    if (_selectedRow == null || _selectedCol == null) return;
    if (_fixedNumbers[_selectedRow!][_selectedCol!]) return;
    _board[_selectedRow!][_selectedCol!] = value;
    onBoardChanged(_board);
    _checkWrongNumbers();
    _checkGameComplete();
  }

  bool isSameNumber(int row, int col) {
    if (_selectedRow == null || _selectedCol == null) return false;
    final selectedValue = getCellValue(_selectedRow!, _selectedCol!);
    final currentValue = getCellValue(row, col);
    return selectedValue != 0 && selectedValue == currentValue;
  }

  bool isRelated(int row, int col) {
    if (_selectedRow == null || _selectedCol == null) return false;
    return _selectedRow! == row ||
        _selectedCol! == col ||
        (_selectedRow! ~/ 3 == row ~/ 3 && _selectedCol! ~/ 3 == col ~/ 3);
  }
}
