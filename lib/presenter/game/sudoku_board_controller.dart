import 'package:flutter/foundation.dart';
import 'package:mysudoku/utils/app_logger.dart';

import 'package:mysudoku/utils/sudoku_generator.dart';

sealed class BoardAction {
  const BoardAction();
}

class CellValueAction extends BoardAction {
  CellValueAction({
    required this.row,
    required this.col,
    required this.previousValue,
    required this.newValue,
    required this.previousCellNotes,
    required this.clearedRelatedNoteKeys,
    this.isHint = false,
  });

  final int row;
  final int col;
  final int previousValue;
  final int newValue;
  final Set<int> previousCellNotes;
  final Set<String> clearedRelatedNoteKeys;
  final bool isHint;
  bool didIncreaseWrongCount = false;
}

class NoteToggleAction extends BoardAction {
  const NoteToggleAction({
    required this.row,
    required this.col,
    required this.noteValue,
    required this.wasAdded,
  });

  final int row;
  final int col;
  final int noteValue;
  final bool wasAdded;
}

class SudokuBoardController {
  SudokuBoardController({
    required List<List<int>> initialBoard,
    required List<List<int>>? solution,
    List<List<int>>? puzzleBoard,
  }) {
    if (solution != null && solution.isNotEmpty) {
      _solution = solution;
      if (kDebugMode) {
        AppLogger.debug('DB 해답 데이터 사용');
      }
    } else {
      _solution = SudokuGenerator.getSolution(initialBoard);
      if (kDebugMode) {
        AppLogger.debug('해답 데이터 없음, 동적 생성 사용');
      }
    }

    initializeBoard(initialBoard, puzzleBoard: puzzleBoard);
  }

  List<List<int>> _board = [];
  List<List<int>> _solution = [];
  List<List<bool>> _fixedNumbers = [];
  List<List<bool>> _wrongNumbers = [];
  List<List<int>> _initialBoard = [];
  List<List<Set<int>>> _noteNumbers = [];
  int? _selectedRow;
  int? _selectedCol;
  final List<BoardAction> _undoStack = [];
  final List<BoardAction> _redoStack = [];

  List<List<int>> get board => _board;
  List<List<int>> get solution => _solution;
  List<List<bool>> get fixedNumbers => _fixedNumbers;
  List<List<bool>> get wrongNumbers => _wrongNumbers;
  List<List<int>> get initialBoard => _initialBoard;
  List<List<Set<int>>> get noteNumbers => _noteNumbers;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  BoardAction? get lastAction =>
      _undoStack.isNotEmpty ? _undoStack.last : null;

  void initializeBoard(
    List<List<int>> board, {
    List<List<int>>? puzzleBoard,
  }) {
    _board = List.generate(9, (row) => List<int>.from(board[row]));
    final sourceBoard = puzzleBoard ?? board;
    _initialBoard = List.generate(9, (row) => List<int>.from(sourceBoard[row]));
    _fixedNumbers = List.generate(9, (row) {
      return List.generate(9, (col) => _initialBoard[row][col] != 0);
    });
    _wrongNumbers = List.generate(9, (_) => List.filled(9, false));
    _noteNumbers = List.generate(
      9,
      (_) => List.generate(9, (_) => <int>{}),
    );
    _selectedRow = null;
    _selectedCol = null;
    clearHistory();
  }

  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void initializeGeneratedBoard(List<List<int>> board, List<List<int>> solution) {
    _solution = solution;
    initializeBoard(board);
  }

  void selectCell(int row, int col) {
    _selectedRow = row;
    _selectedCol = col;
  }

  void clearSelection() {
    _selectedRow = null;
    _selectedCol = null;
  }

  void ensureSolution() {
    if (_solution.isNotEmpty) return;

    if (kDebugMode) {
      AppLogger.debug('해답 데이터가 없어 동적으로 생성합니다');
    }
    _solution = SudokuGenerator.getSolution(_board);
  }

  void updateWrongStatus(int row, int col) {
    _recomputeConflictStatus();

    if (kDebugMode) {
      AppLogger.debug(
        '셀 충돌 체크: [$row][$col], 현재값=${_board[row][col]}, 충돌=${_wrongNumbers[row][col]}',
      );
    }
  }

  void recomputeWrongStatus() {
    _recomputeConflictStatus();
  }

  void setCellValue(int row, int col, int value, {bool isHint = false}) {
    final previousValue = _board[row][col];
    final previousCellNotes = Set<int>.from(_noteNumbers[row][col]);
    final clearedKeys = <String>{};

    if (value != 0) {
      clearedKeys.addAll(_findRelatedNoteKeys(row, col, value));
    }

    _undoStack.add(CellValueAction(
      row: row,
      col: col,
      previousValue: previousValue,
      newValue: value,
      previousCellNotes: previousCellNotes,
      clearedRelatedNoteKeys: clearedKeys,
      isHint: isHint,
    ));
    _redoStack.clear();

    _board[row][col] = value;
    _noteNumbers[row][col].clear();
    if (value != 0) {
      _clearRelatedNotes(row, col, value);
    }
  }

  void toggleNote(int row, int col, int value) {
    if (_fixedNumbers[row][col] || _board[row][col] != 0) {
      return;
    }

    final notes = _noteNumbers[row][col];
    final wasPresent = notes.contains(value);

    _undoStack.add(NoteToggleAction(
      row: row,
      col: col,
      noteValue: value,
      wasAdded: !wasPresent,
    ));
    _redoStack.clear();

    if (wasPresent) {
      notes.remove(value);
    } else {
      notes.add(value);
    }
  }

  BoardAction? undoAction() {
    if (_undoStack.isEmpty) return null;
    final action = _undoStack.removeLast();
    _redoStack.add(action);
    _applyReverse(action);
    return action;
  }

