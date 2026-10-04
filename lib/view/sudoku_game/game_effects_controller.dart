class BoardCompletionDelta {
  const BoardCompletionDelta({
    required this.completedRows,
    required this.completedCols,
    required this.completedBoxes,
    this.isPuzzleComplete = false,
  });

  final int completedRows;
  final int completedCols;
  final int completedBoxes;

  /// 이번 입력으로 보드가 전부 정답으로 채워졌는지.
  /// 이 경우 결과창이 이어서 뜨므로 줄 완성 강조·안내는 생략한다.
  final bool isPuzzleComplete;

  bool get hasNewCompletion =>
      completedRows > 0 || completedCols > 0 || completedBoxes > 0;
}

class GameEffectsController {
  Set<int> _completedRows = <int>{};
  Set<int> _completedCols = <int>{};
  Set<int> _completedBoxes = <int>{};
  List<List<int>> _previousBoard = const [];
  int _effectGeneration = 0;
  int _tokenSeed = 0;

  /// 칸별 최신 토큰. 효과 종류와 무관하게 칸 하나에 하나만 유지한다 — 같은
  /// 칸에 새 효과(오답→정답, 정답→오답, 지우기 등)가 시작되면 토큰을 새로
  /// 발급해 그 칸에 걸린 이전 예약 콜백을 모두 무효화한다.
  final Map<String, int> _tokens = <String, int>{};

  /// 이번 입력에서 줄 완성/퍼즐 완료가 이미 표현되어 일반 정답 강조를
  /// 생략해야 하는지. 직후 이어지는 정답 콜백에서 한 번 소비한다.
  bool _suppressCorrectPulse = false;

  bool _reduceMotion = false;

  /// OS의 동작 줄이기 설정. 켜져 있으면 흔들림 같은 이동 효과를 생략한다.
  /// 실행 중 켜지면 이미 진행 중이던 흔들림도 즉시 원위치로 정리한다.
  bool get reduceMotion => _reduceMotion;
  set reduceMotion(bool value) {
    if (value == _reduceMotion) return;
    _reduceMotion = value;
    if (value) {
      for (final key in _errorOffset.keys.toList()) {
        _errorOffset[key] = 0;
      }
    }
  }

  final Map<String, bool> _waveActive = <String, bool>{};
  final Map<String, bool> _lineCompleteActive = <String, bool>{};

  final Map<String, bool> _errorActive = <String, bool>{};
  final Map<String, double> _errorOffset = <String, double>{};
  final Map<String, bool> _undoActive = <String, bool>{};
  final Map<String, bool> _eraseActive = <String, bool>{};
  final Map<String, bool> _hintAppliedActive = <String, bool>{};

  /// 숫자 1~9 완료 반응으로 보드에서 옅게 강조되는 칸('$row,$col' 키).
  /// 정답·오답·줄 완성 등 기존 효과와는 독립된 별도 토큰으로 관리해서,
  /// 방금 입력한 칸에 이미 걸려 있는 정답 강조(triggerCorrectEffect)를
  /// 지우지 않고 함께 표시할 수 있게 한다.
  final Map<String, bool> _digitCompleteActive = <String, bool>{};
  final Map<String, int> _digitTokens = <String, int>{};
  int _digitTokenSeed = 0;

  /// 현재 되돌리기 강조가 걸려 있는 칸(항상 최대 1개). 새 되돌리기가 다른
  /// 칸을 강조하면 이 칸의 강조는 타이머를 기다리지 않고 즉시 정리한다.
  String? _activeUndoKey;

  Map<String, bool> get waveActive => _waveActive;
  Map<String, bool> get lineCompleteActive => _lineCompleteActive;
  Map<String, bool> get errorActive => _errorActive;
  Map<String, double> get errorOffset => _errorOffset;
  Map<String, bool> get undoActive => _undoActive;
  Map<String, bool> get eraseActive => _eraseActive;
  Map<String, bool> get hintAppliedActive => _hintAppliedActive;
  Map<String, bool> get digitCompleteActive => _digitCompleteActive;

