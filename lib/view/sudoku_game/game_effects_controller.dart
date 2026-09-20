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
  int _effectGeneration = 0;
  int _tokenSeed = 0;

  /// 칸·효과 종류별 최신 토큰. 같은 칸에 효과가 겹치면 이전 종료 콜백이
  /// 새 효과를 지우지 않도록 콜백마다 자기 토큰을 확인한다.
  final Map<String, int> _tokens = <String, int>{};

  /// 이번 입력에서 줄 완성/퍼즐 완료가 이미 표현되어 일반 정답 강조를
  /// 생략해야 하는지. 직후 이어지는 정답 콜백에서 한 번 소비한다.
  bool _suppressCorrectPulse = false;

  /// OS의 동작 줄이기 설정. 켜져 있으면 흔들림 같은 이동 효과를 생략한다.
  bool reduceMotion = false;

  final Map<String, bool> _waveActive = <String, bool>{};
  final Map<String, bool> _lineCompleteActive = <String, bool>{};
  final Map<String, bool> _errorActive = <String, bool>{};
  final Map<String, double> _errorOffset = <String, double>{};

  Map<String, bool> get waveActive => _waveActive;
  Map<String, bool> get lineCompleteActive => _lineCompleteActive;
  Map<String, bool> get errorActive => _errorActive;
  Map<String, double> get errorOffset => _errorOffset;

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
  }

  int _claim(String slot) {
    final token = ++_tokenSeed;
    _tokens[slot] = token;
    return token;
  }

  bool _isCurrent(String slot, int token, int generation, bool mounted) =>
      mounted && generation == _effectGeneration && _tokens[slot] == token;

  void initializeCompletedLineState({
    required List<List<int>> board,
    required List<List<int>> solution,
  }) {
    _completedRows = _getCompletedCorrectRows(board: board, solution: solution);
    _completedCols = _getCompletedCorrectCols(board: board, solution: solution);
    _completedBoxes =
        _getCompletedCorrectBoxes(board: board, solution: solution);
  }

  BoardCompletionDelta handleBoardChanged({
    required List<List<int>> board,
    required List<List<int>> solution,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
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

    _suppressCorrectPulse = delta.hasNewCompletion || isPuzzleComplete;
    if (isPuzzleComplete) {
      // 마지막 입력: 남아 있던 임시 강조를 정리하고 결과창에 자리를 넘긴다.
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
    final slot = 'c:$key';
    final token = _claim(slot);
    setState(() {
      _waveActive[key] = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!_isCurrent(slot, token, generation, isMounted())) {
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
    final slot = 'e:$key';
    final token = _claim(slot);
    setState(() {
      _errorActive[key] = true;
      _errorOffset[key] = 0;
    });

    // 동작 줄이기: 이동 없이 색 강조만 짧게 보여준다.
    const shakeFrames = <double>[3, -3, 2, -1, 0];
    const frameGapMs = 36;
    if (!reduceMotion) {
      for (int i = 0; i < shakeFrames.length; i++) {
        Future<void>.delayed(Duration(milliseconds: frameGapMs * i), () {
          if (!_isCurrent(slot, token, generation, isMounted())) {
            return;
          }
          setState(() {
            _errorOffset[key] = shakeFrames[i];
          });
        });
      }
    }

    Future<void>.delayed(
      Duration(milliseconds: frameGapMs * shakeFrames.length + 24),
      () {
        if (!_isCurrent(slot, token, generation, isMounted())) {
          return;
        }
        setState(() {
          _errorActive[key] = false;
          _errorOffset.remove(key);
        });
      },
    );
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

  void _triggerLineCompletionEffect({
    required Set<int> rows,
    required Set<int> cols,
    required Set<int> boxes,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
    final generation = _effectGeneration;
    final targets = <String>{};
    for (final row in rows) {
      for (int col = 0; col < 9; col++) {
        targets.add('$row,$col');
      }
    }
    for (final col in cols) {
      for (int row = 0; row < 9; row++) {
        targets.add('$row,$col');
      }
    }
    for (final boxIndex in boxes) {
      final startRow = (boxIndex ~/ 3) * 3;
      final startCol = (boxIndex % 3) * 3;
      for (int row = startRow; row < startRow + 3; row++) {
        for (int col = startCol; col < startCol + 3; col++) {
          targets.add('$row,$col');
        }
      }
    }
    if (targets.isEmpty) {
      return;
    }

    // 행·열·박스가 함께 완성돼도 칸의 합집합에 한 번만 적용한다.
    final tokens = <String, int>{
      for (final key in targets) key: _claim('l:$key'),
    };
    setState(() {
      for (final key in targets) {
        _lineCompleteActive[key] = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 550), () {
      if (!_stillValid(isMounted, generation)) {
        return;
      }
      setState(() {
        for (final key in targets) {
          if (_tokens['l:$key'] == tokens[key]) {
            _lineCompleteActive[key] = false;
          }
        }
      });
    });
  }
}
