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
    this.eraseActive = const {},
    this.hintAppliedActive = const {},
    this.digitCompleteActive = const {},
    this.showCompletionGlow = false,
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

  // 지우기 직후 빈칸 강조('$row,$col' 키, 항상 최대 1개 true).
  final Map<String, bool> eraseActive;

  // 힌트로 채운 칸 강조('$row,$col' 키, 항상 최대 1개 true).
  final Map<String, bool> hintAppliedActive;

  // 숫자 1~9 완료 반응: 방금 다 채워진 숫자가 들어간 모든 칸을 짧게
  // 옅은 색으로 강조한다('$row,$col' 키).
  final Map<String, bool> digitCompleteActive;

  // 퍼즐 완료 연출: 결과 다이얼로그가 뜨기 직전 잠깐(≈500ms, 동작 줄이기는
  // ≈100ms) 보드 전체에 겹쳐 그리는 완료 강조. true인 동안만 마운트된다.
  final bool showCompletionGlow;

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
    final eraseHighlightColor = isDark
        ? const Color(0xFF3A4145).withValues(alpha: 0.72)
        : const Color(0xFFDCE4E8).withValues(alpha: 0.82);
    // 힌트로 채운 칸 강조: 보드 안 힌트 숫자 색(파란 계열)과 어울리되 배경으로
    // 쓰기엔 채도를 낮춘 톤. 정답(민트)·오답(핑크)·줄 완성(노랑)·되돌리기(보라)와
    // 겹치지 않는 별도 키로 관리한다.
    final hintAppliedColor = isDark
        ? const Color(0xFF2E4A57).withValues(alpha: 0.75)
        : const Color(0xFFDCEAF0);
    // 숫자 완료 보드 강조: "옅게"라는 요구대로 되돌리기 강조보다도 연한
    // 보라. 방금 입력한 칸의 정답 강조(민트)와 같은 칸에서 겹쳐도, 그쪽이
    // 렌더링 우선순위상 먼저 보이므로 이 옅은 색이 튀지 않는다.
    final digitCompleteColor = isDark
        ? levelPalette.primaryPurple.withValues(alpha: 0.16)
        : levelPalette.primaryPurple.withValues(alpha: 0.12);
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
                    final isEraseActive = eraseActive['$row,$col'] == true;
                    final isHintApplied =
                        hintAppliedActive['$row,$col'] == true;
                    final isDigitComplete =
                        digitCompleteActive['$row,$col'] == true;
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
                                                          : isEraseActive
                                                              ? eraseHighlightColor
                                                              : isDigitComplete
                                                                  ? digitCompleteColor
                                                                  : Colors
                                                                      .transparent,
                                    ),
                                  ),
                                  Center(
                                    child: value != 0
                                        ? _buildDigitText(
                                            value: value,
                                            isWrong: isWrong,
                                            isFixed: isFixed,
                                            isHint: isHint,
                                            digitFontSize: digitFontSize,
                                            digitOnBoard: digitOnBoard,
                                            userNumberColor:
                                                context.colors.boardUserNumber,
                                            playPopIn: isWave && !reduceMotion,
                                            row: row,
                                            col: col,
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
            if (showCompletionGlow)
              Positioned.fill(
                child: IgnorePointer(
                  child: _PuzzleCompleteOverlay(
                    key: const ValueKey('puzzle-complete-overlay'),
                    color: levelPalette.primaryPurple,
                    reduceMotion: reduceMotion,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 칸에 채워진 숫자 텍스트. [playPopIn]이 true면(방금 정답을 입력한 칸,
  /// 동작 줄이기 아님) `0.92 → 1.06 → 1.0`으로 한 번 튀는 등장 애니메이션을
  /// 180ms 동안 재생하고, 그 외에는 애니메이션 없이 그대로 보여준다. 이미
  /// 채워져 있던 숫자나 고정 숫자는 [playPopIn]이 항상 false로 들어와
  /// 재생되지 않는다(호출부에서 isWave로만 판단).
  Widget _buildDigitText({
    required int value,
    required bool isWrong,
    required bool isFixed,
    required bool isHint,
    required double digitFontSize,
    required Color digitOnBoard,
    required Color userNumberColor,
    required bool playPopIn,
    required int row,
    required int col,
  }) {
    final text = Text(
      value.toString(),
      style: isWrong
          ? AppTheme.sudokuWrongNumberStyle.copyWith(fontSize: digitFontSize)
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
                      color: userNumberColor,
                    ),
    );
    if (!playPopIn) {
      return text;
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey('cell-pop-$row-$col'),
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 180),
      curve: const _PopScaleCurve(),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: text,
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

/// 숫자 입력 팝 애니메이션 전용 커브: `TweenAnimationBuilder(begin: 0.92,
/// end: 1.0)`와 함께 쓰여 0.92 → (커브가 만드는 오버슛으로) 약 1.06 →
/// 1.0으로 보이게 한다. t=0.55 부근에서 최고점(1.75)을 찍고 t=1에서
/// 정확히 1.0으로 돌아온다 — Curve 계약(transform(1) == 1)을 지키므로
/// 최종 값은 항상 [Tween]의 end와 같다.
class _PopScaleCurve extends Curve {
  const _PopScaleCurve();

  static const double _peakAt = 0.55;
  static const double _peakValue = 1.75;

  @override
  double transform(double t) {
    if (t <= _peakAt) {
      final p = t / _peakAt;
      return Curves.easeOut.transform(p) * _peakValue;
    }
    final p = (t - _peakAt) / (1 - _peakAt);
    return _peakValue - Curves.easeInOut.transform(p) * (_peakValue - 1);
  }
}

/// 퍼즐 완료 연출: 결과 다이얼로그가 뜨기 직전 잠깐 보드 위에 겹쳐 그리는
/// 완료 강조. 마운트되는 즉시 한 번만 재생하고(부모가 지속 시간이 지나면
/// 위젯 자체를 내려서 끝낸다), 동작 줄이기에서는 파동 없이 짧은 단색
/// 강조만 보여준다.
class _PuzzleCompleteOverlay extends StatelessWidget {
  const _PuzzleCompleteOverlay({
    super.key,
    required this.color,
    required this.reduceMotion,
  });

  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: GameEffectsController.puzzleCompleteGlowDurationReduced,
        builder: (context, t, child) {
          // 0→1→0 삼각파 한 번: 색만 짧게 밝아졌다 사라진다(이동·확산 없음).
          final opacity = t < 0.5 ? t * 2 : (1 - t) * 2;
          return IgnorePointer(
            child: Container(color: color.withValues(alpha: opacity * 0.22)),
          );
        },
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GameEffectsController.puzzleCompleteGlowDuration,
      curve: Curves.easeOut,
      builder: (context, t, child) {
        // 글로우: 중앙에서 바깥으로 반경이 커지며 0→peak→0으로 밝아졌다 사라짐.
        final glowOpacity =
            (t < 0.35 ? t / 0.35 : (1 - t) / 0.65).clamp(0.0, 1.0).toDouble();
        final glowRadius = 0.15 + t * 1.25;
        // 3×3 박스 경계 강조: 글로우보다 살짝 늦게 나타났다 먼저 사라진다.
        final boxT = ((t - 0.2) / 0.55).clamp(0.0, 1.0);
        final boxOpacity =
            (boxT < 0.5 ? boxT * 2 : (1 - boxT) * 2).clamp(0.0, 1.0);

        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: glowRadius,
                    colors: [
                      color.withValues(alpha: glowOpacity * 0.30),
                      color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            if (boxOpacity > 0)
              Opacity(
                opacity: boxOpacity,
                child: CustomPaint(
                  painter: _BoxBoundaryPainter(color: color),
                  size: Size.infinite,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 3×3 박스 경계(내부 구분선 4개)만 강조해서 그린다. 셀 격자 자체의 얇은
/// 보더와 겹쳐도 자연스럽도록 두껍고 약간 반투명한 선을 쓴다.
class _BoxBoundaryPainter extends CustomPainter {
  const _BoxBoundaryPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 2.5;
    for (final fraction in [1 / 3, 2 / 3]) {
      final x = size.width * fraction;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      final y = size.height * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoxBoundaryPainter oldDelegate) =>
      oldDelegate.color != color;
}
