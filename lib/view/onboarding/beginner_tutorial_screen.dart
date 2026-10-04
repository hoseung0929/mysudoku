import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/beginner_tutorial_puzzle.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/services/onboarding/beginner_tutorial_service.dart';
import 'package:sudoku159/theme/app_colors.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/sudoku_hint_finder.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_board_grid.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_hint_panel.dart';
import 'package:sudoku159/widgets/progressive_blur_button.dart';

enum _TutorialStep { rules, input, memo, hint, done }

enum _RuleRegion { row, column, box }

const _tutorialLevel = SudokuLevel(
  name: 'beginner_tutorial_practice',
  description: 'Beginner tutorial practice puzzle',
  difficulty: 1,
  emptyCells: 3,
  gameCount: 0,
);

/// 초보자용 첫 게임 가이드(연습 퍼즐). 실제 게임과 같은 보드(`SudokuBoardGrid`)·
/// 힌트 패널(`SudokuHintPanel`)·로직(`SudokuGamePresenter`)을 그대로 재사용하고,
/// 숫자패드와 액션 버튼도 실제 게임과 같은 모양(3×3 숫자패드, 원형 액션 버튼)으로
/// 보여 준다. 고정된 연습 퍼즐로만 동작하며 일반 기록·연속 일수·저장 게임에는
/// 전혀 반영되지 않는다(그런 서비스 자체를 호출하지 않음).
class BeginnerTutorialScreen extends StatefulWidget {
  const BeginnerTutorialScreen({
    super.key,
    this.tutorialService,
    this.isReplay = false,
  });

  final BeginnerTutorialService? tutorialService;

  /// 설정 화면의 "다시 보기"로 열렸으면 true. 이 경우 완료 버튼은 원래 문제를
  /// 여는 대신 화면을 닫기만 한다(호출부가 puzzle을 열지 않으므로).
  final bool isReplay;

  @override
  State<BeginnerTutorialScreen> createState() => _BeginnerTutorialScreenState();
}

class _BeginnerTutorialScreenState extends State<BeginnerTutorialScreen> {
  late final BeginnerTutorialService _tutorialService =
      widget.tutorialService ?? BeginnerTutorialService();
  late final SudokuGamePresenter _presenter;

  _TutorialStep _step = _TutorialStep.rules;
  _RuleRegion _ruleRegion = _RuleRegion.row;
  bool _showWrongInputHint = false;
  bool _memoNoteAdded = false;
  SudokuHint? _activeHint;
  int _hintStep = 1;
  bool _finished = false;

  /// 안내 카드의 고정 높이. 단계가 바뀌어도 보드·조작부 위치가 움직이지 않게 한다.
  static const double _guideCardHeight = 164;

  static final Map<_RuleRegion, Set<int>> _ruleCells = {
    _RuleRegion.row: {for (var c = 0; c < 9; c++) 1 * 9 + c},
    _RuleRegion.column: {for (var r = 0; r < 9; r++) r * 9 + 1},
    _RuleRegion.box: {
      for (var r = 0; r < 3; r++)
        for (var c = 3; c < 6; c++) r * 9 + c,
    },
  };

