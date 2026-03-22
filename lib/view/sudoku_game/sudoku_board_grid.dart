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
    required this.onCellTapped,
  });

  final SudokuGamePresenter presenter;
  final Map<String, bool> waveActive;
  final Map<String, bool> lineCompleteActive;
  final void Function(int row, int col) onCellTapped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = cs.outlineVariant;
    final relatedFill = Theme.of(context).brightness == Brightness.dark
        ? cs.surfaceContainerHigh
        : Colors.grey.shade100;
    final digitOnBoard = cs.onSurface;

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

                final isWave = waveActive['$row,$col'] == true;
                final isLineComplete = lineCompleteActive['$row,$col'] == true;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onCellTapped(row, col),
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
                        color: isWave
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
                            : SudokuMemoNotesGrid(notes: notes),
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
}
