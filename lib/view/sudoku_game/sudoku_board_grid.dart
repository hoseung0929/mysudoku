import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mysudoku/presenter/sudoku_game_presenter.dart';
import 'package:mysudoku/theme/app_theme.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_memo_notes_grid.dart';

/// 9x9 스도쿠 보드 (셀 탭은 부모에서 setState 처리)
class SudokuBoardGrid extends StatelessWidget {
  const SudokuBoardGrid({
    super.key,
    required this.presenter,
    required this.waveActive,
    required this.lineCompleteActive,
    required this.errorActive,
    this.enableMemoHighlights = true,
    this.enableSmartHintHighlights = true,
    this.highlightedMemoNumber,
    required this.onCellTapped,
  });

  final SudokuGamePresenter presenter;
  final Map<String, bool> waveActive;
  final Map<String, bool> lineCompleteActive;
  final Map<String, bool> errorActive;
  final bool enableMemoHighlights;
  final bool enableSmartHintHighlights;
  final int? highlightedMemoNumber;
  final void Function(int row, int col) onCellTapped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = cs.outlineVariant;
    final relatedFill = Theme.of(context).brightness == Brightness.dark
        ? cs.surfaceContainerHigh
        : Colors.grey.shade100;
    final digitOnBoard = cs.onSurface;
    final selectedRow = presenter.selectedRow;
    final selectedCol = presenter.selectedCol;
    final selectedValue = selectedRow == null || selectedCol == null
        ? 0
        : presenter.getCellValue(selectedRow, selectedCol);
    final highlightedMemo = enableMemoHighlights
        ? (selectedValue == 0 ? highlightedMemoNumber : selectedValue)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(9, (row) {
          return Expanded(
            child: Row(
              children: List.generate(9, (col) {
                final value = presenter.getCellValue(row, col);
                final isFixed = presenter.isCellFixed(row, col);
                final isSelected = presenter.isCellSelected(row, col);
                final isSameNumber = presenter.isSameNumber(row, col);
                final isRelated = presenter.isRelated(row, col);
                final isWrong = presenter.isWrongNumber(row, col);
                final isHint = presenter.isHintNumber(row, col);
                final notes = presenter.getCellNotes(row, col);
                final isRuleSingleCandidateCell =
                    enableSmartHintHighlights &&
                    value == 0 && _countValidCandidates(row, col) == 1;
                final isSingleCandidateCell =
                    enableMemoHighlights && value == 0 && notes.length == 1;
                final hasHighlightedMemoCandidate =
                    highlightedMemo != null &&
                    value == 0 &&
                    notes.contains(highlightedMemo);
                final isHiddenSingleForHighlightedMemo =
                    hasHighlightedMemoCandidate &&
                    _isUniqueMemoCandidate(
                      row: row,
                      col: col,
                      candidate: highlightedMemo,
                    );

                final isWave = waveActive['$row,$col'] == true;
                final isLineComplete = lineCompleteActive['$row,$col'] == true;
                final isErrorActive = errorActive['$row,$col'] == true;
                final horizontalOffset = isErrorActive ? 6.0 : 0.0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onCellTapped(row, col),
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 70),
                      offset: Offset(horizontalOffset / 48, 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: borderColor,
                              width:
                                  (row == 0 || row == 3 || row == 6) ? 1.5 : 0.5,
                            ),
                            left: BorderSide(
                              color: borderColor,
                              width:
                                  (col == 0 || col == 3 || col == 6) ? 1.5 : 0.5,
                            ),
                            right: BorderSide(
                              color: borderColor,
                              width:
                                  (col == 2 || col == 5 || col == 8) ? 1.5 : 0.5,
                            ),
                            bottom: BorderSide(
                              color: borderColor,
                              width:
                                  (row == 2 || row == 5 || row == 8) ? 1.5 : 0.5,
                            ),
                          ),
                          color: isErrorActive
                              ? AppTheme.pinkColor.withValues(alpha: 0.55)
                              : isWave
                                  ? Colors.green.withValues(alpha: 0.4)
                                  : isLineComplete
                                      ? Colors.amber.withValues(alpha: 0.35)
                                      : isSelected
                                          ? AppTheme.sudokuSelectedNumberColor
                                          : isWrong
                                              ? AppTheme.sudokuWrongNumberColor
                                                  .withValues(alpha: 0.3)
                                              : isHint
                                                  ? AppTheme.sudokuHintNumberColor
                                                  : isSameNumber
                                                      ? AppTheme.sudokuSameNumberColor
                                                      : isHiddenSingleForHighlightedMemo
                                                          ? AppTheme.lightBlueColor
                                                              .withValues(alpha: 0.3)
                                                      : hasHighlightedMemoCandidate
                                                          ? AppTheme.lightBlueColor
                                                              .withValues(alpha: 0.18)
                                                      : isRuleSingleCandidateCell
                                                          ? AppTheme.mintColor
                                                              .withValues(alpha: 0.2)
                                                      : isSingleCandidateCell
                                                          ? Colors.amber
                                                              .withValues(alpha: 0.16)
                                                      : isRelated
                                                          ? relatedFill
                                                          : null,
                        ),
                        child: Center(
                          child: value != 0
                              ? Text(
                                  value.toString(),
                                  style: isWrong
                                      ? AppTheme.sudokuWrongNumberStyle
                                      : isHint
                                          ? GoogleFonts.notoSans(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange.shade700,
                                            )
                                          : isFixed
                                              ? GoogleFonts.notoSans(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  color: digitOnBoard,
                                                )
                                              : GoogleFonts.notoSans(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w600,
                                                  color: digitOnBoard,
                                                ),
                                )
                              : SudokuMemoNotesGrid(
                                  notes: notes,
                                  highlightedNote: highlightedMemo,
                                  isSingleCandidate: isSingleCandidateCell,
                                  isHiddenSingleCandidate:
                                      isHiddenSingleForHighlightedMemo,
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  bool _isUniqueMemoCandidate({
    required int row,
    required int col,
    required int candidate,
  }) {
    return _countCandidateInRow(row, candidate) == 1 ||
        _countCandidateInCol(col, candidate) == 1 ||
        _countCandidateInBox(row, col, candidate) == 1;
  }

  int _countCandidateInRow(int row, int candidate) {
    int count = 0;
    for (int col = 0; col < 9; col++) {
      if (presenter.getCellValue(row, col) == 0 &&
          presenter.getCellNotes(row, col).contains(candidate)) {
        count++;
      }
    }
    return count;
  }

  int _countCandidateInCol(int col, int candidate) {
    int count = 0;
    for (int row = 0; row < 9; row++) {
      if (presenter.getCellValue(row, col) == 0 &&
          presenter.getCellNotes(row, col).contains(candidate)) {
        count++;
      }
    }
    return count;
  }

  int _countCandidateInBox(int row, int col, int candidate) {
    int count = 0;
    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (int checkRow = startRow; checkRow < startRow + 3; checkRow++) {
      for (int checkCol = startCol; checkCol < startCol + 3; checkCol++) {
        if (presenter.getCellValue(checkRow, checkCol) == 0 &&
            presenter.getCellNotes(checkRow, checkCol).contains(candidate)) {
          count++;
        }
      }
    }
    return count;
  }

  int _countValidCandidates(int row, int col) {
    int count = 0;
    for (int candidate = 1; candidate <= 9; candidate++) {
      if (_isValueAllowed(row, col, candidate)) {
        count++;
      }
    }
    return count;
  }

  bool _isValueAllowed(int row, int col, int candidate) {
    for (int checkCol = 0; checkCol < 9; checkCol++) {
      if (checkCol != col && presenter.getCellValue(row, checkCol) == candidate) {
        return false;
      }
    }

    for (int checkRow = 0; checkRow < 9; checkRow++) {
      if (checkRow != row && presenter.getCellValue(checkRow, col) == candidate) {
        return false;
      }
    }

    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;
    for (int checkRow = startRow; checkRow < startRow + 3; checkRow++) {
      for (int checkCol = startCol; checkCol < startCol + 3; checkCol++) {
        if ((checkRow != row || checkCol != col) &&
            presenter.getCellValue(checkRow, checkCol) == candidate) {
          return false;
        }
      }
    }

    return true;
  }
}