  BoardAction? redoAction() {
    if (_redoStack.isEmpty) return null;
    final action = _redoStack.removeLast();
    _undoStack.add(action);
    _applyForward(action);
    return action;
  }

  void _applyReverse(BoardAction action) {
    switch (action) {
      case CellValueAction():
        for (final key in action.clearedRelatedNoteKeys) {
          final parts = key.split(',');
          _noteNumbers[int.parse(parts[0])][int.parse(parts[1])]
              .add(action.newValue);
        }
        _noteNumbers[action.row][action.col] =
            Set<int>.from(action.previousCellNotes);
        _board[action.row][action.col] = action.previousValue;
      case NoteToggleAction():
        if (action.wasAdded) {
          _noteNumbers[action.row][action.col].remove(action.noteValue);
        } else {
          _noteNumbers[action.row][action.col].add(action.noteValue);
        }
    }
  }

  void _applyForward(BoardAction action) {
    switch (action) {
      case CellValueAction():
        _board[action.row][action.col] = action.newValue;
        _noteNumbers[action.row][action.col].clear();
        if (action.newValue != 0) {
          _clearRelatedNotes(action.row, action.col, action.newValue);
        }
      case NoteToggleAction():
        if (action.wasAdded) {
          _noteNumbers[action.row][action.col].add(action.noteValue);
        } else {
          _noteNumbers[action.row][action.col].remove(action.noteValue);
        }
    }
  }

  Set<String> _findRelatedNoteKeys(int row, int col, int value) {
    final keys = <String>{};
    for (int c = 0; c < 9; c++) {
      if (c != col && _noteNumbers[row][c].contains(value)) {
        keys.add('$row,$c');
      }
    }
    for (int r = 0; r < 9; r++) {
      if (r != row && _noteNumbers[r][col].contains(value)) {
        keys.add('$r,$col');
      }
    }
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if ((r != row || c != col) && _noteNumbers[r][c].contains(value)) {
          keys.add('$r,$c');
        }
      }
    }
    return keys;
  }

  Set<int> getCellNotes(int row, int col) {
    return Set<int>.from(_noteNumbers[row][col]);
  }

  List<List<Set<int>>> getAllCellNotes() {
    return List.generate(
      9,
      (row) => List.generate(
        9,
        (col) => Set<int>.from(_noteNumbers[row][col]),
      ),
    );
  }

  void restoreNotes(List<List<Set<int>>> notes) {
    _noteNumbers = List.generate(9, (row) {
      return List.generate(9, (col) {
        final rowData = row < notes.length ? notes[row] : const <Set<int>>[];
        final noteSet = col < rowData.length ? rowData[col] : const <int>{};
        if (_fixedNumbers[row][col] || _board[row][col] != 0) {
          return <int>{};
        }
        return Set<int>.from(noteSet);
      });
    });
  }

  bool hasNote(int row, int col, int value) {
    return _noteNumbers[row][col].contains(value);
  }

  int getCorrectValue(int row, int col) {
    ensureSolution();
    return _solution[row][col];
  }

  int getCellValue(int row, int col) => _board[row][col];

  bool isCellFixed(int row, int col) => _fixedNumbers[row][col];

  bool isCellSelected(int row, int col) {
    return row == _selectedRow && col == _selectedCol;
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

  bool isWrongNumber(int row, int col) {
    return _wrongNumbers[row][col];
  }

  bool hasError(int row, int col) {
    return isWrongNumber(row, col);
  }

  double get progress {
    final fixedCellCount = _fixedNumbers
        .expand((row) => row)
        .where((isFixed) => isFixed)
        .length;

    final totalCellsToFill = 81 - fixedCellCount;
    if (totalCellsToFill == 0) return 1.0;

    int currentFilledCells = 0;
    for (final row in _board) {
      for (final cell in row) {
        if (cell != 0) {
          currentFilledCells++;
        }
      }
    }

    final userFilledCells = currentFilledCells - fixedCellCount;
    final ratio = userFilledCells / totalCellsToFill.toDouble();
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }
  void _recomputeConflictStatus() {
    _wrongNumbers = List.generate(9, (row) {
      return List.generate(9, (col) => _hasConflictAt(row, col));
    });
  }

  bool _hasConflictAt(int row, int col) {
    final value = _board[row][col];
    if (value == 0) {
      return false;
    }

    for (int checkCol = 0; checkCol < 9; checkCol++) {
      if (checkCol != col && _board[row][checkCol] == value) {
        return true;
      }
    }

    for (int checkRow = 0; checkRow < 9; checkRow++) {
      if (checkRow != row && _board[checkRow][col] == value) {
        return true;
      }
    }

    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (int checkRow = startRow; checkRow < startRow + 3; checkRow++) {
      for (int checkCol = startCol; checkCol < startCol + 3; checkCol++) {
        if ((checkRow != row || checkCol != col) &&
            _board[checkRow][checkCol] == value) {
          return true;
        }
      }
    }

    return false;
  }

  void _clearRelatedNotes(int row, int col, int value) {
    for (int checkCol = 0; checkCol < 9; checkCol++) {
      if (checkCol != col) {
        _noteNumbers[row][checkCol].remove(value);
      }
    }

    for (int checkRow = 0; checkRow < 9; checkRow++) {
      if (checkRow != row) {
        _noteNumbers[checkRow][col].remove(value);
      }
    }

    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (int checkRow = startRow; checkRow < startRow + 3; checkRow++) {
      for (int checkCol = startCol; checkCol < startCol + 3; checkCol++) {
        if (checkRow == row && checkCol == col) {
          continue;
        }
        _noteNumbers[checkRow][checkCol].remove(value);
      }
    }
  }
}