  /// 일반 정답 강조: 대기 시간. 위젯의 [effectFadeDuration]과 합쳐 총 지속
  /// 시간이 되므로(200 + 60 = 260ms), 컨트롤러 쪽만 따로 늘리지 않는다.
  static const Duration correctPulseHold = Duration(milliseconds: 200);

  /// 동작 줄이기에서 행·열·박스 완성 강조가 켜져 있는 시간(380ms). 평소에는
  /// 입력한 칸에서 바깥으로 퍼졌다가 되돌아오는 파동이라 칸마다 켜져 있는
  /// 시간이 다르다(바깥 칸일수록 짧다). 꺼진 뒤에는 [lineFadeOutDuration]만큼
  /// 서서히 사라진다.
  static const Duration lineCompleteHold = Duration(milliseconds: 380);

  /// 줄·박스 완성 강조의 등장(빠르게 올라와 이웃 칸과 겹치는) 전환 시간.
  /// 칸 사이 간격(25ms)보다 길어야 파동이 계단이 아니라 한 줄기로 보인다.
  static const Duration lineFadeInDuration = Duration(milliseconds: 130);

  /// 줄·박스 완성 강조의 퇴장 전환 시간. 꺼진 뒤 이만큼 서서히 사라진다.
  static const Duration lineFadeOutDuration = Duration(milliseconds: 320);

  /// 오답 강조(배경·흔들림) 대기 시간(140 + 60 = 200ms).
  static const Duration errorHold = Duration(milliseconds: 140);

  /// 되돌리기 결과 칸 강조 대기 시간(140 + 60 = 200ms).
  static const Duration undoHighlightHold = Duration(milliseconds: 140);

  /// 지우기 결과 칸 강조 대기 시간(100 + 60 = 160ms).
  static const Duration eraseHighlightHold = Duration(milliseconds: 100);

  /// 힌트로 채운 칸 강조 대기 시간(140 + 60 = 200ms, 180~220ms 범위).
  static const Duration hintAppliedHold = Duration(milliseconds: 140);

  /// 숫자 완료 보드 강조 대기 시간(250 + 60 = 310ms, 300~320ms 범위).
  static const Duration digitCompleteHold = Duration(milliseconds: 250);

  /// 보드 위젯이 효과 색을 등장·복원시키는 데 쓰는 공통 전환 시간.
  /// 대기 시간과 이 값의 합이 곧 사용자가 보는 전체 지속 시간이므로, 위젯도
  /// 반드시 이 상수를 그대로 사용해야 총 시간이 어긋나지 않는다.
  static const Duration effectFadeDuration = Duration(milliseconds: 60);

  /// 퍼즐 완료 연출(글로우+박스 강조) 전체 길이. 게임 화면은 이 값이 지난
  /// 뒤 햅틱 1회와 함께 결과 다이얼로그를 연다 — 보드 위젯의 글로우
  /// 애니메이션 길이와 반드시 같아야 다이얼로그가 뜨는 순간과 글로우가
  /// 사라지는 순간이 어긋나지 않는다.
  static const Duration puzzleCompleteGlowDuration =
      Duration(milliseconds: 850);

  /// 완료 햅틱을 울리는 시점. 글로우가 가장 밝은 때(전체의 35%, 약 300ms)에
  /// 맞춘다. 동작 줄이기에서는 짧은 연출 끝에서 함께 울린다.
  static const Duration puzzleCompleteHapticAt = Duration(milliseconds: 300);

  /// 동작 줄이기에서의 완료 연출 길이(짧은 단색 강조만).
  static const Duration puzzleCompleteGlowDurationReduced =
      Duration(milliseconds: 100);

  void resetForBoard({
    required List<List<int>> board,
    required List<List<int>> solution,
  }) {
    clearTransientEffects();
    initializeCompletedLineState(board: board, solution: solution);
  }