  @override
  void initState() {
    super.initState();
    _presenter = SudokuGamePresenter(
      level: _tutorialLevel,
      onBoardChanged: (_) => setState(() {}),
      onFixedNumbersChanged: (_) {},
      onWrongNumbersChanged: (_) {},
      onTimeChanged: (_) {},
      onPauseStateChanged: (_) {},
      onGameCompleteChanged: (_) {},
      onWrongCountChanged: (_) {},
      onGameOver: () {},
      onCorrectAnswer: _handleCorrectAnswer,
      onIncorrectAnswer: _handleIncorrectAnswer,
      puzzleBoard: BeginnerTutorialPuzzle.board,
      initialBoard: BeginnerTutorialPuzzle.board,
      solution: BeginnerTutorialPuzzle.solution,
      // 연습용: 실제 실수 제한·힌트 차감과 완전히 무관하게 동작하도록 사실상
      // 무제한으로 둔다.
      maxHints: 999,
      maxWrongCount: 999999,
    );
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  void _handleCorrectAnswer(int row, int col) {
    if (_step == _TutorialStep.input &&
        row == BeginnerTutorialPuzzle.inputRow &&
        col == BeginnerTutorialPuzzle.inputCol) {
      _enterStep(_TutorialStep.memo);
    }
  }

  void _handleIncorrectAnswer(int row, int col) {
    if (_step == _TutorialStep.input) {
      setState(() => _showWrongInputHint = true);
    }
  }

  /// 단계 전환. 학습 목적상 칸 선택과 메모 모드는 자동으로 켜지 않는다 —
  /// 사용자가 직접 강조된 칸과 메모 버튼을 누르게 한다.
  void _enterStep(_TutorialStep step) {
    setState(() {
      _step = step;
      _showWrongInputHint = false;
      _memoNoteAdded = false;
      _activeHint = null;
      _hintStep = 1;
    });
    if (step == _TutorialStep.input ||
        step == _TutorialStep.memo ||
        step == _TutorialStep.hint) {
      _presenter.clearSelection();
    }
    if (_presenter.isMemoMode) _presenter.toggleMemoMode();
  }

  (int, int)? get _targetCell => switch (_step) {
        _TutorialStep.input => (
            BeginnerTutorialPuzzle.inputRow,
            BeginnerTutorialPuzzle.inputCol
          ),
        _TutorialStep.memo => (
            BeginnerTutorialPuzzle.memoRow,
            BeginnerTutorialPuzzle.memoCol
          ),
        _ => null,
      };

  bool get _targetSelected {
    final target = _targetCell;
    return target != null &&
        _presenter.selectedRow == target.$1 &&
        _presenter.selectedCol == target.$2;
  }

  void _onCellTapped(int row, int col) {
    final target = _targetCell;
    if (target == null) return;
    if (row != target.$1 || col != target.$2) return;
    _presenter.selectCell(row, col);
  }

  void _onNumberTapped(int number) {
    // 칸을 직접 선택해야 입력되고, 메모 단계에서는 메모 버튼을 켜야 후보가 적힌다.
    if (!_targetSelected) return;
    if (_step == _TutorialStep.memo && !_presenter.isMemoMode) return;
    _presenter.setSelectedCellValue(number);
    if (_step == _TutorialStep.memo) {
      final notes = _presenter.getCellNotes(
        BeginnerTutorialPuzzle.memoRow,
        BeginnerTutorialPuzzle.memoCol,
      );
      if (notes.isNotEmpty) {
        setState(() => _memoNoteAdded = true);
      } else if (_memoNoteAdded && notes.isEmpty) {
        _enterStep(_TutorialStep.hint);
      }
    }
  }

  void _toggleMemo() {
    if (_step != _TutorialStep.memo) return;
    setState(_presenter.toggleMemoMode);
  }

  void _openHint() {
    if (_step != _TutorialStep.hint) return;
    final hint = SudokuHintFinder.find(
      board: _presenter.boardSnapshot,
      solution: _presenter.solutionSnapshot,
      selectedRow: BeginnerTutorialPuzzle.hintRow,
      selectedCol: BeginnerTutorialPuzzle.hintCol,
    );
    if (hint == null) return;
    setState(() {
      _activeHint = hint;
      _hintStep = 1;
    });
  }

  void _fillHint() {
    final hint = _activeHint;
    if (hint == null) return;
    _presenter.revealHintAt(hint.row, hint.col);
    _enterStep(_TutorialStep.done);
  }

  /// 설정에서 다시 보기(`isReplay`)로 열렸으면 완료 여부와 무관하게 기존
  /// 저장된 가이드 상태를 그대로 둔다. 최초 자동 가이드일 때만 실제로
  /// 완료/건너뜀 상태를 기록한다.
  Future<void> _finish({required bool completed}) async {
    if (_finished) return;
    _finished = true;
    if (!widget.isReplay) {
      if (completed) {
        await _tutorialService.markCompleted();
      } else {
        await _tutorialService.markDismissed();
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  ({String title, String body, Set<int> region}) _stepContent(
    AppLocalizations l10n,
  ) {
    switch (_step) {
      case _TutorialStep.rules:
        return (
          title: l10n.beginnerTutorialStepRulesTitle,
          body: l10n.beginnerTutorialStepRulesBody,
          region: _ruleCells[_ruleRegion]!,
        );
      case _TutorialStep.input:
        return (
          title: l10n.beginnerTutorialStepInputTitle,
          body: _showWrongInputHint
              ? l10n.beginnerTutorialStepInputWrongHint
              : l10n.beginnerTutorialStepInputBody,
          region: {
            BeginnerTutorialPuzzle.inputRow * 9 +
                BeginnerTutorialPuzzle.inputCol,
          },
        );
      case _TutorialStep.memo:
        return (
          title: l10n.beginnerTutorialStepMemoTitle,
          body: _memoNoteAdded
              ? l10n.beginnerTutorialStepMemoEraseBody
              : l10n.beginnerTutorialStepMemoAddBody,
          region: {
            BeginnerTutorialPuzzle.memoRow * 9 + BeginnerTutorialPuzzle.memoCol,
          },
        );
      case _TutorialStep.hint:
        return (
          title: l10n.beginnerTutorialStepHintTitle,
          body: l10n.beginnerTutorialStepHintBody,
          region: {
            BeginnerTutorialPuzzle.hintRow * 9 + BeginnerTutorialPuzzle.hintCol,
          },
        );
      case _TutorialStep.done:
        return (
          title: l10n.beginnerTutorialStepDoneTitle,
          body: l10n.beginnerTutorialStepDoneBody,
          region: const {},
        );
    }
  }

  int get _stepNumber => _TutorialStep.values.indexOf(_step) + 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final isTabletLandscape = mediaQuery.size.width > 600 &&
        mediaQuery.orientation == Orientation.landscape;
    final textColor = context.colors.textPrimary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_finish(completed: false));
      },
      child: Scaffold(
        backgroundColor: context.colors.surface,
        appBar: AppBar(
          toolbarHeight: 50,
          backgroundColor: context.colors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            l10n.beginnerTutorialPracticeTitle,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          leadingWidth: 52,
          leading: IconButton(
            icon: const Icon(Icons.close),
            visualDensity: VisualDensity.compact,
            tooltip: l10n.beginnerTutorialSkip,
            onPressed: () => _finish(completed: false),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Semantics(
                  label: l10n.beginnerTutorialStepIndicator(
                    _stepNumber,
                    _TutorialStep.values.length,
                  ),
                  excludeSemantics: true,
                  child: Text(
                    l10n.beginnerTutorialStepIndicator(
                      _stepNumber,
                      _TutorialStep.values.length,
                    ),
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => isTabletLandscape
                ? _buildLandscape(context, l10n, constraints)
                : _buildPortrait(context, l10n, constraints),
          ),
        ),
      ),
    );
  }

  Widget _board(double size) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: size,
      height: size,
      child: SudokuBoardGrid(
        presenter: _presenter,
        waveActive: const {},
        lineCompleteActive: const {},
        errorActive: const {},
        errorOffset: const {},
        onCellTapped: _onCellTapped,
        hintRegionCells: _stepContent(l10n).region,
      ),
    );
  }

