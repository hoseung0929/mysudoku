class BoardCompletionDelta {
  const BoardCompletionDelta({
    required this.completedRows,
    required this.completedCols,
    required this.completedBoxes,
  });

  final int completedRows;
  final int completedCols;
  final int completedBoxes;

  bool get hasNewCompletion =>
      completedRows > 0 || completedCols > 0 || completedBoxes > 0;
}

class GameEffectsController {
  Set<int> _completedRows = <int>{};
  Set<int> _completedCols = <int>{};
  Set<int> _completedBoxes = <int>{};
  int _effectGeneration = 0;

  final Map<String, bool> _waveActive = <String, bool>{};
  final Map<String, bool> _lineCompleteActive = <String, bool>{};
  final Map<String, bool> _errorActive = <String, bool>{};

  Map<String, bool> get waveActive => _waveActive;
  Map<String, bool> get lineCompleteActive => _lineCompleteActive;
  Map<String, bool> get errorActive => _errorActive;

  void resetForBoard({
    required List<List<int>> board,
    required List<List<int>> solution,
  }) {
    _effectGeneration++;
    _waveActive.clear();
    _lineCompleteActive.clear();
    _errorActive.clear();
    initializeCompletedLineState(board: board, solution: solution);
  }

  void dispose() {
    _effectGeneration++;
    _waveActive.clear();
    _lineCompleteActive.clear();
    _errorActive.clear();
  }

  void initializeCompletedLineState({
    required List<List<int>> board,
    required List<List<int>> solution,
  }) {
    _completedRows = _getCompletedCorrectRows(board: board, solution: solution);
    _completedCols = _getCompletedCorrectCols(board: board, solution: solution);
    _completedBoxes = _getCompletedCorrectBoxes(board: board, solution: solution);
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

    final delta = BoardCompletionDelta(
      completedRows: newlyCompletedRows.length,
      completedCols: newlyCompletedCols.length,
      completedBoxes: newlyCompletedBoxes.length,
    );

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

  void triggerWaveEffect({
    required int row,
    required int col,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
    final effectGeneration = _effectGeneration;
    const int waveSpeed = 30;
    const int returnDelay = 100;

    setState(() {
      _waveActive.clear();
    });

    int maxDistance = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (r == row || c == col) {
          final distance = (r == row) ? (c - col).abs() : (r - row).abs();
          if (distance > maxDistance) {
            maxDistance = distance;
          }
        }
      }
    }

    final totalWaveTime = waveSpeed * maxDistance;

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (r != row && c != col) {
          continue;
        }

        final distance = (r == row) ? (c - col).abs() : (r - row).abs();
        final delay = Duration(milliseconds: waveSpeed * distance);
        Future.delayed(delay, () {
          if (!isMounted() || effectGeneration != _effectGeneration) {
            return;
          }
          setState(() {
            _waveActive['$r,$c'] = true;
          });
        });

        final returnDelayTime =
            totalWaveTime + returnDelay + (waveSpeed * (maxDistance - distance));
        Future.delayed(Duration(milliseconds: returnDelayTime), () {
          if (!isMounted() || effectGeneration != _effectGeneration) {
            return;
          }
          setState(() {
            _waveActive['$r,$c'] = false;
          });
        });
      }
    }
  }

  void triggerErrorEffect({
    required int row,
    required int col,
    required void Function(void Function()) setState,
    required bool Function() isMounted,
  }) {
    final effectGeneration = _effectGeneration;
    final key = '$row,$col';
    setState(() {
      _errorActive[key] = false;
    });

    Future<void>.delayed(Duration.zero, () {
      if (!isMounted() || effectGeneration != _effectGeneration) {
        return;
      }
      setState(() {
        _errorActive[key] = true;
      });
    });

    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!isMounted() || effectGeneration != _effectGeneration) {
        return;
      }
      setState(() {
        _errorActive[key] = false;
      });
    });
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
    final effectGeneration = _effectGeneration;
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

    setState(() {
      for (final key in targets) {
        _lineCompleteActive[key] = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!isMounted() || effectGeneration != _effectGeneration) {
        return;
      }
      setState(() {
        for (final key in targets) {
          _lineCompleteActive[key] = false;
        }
      });
    });
  }
}