  void dispose() {
    clearTransientEffects();
  }

  /// 진행 중인 모든 임시 효과를 멈추고 대기 중인 종료 콜백을 무효화한다.
  void clearTransientEffects() {
    _effectGeneration++;
    _tokens.clear();
    _suppressCorrectPulse = false;
    _waveActive.clear();
    _lineCompleteActive.clear();
    _errorActive.clear();
    _errorOffset.clear();
    _undoActive.clear();
    _eraseActive.clear();
    _activeUndoKey = null;
    _hintAppliedActive.clear();
    _digitCompleteActive.clear();
    _digitTokens.clear();
  }

  /// [key] 칸에 새 효과를 걸 준비를 한다: 새 토큰을 발급해 그 칸에 걸린
  /// 이전 예약 콜백을 전부 무효화하고, 화면에 남아 있던 이전 강조(다른
  /// 종류 포함)도 즉시 지운다. 정답↔오답↔지우기처럼 같은 칸에서 값이
  /// 바뀌는 모든 경로가 이 메서드를 거쳐야 한다.
  int _claim(String key) {
    final token = ++_tokenSeed;
    _tokens[key] = token;
    _waveActive.remove(key);
    _lineCompleteActive.remove(key);
    _errorActive.remove(key);
    _errorOffset.remove(key);
    _undoActive.remove(key);
    _eraseActive.remove(key);
    _hintAppliedActive.remove(key);
    return token;
  }

  bool _isCurrent(String key, int token, int generation, bool mounted) =>
      mounted && generation == _effectGeneration && _tokens[key] == token;

  List<List<int>> _copyBoard(List<List<int>> board) =>
      [for (final row in board) List<int>.from(row)];