  Widget _buildPortrait(
    BuildContext context,
    AppLocalizations l10n,
    BoxConstraints constraints,
  ) {
    final maxWidth = constraints.maxWidth;
    final maxHeight = constraints.maxHeight;
    final horizontalPadding = (maxWidth * 0.015).clamp(4.0, 8.0);
    final contentWidth = maxWidth - horizontalPadding * 2;
    const numberGap = 5.0;
    const sectionGap = 8.0;
    final actionSize = ((contentWidth - 4 * 14) / 6).clamp(36.0, 70.0);
    const numberHeight = 48.0;
    final controlsHeight = numberHeight * 3 +
        numberGap * 4 +
        sectionGap +
        actionSize +
        8; // 숫자패드 + 액션 행
    final boardMax = contentWidth.clamp(256.0, 680.0);
    final boardSize =
        (maxHeight - _guideCardHeight - controlsHeight - sectionGap * 3 - 12)
            .clamp(256.0, boardMax);
    final numberWidth = (boardSize - numberGap * 3) / 3;

    final content = Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
      child: Column(
        children: [
          _board(boardSize),
          const SizedBox(height: sectionGap),
          SizedBox(
            width: boardSize,
            child: _hintOr(
              height: _guideCardHeight + sectionGap + controlsHeight,
              child: Column(
                children: [
                  _guideCard(context, l10n, _guideCardHeight),
                  const SizedBox(height: sectionGap),
                  _controls(
                    numberWidth: numberWidth,
                    numberHeight: numberHeight,
                    numberGap: numberGap,
                    actionSize: actionSize,
                    gap: sectionGap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    // 일반 휴대폰에서는 한 화면에 고정하고, 작은 화면·큰 글씨에서만 스크롤한다.
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: maxHeight),
        child: Align(alignment: Alignment.topCenter, child: content),
      ),
    );
  }

  Widget _buildLandscape(
    BuildContext context,
    AppLocalizations l10n,
    BoxConstraints constraints,
  ) {
    final boardSize = math.min(
      constraints.maxHeight * 0.92,
      constraints.maxWidth * 0.5,
    );
    const numberGap = 5.0;
    const sectionGap = 12.0;
    const actionSize = 64.0;
    final panelWidth = math.min(constraints.maxWidth * 0.4, 420.0);
    final numberWidth = (panelWidth - numberGap * 3) / 3;
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _board(boardSize),
              const SizedBox(width: 24),
              SizedBox(
                width: panelWidth,
                child: _hintOr(
                  height: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _guideCard(context, l10n, _guideCardHeight),
                      const SizedBox(height: sectionGap),
                      _controls(
                        numberWidth: numberWidth,
                        numberHeight: 56,
                        numberGap: numberGap,
                        actionSize: actionSize,
                        gap: sectionGap,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 힌트 패널이 열려 있으면 안내 카드+조작부 자리를 대신 쓴다(실제 게임에서도
  /// 숫자패드 자리를 대체한다). 유한한 높이를 가정하므로 고정 높이를 준다.
  Widget _hintOr({required double height, required Widget child}) {
    final hint = _activeHint;
    if (hint == null) return child;
    return SizedBox(
      height: height,
      child: SudokuHintPanel(
        hint: hint,
        step: _hintStep,
        onNext: () => setState(() => _hintStep = 2),
        onFill: _fillHint,
        onClose: () => setState(() => _activeHint = null),
      ),
    );
  }

  Widget _guideCard(
      BuildContext context, AppLocalizations l10n, double height) {
    final content = _stepContent(l10n);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final colors = context.colors;
    return Semantics(
      liveRegion: true,
      container: true,
      label: '${content.title}. ${content.body}',
      child: Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topLeft,
            children: [...previous, if (current != null) current],
          ),
          child: SingleChildScrollView(
            key: ValueKey('$_step-$_showWrongInputHint-$_memoNoteAdded'),
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ExcludeSemantics(
                        child: Text(
                          content.title,
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (_step == _TutorialStep.rules)
                      FilledButton(
                        onPressed: () => _enterStep(_TutorialStep.input),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(64, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(l10n.beginnerTutorialNextButton),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                ExcludeSemantics(
                  child: Text(
                    content.body,
                    style: GoogleFonts.notoSans(
                      fontSize: 13.5,
                      height: 1.35,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (_step == _TutorialStep.rules) ...[
                  const SizedBox(height: 10),
                  _ruleSelector(l10n),
                ],
                if (_step == _TutorialStep.done) ...[
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => _finish(completed: true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: Text(
                      widget.isReplay
                          ? l10n.beginnerTutorialCloseButton
                          : l10n.beginnerTutorialFirstPuzzleButton,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ruleSelector(AppLocalizations l10n) {
    final labels = {
      _RuleRegion.row: l10n.beginnerTutorialRuleRow,
      _RuleRegion.column: l10n.beginnerTutorialRuleColumn,
      _RuleRegion.box: l10n.beginnerTutorialRuleBox,
    };
    final colors = context.colors;
    return Row(
      children: [
        for (final region in _RuleRegion.values) ...[
          if (region != _RuleRegion.row) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              selected: _ruleRegion == region,
              child: GestureDetector(
                key: ValueKey('tutorial-rule-${region.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _ruleRegion = region),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 36),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: _ruleRegion == region
                        ? AppTheme.lightBlueColor.withValues(alpha: 0.22)
                        : colors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _ruleRegion == region
                          ? AppTheme.lightBlueColor
                          : colors.borderLight,
                      width: _ruleRegion == region ? 1.6 : 1,
                    ),
                  ),
                  child: Text(
                    labels[region]!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: _ruleRegion == region
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  int _remainingCount(int number) {
    var placed = 0;
    for (final row in _presenter.boardSnapshot) {
      for (final value in row) {
        if (value == number) placed++;
      }
    }
    return (9 - placed).clamp(0, 9);
  }

  /// 실제 게임과 같은 3×3 숫자패드 + 되돌리기·메모·힌트·지우기 원형 버튼.
  /// 현재 단계에 필요한 버튼만 활성화한다.
  Widget _controls({
    required double numberWidth,
    required double numberHeight,
    required double numberGap,
    required double actionSize,
    required double gap,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final numbersEnabled =
        _step == _TutorialStep.input || _step == _TutorialStep.memo;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var j = 1; j <= 3; j++)
                Padding(
                  padding: EdgeInsets.all(numberGap / 2),
                  child: _numberButton(
                    i * 3 + j,
                    width: numberWidth,
                    height: numberHeight,
                    enabled: numbersEnabled,
                  ),
                ),
            ],
          ),
        SizedBox(height: gap),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _actionButton(
              icon: Icons.undo_rounded,
              label: l10n.gameUndoShort,
              color: AppTheme.lightBlueColor,
              size: actionSize,
              onPressed: null,
            ),
            _actionButton(
              icon: Icons.edit_note,
              label: _presenter.isMemoMode
                  ? l10n.gameMemoOnShort
                  : l10n.gameMemoShort,
              semanticsLabel: l10n.gameMemoShort,
              toggled: _presenter.isMemoMode,
              color: _presenter.isMemoMode
                  ? AppTheme.mintColor
                  : AppTheme.lightBlueColor,
              isActive: _presenter.isMemoMode,
              size: actionSize,
              onPressed: _step == _TutorialStep.memo ? _toggleMemo : null,
            ),
            _actionButton(
              icon: Icons.lightbulb_outline,
              label: l10n.gameHintShort,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF8A6820)
                  : AppTheme.yellowColor,
              size: actionSize,
              onPressed: _step == _TutorialStep.hint ? _openHint : null,
            ),
            _actionButton(
              icon: Icons.backspace_outlined,
              label: l10n.gameEraseShort,
              color: context.colors.attentionSurface,
              size: actionSize,
              onPressed: null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberButton(
    int number, {
    required double width,
    required double height,
    required bool enabled,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = _remainingCount(number);
    final completed = remaining == 0;
    final background = completed
        ? (isDark ? const Color(0xFF232323) : context.colors.surfaceSubtle)
        : (isDark ? const Color(0xFF323232) : context.colors.surface);
    return MediaQuery.withNoTextScaling(
      child: ProgressiveBlurButton(
        key: ValueKey('tutorial-number-$number'),
        onPressed: enabled ? () => _onNumberTapped(number) : null,
        backgroundColor: background,
        width: width,
        height: height,
        borderRadius: (width * 0.24).clamp(16.0, 28.0),
        enablePressScale: true,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                '$number',
                style: GoogleFonts.notoSans(
                  fontSize: (height * 0.58).clamp(28.0, 34.0),
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2E2E2E)
                      : context.colors.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3E3E3E)
                        : context.colors.borderLight,
                  ),
                ),
                child: completed
                    ? Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: context.colors.textSecondary,
                      )
                    : Text(
                        '$remaining',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textSecondary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required double size,
    required VoidCallback? onPressed,
    bool isActive = false,
    String? semanticsLabel,
    bool? toggled,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentColor = (isActive && isDark)
        ? const Color(0xFF6DCCA0)
        : Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.5),
      child: Semantics(
        container: true,
        button: true,
        enabled: onPressed != null,
        toggled: toggled,
        label: semanticsLabel ?? label,
        excludeSemantics: true,
        onTap: onPressed,
        child: ProgressiveBlurButton(
          onPressed: onPressed,
          width: size,
          height: size,
          borderRadius: size / 2,
          backgroundColor: color,
          isActive: isActive,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: contentColor, size: size * 0.36 - 1),
              const SizedBox(height: 2),
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: size * 0.86),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: GoogleFonts.notoSans(
                        color: contentColor,
                        fontSize: size <= 50 ? 7.5 : 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
