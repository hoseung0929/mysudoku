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
    required this.errorOffset,
    this.enableMemoHighlights = true,
    this.highlightedMemoNumber,
    required this.onCellTapped,
  });

  final SudokuGamePresenter presenter;
  final Map<String, bool> waveActive;
  final Map<String, bool> lineCompleteActive;
  final Map<String, bool> errorActive;
  final Map<String, double> errorOffset;
  final bool enableMemoHighlights;
  final int? highlightedMemoNumber;
  final void Function(int row, int col) onCellTapped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const borderColor = Color(0xFFE4DED3);
    const relatedFill = Color(0xFFF7F3EB);
    final digitOnBoard = cs.onSurface;
    final selectedRow = presenter.selectedRow;
    final selectedCol = presenter.selectedCol;
    final selectedValue = selectedRow == null || selectedCol == null
        ? 0
        : presenter.getCellValue(selectedRow, selectedCol);
    final highlightedMemo = enableMemoHighlights
        ? (selectedValue == 0 ? highlightedMemoNumber : selectedValue)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellExtent = constraints.maxWidth / 9;
        final digitFontSize = (cellExtent * 0.62).clamp(18.0, 28.0);
        final memoCellExtent = (cellExtent * 0.54).clamp(10.0, 16.0);
        final boardRadius = (cellExtent * 0.55).clamp(14.0, 20.0);

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(boardRadius),
            border: Border.all(color: const Color(0xFFE4DED3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF21382A).withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
                final isHint = presenter.isHintCell(row, col);
                final notes = presenter.getCellNotes(row, col);
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
                final horizontalOffset = errorOffset['$row,$col'] ?? 0.0;

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
                                      (row == 0 || row == 3 || row == 6) ? 1.2 : 0.35,
                                ),
                                left: BorderSide(
                                  color: borderColor,
                                  width:
                                      (col == 0 || col == 3 || col == 6) ? 1.2 : 0.35,
                                ),
                                right: BorderSide(
                                  color: borderColor,
                                  width:
                                      (col == 2 || col == 5 || col == 8) ? 1.2 : 0.35,
                                ),
                                bottom: BorderSide(
                                  color: borderColor,
                                  width:
                                      (row == 2 || row == 5 || row == 8) ? 1.2 : 0.35,
                                ),
                              ),
                              color: isErrorActive
                                  ? AppTheme.pinkColor.withValues(alpha: 0.28)
                                  : isWave
                                      ? AppTheme.mintColor.withValues(alpha: 0.22)
                                              : isLineComplete
                                          ? AppTheme.yellowColor.withValues(alpha: 0.26)
                                          : isSelected
                                              ? AppTheme.lightBlueColor.withValues(alpha: 0.22)
                                          : isWrong
                                                  ? AppTheme.pinkColor.withValues(alpha: 0.18)
                                                  : isSameNumber
                                                          ? AppTheme.lightBlueColor.withValues(alpha: 0.14)
                                                          : isHiddenSingleForHighlightedMemo
                                                              ? AppTheme.lightBlueColor
                                                                  .withValues(alpha: 0.24)
                                                          : hasHighlightedMemoCandidate
                                                              ? AppTheme.lightBlueColor
                                                                  .withValues(alpha: 0.14)
                                                          : isSingleCandidateCell
                                                              ? AppTheme.yellowColor
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
                                          ? AppTheme.sudokuWrongNumberStyle.copyWith(
                                              fontSize: digitFontSize,
                                            )
                                          : isFixed
                                                  ? GoogleFonts.notoSans(
                                                      fontSize: digitFontSize,
                                                      fontWeight: FontWeight.bold,
                                                      color: digitOnBoard,
                                                    )
                                                  : isHint
                                                      ? GoogleFonts.notoSans(
                                                          fontSize: digitFontSize,
                                                          fontWeight: FontWeight.w600,
                                                          color: const Color(0xFF457B9D),
                                                        )
                                                      : GoogleFonts.notoSans(
                                                          fontSize: digitFontSize,
                                                          fontWeight: FontWeight.w600,
                                                          color: const Color(0xFF285B3F),
                                                        ),
                                    )
                                  : SudokuMemoNotesGrid(
                                      notes: notes,
                                      highlightedNote: highlightedMemo,
                                      isSingleCandidate: isSingleCandidateCell,
                                      isHiddenSingleCandidate:
                                          isHiddenSingleForHighlightedMemo,
                                      cellExtent: memoCellExtent,
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
      },
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
}
