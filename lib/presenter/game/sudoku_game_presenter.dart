import 'package:flutter/foundation.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/utils/sudoku_generator.dart';
import 'package:sudoku159/presenter/game/game_timer_controller.dart';
import 'package:sudoku159/presenter/game/sudoku_board_controller.dart';

/// [SudokuGamePresenter.applyAutoNotes] 결과.
enum AutoNotesResult {
  /// 모든 빈 칸의 메모를 새로 채웠다.
  applied,

  /// 모순(후보가 0개인 빈 칸)이 있어 아무것도 바꾸지 않았다.
  contradiction,

  /// 채울 빈 칸이 아예 없었다(변경 없음, 실패는 아님).
  noBlankCells,

  /// 완료·게임오버·일시정지 상태라 실행하지 않았다.
  blocked,
}

/// 스도쿠 게임의 비즈니스 로직을 처리하는 Presenter 클래스
/// MVP 패턴에서 View와 Model 사이의 중재자 역할을 수행
class SudokuGamePresenter {
  final SudokuLevel level;
  final Function(List<List<int>>) onBoardChanged;
  final Function(List<List<bool>>) onFixedNumbersChanged;
  final Function(List<List<bool>>) onWrongNumbersChanged;
  final Function(int) onTimeChanged;
  final Function(bool) onPauseStateChanged;
  final Function(bool) onGameCompleteChanged;
  final Function(int) onWrongCountChanged;
  final Function() onGameOver;
  final Function(int, int)? onCorrectAnswer;
  final Function(int, int)? onIncorrectAnswer;

  final int maxHints;
  final int maxWrongCount;

  bool _isPaused = false;
  bool _isGameComplete = false;
  int _wrongCount = 0;
  bool _isGameOver = false;
  bool _isMemoMode = false;
  late int _hintsRemaining;
  final Set<String> _hintCells = {};
  bool _autoNotesUsed = false;

  /// 되돌리기 기록(숫자 입력·메모·지우기 직전 상태). 실수 횟수와 힌트 사용은
  /// 기록하지 않으므로 되돌려도 줄어들지 않는다. 앱 세션 안에서만 유지한다.
  final List<_UndoEntry> _undoStack = [];
  static const int _maxUndoDepth = 200;
  late final GameTimerController _timerController;
  late final SudokuBoardController _boardController;

