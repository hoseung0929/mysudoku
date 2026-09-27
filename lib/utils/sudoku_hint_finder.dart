/// 힌트 설명에 쓰는 풀이 기법. 1차 버전은 싱글 기법만 찾는다.
enum SudokuHintTechnique {
  /// 칸의 가로줄·세로줄·박스에 다른 숫자 8개가 모두 있어 남는 숫자가 하나.
  nakedSingle,

  /// 박스 안에서 어떤 숫자가 들어갈 자리가 한 칸뿐.
  hiddenSingleBox,

  /// 가로줄 안에서 어떤 숫자가 들어갈 자리가 한 칸뿐.
  hiddenSingleRow,

  /// 세로줄 안에서 어떤 숫자가 들어갈 자리가 한 칸뿐.
  hiddenSingleCol,

  /// 싱글 기법으로 찾을 수 없어 정답만 알려 준다.
  reveal,
}

class SudokuHint {
  const SudokuHint({
    required this.row,
    required this.col,
    required this.value,
    required this.technique,
    required this.regionCells,
    required this.blockerCells,
    required this.movedFromSelection,
  });

  final int row;
  final int col;
  final int value;
  final SudokuHintTechnique technique;

  /// 1단계에서 "여기를 보세요"로 강조할 칸(칸 번호 = row * 9 + col).
  final Set<int> regionCells;

  /// 2단계에서 이유로 짚어 줄 칸. 숨은 싱글이면 다른 빈칸을 막는 같은 숫자.
  final Set<int> blockerCells;

  /// 선택한 칸 대신 먼저 풀 수 있는 다른 칸을 골랐는지.
  final bool movedFromSelection;

  int get cellIndex => row * 9 + col;
}

/// 현재 보드에서 사람이 따라갈 수 있는 다음 한 수를 찾는다.
///
/// 후보는 사용자의 메모가 아니라 보드 값에서 직접 계산한다. 정답과 다른 값은
/// 빈칸으로 보고 계산하므로 잘못된 입력이 설명을 오염시키지 않는다.
class SudokuHintFinder {
  SudokuHintFinder._();

  static SudokuHint? find({
    required List<List<int>> board,
    required List<List<int>> solution,
    int? selectedRow,
    int? selectedCol,
  }) {
    final grid = List.generate(9, (row) {
      return List.generate(9, (col) {
        final value = board[row][col];
        return value == solution[row][col] ? value : 0;
      });
    });

    final hasEmpty = grid.any((row) => row.contains(0));
    if (!hasEmpty) return null;

    final hasSelection = selectedRow != null &&
        selectedCol != null &&
        grid[selectedRow][selectedCol] == 0;

    SudokuHint? verified(SudokuHint? hint) {
      if (hint == null) return null;
      return solution[hint.row][hint.col] == hint.value ? hint : null;
    }

    if (hasSelection) {
      final atSelection = verified(
        _hiddenSingleAt(grid, selectedRow, selectedCol) ??
            _nakedSingleAt(grid, selectedRow, selectedCol),
      );
      if (atSelection != null) return atSelection;
    }

    // 눈으로 찾기 쉬운 순서: 박스 숨은 싱글 → 유일 후보 → 줄 숨은 싱글.
    final elsewhere = verified(
      _firstHiddenSingle(grid, SudokuHintTechnique.hiddenSingleBox) ??
          _firstNakedSingle(grid) ??
          _firstHiddenSingle(grid, SudokuHintTechnique.hiddenSingleRow) ??
          _firstHiddenSingle(grid, SudokuHintTechnique.hiddenSingleCol),
    );
    if (elsewhere != null) {
      return _withMoved(elsewhere, moved: hasSelection);
    }

    final (row, col) =
        hasSelection ? (selectedRow, selectedCol) : _fewestCandidatesCell(grid);
    return SudokuHint(
      row: row,
      col: col,
      value: solution[row][col],
      technique: SudokuHintTechnique.reveal,
      regionCells: {row * 9 + col},
      blockerCells: const {},
      movedFromSelection: false,
    );
  }

  static SudokuHint _withMoved(SudokuHint hint, {required bool moved}) {
    return SudokuHint(
      row: hint.row,
      col: hint.col,
      value: hint.value,
      technique: hint.technique,
      regionCells: hint.regionCells,
      blockerCells: hint.blockerCells,
      movedFromSelection: moved,
    );
  }

  static Set<int> candidatesAt(List<List<int>> grid, int row, int col) {
    if (grid[row][col] != 0) return const {};
    final used = <int>{};
    for (final (r, c) in _peers(row, col)) {
      used.add(grid[r][c]);
    }
    return {
      for (int value = 1; value <= 9; value++)
        if (!used.contains(value)) value,
    };
  }

