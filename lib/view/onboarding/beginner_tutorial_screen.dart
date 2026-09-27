import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/beginner_tutorial_puzzle.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/services/onboarding/beginner_tutorial_service.dart';
import 'package:sudoku159/utils/sudoku_hint_finder.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_board_grid.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_hint_panel.dart';

enum _TutorialStep { row, column, box, input, memo, hint, done }

const _tutorialLevel = SudokuLevel(
  name: 'beginner_tutorial_practice',
  description: 'Beginner tutorial practice puzzle',
  difficulty: 1,
  emptyCells: 3,
  gameCount: 0,
);

/// 초보자용 첫 게임 가이드. 실제 게임과 같은 보드(`SudokuBoardGrid`)·
/// 힌트 패널(`SudokuHintPanel`)·로직(`SudokuGamePresenter`)을 그대로 재사용하되,
/// 고정된 연습 퍼즐로만 동작하며 일반 기록·연속 일수·저장 게임에는
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

  _TutorialStep _step = _TutorialStep.row;
  bool _showWrongInputHint = false;
  bool _memoNoteAdded = false;
  SudokuHint? _activeHint;
  int _hintStep = 1;
  bool _finished = false;

  static final Set<int> _rowRegion = {
    for (var c = 0; c < 9; c++) 1 * 9 + c,
  };
  static final Set<int> _columnRegion = {
    for (var r = 0; r < 9; r++) r * 9 + 1,
  };
  static final Set<int> _boxRegion = {
    for (var r = 0; r < 3; r++)
      for (var c = 3; c < 6; c++) r * 9 + c,
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

  void _enterStep(_TutorialStep step) {
    setState(() {
      _step = step;
      _showWrongInputHint = false;
      _memoNoteAdded = false;
      _activeHint = null;
      _hintStep = 1;
    });
    switch (step) {
      case _TutorialStep.input:
        _presenter.selectCell(
          BeginnerTutorialPuzzle.inputRow,
          BeginnerTutorialPuzzle.inputCol,
        );
        break;
      case _TutorialStep.memo:
        if (!_presenter.isMemoMode) _presenter.toggleMemoMode();
        _presenter.selectCell(
          BeginnerTutorialPuzzle.memoRow,
          BeginnerTutorialPuzzle.memoCol,
        );
        break;
      case _TutorialStep.hint:
        _presenter.selectCell(
          BeginnerTutorialPuzzle.hintRow,
          BeginnerTutorialPuzzle.hintCol,
        );
        break;
      default:
        break;
    }
  }

  void _onCellTapped(int row, int col) {
    final target = switch (_step) {
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
    if (target == null) return;
    if (row != target.$1 || col != target.$2) return;
    _presenter.selectCell(row, col);
  }

  void _onNumberTapped(int number) {
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

  void _openHint() {
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
      case _TutorialStep.row:
        return (
          title: l10n.beginnerTutorialStepRowTitle,
          body: l10n.beginnerTutorialStepRowBody,
          region: _rowRegion,
        );
      case _TutorialStep.column:
        return (
          title: l10n.beginnerTutorialStepColumnTitle,
          body: l10n.beginnerTutorialStepColumnBody,
          region: _columnRegion,
        );
      case _TutorialStep.box:
        return (
          title: l10n.beginnerTutorialStepBoxTitle,
          body: l10n.beginnerTutorialStepBoxBody,
          region: _boxRegion,
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final mediaQuery = MediaQuery.of(context);
    final isTabletLandscape = mediaQuery.size.width > 600 &&
        mediaQuery.orientation == Orientation.landscape;

    final panel = _buildPanel(context, l10n, reduceMotion);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_finish(completed: false));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsHowToPlayTitle),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.beginnerTutorialSkip,
            onPressed: () => _finish(completed: false),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boardSize = isTabletLandscape
                  ? math.min(
                      constraints.maxHeight * 0.85, constraints.maxWidth * 0.5)
                  : math.min(constraints.maxWidth * 0.94,
                      constraints.maxHeight * 0.55);
              final board = Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: SudokuBoardGrid(
                    presenter: _presenter,
                    waveActive: const {},
                    lineCompleteActive: const {},
                    errorActive: const {},
                    errorOffset: const {},
                    onCellTapped: _onCellTapped,
                    hintRegionCells: _stepContent(l10n).region,
                  ),
                ),
              );
              return SingleChildScrollView(
                child: isTabletLandscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          board,
                          Expanded(child: panel),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          board,
                          panel,
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context,
    AppLocalizations l10n,
    bool reduceMotion,
  ) {
    final content = _stepContent(l10n);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      label:
          '${l10n.beginnerTutorialStepIndicator(_stepNumber, _TutorialStep.values.length)}. '
          '${content.title}. ${content.body}',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.beginnerTutorialStepIndicator(
                _stepNumber,
                _TutorialStep.values.length,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              child: Column(
                key: ValueKey(_step),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(content.body),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildStepControls(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildStepControls(BuildContext context, AppLocalizations l10n) {
    switch (_step) {
      case _TutorialStep.row:
        return _nextButton(l10n, () => _enterStep(_TutorialStep.column));
      case _TutorialStep.column:
        return _nextButton(l10n, () => _enterStep(_TutorialStep.box));
      case _TutorialStep.box:
        return _nextButton(l10n, () => _enterStep(_TutorialStep.input));
      case _TutorialStep.input:
      case _TutorialStep.memo:
        return _numberPad(l10n);
      case _TutorialStep.hint:
        return _activeHint == null
            ? FilledButton(
                onPressed: _openHint,
                child: Text(l10n.beginnerTutorialStepHintButton),
              )
            // SudokuHintPanel은 유한한 높이를 가정하므로(실제 게임에서도 숫자패드
            // 자리를 대체하는 고정 영역), 스크롤 뷰 안에서도 무한 높이가 되지
            // 않도록 고정 높이를 준다.
            : SizedBox(
                height: 280,
                child: SudokuHintPanel(
                  hint: _activeHint!,
                  step: _hintStep,
                  onNext: () => setState(() => _hintStep = 2),
                  onFill: _fillHint,
                  onClose: () => setState(() => _activeHint = null),
                ),
              );
      case _TutorialStep.done:
        return FilledButton(
          onPressed: () => _finish(completed: true),
          child: Text(
            widget.isReplay
                ? l10n.beginnerTutorialCloseButton
                : l10n.beginnerTutorialFirstPuzzleButton,
          ),
        );
    }
  }

  Widget _nextButton(AppLocalizations l10n, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(l10n.beginnerTutorialNextButton),
      ),
    );
  }

  Widget _numberPad(AppLocalizations l10n) {
    final isMemo = _presenter.isMemoMode;
    return Column(
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var n = 1; n <= 9; n++)
              SizedBox(
                width: 40,
                height: 40,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => _onNumberTapped(n),
                  child: Text('$n'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _presenter.toggleMemoMode();
              }),
              icon: Icon(
                Icons.edit_note,
                color: isMemo ? Theme.of(context).colorScheme.primary : null,
              ),
              label: Text(l10n.gameMemoShort),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _presenter.eraseSelectedCell();
              }),
              icon: const Icon(Icons.backspace_outlined),
              label: Text(l10n.gameEraseShort),
            ),
          ],
        ),
      ],
    );
  }
}
