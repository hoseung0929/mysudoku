import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/theme/app_colors.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/view/sudoku_game/game_effects_controller.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_memo_notes_grid.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_pencil_input_overlay.dart';

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
    this.onPencilDigit,
    this.hintRegionCells = const {},
    this.hintBlockerCells = const {},
    this.hintTargetCell,
    this.undoActive = const {},
    this.hintAppliedActive = const {},
  });

  final SudokuGamePresenter presenter;
  final Map<String, bool> waveActive;
  final Map<String, bool> lineCompleteActive;
  final Map<String, bool> errorActive;
  final Map<String, double> errorOffset;
  final bool enableMemoHighlights;
  final int? highlightedMemoNumber;
  final void Function(int row, int col) onCellTapped;
  // 아이패드 애플펜슬 필기 입력 콜백 (선택 사항). null이면(기본값, 아이폰
  // 호출부) 오버레이 자체를 만들지 않아 기존 동작과 완전히 동일하다.
  final void Function(int digit)? onPencilDigit;

  // 힌트 설명 중 강조할 칸(칸 번호 = row * 9 + col). 비어 있으면 평소와 같다.
  final Set<int> hintRegionCells;
  final Set<int> hintBlockerCells;
  final int? hintTargetCell;

  // 되돌리기 결과 칸 강조('$row,$col' 키, 항상 최대 1개 true).
  final Map<String, bool> undoActive;

  // 힌트로 채운 칸 강조('$row,$col' 키, 항상 최대 1개 true).
  final Map<String, bool> hintAppliedActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelPalette = LevelStatusPalette.of(context);
    // ── 보드 라인 색상 ─────────────────────────────────────────────
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : context.colors.border;
    final borderColorStrong =
        isDark ? const Color(0xFF444444) : context.colors.border;
    final boardOutlineColor =
        isDark ? const Color(0xFF4A4A4A) : context.colors.border;
    // ── 셀 하이라이트 색상 (다크/라이트 분기) ──────────────────────
    final selectedCellColor = isDark
        ? levelPalette.primaryPurple.withValues(alpha: 0.25)
        : levelPalette.primaryPurple.withValues(alpha: 0.14);
    final sameNumberColor = isDark
        ? const Color(0xFF304050)
        : AppTheme.lightBlueColor.withValues(alpha: 0.14);
    final relatedFill =
        isDark ? const Color(0xFF242A30) : context.colors.surfaceSubtle;
    final wrongCellColor = isDark
        ? const Color(0xFF4A2525)
        : AppTheme.pinkColor.withValues(alpha: 0.18);
    final errorActiveCellColor = isDark
        ? const Color(0xFF5A2828)
        : AppTheme.pinkColor.withValues(alpha: 0.28);
    final waveCellColor = isDark
        ? const Color(0xFF2A3A2E)
        : AppTheme.mintColor.withValues(alpha: 0.22);
    final lineCompleteCellColor = isDark
        ? const Color(0xFF3A3020)
        : AppTheme.yellowColor.withValues(alpha: 0.26);
    final hiddenSingleColor = isDark
        ? const Color(0xFF2B3F50)
        : AppTheme.lightBlueColor.withValues(alpha: 0.24);
    final memoHighlightColor = isDark
        ? const Color(0xFF263040)
        : AppTheme.lightBlueColor.withValues(alpha: 0.14);
    final singleCandidateColor = isDark
        ? const Color(0xFF3A3020)
        : AppTheme.yellowColor.withValues(alpha: 0.16);
    final hintRegionColor =
        isDark ? const Color(0xFF3A331C) : const Color(0xFFFFF0C2);
    final hintBlockerColor =
        isDark ? const Color(0xFF6A5520) : const Color(0xFFF6CD5C);
    const hintTargetBorderColor = Color(0xFFE0A526);
    // 되돌리기 강조: 선택 배경(0.14~0.25)보다 진하지만 정답·오답 강조보다
    // 세지 않은 옅은 보라. 정답·오답·줄 완성 색과 겹치지 않는 별도 키로 관리한다.
    final undoHighlightColor = isDark
        ? levelPalette.primaryPurple.withValues(alpha: 0.32)
        : levelPalette.primaryPurple.withValues(alpha: 0.24);
    // 힌트로 채운 칸 강조: 보드 안 힌트 숫자 색(파란 계열)과 어울리되 배경으로
    // 쓰기엔 채도를 낮춘 톤. 정답(민트)·오답(핑크)·줄 완성(노랑)·되돌리기(보라)와
    // 겹치지 않는 별도 키로 관리한다.
    final hintAppliedColor = isDark
        ? const Color(0xFF2E4A57).withValues(alpha: 0.75)
        : const Color(0xFFDCEAF0);
    final isHintActive = hintRegionCells.isNotEmpty;
    final digitOnBoard = cs.onSurface;
    final selectedRow = presenter.selectedRow;
    final selectedCol = presenter.selectedCol;
    final selectedValue = selectedRow == null || selectedCol == null
        ? 0
        : presenter.getCellValue(selectedRow, selectedCol);
    final highlightedMemo = enableMemoHighlights
        ? (selectedValue == 0 ? highlightedMemoNumber : selectedValue)
        : null;

    // 동작 줄이기: 선택·정답·오답 상태를 즉시 반영하고 이동은 만들지 않는다
    // (흔들림 자체는 컨트롤러가 오프셋을 채우지 않아 이미 생략된다).
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final baseTransitionDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 90);
    final effectTransitionDuration =
        reduceMotion ? Duration.zero : GameEffectsController.effectFadeDuration;
    // 힌트 영역·블로커 강조 전용(공통 모션 규칙의 "선택 상태 변경" 범위,
    // 120~160ms). 선택 등 기본 배경(baseTransitionDuration, 100ms 이내)과는
    // 별개 레이어라 서로의 속도를 바꾸지 않는다.
    final hintTransitionDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 140);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellExtent = constraints.maxWidth / 9;
        final digitFontSize = (cellExtent * 0.62).clamp(18.0, 34.0);
        final memoCellExtent = (cellExtent * 0.54).clamp(10.0, 16.0);

        final board = Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            border:
                Border.all(color: boardOutlineColor, width: isDark ? 1.2 : 1.0),
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
                    final cellIndex = row * 9 + col;
                    final isHintRegion = hintRegionCells.contains(cellIndex);
                    final isHintBlocker = hintBlockerCells.contains(cellIndex);
                    final isHintTarget = hintTargetCell == cellIndex;
                    // 힌트 중에는 선택 칸 주변 강조를 끄고 힌트 영역만 보여 준다.
                    final isRelated =
                        !isHintActive && presenter.isRelated(row, col);
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
                    final isLineComplete =
                        lineCompleteActive['$row,$col'] == true;
                    final isErrorActive = errorActive['$row,$col'] == true;
                    final isUndoActive = undoActive['$row,$col'] == true;
                    final isHintApplied =
                        hintAppliedActive['$row,$col'] == true;
                    final horizontalOffset = errorOffset['$row,$col'] ?? 0.0;

                    final l10n = AppLocalizations.of(context)!;
                    final content = value != 0
                        ? '$value'
                        : notes.isEmpty
                            ? l10n.gameCellEmpty
                            : l10n.gameCellNotes(
                                (notes.toList()..sort()).join(', '));
                    final cellLabel = [
                      l10n.gameCellLabel(row + 1, col + 1, content),
                      if (isFixed) l10n.gameCellGiven,
                      if (isHint) l10n.gameCellHint,
                      if (isWrong) l10n.gameCellWrong,
                    ].join(', ');

                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: cellLabel,
                        excludeSemantics: true,
                        onTap: () => onCellTapped(row, col),
                        child: GestureDetector(
                          onTap: () => onCellTapped(row, col),
                          // 흔들림은 자식 크기에 비례하는 AnimatedSlide 대신
                          // 실제 픽셀 값을 그대로 옮겨, 칸 크기가 달라지는
                          // 아이폰·아이패드에서 이동 폭이 항상 동일하게 한다.
                          // 키프레임을 그대로 반영하므로 별도 보간은 두지
                          // 않는다(취소·종료 시 오프셋이 0으로 즉시 복귀).
                          child: Transform.translate(
                            offset: Offset(horizontalOffset, 0),
                            child: AnimatedContainer(
                              key: ValueKey('cell-base-$row-$col'),
                              duration: baseTransitionDuration,
                              curve: Curves.easeOut,
                              // 성공·오답 강조가 선택 배경색을 덮어도 선택 칸은 테두리로 남긴다.
                              foregroundDecoration: isHintTarget
                                  ? BoxDecoration(
                                      border: Border.all(
                                        color: hintTargetBorderColor,
                                        width: 2.5,
                                      ),
                                    )
                                  : isSelected &&
                                          (isWave ||
                                              isLineComplete ||
                                              isErrorActive)
                                      ? BoxDecoration(
                                          border: Border.all(
                                            color: levelPalette.primaryPurple,
                                            width: 2,
                                          ),
                                        )
                                      : null,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: (row == 0 || row == 3 || row == 6)
                                        ? borderColorStrong
                                        : borderColor,
                                    width: (row == 0 || row == 3 || row == 6)
                                        ? 1.2
                                        : 0.35,
                                  ),
                                  left: BorderSide(
                                    color: (col == 0 || col == 3 || col == 6)
                                        ? borderColorStrong
                                        : borderColor,
                                    width: (col == 0 || col == 3 || col == 6)
                                        ? 1.2
                                        : 0.35,
                                  ),
                                  right: BorderSide(
                                    color: (col == 2 || col == 5 || col == 8)
                                        ? borderColorStrong
                                        : borderColor,
                                    width: (col == 2 || col == 5 || col == 8)
                                        ? 1.2
                                        : 0.35,
                                  ),
                                  bottom: BorderSide(
                                    color: (row == 2 || row == 5 || row == 8)
                                        ? borderColorStrong
                                        : borderColor,
                                    width: (row == 2 || row == 5 || row == 8)
                                        ? 1.2
                                        : 0.35,
                                  ),
                                ),
                                // 성공·오답 강조는 별도의 빠른 오버레이로 그려
                                // 여기서는 선택·오답 확정·관련 칸 등 시간에
                                // 덜 민감한 배경만 담당한다.
                                color: isSelected
                                    ? selectedCellColor
                                    : isWrong
                                        ? wrongCellColor
                                        : isSameNumber
                                            ? sameNumberColor
                                            : isHiddenSingleForHighlightedMemo
                                                ? hiddenSingleColor
                                                : hasHighlightedMemoCandidate
                                                    ? memoHighlightColor
                                                    : isSingleCandidateCell
                                                        ? singleCandidateColor
                                                        : isRelated
                                                            ? relatedFill
                                                            : null,
                              ),
                              child: Stack(
                                children: [
                                  // 힌트 영역·블로커 강조: 선택 등 기본 배경과
                                  // 별개 레이어라 각자의 전환 시간을 그대로
                                  // 지킨다(기본 배경은 100ms 이내, 이 레이어는
                                  // 120~160ms 범위).
                                  Positioned.fill(
                                    child: AnimatedContainer(
                                      key: ValueKey('cell-hint-$row-$col'),
                                      duration: hintTransitionDuration,
                                      curve: Curves.easeOut,
                                      color: isHintBlocker
                                          ? hintBlockerColor
                                          : isHintRegion
                                              ? hintRegionColor
                                              : Colors.transparent,
                                    ),
                                  ),
                                  // 정답·오답·줄 완성 색은 기본 배경과 분리된
                                  // 자신만의 짧은 전환 시간을 써서, 컨트롤러의
                                  // 대기 시간에 위젯 전환 시간이 더해지며 전체
                                  // 지속 시간이 늘어나지 않게 한다.
                                  Positioned.fill(
                                    child: AnimatedContainer(
                                      key: ValueKey('cell-effect-$row-$col'),
                                      duration: effectTransitionDuration,
                                      curve: Curves.easeOut,
                                      color: isErrorActive
                                          ? errorActiveCellColor
                                          : isWave
                                              ? waveCellColor
                                              : isLineComplete
                                                  ? lineCompleteCellColor
                                                  : isHintApplied
                                                      ? hintAppliedColor
                                                      : isUndoActive
                                                          ? undoHighlightColor
                                                          : Colors.transparent,
                                    ),
                                  ),
                                  Center(
                                    child: value != 0
                                        ? Text(
                                            value.toString(),
                                            style: isWrong
                                                ? AppTheme
                                                    .sudokuWrongNumberStyle
                                                    .copyWith(
                                                    fontSize: digitFontSize,
                                                  )
                                                : isFixed
                                                    ? GoogleFonts.notoSans(
                                                        fontSize: digitFontSize,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: digitOnBoard,
                                                      )
                                                    : isHint
                                                        ? GoogleFonts.notoSans(
                                                            fontSize:
                                                                digitFontSize,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: const Color(
                                                                0xFF457B9D),
                                                          )
                                                        : GoogleFonts.notoSans(
                                                            fontSize:
                                                                digitFontSize,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: context
                                                                .colors
                                                                .boardUserNumber,
                                                          ),
                                          )
                                        : SudokuMemoNotesGrid(
                                            notes: notes,
                                            highlightedNote: highlightedMemo,
                                            isSingleCandidate:
                                                isSingleCandidateCell,
                                            isHiddenSingleCandidate:
                                                isHiddenSingleForHighlightedMemo,
                                            cellExtent: memoCellExtent,
                                          ),
                                  ),
                                ],
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

        return Stack(
          children: [
            board,
            if (onPencilDigit != null)
              SudokuPencilInputOverlay(
                selectedRow: selectedRow,
                selectedCol: selectedCol,
                cellExtent: cellExtent,
                onDigitEntered: onPencilDigit!,
              ),
          ],
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
