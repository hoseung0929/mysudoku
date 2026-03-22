import 'package:flutter/foundation.dart';
import 'package:mysudoku/utils/app_logger.dart';

import '../utils/sudoku_generator.dart';

class SudokuBoardController {
  SudokuBoardController({
    required List<List<int>> initialBoard,
    required List<List<int>>? solution,
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

    initializeBoard(initialBoard);
  }

  List<List<int>> _board = [];
  List<List<int>> _solution = [];
  List<List<bool>> _fixedNumbers = [];
  List<List<bool>> _wrongNumbers = [];
  List<List<int>> _initialBoard = [];
  List<List<Set<int>>> _noteNumbers = [];
  final Set<String> _hintCells = <String>{};
  int? _selectedRow;
  int? _selectedCol;

  List<List<int>> get board => _board;
  List<List<int>> get solution => _solution;
  List<List<bool>> get fixedNumbers => _fixedNumbers;
  List<List<bool>> get wrongNumbers => _wrongNumbers;
  List<List<int>> get initialBoard => _initialBoard;
  List<List<Set<int>>> get noteNumbers => _noteNumbers;
  int? get selectedRow => _selectedRow;
  int? get selectedCol => _selectedCol;

  void initializeBoard(List<List<int>> board) {
    _hintCells.clear();
    _board = List.generate(9, (row) => List<int>.from(board[row]));
    _initialBoard = List.generate(9, (row) => List<int>.from(_board[row]));
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
    ensureSolution();

    final currentValue = _board[row][col];
    final correctValue = _solution[row][col];
    final isWrong = currentValue != 0 && currentValue != correctValue;
    _wrongNumbers[row][col] = isWrong;

    if (kDebugMode) {
      AppLogger.debug(
        '셀 상태 체크: [$row][$col], 현재값=$currentValue, 정답=$correctValue, 오답=$isWrong',
      );
    }
  }

  void setCellValue(int row, int col, int value) {
    _board[row][col] = value;
    _hintCells.remove(_cellKey(row, col));
    _noteNumbers[row][col].clear();
  }

  void applyHint(int row, int col) {
    ensureSolution();
    _board[row][col] = _solution[row][col];
    _hintCells.add(_cellKey(row, col));
    _noteNumbers[row][col].clear();
  }

  void toggleNote(int row, int col, int value) {
    if (_fixedNumbers[row][col] || _board[row][col] != 0) {
      return;
    }

    final notes = _noteNumbers[row][col];
    if (notes.contains(value)) {
      notes.remove(value);
      return;
    }

    notes.add(value);
  }

  Set<int> getCellNotes(int row, int col) {
    return Set<int>.from(_noteNumbers[row][col]);
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
    ensureSolution();
    if (_board[row][col] == 0) return false;
    return _board[row][col] != _solution[row][col];
  }

  bool hasError(int row, int col) {
    return isWrongNumber(row, col);
  }

  bool isHintNumber(int row, int col) {
    return _hintCells.contains(_cellKey(row, col));
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

  String _cellKey(int row, int col) => '$row,$col';
}