  /// 이전에 기록해 둔 보드와 비교해 실제 값이 바뀐 칸만 골라 그 칸의 이전
  /// 효과를 취소한다. 선택 이동이나 메모 토글처럼 [board]의 숫자 값 자체가
  /// 바뀌지 않는 변경은 건드리지 않는다.
  ///
  /// 값이 바뀐 칸(방금 입력한 칸)을 돌려준다. 줄·박스 완성 파동의 출발점으로
  /// 쓰며, 바뀐 칸이 없으면 null이다.
  ({int row, int col})? _cancelStaleEffectsForChangedCells(
    List<List<int>> board,
  ) {
    ({int row, int col})? changed;
    if (_previousBoard.length == 9) {
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          if (_previousBoard[row][col] != board[row][col]) {
            _claim('$row,$col');
            changed ??= (row: row, col: col);
          }
        }
      }
    }
    _previousBoard = _copyBoard(board);
    return changed;
  }

  void initializeCompletedLineState({
    required List<List<int>> board,
    required List<List<int>> solution,
  }) {
    _completedRows = _getCompletedCorrectRows(board: board, solution: solution);
    _completedCols = _getCompletedCorrectCols(board: board, solution: solution);
    _completedBoxes =
        _getCompletedCorrectBoxes(board: board, solution: solution);
    _previousBoard = _copyBoard(board);
  }

  BoardCompletionDelta handleBoardChanged({
    required List<List<int>> board,
    required List<List<int>> solution,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
    final origin = _cancelStaleEffectsForChangedCells(board);

    final currentCompletedRows =
        _getCompletedCorrectRows(board: board, solution: solution);
    final currentCompletedCols =
        _getCompletedCorrectCols(board: board, solution: solution);
    final currentCompletedBoxes =
        _getCompletedCorrectBoxes(board: board, solution: solution);

    final newlyCompletedRows = currentCompletedRows.difference(_completedRows);
    final newlyCompletedCols = currentCompletedCols.difference(_completedCols);
    final newlyCompletedBoxes =
        currentCompletedBoxes.difference(_completedBoxes);

    _completedRows = currentCompletedRows;
    _completedCols = currentCompletedCols;
    _completedBoxes = currentCompletedBoxes;

    final isPuzzleComplete =
        solution.isNotEmpty && currentCompletedRows.length == 9;
    final delta = BoardCompletionDelta(
      completedRows: newlyCompletedRows.length,
      completedCols: newlyCompletedCols.length,
      completedBoxes: newlyCompletedBoxes.length,
      isPuzzleComplete: isPuzzleComplete,
    );

    // 퍼즐을 완성시킨 마지막 입력은 줄 완성 파동(행 9개가 한 번에 완성돼
    // 의미가 없다)은 생략하되, 마지막 칸 자체의 정답 강조는 그대로 재생해
    // 완료 연출(_beginPuzzleCompleteSequence)의 1단계로 이어지게 한다.
    _suppressCorrectPulse = delta.hasNewCompletion && !isPuzzleComplete;
    if (isPuzzleComplete) {
      // 남아 있던 다른 칸의 임시 강조만 정리하고, 결과창에 자리를 넘기기
      // 전에 마지막 칸의 정답 강조(triggerCorrectEffect)가 걸릴 자리를
      // 남겨 둔다.
      _clearVisibleEffects();
      return delta;
    }
    if (!delta.hasNewCompletion) {
      return delta;
    }
    _triggerLineCompletionEffect(
      rows: newlyCompletedRows,
      cols: newlyCompletedCols,
      boxes: newlyCompletedBoxes,
      origin: origin,
      setState: setState,
      isMounted: isMounted,
    );
    return delta;
  }

  /// 정답 입력 시 입력한 칸만 짧게 강조한다. 줄 완성·퍼즐 완료와 겹치는
  /// 입력에서는 그쪽 효과가 우선하므로 생략한다.
  void triggerCorrectEffect({
    required int row,
    required int col,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
    if (_suppressCorrectPulse) {
      _suppressCorrectPulse = false;
      return;
    }
    final generation = _effectGeneration;
    final key = '$row,$col';
    final token = _claim(key);
    setState(() {
      _waveActive[key] = true;
    });
    Future<void>.delayed(correctPulseHold, () {
      if (!_isCurrent(key, token, generation, isMounted())) {
        return;
      }
      setState(() {
        _waveActive[key] = false;
      });
    });
  }

  void triggerErrorEffect({
    required int row,
    required int col,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
    final generation = _effectGeneration;
    final key = '$row,$col';
    final token = _claim(key);
    setState(() {
      _errorActive[key] = true;
      _errorOffset[key] = 0;
    });

    // 동작 줄이기: 이동 없이 색 강조만 짧게 보여준다.
    const shakeFrames = <double>[3, -3, 2, -1, 0];
    final frameGapMs = errorHold.inMilliseconds ~/ shakeFrames.length;
    if (!reduceMotion) {
      for (int i = 0; i < shakeFrames.length; i++) {
        Future<void>.delayed(Duration(milliseconds: frameGapMs * i), () {
          // 실행 중 동작 줄이기가 켜지면 이후 프레임은 반영하지 않는다.
          if (!_isCurrent(key, token, generation, isMounted()) ||
              reduceMotion) {
            return;
          }
          setState(() {
            _errorOffset[key] = shakeFrames[i];
          });
        });
      }
    }

    Future<void>.delayed(errorHold, () {
      if (!_isCurrent(key, token, generation, isMounted())) {
        return;
      }
      setState(() {
        _errorActive[key] = false;
        _errorOffset.remove(key);
      });
    });
  }

  /// 되돌리기로 실제 값이 바뀐 대표 칸(presenter가 계산한 결과)을 짧게
  /// 강조한다. 정답·오답·줄 완성 효과는 전혀 건드리지 않는다(그 효과들은
  /// undo()가 onCorrectAnswer/onIncorrectAnswer를 호출하지 않으므로 애초에
  /// 재실행되지 않는다). 항상 최대 한 칸만 강조하며, 연속으로 되돌리면
  /// 이전 칸의 강조를 기다리지 않고 즉시 지운 뒤 새 칸으로 옮긴다.
  void triggerUndoEffect({
    required int row,
    required int col,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
    final generation = _effectGeneration;
    final key = '$row,$col';
    final previousKey = _activeUndoKey;
    final token = _claim(key);
    _activeUndoKey = key;
    setState(() {
      if (previousKey != null && previousKey != key) {
        _undoActive[previousKey] = false;
      }
      _undoActive[key] = true;
    });

    Future<void>.delayed(undoHighlightHold, () {
      if (!_isCurrent(key, token, generation, isMounted())) {
        return;
      }
      setState(() {
        _undoActive[key] = false;
      });
      if (_activeUndoKey == key) {
        _activeUndoKey = null;
      }
    });
  }

  /// 사용자가 숫자나 메모를 지운 빈칸을 짧게 강조한다.
  void triggerEraseEffect({
    required int row,
    required int col,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
    final generation = _effectGeneration;
    final key = '$row,$col';
    final token = _claim(key);
    setState(() => _eraseActive[key] = true);
    Future<void>.delayed(eraseHighlightHold, () {
      if (!_isCurrent(key, token, generation, isMounted())) return;
      setState(() => _eraseActive[key] = false);
    });
  }

  /// 힌트로 채워진 칸 하나만 짧게 강조한다. 정답 입력 콜백에서
  /// [triggerCorrectEffect] 대신 호출해야 한다(둘을 같은 칸에 함께 걸면
  /// 나중 호출이 앞 호출을 즉시 지워 버린다). 이번 입력으로 줄·박스가
  /// 완성됐거나 퍼즐이 끝났다면(둘 다 [handleBoardChanged]가 미리 설정하는
  /// [_suppressCorrectPulse]로 판단) 그쪽 효과가 이미 이 칸을 포함해 강조
  /// 중이므로 힌트 강조는 생략해 서로 겹치지 않게 한다.
  void triggerHintAppliedEffect({
    required int row,
    required int col,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
    if (_suppressCorrectPulse) {
      _suppressCorrectPulse = false;
      return;
    }
    final generation = _effectGeneration;
    final key = '$row,$col';
    final token = _claim(key);
    setState(() {
      _hintAppliedActive[key] = true;
    });
    Future<void>.delayed(hintAppliedHold, () {
      if (!_isCurrent(key, token, generation, isMounted())) {
        return;
      }
      setState(() {
        _hintAppliedActive[key] = false;
      });
    });
  }

  /// 특정 숫자가 9개 모두 채워진 순간, 보드에서 그 숫자가 들어간 칸을 모두
  /// 짧게 옅은 색으로 강조한다. 자체 토큰 맵을 따로 두므로, 방금 입력한
  /// 칸에 이미 걸려 있는 정답 강조(triggerCorrectEffect)를 지우지 않는다.
  void triggerDigitCompleteEffect({
    required int digit,
    required List<List<int>> board,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
    final generation = _effectGeneration;
    final targets = <String>{};
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == digit) {
          targets.add('$row,$col');
        }
      }
    }
    if (targets.isEmpty) return;

    final tokens = <String, int>{};
    for (final key in targets) {
      final token = ++_digitTokenSeed;
      _digitTokens[key] = token;
      tokens[key] = token;
    }
    setState(() {
      for (final key in targets) {
        _digitCompleteActive[key] = true;
      }
    });

    Future<void>.delayed(digitCompleteHold, () {
      if (!_stillValid(isMounted, generation)) {
        return;
      }
      setState(() {
        for (final key in targets) {
          if (_digitTokens[key] == tokens[key]) {
            _digitCompleteActive[key] = false;
          }
        }
      });
    });
  }

  bool _stillValid(bool Function() isMounted, int generation) =>
      isMounted() && generation == _effectGeneration;

  void _clearVisibleEffects() {
    _effectGeneration++;
    _tokens.clear();
    _waveActive.clear();
    _lineCompleteActive.clear();
    _errorActive.clear();
    _errorOffset.clear();
    _undoActive.clear();
    _activeUndoKey = null;
    _hintAppliedActive.clear();
    _digitCompleteActive.clear();
    _digitTokens.clear();
  }

  Set<int> _getCompletedCorrectRows({
    required List<List<int>> board,
    required List<List<int>> solution,
  }) {
    if (solution.isEmpty) {
      return <int>{};
    }

    final completedRows = <int>{};
    for (int row = 0; row < 9; row++) {
      var isCorrectLine = true;
      for (int col = 0; col < 9; col++) {
        final value = board[row][col];
        final answer = solution[row][col];
        if (value == 0 || value != answer) {
          isCorrectLine = false;
          break;
        }
      }
      if (isCorrectLine) {
        completedRows.add(row);
      }
    }
    return completedRows;
  }

  Set<int> _getCompletedCorrectCols({
    required List<List<int>> board,
    required List<List<int>> solution,
  }) {
    if (solution.isEmpty) {
      return <int>{};
    }

    final completedCols = <int>{};
    for (int col = 0; col < 9; col++) {
      var isCorrectLine = true;
      for (int row = 0; row < 9; row++) {
        final value = board[row][col];
        final answer = solution[row][col];
        if (value == 0 || value != answer) {
          isCorrectLine = false;
          break;
        }
      }
      if (isCorrectLine) {
        completedCols.add(col);
      }
    }
    return completedCols;
  }

  Set<int> _getCompletedCorrectBoxes({
    required List<List<int>> board,
    required List<List<int>> solution,
  }) {
    if (solution.isEmpty) {
      return <int>{};
    }

    final completedBoxes = <int>{};
    for (int boxIndex = 0; boxIndex < 9; boxIndex++) {
      final startRow = (boxIndex ~/ 3) * 3;
      final startCol = (boxIndex % 3) * 3;
      var isCorrectBox = true;

      for (int row = startRow; row < startRow + 3; row++) {
        for (int col = startCol; col < startCol + 3; col++) {
          final value = board[row][col];
          final answer = solution[row][col];
          if (value == 0 || value != answer) {
            isCorrectBox = false;
            break;
          }
        }
        if (!isCorrectBox) {
          break;
        }
      }

      if (isCorrectBox) {
        completedBoxes.add(boxIndex);
      }
    }
    return completedBoxes;
  }

  /// 파동이 칸 하나를 지나는 간격. 입력한 칸에서 바깥으로 한 칸씩 퍼진다.
  static const int _rippleStepMs = 28;

  /// 파동이 가장 먼 칸에 닿은 뒤 되돌아오기 전까지 머무는 시간.
  static const int _rippleTurnaroundMs = 160;

  void _triggerLineCompletionEffect({
    required Set<int> rows,
    required Set<int> cols,
    required Set<int> boxes,
    required ({int row, int col})? origin,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
    final generation = _effectGeneration;
    // 칸별 켜지는 시점(ms)과 꺼지는 시점(ms). 파동은 입력한 칸(출발점)에서
    // 바깥으로 퍼졌다가 같은 순서의 거꾸로, 바깥 칸부터 출발점으로 되돌아오며
    // 꺼진다. 여러 줄·박스에 동시에 걸리면 가장 먼저 켜지고 가장 늦게 꺼진다.
    final onAt = <String, int>{};
    final offAt = <String, int>{};
    void considerSpan(String key, int on, int off) {
      final existingOn = onAt[key];
      if (existingOn == null || on < existingOn) onAt[key] = on;
      final existingOff = offAt[key];
      if (existingOff == null || off > existingOff) offAt[key] = off;
    }

    // 동작 줄이기에서는 퍼짐 없이 대상 전체를 동시에 켜고 같은 시간 뒤에 끈다.
    final wave = !reduceMotion;
    final holdMs = lineCompleteHold.inMilliseconds;
    // [distance]: 출발점에서 이 칸까지 거리, [maxDistance]: 그 줄·박스에서
    // 가장 먼 칸까지의 거리.
    void considerCell(int row, int col, int distance, int maxDistance) {
      final on = wave ? distance * _rippleStepMs : 0;
      final off = wave
          ? _rippleTurnaroundMs + (2 * maxDistance - distance) * _rippleStepMs
          : holdMs;
      considerSpan('$row,$col', on, off);
    }

    for (final row in rows) {
      final from = origin != null && origin.row == row ? origin.col : 0;
      final far = from > 8 - from ? from : 8 - from;
      for (int col = 0; col < 9; col++) {
        considerCell(row, col, (col - from).abs(), far);
      }
    }
    for (final col in cols) {
      final from = origin != null && origin.col == col ? origin.row : 0;
      final far = from > 8 - from ? from : 8 - from;
      for (int row = 0; row < 9; row++) {
        considerCell(row, col, (row - from).abs(), far);
      }
    }
    for (final boxIndex in boxes) {
      final startRow = (boxIndex ~/ 3) * 3;
      final startCol = (boxIndex % 3) * 3;
      final inside = origin != null &&
          origin.row >= startRow &&
          origin.row < startRow + 3 &&
          origin.col >= startCol &&
          origin.col < startCol + 3;
      final fromRow = inside ? origin.row : startRow;
      final fromCol = inside ? origin.col : startCol;
      var far = 0;
      for (int r = startRow; r < startRow + 3; r++) {
        for (int c = startCol; c < startCol + 3; c++) {
          final d = (r - fromRow).abs() + (c - fromCol).abs();
          if (d > far) far = d;
        }
      }
      for (int r = startRow; r < startRow + 3; r++) {
        for (int c = startCol; c < startCol + 3; c++) {
          considerCell(r, c, (r - fromRow).abs() + (c - fromCol).abs(), far);
        }
      }
    }
    final delays = onAt;
    if (delays.isEmpty) {
      return;
    }

    // 행·열·박스가 함께 완성돼도 칸의 합집합에 한 번만 적용한다. _claim은
    // 지금(모든 칸의 지연이 결정된 시점) 한꺼번에 걸어, 그 칸에 남아 있던
    // 일반 정답 효과(이전 입력의 잔상 포함)를 정리하고 기존 토큰 취소
    // 구조를 그대로 유지한다 — 실제 활성화는 각자의 지연만큼 뒤에 온다.
    final tokens = <String, int>{
      for (final key in delays.keys) key: _claim(key),
    };

    void scheduleOff(String key, int token) {
      final lit = offAt[key]! - onAt[key]!;
      Future.delayed(Duration(milliseconds: lit), () {
        if (!_stillValid(isMounted, generation)) {
          return;
        }
        setState(() {
          if (_tokens[key] == token) {
            _lineCompleteActive[key] = false;
          }
        });
      });
    }

    // 지연이 0인 칸(파동의 맨 앞, 또는 동작 줄이기의 전체)은 한 setState로
    // 동시에 켠다 — Future.delayed(Duration.zero)를 거치면 다음 이벤트
    // 루프 턴까지 밀려 "즉시 반응"이 아니게 되므로 피한다.
    final immediateKeys = [
      for (final entry in delays.entries)
        if (entry.value == 0) entry.key,
    ];
    if (immediateKeys.isNotEmpty) {
      setState(() {
        for (final key in immediateKeys) {
          _lineCompleteActive[key] = true;
        }
      });
      for (final key in immediateKeys) {
        scheduleOff(key, tokens[key]!);
      }
    }

    for (final entry in delays.entries) {
      if (entry.value == 0) continue; // 위에서 이미 처리함.
      final key = entry.key;
      final token = tokens[key]!;
      Future.delayed(Duration(milliseconds: entry.value), () {
        if (!_isCurrent(key, token, generation, isMounted())) {
          return;
        }
        setState(() {
          _lineCompleteActive[key] = true;
        });
        scheduleOff(key, token);
      });
    }
  }
}
