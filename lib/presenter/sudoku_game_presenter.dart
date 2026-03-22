import 'package:flutter/foundation.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/utils/sudoku_generator.dart';
import 'package:mysudoku/presenter/game_timer_controller.dart';
import 'package:mysudoku/presenter/sudoku_board_controller.dart';

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
  bool _isPaused = false; // 일시정지 상태
  int _hintsRemaining = 3; // 남은 힌트 수
  bool _isGameComplete = false; // 게임 완료 상태
  int _wrongCount = 0; // 오답 카운트
  bool _isGameOver = false; // 게임 오버 상태
  bool _isMemoMode = false; // 후보 메모 모드
  late final GameTimerController _timerController;
  late final SudokuBoardController _boardController;

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
    required List<List<int>>? solution,
  }) {
    _timerController = GameTimerController(
      onTick: onTimeChanged,
      canTick: () => !_isPaused && !_isGameComplete && !_isGameOver,
    );
    _boardController = SudokuBoardController(
      initialBoard: initialBoard,
      solution: solution,
    );
    _initializeBoard(initialBoard);
    _startTimer();
  }

  /// 타이머 시작
  void _startTimer() {
    _timerController.start();
  }

  /// 타이머 정지
  void _stopTimer() {
    _timerController.stop();
  }

  /// 게임 보드 초기화
  /// 스도쿠 생성기를 사용하여 새로운 보드를 생성하고
  /// 고정 숫자와 잘못된 숫자 표시를 초기화
  void _initializeBoard([List<List<int>>? initialBoard]) {
    if (initialBoard == null) {
      final board = SudokuGenerator.generateSudoku(level.emptyCells);
      final solution = SudokuGenerator.getSolution(board);
      _boardController.initializeGeneratedBoard(board, solution);
    } else {
      _boardController.initializeBoard(initialBoard);
    }
    onBoardChanged(_boardController.board);
    onFixedNumbersChanged(_boardController.fixedNumbers);
    onWrongNumbersChanged(_boardController.wrongNumbers);
  }

  /// 셀 선택 처리
  /// [row] 선택된 행
  /// [col] 선택된 열
  void selectCell(int row, int col) {
    // 이전에 선택된 셀이 있었다면 해당 셀의 상태 체크
    if (_boardController.selectedRow != null && _boardController.selectedCol != null) {
      _checkCellStatus(_boardController.selectedRow!, _boardController.selectedCol!);
    }

    _boardController.selectCell(row, col);

    // 새로 선택된 셀의 상태도 체크
    _checkCellStatus(row, col);

    // UI 업데이트를 위한 콜백 호출
    onBoardChanged(_boardController.board);
  }

  /// 특정 셀의 상태를 체크하고 오답 여부를 업데이트
  void _checkCellStatus(int row, int col) {
    _boardController.updateWrongStatus(row, col);
    onWrongNumbersChanged(_boardController.wrongNumbers);
  }

  /// 숫자 입력 처리
  /// [number] 입력된 숫자 (1-9)
  void onNumberSelected(int number) {
    _applySelectedCellValue(number);
  }

  /// 실제 해답과 비교하여 오답을 체크하고, 스도쿠 규칙 위반도 시각적으로 표시
  void _checkWrongNumbers() {
    // 현재 선택된 셀이 있으면 해당 셀의 상태 체크
    if (_boardController.selectedRow != null && _boardController.selectedCol != null) {
      _checkCellStatus(_boardController.selectedRow!, _boardController.selectedCol!);
    }
  }

  /// 게임 완료 검사
  void _checkGameComplete() {
    _boardController.ensureSolution();

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_boardController.board[row][col] == 0) return;
      }
    }

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_boardController.board[row][col] != _boardController.solution[row][col]) {
          if (kDebugMode) {
            AppLogger.debug(
              '게임 완료 체크 실패: 셀 [$row][$col], 입력값=${_boardController.board[row][col]}, 정답=${_boardController.solution[row][col]}',
            );
          }
          return;
        }
      }
    }

    if (kDebugMode) {
      AppLogger.debug('게임 완료: 모든 셀이 정답으로 채워졌습니다');
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
        _boardController.selectedRow == null ||
        _boardController.selectedCol == null ||
        _isPaused ||
        _isGameComplete ||
        _isGameOver ||
        _boardController.isCellFixed(
          _boardController.selectedRow!,
          _boardController.selectedCol!,
        )) {
      return;
    }

    final row = _boardController.selectedRow!;
    final col = _boardController.selectedCol!;
    if (_boardController.getCellValue(row, col) != 0) return;
    _hintsRemaining--;
    _boardController.applyHint(row, col);

    onHintsChanged(_hintsRemaining);
    onBoardChanged(_boardController.board);
    _checkWrongNumbers();
    _checkGameComplete();
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
    _timerController.update(seconds);
  }

  /// 시간을 MM:SS 형식으로 변환
  String get formattedTime {
    return _timerController.formattedTime;
  }

  /// 게임 재시작 (현재 게임을 다시 시작)
  /// 모든 게임 상태를 초기화하고 현재 보드로 재시작
  void restartGame() {
    _stopTimer();
    _isPaused = false;
    _hintsRemaining = 3;
    _isGameComplete = false;
    _isGameOver = false;
    _isMemoMode = false;
    _wrongCount = 0;
    _boardController.clearSelection();

    _timerController.reset();
    onPauseStateChanged(_isPaused);
    onHintsChanged(_hintsRemaining);
    onGameCompleteChanged(_isGameComplete);
    onWrongCountChanged(_wrongCount);

    // 초기 보드로 초기화
    final restartBoard = List.generate(
      9,
      (row) => List<int>.from(_boardController.initialBoard[row]),
    );
    _initializeBoard(restartBoard);
    _startTimer();
  }

  /// 같은 레벨의 새로운 게임으로 재시작
  /// 모든 게임 상태를 초기화하고 새로운 보드 생성
  void restartWithNewGame() {
    _stopTimer();
    _isPaused = false;
    _hintsRemaining = 3;
    _isGameComplete = false;
    _isGameOver = false;
    _isMemoMode = false;
    _wrongCount = 0;
    _boardController.clearSelection();

    _timerController.reset();
    onPauseStateChanged(_isPaused);
    onHintsChanged(_hintsRemaining);
    onGameCompleteChanged(_isGameComplete);
    onWrongCountChanged(_wrongCount);

    _initializeBoard();
    _startTimer();
  }

  /// 리소스 정리
  void dispose() {
    _timerController.dispose();
  }

  // Getters
  int get seconds => _timerController.seconds;
  bool get isPaused => _isPaused;
  int get hintsRemaining => _hintsRemaining;
  bool get isGameComplete => _isGameComplete;
  bool get isGameOver => _isGameOver;
  bool get isMemoMode => _isMemoMode;
  int get wrongCount => _wrongCount;
  int? get selectedRow => _boardController.selectedRow;
  int? get selectedCol => _boardController.selectedCol;

  int getCellValue(int row, int col) => _boardController.getCellValue(row, col);
  bool isCellFixed(int row, int col) => _boardController.isCellFixed(row, col);
  bool isCellSelected(int row, int col) =>
      _boardController.isCellSelected(row, col);

  int getCorrectValue(int row, int col) {
    return _boardController.getCorrectValue(row, col);
  }

  bool hasError(int row, int col) {
    return _boardController.hasError(row, col);
  }

  void setSelectedCellValue(int value) {
    if (_boardController.selectedRow == null || _boardController.selectedCol == null) return;
    if (_boardController.isCellFixed(
      _boardController.selectedRow!,
      _boardController.selectedCol!,
    )) {
      return;
    }
    _applySelectedCellValue(value);
  }

  bool isSameNumber(int row, int col) {
    return _boardController.isSameNumber(row, col);
  }

  bool isRelated(int row, int col) {
    return _boardController.isRelated(row, col);
  }

  /// 잘못된 숫자인지 확인
  bool isWrongNumber(int row, int col) {
    return _boardController.isWrongNumber(row, col);
  }

  /// 힌트로 입력된 숫자인지 확인
  /// [row] 행 인덱스
  /// [col] 열 인덱스
  /// Returns: 힌트로 입력된 숫자이면 true, 아니면 false
  bool isHintNumber(int row, int col) {
    return _boardController.isHintNumber(row, col);
  }

  Set<int> getCellNotes(int row, int col) {
    return _boardController.getCellNotes(row, col);
  }

  bool hasNote(int row, int col, int value) {
    return _boardController.hasNote(row, col, value);
  }

  /// 진행률 계산 (0.0 ~ 1.0)
  /// 사용자가 채워야 하는 초기 빈칸 대비 얼마나 채웠는지를 기준으로 계산합니다.
  double get progress {
    return _boardController.progress;
  }

  void toggleMemoMode() {
    if (_isGameComplete || _isGameOver) return;
    _isMemoMode = !_isMemoMode;
    onBoardChanged(_boardController.board);
  }

  void _applySelectedCellValue(int value) {
    if (_boardController.selectedRow == null ||
        _boardController.selectedCol == null ||
        _isGameComplete ||
        _isPaused ||
        _isGameOver) {
      return;
    }

    final row = _boardController.selectedRow!;
    final col = _boardController.selectedCol!;

    if (_isMemoMode) {
      _boardController.toggleNote(row, col, value);
      onBoardChanged(_boardController.board);
      return;
    }

    _boardController.setCellValue(row, col, value);
    onBoardChanged(_boardController.board);
    _checkWrongNumbers();

    final correctValue = _boardController.getCorrectValue(row, col);
    final isWrongNow = value != correctValue;
    final isCorrectAnswer = value == correctValue;

    if (isCorrectAnswer && onCorrectAnswer != null) {
      onCorrectAnswer!(row, col);
    }

    if (_shouldIncreaseWrongCount(isWrongNow: isWrongNow)) {
      _wrongCount++;
      onWrongCountChanged(_wrongCount);

      if (_wrongCount >= 3) {
        _handleGameOver();
        return;
      }
    }

    _checkGameComplete();
  }

  bool _shouldIncreaseWrongCount({
    required bool isWrongNow,
  }) {
    // 기존 동작을 유지하기 위해, 오답 입력이면 이전 상태와 관계없이 카운트를 증가시킨다.
    return isWrongNow;
  }

  void _handleGameOver() {
    _isGameOver = true;
    _isPaused = true;
    _stopTimer();
    onGameOver();
    onPauseStateChanged(_isPaused);
  }
}
