import 'dart:async';
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
  final Function(int) onWrongCountChanged; // 오답 카운트 변경 시 호출
  final Function() onGameOver; // 게임 오버 시 호출
  final Function(int, int)? onCorrectAnswer; // 정답 입력 시 호출 (행, 열)

  // 게임 상태를 관리하는 private 변수들
  final List<List<int>> _initialBoard;
  List<List<int>> _board;
  final List<List<int>> _solution;
  List<List<bool>> _fixedNumbers = [];
  List<List<bool>> _wrongNumbers = []; // 잘못된 숫자 표시
  int _seconds = 0; // 게임 진행 시간
  bool _isPaused = false; // 일시정지 상태
  int _hintsRemaining = 3; // 남은 힌트 수
  bool _isGameComplete = false; // 게임 완료 상태
  int? _selectedRow; // 현재 선택된 행
  int? _selectedCol; // 현재 선택된 열
  int _wrongCount = 0; // 오답 카운트
  bool _isGameOver = false; // 게임 오버 상태
  Timer? _timer; // 타이머

  /// Presenter 생성자
  /// [level] 현재 선택된 레벨
  /// [onBoardChanged] 보드 상태 변경 콜백
  /// [onFixedNumbersChanged] 고정 숫자 변경 콜백
  /// [onWrongNumbersChanged] 잘못된 숫자 변경 콜백
  /// [onTimeChanged] 시간 변경 콜백
  /// [onHintsChanged] 힌트 수 변경 콜백
  /// [onPauseStateChanged] 일시정지 상태 변경 콜백
  /// [onGameCompleteChanged] 게임 완료 상태 변경 콜백
  /// [onWrongCountChanged] 오답 카운트 변경 콜백
  /// [onGameOver] 게임 오버 콜백
  /// [onCorrectAnswer] 정답 입력 콜백
  SudokuGamePresenter({
    required this.level,
    required this.onBoardChanged,
    required this.onFixedNumbersChanged,
    required this.onWrongNumbersChanged,
    required this.onTimeChanged,
    required this.onHintsChanged,
    required this.onPauseStateChanged,
    required this.onGameCompleteChanged,
    required this.onWrongCountChanged,
    required this.onGameOver,
    this.onCorrectAnswer,
    required List<List<int>> initialBoard,
    required List<List<int>> solution,
  })  : _initialBoard = initialBoard,
        _board = List.generate(
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
    _fixedNumbers.clear();
    _initializeBoard();
    _startTimer();
  }

  /// 타이머 시작
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isGameComplete && !_isGameOver) {
        _seconds++;
        onTimeChanged(_seconds);
      }
    });
  }

  /// 타이머 정지
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 게임 보드 초기화
  /// 스도쿠 생성기를 사용하여 새로운 보드를 생성하고
  /// 고정 숫자와 잘못된 숫자 표시를 초기화
  void _initializeBoard([List<List<int>>? initialBoard]) {
    _fixedNumbers.clear();
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
        _isPaused ||
        _isGameOver) {
      return;
    }

    // 이전 값 저장
    final previousValue = _board[_selectedRow!][_selectedCol!];

    // 이전에 오답이었는지 확인
    final wasWrongBefore = previousValue != 0 &&
        previousValue != _solution[_selectedRow!][_selectedCol!];

    _board[_selectedRow!][_selectedCol!] = number;
    onBoardChanged(_board);

    // 오답 체크
    _checkWrongNumbers();

    // 새로운 값이 오답인지 확인
    final isWrongNow = number != _solution[_selectedRow!][_selectedCol!];

    // 오답 카운트 업데이트
    if (isWrongNow && !wasWrongBefore) {
      // 이전에는 정답이었는데 지금 오답이 되었으면 카운트 증가
      _wrongCount++;
      onWrongCountChanged(_wrongCount);

      // 오답이 3개 이상이면 게임 오버
      if (_wrongCount >= 3) {
        _isGameOver = true;
        _isPaused = true;
        _stopTimer();
        onGameOver();
        onPauseStateChanged(_isPaused);
        return; // 게임 오버 시 더 이상 진행하지 않음
      }
    } else if (isWrongNow && wasWrongBefore) {
      // 이전에도 오답이었고 지금도 오답이면 카운트 증가 (다른 오답으로 변경)
      _wrongCount++;
      onWrongCountChanged(_wrongCount);

      // 오답이 3개 이상이면 게임 오버
      if (_wrongCount >= 3) {
        _isGameOver = true;
        _isPaused = true;
        _stopTimer();
        onGameOver();
        onPauseStateChanged(_isPaused);
        return; // 게임 오버 시 더 이상 진행하지 않음
      }
    }

    _checkGameComplete();
  }

  /// 잘못된 숫자 검사
  /// 실제 해답과 비교하여 오답을 체크하고, 스도쿠 규칙 위반도 시각적으로 표시
  void _checkWrongNumbers() {
    _wrongNumbers = List.generate(9, (_) => List.filled(9, false));

    // 실제 해답과 비교하여 오답 체크 (오답 카운트에 포함)
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_board[row][col] != 0 && _board[row][col] != _solution[row][col]) {
          _wrongNumbers[row][col] = true;
        }
      }
    }

    // 스도쿠 규칙 위반 체크 (시각적 피드백용, 오답 카운트에는 포함하지 않음)
    // 행 검사
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_board[row][col] != 0) {
          for (int c = 0; c < 9; c++) {
            if (c != col && _board[row][c] == _board[row][col]) {
              // 이미 오답으로 표시된 경우가 아니면 규칙 위반으로 표시
              if (!_wrongNumbers[row][col]) {
                _wrongNumbers[row][col] = true;
              }
              if (!_wrongNumbers[row][c]) {
                _wrongNumbers[row][c] = true;
              }
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
              // 이미 오답으로 표시된 경우가 아니면 규칙 위반으로 표시
              if (!_wrongNumbers[row][col]) {
                _wrongNumbers[row][col] = true;
              }
              if (!_wrongNumbers[r][col]) {
                _wrongNumbers[r][col] = true;
              }
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
                    // 이미 오답으로 표시된 경우가 아니면 규칙 위반으로 표시
                    if (!_wrongNumbers[row][col]) {
                      _wrongNumbers[row][col] = true;
                    }
                    if (!_wrongNumbers[r][c]) {
                      _wrongNumbers[r][c] = true;
                    }
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
    _stopTimer();
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
    if (_isGameComplete || _isGameOver) return;

    _isPaused = !_isPaused;
    onPauseStateChanged(_isPaused);
  }

  /// 시간 업데이트
  /// [seconds] 새로운 시간 값
  void updateTime(int seconds) {
    _seconds = seconds;
    onTimeChanged(_seconds);
  }

  /// 시간을 MM:SS 형식으로 변환
  String get formattedTime {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 게임 재시작 (현재 게임을 다시 시작)
  /// 모든 게임 상태를 초기화하고 현재 보드로 재시작
  void restartGame() {
    _stopTimer();
    _seconds = 0;
    _isPaused = false;
    _hintsRemaining = 3;
    _isGameComplete = false;
    _isGameOver = false;
    _wrongCount = 0;
    _selectedRow = null;
    _selectedCol = null;

    onTimeChanged(_seconds);
    onPauseStateChanged(_isPaused);
    onHintsChanged(_hintsRemaining);
    onGameCompleteChanged(_isGameComplete);
    onWrongCountChanged(_wrongCount);

    // 현재 보드로 초기화
    _initializeBoard();
    _startTimer();
  }

  /// 같은 레벨의 새로운 게임으로 재시작
  /// 모든 게임 상태를 초기화하고 새로운 보드 생성
  void restartWithNewGame() {
    _stopTimer();
    _seconds = 0;
    _isPaused = false;
    _hintsRemaining = 3;
    _isGameComplete = false;
    _isGameOver = false;
    _wrongCount = 0;
    _selectedRow = null;
    _selectedCol = null;

    onTimeChanged(_seconds);
    onPauseStateChanged(_isPaused);
    onHintsChanged(_hintsRemaining);
    onGameCompleteChanged(_isGameComplete);
    onWrongCountChanged(_wrongCount);

    _fixedNumbers.clear(); // 재시작 시 리스트 초기화
    _initializeBoard();
    _startTimer();
  }

  /// 리소스 정리
  void dispose() {
    _stopTimer();
  }

  // Getters
  int get seconds => _seconds;
  bool get isPaused => _isPaused;
  int get hintsRemaining => _hintsRemaining;
  bool get isGameComplete => _isGameComplete;
  bool get isGameOver => _isGameOver;
  int get wrongCount => _wrongCount;
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
    if (_isGameComplete || _isPaused || _isGameOver) return;

    // 이전 값 저장
    final previousValue = _board[_selectedRow!][_selectedCol!];

    // 이전에 오답이었는지 확인
    final wasWrongBefore = previousValue != 0 &&
        previousValue != _solution[_selectedRow!][_selectedCol!];

    _board[_selectedRow!][_selectedCol!] = value;
    onBoardChanged(_board);

    // 오답 체크
    _checkWrongNumbers();

    // 새로운 값이 오답인지 확인
    final isWrongNow = value != _solution[_selectedRow!][_selectedCol!];

    // 정답을 입력했는지 확인
    final isCorrectAnswer = value == _solution[_selectedRow!][_selectedCol!];

    // 정답 입력 시 이벤트 트리거
    if (isCorrectAnswer && onCorrectAnswer != null) {
      onCorrectAnswer!(_selectedRow!, _selectedCol!);
    }

    // 오답 카운트 업데이트
    if (isWrongNow && !wasWrongBefore) {
      // 이전에는 정답이었는데 지금 오답이 되었으면 카운트 증가
      _wrongCount++;
      onWrongCountChanged(_wrongCount);

      // 오답이 3개 이상이면 게임 오버
      if (_wrongCount >= 3) {
        _isGameOver = true;
        _isPaused = true;
        _stopTimer();
        onGameOver();
        onPauseStateChanged(_isPaused);
        return; // 게임 오버 시 더 이상 진행하지 않음
      }
    } else if (isWrongNow && wasWrongBefore) {
      // 이전에도 오답이었고 지금도 오답이면 카운트 증가 (다른 오답으로 변경)
      _wrongCount++;
      onWrongCountChanged(_wrongCount);

      // 오답이 3개 이상이면 게임 오버
      if (_wrongCount >= 3) {
        _isGameOver = true;
        _isPaused = true;
        _stopTimer();
        onGameOver();
        onPauseStateChanged(_isPaused);
        return; // 게임 오버 시 더 이상 진행하지 않음
      }
    }

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

  /// 잘못된 숫자인지 확인
  /// [row] 행 인덱스
  /// [col] 열 인덱스
  /// Returns: 잘못된 숫자이면 true, 아니면 false
  bool isWrongNumber(int row, int col) {
    return _wrongNumbers[row][col];
  }

  /// 힌트로 입력된 숫자인지 확인
  /// [row] 행 인덱스
  /// [col] 열 인덱스
  /// Returns: 힌트로 입력된 숫자이면 true, 아니면 false
  bool isHintNumber(int row, int col) {
    // 현재는 힌트 기능이 구현되지 않았으므로 false 반환
    // TODO: 힌트 표시 기능 구현 시 이 메서드를 업데이트
    return false;
  }

  /// 진행률 계산 (0.0 ~ 1.0)
  /// 사용자가 채워야 하는 초기 빈칸 대비 얼마나 채웠는지를 기준으로 계산합니다.
  double get progress {
    // 사용자가 채워야 할 총 칸의 수
    final int totalCellsToFill = 81 - _fixedNumbers.length;
    if (totalCellsToFill == 0) {
      // 이미 모든 칸이 채워져 있는 경우
      return 1.0;
    }

    // 현재 채워진 모든 칸의 수
    int currentFilledCells = 0;
    for (var row in _board) {
      for (var cell in row) {
        if (cell != 0) {
          currentFilledCells++;
        }
      }
    }

    // 사용자가 직접 채운 칸의 수
    final int userFilledCells = currentFilledCells - _fixedNumbers.length;

    // 진행률 반환
    return userFilledCells / totalCellsToFill.toDouble();
  }
}