  static SudokuHint? _nakedSingleAt(List<List<int>> grid, int row, int col) {
    final candidates = candidatesAt(grid, row, col);
    if (candidates.length != 1) return null;
    return SudokuHint(
      row: row,
      col: col,
      value: candidates.single,
      technique: SudokuHintTechnique.nakedSingle,
      regionCells: {
        row * 9 + col,
        for (final (r, c) in _peers(row, col)) r * 9 + c,
      },
      blockerCells: const {},
      movedFromSelection: false,
    );
  }

  static SudokuHint? _firstNakedSingle(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final hint = _nakedSingleAt(grid, row, col);
        if (hint != null) return hint;
      }
    }
    return null;
  }

  static SudokuHint? _hiddenSingleAt(List<List<int>> grid, int row, int col) {
    for (final technique in const [
      SudokuHintTechnique.hiddenSingleBox,
      SudokuHintTechnique.hiddenSingleRow,
      SudokuHintTechnique.hiddenSingleCol,
    ]) {
      final unit = _unitOf(technique, row, col);
      for (final value in candidatesAt(grid, row, col)) {
        final hint = _hiddenSingleIn(grid, unit, value, technique);
        if (hint != null && hint.row == row && hint.col == col) return hint;
      }
    }
    return null;
  }

  static SudokuHint? _firstHiddenSingle(
    List<List<int>> grid,
    SudokuHintTechnique technique,
  ) {
    for (int index = 0; index < 9; index++) {
      final unit = switch (technique) {
        SudokuHintTechnique.hiddenSingleRow => _rowCells(index),
        SudokuHintTechnique.hiddenSingleCol => _colCells(index),
        _ => _boxCells((index ~/ 3) * 3, (index % 3) * 3),
      };
      for (int value = 1; value <= 9; value++) {
        final hint = _hiddenSingleIn(grid, unit, value, technique);
        if (hint != null) return hint;
      }
    }
    return null;
  }

  /// [unit] 안에서 [value]가 들어갈 수 있는 빈칸이 정확히 하나면 그 칸.
  static SudokuHint? _hiddenSingleIn(
    List<List<int>> grid,
    List<(int, int)> unit,
    int value,
    SudokuHintTechnique technique,
  ) {
    if (unit.any((cell) => grid[cell.$1][cell.$2] == value)) return null;
    final empties = unit.where((cell) => grid[cell.$1][cell.$2] == 0).toList();
    final spots = empties
        .where((cell) => candidatesAt(grid, cell.$1, cell.$2).contains(value))
        .toList();
    if (spots.length != 1) return null;
    final (row, col) = spots.single;

    // 다른 빈칸마다 그 칸을 막는 같은 숫자 하나를 이유로 보여 준다.
    final blockers = <int>{};
    for (final (r, c) in empties) {
      if (r == row && c == col) continue;
      for (final (pr, pc) in _peers(r, c)) {
        if (grid[pr][pc] == value) {
          blockers.add(pr * 9 + pc);
          break;
        }
      }
    }

    return SudokuHint(
      row: row,
      col: col,
      value: value,
      technique: technique,
      regionCells: {for (final (r, c) in unit) r * 9 + c},
      blockerCells: blockers,
      movedFromSelection: false,
    );
  }

  static (int, int) _fewestCandidatesCell(List<List<int>> grid) {
    (int, int)? best;
    var bestCount = 10;
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] != 0) continue;
        final count = candidatesAt(grid, row, col).length;
        if (count < bestCount) {
          best = (row, col);
          bestCount = count;
        }
      }
    }
    return best!;
  }

  static List<(int, int)> _unitOf(
    SudokuHintTechnique technique,
    int row,
    int col,
  ) {
    return switch (technique) {
      SudokuHintTechnique.hiddenSingleRow => _rowCells(row),
      SudokuHintTechnique.hiddenSingleCol => _colCells(col),
      _ => _boxCells((row ~/ 3) * 3, (col ~/ 3) * 3),
    };
  }

  static List<(int, int)> _rowCells(int row) => [
        for (int col = 0; col < 9; col++) (row, col),
      ];

  static List<(int, int)> _colCells(int col) => [
        for (int row = 0; row < 9; row++) (row, col),
      ];

  static List<(int, int)> _boxCells(int startRow, int startCol) => [
        for (int r = startRow; r < startRow + 3; r++)
          for (int c = startCol; c < startCol + 3; c++) (r, c),
      ];

  /// 같은 가로줄·세로줄·박스에 있는 다른 칸(중복 없음).
  static Iterable<(int, int)> _peers(int row, int col) {
    final peers = <(int, int)>{
      ..._rowCells(row),
      ..._colCells(col),
      ..._boxCells((row ~/ 3) * 3, (col ~/ 3) * 3),
    }..remove((row, col));
    return peers;
  }
}