  /// Presenter 생성자
  /// [level] 현재 선택된 레벨
  /// [onBoardChanged] 보드 상태 변경 콜백
  /// [onFixedNumbersChanged] 고정 숫자 변경 콜백
  /// [onWrongNumbersChanged] 잘못된 숫자 변경 콜백
  /// [onTimeChanged] 시간 변경 콜백
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
    required this.onPauseStateChanged,
    required this.onGameCompleteChanged,
    required this.onWrongCountChanged,
    required this.onGameOver,
    this.onCorrectAnswer,
    this.onIncorrectAnswer,
    required List<List<int>> puzzleBoard,
    required List<List<int>> initialBoard,
    required List<List<int>>? solution,
    required this.maxHints,
    required this.maxWrongCount,
    int initialElapsedSeconds = 0,
    int initialWrongCount = 0,
    bool initialMemoMode = false,
    List<List<Set<int>>>? initialNotes,
    int? initialHintsRemaining,
    Set<String> initialHintCells = const {},
    bool initialAutoNotesUsed = false,
  }) {
    _timerController = GameTimerController(
      onTick: onTimeChanged,
      canTick: () => !_isPaused && !_isGameComplete && !_isGameOver,
    );
    _boardController = SudokuBoardController(
      initialBoard: initialBoard,
      solution: solution,
      puzzleBoard: puzzleBoard,
    );
    _initializeBoard(initialBoard, puzzleBoard);
    _hintsRemaining = maxHints;
    _autoNotesUsed = initialAutoNotesUsed;
    _restoreSessionState(
      elapsedSeconds: initialElapsedSeconds,
      wrongCount: initialWrongCount,
      isMemoMode: initialMemoMode,
      notes: initialNotes,
      hintsRemaining: initialHintsRemaining ?? maxHints,
      hintCells: initialHintCells,
    );
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
  void _initializeBoard(
      [List<List<int>>? initialBoard, List<List<int>>? puzzleBoard]) {
    if (initialBoard == null) {
      List<List<int>>? board;
      while (board == null) {
        board = SudokuGenerator.tryGenerateSudoku(level.emptyCells);
      }
      final solution = SudokuGenerator.getSolution(board);
      _boardController.initializeGeneratedBoard(board, solution);
    } else {
      _boardController.initializeBoard(initialBoard, puzzleBoard: puzzleBoard);
    }
    onBoardChanged(_boardController.board);
    onFixedNumbersChanged(_boardController.fixedNumbers);
    onWrongNumbersChanged(_boardController.wrongNumbers);
  }

  /// 셀 선택 처리
  /// [row] 선택된 행
  /// [col] 선택된 열
  void selectCell(int row, int col) {
    if (_isPaused || _isGameComplete || _isGameOver) {
      return;
    }

    // 이전에 선택된 셀이 있었다면 해당 셀의 상태 체크
    if (_boardController.selectedRow != null &&
        _boardController.selectedCol != null) {
      _checkCellStatus(
          _boardController.selectedRow!, _boardController.selectedCol!);
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

  /// 실제 해답과 비교하여 오답을 체크하고, 스도쿠 규칙 위반도 시각적으로 표시
  void _checkWrongNumbers() {
    // 현재 선택된 셀이 있으면 해당 셀의 상태 체크
    if (_boardController.selectedRow != null &&
        _boardController.selectedCol != null) {
      _checkCellStatus(
          _boardController.selectedRow!, _boardController.selectedCol!);
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
        if (_boardController.board[row][col] !=
            _boardController.solution[row][col]) {
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
    _clearSelectionForLockedState();
    _stopTimer();
    onGameCompleteChanged(_isGameComplete);
    onPauseStateChanged(_isPaused);
  }

  /// 일시정지 토글
  /// 게임의 일시정지 상태를 전환
  void togglePause() {
    if (_isGameComplete || _isGameOver) return;

    _isPaused = !_isPaused;
    if (_isPaused) {
      _clearSelectionForLockedState();
    }
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

  /// 시간을 분 단위 중심으로 부드럽게 표시
  String get calmFormattedTime {
    final totalSeconds = _timerController.seconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    // 1시간 미만이면 불필요한 "00:" 시간 자리를 표시하지 않는다.
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }

  /// 게임 재시작 (현재 게임을 다시 시작)
  /// 모든 게임 상태를 초기화하고 현재 보드로 재시작
  void restartGame() {
    _resetSessionState();

    // 초기 보드로 초기화
    final restartBoard = List.generate(
      9,
      (row) => List<int>.from(_boardController.initialBoard[row]),
    );
    _initializeBoard(restartBoard);
    _startTimer();
  }

  void _resetSessionState() {
    _stopTimer();
    _undoStack.clear();
    _isPaused = false;
    _isGameComplete = false;
    _isGameOver = false;
    _isMemoMode = false;
    _wrongCount = 0;
    _hintsRemaining = maxHints;
    _hintCells.clear();
    _autoNotesUsed = false;
    _boardController.clearSelection();

    _timerController.reset();
    _notifySessionReset();
  }

  void _notifySessionReset() {
    onPauseStateChanged(_isPaused);
    onGameCompleteChanged(_isGameComplete);
    onWrongCountChanged(_wrongCount);
  }

  void _restoreSessionState({
    required int elapsedSeconds,
    required int wrongCount,
    required bool isMemoMode,
    List<List<Set<int>>>? notes,
    required int hintsRemaining,
    Set<String> hintCells = const {},
  }) {
    _wrongCount = wrongCount.clamp(0, maxWrongCount);
    _isMemoMode = isMemoMode;
    _hintsRemaining = hintsRemaining.clamp(0, maxHints);
    _hintCells
      ..clear()
      ..addAll(_sanitizeHintCells(hintCells));

    if (notes != null) {
      _boardController.restoreNotes(notes);
    }
    _boardController.recomputeWrongStatus();

    _timerController.update(elapsedSeconds);
    onWrongCountChanged(_wrongCount);
    onPauseStateChanged(_isPaused);
    onBoardChanged(_boardController.board);
    onWrongNumbersChanged(_boardController.wrongNumbers);
  }

  Set<String> _sanitizeHintCells(Set<String> hintCells) {
    return hintCells.where((cellKey) {
      final parts = cellKey.split(',');
      if (parts.length != 2) {
        return false;
      }

      final row = int.tryParse(parts[0]);
      final col = int.tryParse(parts[1]);
      if (row == null ||
          col == null ||
          row < 0 ||
          row > 8 ||
          col < 0 ||
          col > 8) {
        return false;
      }

      return _boardController.getCellValue(row, col) != 0;
    }).toSet();
  }

  /// 리소스 정리
  void dispose() {
    _timerController.dispose();
  }

  // Getters
  int get seconds => _timerController.seconds;
  bool get isPaused => _isPaused;
  bool get isGameComplete => _isGameComplete;
  bool get isGameOver => _isGameOver;
  bool get isMemoMode => _isMemoMode;
  int get wrongCount => _wrongCount;
  int get hintsRemaining => _hintsRemaining;
  bool get autoNotesUsed => _autoNotesUsed;
  Set<String> get hintCells => Set<String>.unmodifiable(_hintCells);
  int? get selectedRow => _boardController.selectedRow;
  int? get selectedCol => _boardController.selectedCol;

  bool isHintCell(int row, int col) => _hintCells.contains('$row,$col');

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
    if (_boardController.selectedRow == null ||
        _boardController.selectedCol == null) {
      return;
    }
    final row = _boardController.selectedRow!;
    final col = _boardController.selectedCol!;
    if (_boardController.isCellFixed(row, col)) return;
    if (_hintCells.contains('$row,$col')) return;
    _applySelectedCellValue(value);
  }

  /// 오답 자동삭제용: 특정 셀 값을 직접 클리어
  void clearCellValue(int row, int col) {
    if (_isGameComplete || _isGameOver || _isPaused) return;
    if (_boardController.isCellFixed(row, col)) return;
    if (_hintCells.contains('$row,$col')) return;
    if (_boardController.getCellValue(row, col) == 0) return;
    _boardController.setCellValue(row, col, 0);
    _boardController.recomputeWrongStatus();
    _pruneNoOpUndoEntries();
    onBoardChanged(_boardController.board);
    onWrongNumbersChanged(_boardController.wrongNumbers);
  }

  /// 지우기 버튼 대상 여부: 선택한 칸에 사용자 숫자나 후보 메모가 있을 때만 true.
  /// 고정 칸과 힌트 칸은 기존 정책대로 수정할 수 없다.
  bool get canEraseSelectedCell {
    if (_isGameComplete || _isGameOver || _isPaused) return false;
    final row = _boardController.selectedRow;
    final col = _boardController.selectedCol;
    if (row == null || col == null) return false;
    if (_boardController.isCellFixed(row, col)) return false;
    if (_hintCells.contains('$row,$col')) return false;
    return _boardController.getCellValue(row, col) != 0 ||
        _boardController.getCellNotes(row, col).isNotEmpty;
  }

  /// 선택한 칸의 사용자 입력만 지운다. 숫자가 있으면 숫자를, 없으면 그 칸의
  /// 후보 메모를 지운다(숫자 입력 시 그 칸 메모는 이미 비워지므로 둘이 함께
  /// 존재하지 않는다). 오답·힌트 횟수와 다른 칸의 메모는 건드리지 않는다.
  void eraseSelectedCell() {
    if (!canEraseSelectedCell) return;
    final row = _boardController.selectedRow!;
    final col = _boardController.selectedCol!;
    _recordUndoSnapshot();
    if (_boardController.getCellValue(row, col) != 0) {
      _boardController.setCellValue(row, col, 0);
      _boardController.recomputeWrongStatus();
      onBoardChanged(_boardController.board);
      onWrongNumbersChanged(_boardController.wrongNumbers);
    } else {
      _boardController.clearNotes(row, col);
      onBoardChanged(_boardController.board);
    }
  }

  /// 현재 보드의 행·열·박스 규칙만으로 모든 빈 칸의 기본 후보를 한 번에
  /// 메모로 채운다. 정답(solution)은 보지 않는다. 모순으로 후보가 0개인 빈
  /// 칸이 하나라도 있으면 아무것도 바꾸지 않고 [AutoNotesResult.contradiction]을
  /// 반환한다. 변경 전체가 되돌리기 한 단계로 기록되며, 남은 힌트·실수 횟수는
  /// 건드리지 않는다.
  AutoNotesResult applyAutoNotes() {
    if (_isGameComplete || _isGameOver || _isPaused) {
      return AutoNotesResult.blocked;
    }
    final candidates = _boardController.computeBasicCandidates();
    if (candidates == null) {
      return AutoNotesResult.contradiction;
    }
    if (candidates.isEmpty) {
      return AutoNotesResult.noBlankCells;
    }
    _recordUndoSnapshot();
    _boardController.applyCandidateNotes(candidates);
    _pruneNoOpUndoEntries();
    _autoNotesUsed = true;
    onBoardChanged(_boardController.board);
    return AutoNotesResult.applied;
  }

  void useHint() {
    final row = _boardController.selectedRow;
    final col = _boardController.selectedCol;
    if (row == null || col == null) return;
    if (_boardController.isCellFixed(row, col)) return;
    if (_boardController.getCellValue(row, col) != 0) return;
    if (!consumeHint()) return;
    revealHintAt(row, col);
  }

  /// 힌트 1회를 사용한다. 설명을 여는 순간 차감하고, 같은 힌트 안에서 정답을
  /// 넣는 것([revealHintAt])은 추가로 차감하지 않는다.
  bool consumeHint() {
    if (_isGameComplete || _isPaused || _isGameOver) return false;
    if (_hintsRemaining <= 0) return false;
    _hintsRemaining--;
    onBoardChanged(_boardController.board);
    return true;
  }

  /// 힌트 대상 칸에 정답을 넣고 힌트 칸으로 고정한다(남은 힌트는 줄이지 않음).
  void revealHintAt(int row, int col) {
    if (_isGameComplete || _isPaused || _isGameOver) return;
    if (_boardController.isCellFixed(row, col)) return;
    if (_hintCells.contains('$row,$col')) return;

    final correctValue = _boardController.getCorrectValue(row, col);

    _boardController.setCellValue(row, col, correctValue, isHint: true);
    _hintCells.add('$row,$col');
    _pruneNoOpUndoEntries();

    onBoardChanged(_boardController.board);
    _boardController.recomputeWrongStatus();
    onWrongNumbersChanged(_boardController.wrongNumbers);

    if (onCorrectAnswer != null) {
      onCorrectAnswer!(row, col);
    }

    _checkGameComplete();
  }

  /// 힌트 설명을 만들 때 쓰는 현재 보드와 정답(복사본).
  List<List<int>> get boardSnapshot =>
      List.generate(9, (row) => List<int>.from(_boardController.board[row]));

  List<List<int>> get solutionSnapshot {
    _boardController.ensureSolution();
    return List.generate(
      9,
      (row) => List<int>.from(_boardController.solution[row]),
    );
  }

  /// 개발/디버그 전용: 선택된 셀에 즉시 정답을 입력한다.
  ///
  /// 오답 카운트에 영향을 주지 않으며, 해당 셀을 힌트 셀로 표시해 이후
  /// 사용자 입력 대상에서 제외한다. `kDebugMode` 에서만 사용해야 한다.
  void devFillSelectedCellWithAnswer() {
    if (_isGameComplete || _isGameOver || _isPaused) return;
    final row = _boardController.selectedRow;
    final col = _boardController.selectedCol;
    if (row == null || col == null) return;
    if (_boardController.isCellFixed(row, col)) return;

    final correctValue = _boardController.getCorrectValue(row, col);
    if (_boardController.getCellValue(row, col) == correctValue) return;

    _boardController.setCellValue(row, col, correctValue, isHint: true);
    _hintCells.add('$row,$col');

    _boardController.recomputeWrongStatus();
    onBoardChanged(_boardController.board);
    onWrongNumbersChanged(_boardController.wrongNumbers);

    if (onCorrectAnswer != null) {
      onCorrectAnswer!(row, col);
    }

    _checkGameComplete();
  }

  /// 개발/디버그 전용: 모든 빈 칸을 정답으로 채워 게임을 즉시 완료 상태로 만든다.
  ///
  /// 오답/힌트 카운트에 영향을 주지 않는다. `kDebugMode` 에서만 사용해야 한다.
  void devAutoSolve() {
    if (_isGameComplete || _isGameOver || _isPaused) return;

    var filledAny = false;
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_boardController.isCellFixed(row, col)) continue;
        final correctValue = _boardController.getCorrectValue(row, col);
        if (_boardController.getCellValue(row, col) == correctValue) continue;
        _boardController.setCellValue(row, col, correctValue, isHint: true);
        _hintCells.add('$row,$col');
        filledAny = true;
      }
    }

    if (!filledAny) return;

    _boardController.recomputeWrongStatus();
    onBoardChanged(_boardController.board);
    onWrongNumbersChanged(_boardController.wrongNumbers);

    _checkGameComplete();
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

  Set<int> getCellNotes(int row, int col) {
    return _boardController.getCellNotes(row, col);
  }

  List<List<Set<int>>> get allCellNotes {
    return _boardController.getAllCellNotes();
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
    if (_isGameComplete || _isGameOver || _isPaused) return;
    _isMemoMode = !_isMemoMode;
    onBoardChanged(_boardController.board);
  }

  void clearSelection() {
    _boardController.clearSelection();
    onBoardChanged(_boardController.board);
    onWrongNumbersChanged(_boardController.wrongNumbers);
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
    if (_boardController.isCellFixed(row, col)) return;
    if (_hintCells.contains('$row,$col')) return;
    final previousValue = _boardController.getCellValue(row, col);
    _recordUndoSnapshot();

    if (_isMemoMode) {
      _boardController.toggleNote(row, col, value);
      _pruneNoOpUndoEntries();
      onBoardChanged(_boardController.board);
      return;
    }

    _boardController.setCellValue(row, col, value);
    _pruneNoOpUndoEntries();
    onBoardChanged(_boardController.board);
    _checkWrongNumbers();

    final correctValue = _boardController.getCorrectValue(row, col);
    final isWrongNow = value != correctValue;
    final isCorrectAnswer = value == correctValue;

    if (isCorrectAnswer && onCorrectAnswer != null) {
      onCorrectAnswer!(row, col);
    }
    if (isWrongNow && onIncorrectAnswer != null) {
      onIncorrectAnswer!(row, col);
    }

    final shouldIncrease = _shouldIncreaseWrongCount(
      previousValue: previousValue,
      nextValue: value,
      isWrongNow: isWrongNow,
    );
    if (shouldIncrease) {
      _wrongCount++;
      onWrongCountChanged(_wrongCount);

      if (_wrongCount >= maxWrongCount) {
        _handleGameOver();
        return;
      }
    }

    _checkGameComplete();
  }

  bool _shouldIncreaseWrongCount({
    required int previousValue,
    required int nextValue,
    required bool isWrongNow,
  }) {
    // 같은 값을 다시 누른 경우는 카운트하지 않고,
    // 값이 실제로 바뀌면서 오답으로 입력된 경우마다 카운트합니다.
    if (previousValue == nextValue) {
      return false;
    }
    return isWrongNow;
  }

  void _handleGameOver() {
    _isGameOver = true;
    _isPaused = true;
    _clearSelectionForLockedState();
    _stopTimer();
    onGameOver();
    onPauseStateChanged(_isPaused);
  }

  /// 되돌릴 입력이 있고 게임이 진행 중일 때만 true.
  bool get canUndo =>
      !_isGameComplete && !_isGameOver && !_isPaused && _undoStack.isNotEmpty;

  (int, int)? _lastUndoCell;

  /// 가장 최근 undo()가 실제로 바꾼 대표 칸. 그 undo()가 아무것도 바꾸지
  /// 못했으면(이론상 빈 스택 소진) null. 화면이 이 칸만 짧게 강조한다.
  (int, int)? get lastUndoCell => _lastUndoCell;

  /// 마지막 숫자 입력·메모·지우기를 되돌린다. 실수 횟수·남은 힌트는 그대로이고,
  /// 힌트로 채운 칸은 되돌려도 유지된다. 되돌린 칸을 선택해 위치를 보여 준다.
  void undo() {
    if (!canUndo) return;
    _lastUndoCell = null;
    final before = _currentUndoEntry();
    _UndoEntry? target;
    while (_undoStack.isNotEmpty) {
      final candidate = _withHintCellsApplied(_undoStack.removeLast());
      if (!candidate.sameAs(before)) {
        target = candidate;
        break;
      }
    }
    if (target == null) return;

    _boardController.restoreBoardAndNotes(target.board, target.notes);
    final changedCell = before.firstDifferentCell(target);
    _lastUndoCell = changedCell;
    if (changedCell != null) {
      _boardController.selectCell(changedCell.$1, changedCell.$2);
    }
    _boardController.recomputeWrongStatus();
    onBoardChanged(_boardController.board);
    onWrongNumbersChanged(_boardController.wrongNumbers);
  }

  _UndoEntry _currentUndoEntry() {
    return _UndoEntry(
      board: List.generate(
          9, (row) => List<int>.from(_boardController.board[row])),
      notes: _boardController.getAllCellNotes(),
    );
  }

  void _recordUndoSnapshot() {
    _undoStack.add(_currentUndoEntry());
    if (_undoStack.length > _maxUndoDepth) {
      _undoStack.removeAt(0);
    }
  }

  /// 변화가 없었던 기록(같은 값 재입력, 자동으로 지워진 오답 등)은 버튼을
  /// 눌러도 아무 일이 없으므로 맨 위에서부터 걷어낸다.
  void _pruneNoOpUndoEntries() {
    final current = _currentUndoEntry();
    while (_undoStack.isNotEmpty &&
        _withHintCellsApplied(_undoStack.last).sameAs(current)) {
      _undoStack.removeLast();
    }
  }

  /// 힌트 칸은 되돌리기 대상이 아니므로, 기록 시점 이후에 받은 힌트도
  /// 현재 값 그대로 얹는다(숫자 입력과 같은 규칙으로 주변 메모도 정리).
  _UndoEntry _withHintCellsApplied(_UndoEntry entry) {
    final board = List.generate(9, (row) => List<int>.from(entry.board[row]));
    final notes = List.generate(
      9,
      (row) => List.generate(9, (col) => Set<int>.from(entry.notes[row][col])),
    );
    for (final cellKey in _hintCells) {
      final parts = cellKey.split(',');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      final value = _boardController.getCorrectValue(row, col);
      board[row][col] = value;
      notes[row][col].clear();
      for (int i = 0; i < 9; i++) {
        notes[row][i].remove(value);
        notes[i][col].remove(value);
      }
      final startRow = (row ~/ 3) * 3;
      final startCol = (col ~/ 3) * 3;
      for (int r = startRow; r < startRow + 3; r++) {
        for (int c = startCol; c < startCol + 3; c++) {
          notes[r][c].remove(value);
        }
      }
    }
    return _UndoEntry(board: board, notes: notes);
  }

  void _clearSelectionForLockedState() {
    _boardController.clearSelection();
    onBoardChanged(_boardController.board);
    onWrongNumbersChanged(_boardController.wrongNumbers);
  }
}

class _UndoEntry {
  const _UndoEntry({required this.board, required this.notes});

  final List<List<int>> board;
  final List<List<Set<int>>> notes;

  bool sameAs(_UndoEntry other) => firstDifferentCell(other) == null;

  (int, int)? firstDifferentCell(_UndoEntry other) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] != other.board[row][col]) return (row, col);
        final a = notes[row][col];
        final b = other.notes[row][col];
        if (a.length != b.length || !a.containsAll(b)) return (row, col);
      }
    }
    return null;
  }
}
