import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_game_feature_policy.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/theme/app_colors.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/utils/sudoku_hint_finder.dart';
import 'package:sudoku159/utils/time_format.dart';
import 'package:sudoku159/view/sudoku_game/game_end_flow.dart';
import 'package:sudoku159/view/sudoku_game/game_session_controller.dart';
import 'package:sudoku159/view/sudoku_game/game_settings_controller.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_answer_box.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_board_grid.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_hint_panel.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_info_card.dart';
import 'package:sudoku159/view/sudoku_game/game_effects_controller.dart';
import 'package:sudoku159/services/game/auto_notes_tip_service.dart';
import 'package:sudoku159/view/home/level_picker_screen.dart';
import 'package:sudoku159/widgets/progressive_blur_button.dart';
import 'package:sudoku159/widgets/waddling_penguin_icon.dart';

/// 스도쿠 게임의 메인 화면
/// MVP 패턴에서 View 역할을 수행하며, 사용자 인터페이스를 담당
class SudokuGameScreen extends StatefulWidget {
  final SudokuGame game;
  final SudokuLevel level;
  final bool restoreSavedSession;

  /// 오늘의 도전으로 시작했다면 그 도전의 날짜(YYYY-MM-DD). 완료 귀속에 쓰인다.
  final String? challengeDate;

  /// 이 도전 완료가 연속 일수 계산에 들어가도 되는지. 오늘의 도전을 정상적인
  /// 흐름으로 시작했으면 true(기본값), 과거 날짜를 월간 달력에서 다시
  /// 시작했으면 false로 넘긴다.
  final bool challengeCountsForStreak;

  const SudokuGameScreen({
    super.key,
    required this.game,
    required this.level,
    this.restoreSavedSession = false,
    this.challengeDate,
    this.challengeCountsForStreak = true,
  });

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen>
    with WidgetsBindingObserver {
  late final GameEndFlow _gameEndFlow = GameEndFlow();

  /// 이 게임이 속한 오늘의 도전 날짜(없으면 일반 게임). 저장 세션에도 보존된다.
  String? _challengeDate;
  final GameSessionController _sessionController = GameSessionController();
  final GameSettingsController _settingsController = GameSettingsController();
  late final SudokuGamePresenter _presenter;
  late final SudokuGameFeaturePolicy _featurePolicy;
  bool _presenterReady = false;
  bool _isVibrationEnabled = true;
  bool _oneHandModeEnabled = false;
  bool _memoHighlightEnabled = true;
  bool _showDeveloperAnswerPreview = false;
  final ValueNotifier<String> _timeNotifier = ValueNotifier<String>('0m');
  bool _isLeavingScreen = false;
  int? _memoFocusNumber;
  // 자동 메모 적용 직후 보드 전체에 짧게 강조를 준다. 트리거될 때마다 새 키를
  // 줘서 TweenAnimationBuilder가 처음부터 다시 재생하게 한다.
  Key? _autoNotesFlashKey;
  bool _autoNotesTipShown = false;
  final GameEffectsController _effectsController = GameEffectsController();
  final AutoNotesTipService _autoNotesTipService = AutoNotesTipService();
  OverlayEntry? _completionFeedbackEntry;
  Timer? _completionFeedbackTimer;
  final Map<String, Timer> _wrongCellTimers = {};
  Set<int> _completedUnitIds = {};
  bool _isPenguinActive = false;
  Timer? _penguinActiveTimer;
  bool _autoPausedByLifecycle = false;

  /// 설명 중인 힌트와 단계(1: 살펴볼 곳, 2: 기법과 이유).
  SudokuHint? _activeHint;
  int _hintStep = 1;

  /// 가로줄(0~8) · 세로줄(9~17) · 3x3박스(18~26) 중 현재 완성된 유닛 id 집합.
  Set<int> _computeCompletedUnitIds() {
    bool isLineComplete(Iterable<List<int>> cells) {
      for (final cell in cells) {
        final row = cell[0];
        final col = cell[1];
        if (_presenter.getCellValue(row, col) == 0 ||
            _presenter.isWrongNumber(row, col)) {
          return false;
        }
      }
      return true;
    }

    final completed = <int>{};
    for (int r = 0; r < 9; r++) {
      if (isLineComplete([
        for (int c = 0; c < 9; c++) [r, c]
      ])) {
        completed.add(r);
      }
    }
    for (int c = 0; c < 9; c++) {
      if (isLineComplete([
        for (int r = 0; r < 9; r++) [r, c]
      ])) {
        completed.add(9 + c);
      }
    }
    for (int b = 0; b < 9; b++) {
      final startRow = (b ~/ 3) * 3;
      final startCol = (b % 3) * 3;
      final boxCells = [
        for (int r = startRow; r < startRow + 3; r++)
          for (int c = startCol; c < startCol + 3; c++) [r, c],
      ];
      if (isLineComplete(boxCells)) {
        completed.add(18 + b);
      }
    }
    return completed;
  }

  /// 재개한 게임에서 이미 완성돼 있던 유닛까지 축하 애니메이션이 뜨지 않도록
  /// 기준선을 조용히 세팅합니다.
  void _primeCompletedUnitIds() {
    _completedUnitIds = _computeCompletedUnitIds();
  }

  /// 새로 완성된 유닛이 있으면 펭귄이 5초간 뒤뚱거리도록 트리거합니다.
  void _checkForNewlyCompletedUnits() {
    final completed = _computeCompletedUnitIds();
    final hasNewCompletion = completed.difference(_completedUnitIds).isNotEmpty;
    _completedUnitIds = completed;
    if (hasNewCompletion) {
      _triggerPenguinBurst();
    }
  }

  void _triggerPenguinBurst() {
    _penguinActiveTimer?.cancel();
    setState(() => _isPenguinActive = true);
    _penguinActiveTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _isPenguinActive = false);
    });
  }

  bool get _hasEditableSelection {
    final row = _presenter.selectedRow;
    final col = _presenter.selectedCol;
    if (!_presenterReady || row == null || col == null) {
      return false;
    }
    if (_presenter.isPaused ||
        _presenter.isGameComplete ||
        _presenter.isGameOver) {
      return false;
    }
    return !_presenter.isCellFixed(row, col) &&
        !_presenter.isHintCell(row, col);
  }

  bool get _canToggleMemo {
    return _presenterReady &&
        _featurePolicy.memoEnabled &&
        !_presenter.isPaused &&
        !_presenter.isGameComplete &&
        !_presenter.isGameOver;
  }

  /// 자동 메모는 메모 버튼을 쓸 수 있는 상태이면서, 힌트 패널이 열려 있지
  /// 않을 때만 실행한다.
  bool get _canUseAutoNotes => _canToggleMemo && _activeHint == null;

  Future<void> _toggleMemoMode() async {
    final wasOff = !_presenter.isMemoMode;
    setState(() {
      _memoFocusNumber = null;
      _presenter.toggleMemoMode();
    });
    if (wasOff && _presenter.isMemoMode) {
      unawaited(_maybeShowAutoNotesTip());
    }
  }

  Future<void> _maybeShowAutoNotesTip() async {
    if (_autoNotesTipShown) return;
    final alreadyShown = await _autoNotesTipService.hasShownTip();
    if (alreadyShown) {
      _autoNotesTipShown = true;
      return;
    }
    _autoNotesTipShown = true;
    await _autoNotesTipService.markTipShown();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(AppLocalizations.of(context)!.autoNotesTipMessage)),
    );
  }

  Future<void> _applyAutoNotes() async {
    if (!_canUseAutoNotes) return;
    final hasExistingNotes = _presenter.allCellNotes
        .any((row) => row.any((cell) => cell.isNotEmpty));
    if (hasExistingNotes) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.autoNotesConfirmTitle),
          content: Text(l10n.autoNotesConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.autoNotesConfirmApply),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }

    final result = _presenter.applyAutoNotes();
    if (!mounted) return;
    switch (result) {
      case AutoNotesResult.applied:
        setState(() {
          _autoNotesFlashKey = UniqueKey();
        });
        break;
      case AutoNotesResult.contradiction:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.autoNotesContradictionMessage,
            ),
          ),
        );
        break;
      case AutoNotesResult.noBlankCells:
      case AutoNotesResult.blocked:
        break;
    }
  }

  /// 힌트는 선택 칸과 상관없이 쓸 수 있다. 선택한 빈칸에서 풀 수 있는 수가
  /// 있으면 그 칸을, 없으면 먼저 풀 수 있는 다른 칸을 설명한다.
  bool get _canUseHint {
    if (!_presenterReady ||
        !_featurePolicy.hintEnabled ||
        _presenter.isPaused ||
        _presenter.isGameComplete ||
        _presenter.isGameOver ||
        _activeHint != null) {
      return false;
    }
    return _presenter.hintsRemaining > 0 && _presenter.progress < 1.0;
  }

  /// 1단계의 숨은 싱글은 영역만 보여 주고 정답 칸은 2단계에서 드러낸다.
  int? get _visibleHintTarget {
    final hint = _activeHint;
    if (hint == null) return null;
    final revealsCellEarly =
        hint.technique == SudokuHintTechnique.nakedSingle ||
            hint.technique == SudokuHintTechnique.reveal;
    return _hintStep == 2 || revealsCellEarly ? hint.cellIndex : null;
  }

  void _startHint() {
    if (!_canUseHint) return;
    final hint = SudokuHintFinder.find(
      board: _presenter.boardSnapshot,
      solution: _presenter.solutionSnapshot,
      selectedRow: _hasEditableSelection ? _presenter.selectedRow : null,
      selectedCol: _hasEditableSelection ? _presenter.selectedCol : null,
    );
    if (hint == null || !_presenter.consumeHint()) return;
    // 1단계에서 정답 칸을 바로 드러내지 않도록 선택을 잠시 해제한다.
    _presenter.clearSelection();
    setState(() {
      _memoFocusNumber = null;
      _activeHint = hint;
      _hintStep = 1;
    });
  }

  void _advanceHint() {
    final hint = _activeHint;
    if (hint == null) return;
    _presenter.selectCell(hint.row, hint.col);
    setState(() => _hintStep = 2);
  }

  /// `onCorrectAnswer` 콜백이 [revealHintAt] 안에서 동기적으로 실행되는
  /// 동안만 켠다. 그동안은 일반 정답 강조 대신 힌트 전용 강조를 쓴다.
  bool _isApplyingHintFill = false;

  void _fillHint() {
    final hint = _activeHint;
    if (hint == null) return;
    setState(() => _activeHint = null);
    _cancelWrongCellTimer(hint.row, hint.col);
    _presenter.selectCell(hint.row, hint.col);
    if (!_presenter.isHintCell(hint.row, hint.col)) {
      // 정답 입력과 저장은 이 강조와 무관하게 즉시 처리된다 — revealHintAt은
      // 동기 호출이라 애니메이션을 기다리지 않는다.
      _isApplyingHintFill = true;
      try {
        _presenter.revealHintAt(hint.row, hint.col);
      } finally {
        _isApplyingHintFill = false;
      }
    }
  }

  void _closeHint() {
    if (_activeHint == null) return;
    setState(() => _activeHint = null);
  }

  static const Duration _hintPanelEnterDuration = Duration(milliseconds: 160);
  static const Duration _hintPanelExitDuration = Duration(milliseconds: 120);

  /// 숫자패드·동작 버튼 영역 위에 힌트 설명을 겹친다. 아래 영역의 크기는
  /// 그대로 두므로 보드 배치가 바뀌지 않는다.
  ///
  /// 패널이 없을 때(hint == null)는 항상 `IgnorePointer`로 감싸, 방금 닫혀
  /// 아직 120ms 페이드아웃 중인 이전 패널이 남아 있어도 숫자패드를 즉시
  /// 다시 쓸 수 있게 한다. 패널이 있을 때는 전체 영역을 불투명 히트테스트로
  /// 막아 등장 애니메이션 중에도 빈 여백을 통해 뒤 숫자패드가 눌리지 않는다.
  Widget _withHintPanel(Widget keypad, {double bottomInset = 0}) {
    final hint = _activeHint;
    final reduceMotion = _effectsController.reduceMotion;
    return Stack(
      children: [
        keypad,
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: bottomInset,
          child: IgnorePointer(
            ignoring: hint == null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: AnimatedSwitcher(
                duration:
                    reduceMotion ? Duration.zero : _hintPanelEnterDuration,
                reverseDuration:
                    reduceMotion ? Duration.zero : _hintPanelExitDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  children: [
                    for (final child in previousChildren)
                      Positioned.fill(child: child),
                    if (currentChild != null)
                      Positioned.fill(child: currentChild),
                  ],
                ),
                transitionBuilder: (child, animation) {
                  if (reduceMotion) {
                    return FadeTransition(opacity: animation, child: child);
                  }
                  return FadeTransition(
                    opacity: animation,
                    child: AnimatedBuilder(
                      animation: animation,
                      // 닫힐 때(reverse)는 자리 이동 없이 페이드만 한다.
                      // 열릴 때만 4px 아래에서 제자리로 올라온다.
                      builder: (context, builtChild) =>
                          animation.status == AnimationStatus.reverse
                              ? builtChild!
                              : Transform.translate(
                                  offset: Offset(0, (1 - animation.value) * 4),
                                  child: builtChild,
                                ),
                      child: child,
                    ),
                  );
                },
                child: hint == null
                    ? const SizedBox.shrink(key: ValueKey('hint-panel-empty'))
                    : SudokuHintPanel(
                        key: const ValueKey('hint-panel-visible'),
                        hint: hint,
                        step: _hintStep,
                        onNext: _advanceHint,
                        onFill: _fillHint,
                        onClose: _closeHint,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool get _canEraseSelection =>
      _presenterReady && _presenter.canEraseSelectedCell;

  void _eraseSelectedCell() {
    if (!_canEraseSelection) return;
    _cancelWrongCellTimer(_presenter.selectedRow, _presenter.selectedCol);
    _presenter.eraseSelectedCell();
  }

  bool get _canUndo => _presenterReady && _presenter.canUndo;

  /// presenter.undo()가 동기적으로 실행되는 동안만 켠다. onBoardChanged
  /// 콜백이 이 플래그를 보고 정답·오답·줄 완성 효과를 재실행하지 않는다.
  bool _isApplyingUndo = false;

  /// 퍼즐 완료 연출(보드 글로우) 표시 여부. true인 동안 결과 다이얼로그는
  /// 아직 뜨지 않은 상태다.
  bool _showCompletionGlow = false;

  /// [onGameCompleteChanged]가 두 번 이상 호출되어도 완료 연출·다이얼로그가
  /// 중복 실행되지 않도록 막는 가드.
  bool _completionSequenceStarted = false;

  /// 완료 연출이 끝난 뒤 햅틱+다이얼로그를 여는 예약 작업. 화면이 닫히면
  /// (뒤로 가기 등으로 dispose되면) 취소해 언마운트된 context로 다이얼로그를
  /// 열려는 시도를 막는다.
  Timer? _completionSequenceTimer;

  /// 마지막 칸의 정답 강조 → 보드 글로우+박스 강조 → 햅틱 1회 → 결과
  /// 다이얼로그 순서로 진행하는 퍼즐 완료 연출을 시작한다.
  void _beginPuzzleCompleteSequence() {
    if (_completionSequenceStarted) return;
    _completionSequenceStarted = true;
    final duration = _effectsController.reduceMotion
        ? GameEffectsController.puzzleCompleteGlowDurationReduced
        : GameEffectsController.puzzleCompleteGlowDuration;
    setState(() => _showCompletionGlow = true);
    _completionSequenceTimer = Timer(duration, () {
      _completionSequenceTimer = null;
      if (!mounted) return;
      setState(() => _showCompletionGlow = false);
      if (_isVibrationEnabled) {
        unawaited(HapticFeedback.heavyImpact());
      }
      _showGameCompleteDialog();
    });
  }

  /// 이번 세션에서 완료 반응을 이미 보여준 숫자(1~9). 게임 시작 시 이미
  /// 다 채워져 있던 숫자, 그리고 완료 반응을 한 번 재생한 숫자가 들어간다
  /// — 되돌리기로 다시 모자라졌다가 재입력으로 다시 채워져도 반복하지 않는다.
  final Set<int> _celebratedCompleteDigits = {};

  /// 숫자패드에서 완료(1.0→1.08→1.0) 팝을 재생 중인 숫자. null이면 없음.
  int? _numberPopDigit;
  Timer? _numberPopTimer;

  /// 게임 시작·재시작 시점에 이미 9개가 다 채워진 숫자는 "새로 완료됨"이
  /// 아니므로 조용히 완료 목록에 먼저 넣어 둔다.
  void _primeCelebratedCompleteDigits() {
    _celebratedCompleteDigits.clear();
    for (var digit = 1; digit <= 9; digit++) {
      if (_remainingCountForNumber(digit) == 0) {
        _celebratedCompleteDigits.add(digit);
      }
    }
  }

  /// 방금 [row],[col]에 넣은 정답으로 어떤 숫자가 처음 9개 모두 채워졌다면
  /// 숫자패드 팝·보드 강조·햅틱으로 짧게 알려준다.
  void _maybeCelebrateDigitCompletion(int row, int col) {
    final value = _presenter.getCellValue(row, col);
    if (value == 0 || _celebratedCompleteDigits.contains(value)) return;
    if (_remainingCountForNumber(value) != 0) return;
    _celebratedCompleteDigits.add(value);

    if (_isVibrationEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
    _showTopFeedback(
      AppLocalizations.of(context)!.gameDigitCompleteSentence(value),
    );
    if (_effectsController.reduceMotion) {
      // 동작 줄이기: 배지의 체크 아이콘 전환(AnimatedSwitcher)만 그대로
      // 적용되고, 숫자패드 팝·보드 강조는 재생하지 않는다.
      return;
    }
    _numberPopTimer?.cancel();
    setState(() => _numberPopDigit = value);
    _numberPopTimer = Timer(const Duration(milliseconds: 220), () {
      _numberPopTimer = null;
      if (!mounted) return;
      setState(() => _numberPopDigit = null);
    });
    _effectsController.triggerDigitCompleteEffect(
      digit: value,
      board: _presenter.boardSnapshot,
      setState: setState,
      isMounted: () => mounted,
    );
  }

  void _undoLastInput() {
    if (!_canUndo) return;
    // 되돌린 칸에 오답 자동 삭제 타이머가 남아 있으면 복원한 값을 지워 버린다.
    _cancelAllWrongCellTimers();
    setState(() {
      _memoFocusNumber = null;
    });
    _isApplyingUndo = true;
    try {
      _presenter.undo();
    } finally {
      _isApplyingUndo = false;
    }

    final cell = _presenter.lastUndoCell;
    if (cell == null) return;
    _effectsController.triggerUndoEffect(
      row: cell.$1,
      col: cell.$2,
      setState: setState,
      isMounted: () => mounted,
    );
    unawaited(_maybeVibrateForUndo());
  }

  Future<void> _maybeVibrateForUndo() async {
    if (!_isVibrationEnabled || _effectsController.reduceMotion) return;
    await HapticFeedback.selectionClick();
  }

  /// 사용자가 직접 멈춘 일시정지(앱 전환으로 인한 자동 정지와 구분하지 않고,
  /// 멈춰 있는 동안에는 보드를 가린다).
  bool get _isBoardCovered =>
      _presenterReady &&
      _presenter.isPaused &&
      !_presenter.isGameComplete &&
      !_presenter.isGameOver;

  bool get _canTogglePause =>
      _presenterReady && !_presenter.isGameComplete && !_presenter.isGameOver;

  void _togglePause() {
    if (!_canTogglePause) return;
    _autoPausedByLifecycle = false;
    _effectsController.clearTransientEffects();
    _activeHint = null;
    _presenter.togglePause();
  }

  bool get _canResetCurrentGame {
    return _presenterReady &&
        !_presenter.isGameComplete &&
        !_presenter.isGameOver;
  }

  /// 고정(원본) 칸을 제외하고 사용자가 직접 채운 숫자 칸 수. 힌트로 채운
  /// 칸도 "채웠다"에 포함한다(실제로 칸이 비어 있지 않으므로).
  int get _userFilledCellCount {
    var count = 0;
    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        if (!_presenter.isCellFixed(row, col) &&
            _presenter.getCellValue(row, col) != 0) {
          count++;
        }
      }
    }
    return count;
  }

  GameSessionSnapshot _buildSessionSnapshot() {
    return GameSessionSnapshot(
      board: List.generate(
        9,
        (row) => List.generate(9, (col) => _presenter.getCellValue(row, col)),
      ),
      notes: _presenter.allCellNotes,
      elapsedSeconds: _presenter.seconds,
      wrongCount: _presenter.wrongCount,
      isMemoMode: _presenter.isMemoMode,
      isGameComplete: _presenter.isGameComplete,
      isGameOver: _presenter.isGameOver,
      hintsRemaining: _presenter.hintsRemaining,
      hintCells: _presenter.hintCells,
      challengeDate: _challengeDate,
      initialHints: _featurePolicy.maxHints,
      autoNotesUsed: _presenter.autoNotesUsed,
      userFilledCells: _userFilledCellCount,
    );
  }

  void _scheduleSessionSave() {
    if (!_presenterReady) return;
    _sessionController.scheduleSave(
      level: widget.level,
      gameNumber: widget.game.gameNumber,
      snapshot: _buildSessionSnapshot(),
    );
  }

  Future<void> _flushPendingSessionSave() async {
    if (!_presenterReady) return;
    await _sessionController.flushSave(
      level: widget.level,
      gameNumber: widget.game.gameNumber,
      snapshot: _buildSessionSnapshot(),
    );
  }

  Future<void> _flushPendingSessionOnPause() async {
    if (!_presenterReady) return;
    await _flushPendingSessionSave();
  }

  Future<void> _popAfterSaving() async {
    if (_isLeavingScreen) return;
    _isLeavingScreen = true;
    await _flushPendingSessionSave();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _featurePolicy = SudokuGameFeaturePolicy.forLevel(widget.level);
    WidgetsBinding.instance.addObserver(this);
    _initializeGame();
  }

  /// 게임 초기화
  Future<void> _initializeGame() async {
    await _loadGameSettings();

    var sessionBootstrap = await _sessionController.prepareSession(
      game: widget.game,
      level: widget.level,
      restoreSavedSession: widget.restoreSavedSession,
      maxWrongCount: _featurePolicy.maxWrongCount,
    );

    // 이 화면이 특정 날짜의 도전으로 열렸다면, 복원된 세션이 그 날짜가 아닌
    // 다른(또는 없는) challengeDate를 갖고 있을 때 이어하지 않는다. 같은
    // 레벨·번호의 퍼즐이라도 다른 날짜 세션을 잘못 복원하지 않기 위함이다.
    if (widget.challengeDate != null &&
        sessionBootstrap.activeSession != null &&
        sessionBootstrap.activeSession!.challengeDate != widget.challengeDate) {
      await _sessionController.clear(
        level: widget.level,
        gameNumber: widget.game.gameNumber,
      );
      sessionBootstrap = GameSessionBootstrap(
        initialBoard: widget.game.board,
        activeSession: null,
      );
    }

    final activeSession = sessionBootstrap.activeSession;
    // 도전으로 시작했다면 그 날짜를, 저장 세션을 이어받았다면 세션에 남은 날짜를 쓴다.
    _challengeDate = widget.challengeDate ?? activeSession?.challengeDate;
    final initialBoard = sessionBootstrap.initialBoard;

    _effectsController.resetForBoard(
      board: initialBoard,
      solution: widget.game.solution,
    );

    _presenter = SudokuGamePresenter(
      puzzleBoard: widget.game.board,
      initialBoard: initialBoard,
      solution: widget.game.solution,
      maxHints: _featurePolicy.maxHints,
      maxWrongCount: _featurePolicy.maxWrongCount,
      initialElapsedSeconds: activeSession?.elapsedSeconds ?? 0,
      initialWrongCount: activeSession?.wrongCount ?? 0,
      initialMemoMode: activeSession?.isMemoMode ?? false,
      initialNotes: activeSession?.notes,
      initialHintsRemaining: activeSession?.hintsRemaining,
      initialHintCells: activeSession?.hintCells ?? const {},
      initialAutoNotesUsed: activeSession?.autoNotesUsed ?? false,
      level: widget.level,
      onBoardChanged: (board) {
        if (_isApplyingUndo) {
          // 되돌리기는 정답·오답·줄 완성 효과를 재실행하지 않는다. 완성된
          // 줄 추적만 조용히 새 보드에 맞추고(다음 정상 입력부터 다시
          // "새로 완성됨"을 올바르게 판정하도록), 효과·안내는 생략한다.
          _effectsController.initializeCompletedLineState(
            board: board,
            solution: widget.game.solution,
          );
          setState(() {});
          _scheduleSessionSave();
          return;
        }
        final completionDelta = _effectsController.handleBoardChanged(
          board: board,
          solution: widget.game.solution,
          setState: setState,
          isMounted: () => mounted,
        );
        setState(() {});
        if (completionDelta.isPuzzleComplete) {
          _hideCompletionFeedback();
        } else {
          _showCompletionFeedback(completionDelta);
        }
        _scheduleSessionSave();
      },
      onFixedNumbersChanged: (fixedNumbers) {
        setState(() {});
      },
      onWrongNumbersChanged: (wrongNumbers) {
        setState(() {});
        if (_presenterReady) {
          _checkForNewlyCompletedUnits();
        }
      },
      onTimeChanged: (time) {
        _timeNotifier.value = formatElapsedSeconds(time);
      },
      onPauseStateChanged: (isPaused) {
        setState(() {});
        _scheduleSessionSave();
      },
      onGameCompleteChanged: (isComplete) {
        if (isComplete) {
          _activeHint = null;
          _beginPuzzleCompleteSequence();
        }
        setState(() {});
      },
      onWrongCountChanged: (wrongCount) {
        setState(() {});
        _scheduleSessionSave();
      },
      onGameOver: () {
        _activeHint = null;
        if (_isVibrationEnabled) {
          HapticFeedback.heavyImpact()
              .then((_) => Future<void>.delayed(
                    const Duration(milliseconds: 80),
                  ))
              .then((_) => HapticFeedback.heavyImpact())
              .then((_) => Future<void>.delayed(
                    const Duration(milliseconds: 80),
                  ))
              .then((_) => HapticFeedback.heavyImpact());
        }
        _showGameOverDialog();
      },
      onCorrectAnswer: (row, col) {
        if (_isApplyingHintFill) {
          // 힌트로 채운 칸은 일반 정답 강조 대신 전용 강조를 쓴다. 둘 다
          // 같은 칸에 걸면 나중 호출이 앞 호출을 즉시 지워 버리므로 배타적으로 둔다.
          _effectsController.triggerHintAppliedEffect(
            row: row,
            col: col,
            setState: setState,
            isMounted: () => mounted,
          );
        } else {
          _effectsController.triggerCorrectEffect(
            row: row,
            col: col,
            setState: setState,
            isMounted: () => mounted,
          );
        }
        // 힌트로 채웠든 직접 입력했든, 이 입력으로 어떤 숫자가 9개 모두
        // 채워졌다면 완료 반응을 준다(둘 다 정답 입력이라는 점은 같다).
        _maybeCelebrateDigitCompletion(row, col);
      },
      onIncorrectAnswer: (row, col) {
        _effectsController.triggerErrorEffect(
          row: row,
          col: col,
          setState: setState,
          isMounted: () => mounted,
        );
        _scheduleWrongCellAutoClear(row, col);
      },
    );

    _primeCompletedUnitIds();
    _primeCelebratedCompleteDigits();
    if (mounted) {
      setState(() {
        _presenterReady = true;
        _memoFocusNumber = null;
      });
    }
    _timeNotifier.value = _presenter.calmFormattedTime;

    _presenter.clearSelection();

    await _flushPendingSessionSave();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        return;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // 백그라운드에 머무는 동안 타이머가 계속 흐르지 않도록 정지.
        // (수동 일시정지 중이었다면 건드리지 않음)
        if (_presenterReady && !_presenter.isPaused) {
          _presenter.togglePause();
          _autoPausedByLifecycle = true;
        }
        _effectsController.clearTransientEffects();
        unawaited(_flushPendingSessionOnPause());
        return;
      case AppLifecycleState.resumed:
        if (_presenterReady && _autoPausedByLifecycle) {
          _presenter.togglePause();
          _autoPausedByLifecycle = false;
        }
        return;
    }
  }

  void _showCompletionFeedback(BoardCompletionDelta completionDelta) {
    if (!mounted || !completionDelta.hasNewCompletion) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    // 한 가지 영역만 완성됐으면 자연스러운 문장으로, 여러 영역이 동시에
    // 완성되면 문장으로 억지로 합치지 않고 짧은 라벨을 나열한다(완성은
    // 한 번만 붙인다). 완성 개수(행 2개 등)는 어느 쪽이든 보여주지 않는다.
    final completedKinds = [
      if (completionDelta.completedRows > 0) _LineWaveKind.row,
      if (completionDelta.completedCols > 0) _LineWaveKind.col,
      if (completionDelta.completedBoxes > 0) _LineWaveKind.box,
    ];
    if (completedKinds.isEmpty) {
      return;
    }

    if (completedKinds.length == 1) {
      final message = switch (completedKinds.single) {
        _LineWaveKind.row => l10n.gameLineWaveRowSentence,
        _LineWaveKind.col => l10n.gameLineWaveColSentence,
        _LineWaveKind.box => l10n.gameLineWaveBoxSentence,
      };
      _showTopFeedback(message);
      return;
    }

    final parts = completedKinds.map((kind) => switch (kind) {
          _LineWaveKind.row => l10n.gameLineWaveRowLabel,
          _LineWaveKind.col => l10n.gameLineWaveColLabel,
          _LineWaveKind.box => l10n.gameLineWaveBoxLabel,
        });
    _showTopFeedback(l10n.gameLineWaveAnnounce(parts.join(' · ')));
  }

  /// 완성 안내 칩의 등장/퇴장 페이드 길이.
  static const Duration _completionFeedbackFade = Duration(milliseconds: 120);

  /// 완전히 보이는 상태로 머무는 시간(페이드 제외).
  static const Duration _completionFeedbackHold = Duration(milliseconds: 900);

  /// 완전히 보이는 상태인지. OverlayEntry의 builder가 매 rebuild마다 이
  /// 값을 읽어 [AnimatedOpacity]의 목표값으로 쓴다.
  bool _completionFeedbackVisible = false;

  void _showTopFeedback(
    String message, {
    Color backgroundColor = const Color(0xFF242B2D),
  }) {
    if (!mounted) {
      return;
    }

    // 연속 입력으로 이전 안내가 남아 있다면 즉시(페이드 없이) 치우고
    // 최신 안내 하나만 보여준다.
    _hideCompletionFeedback();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    // 앱바(toolbarHeight 50) 바로 아래, 상태바를 가리지 않는 위치.
    final mediaQuery = MediaQuery.of(context);
    final topOffset = mediaQuery.padding.top + 50 + 10;
    final fadeDuration = _effectsController.reduceMotion
        ? Duration.zero
        : _completionFeedbackFade;

    _completionFeedbackVisible = false;
    _completionFeedbackEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topOffset,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: AnimatedOpacity(
                opacity: _completionFeedbackVisible ? 1 : 0,
                duration: fadeDuration,
                curve: Curves.easeOut,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_completionFeedbackEntry!);
    // 다음 프레임에 표시 상태로 바꿔야 AnimatedOpacity가 0→1 페이드인을
    // 실제로 재생한다(삽입과 같은 프레임이면 애니메이션 없이 바로 1로 그려짐).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_completionFeedbackEntry == null || !mounted) return;
      _completionFeedbackVisible = true;
      _completionFeedbackEntry!.markNeedsBuild();
    });

    _completionFeedbackTimer = Timer(_completionFeedbackHold, () {
      if (_completionFeedbackEntry == null) return;
      _completionFeedbackVisible = false;
      _completionFeedbackEntry!.markNeedsBuild();
      _completionFeedbackTimer = Timer(fadeDuration, () {
        _completionFeedbackEntry?.remove();
        _completionFeedbackEntry = null;
      });
    });
  }

  void _hideCompletionFeedback() {
    _completionFeedbackTimer?.cancel();
    _completionFeedbackTimer = null;
    _completionFeedbackVisible = false;
    _completionFeedbackEntry?.remove();
    _completionFeedbackEntry = null;
  }

  Future<void> _clearCurrentGameState() async {
    await _sessionController.clear(
      level: widget.level,
      gameNumber: widget.game.gameNumber,
    );
  }

  Future<void> _resetAndRestartCurrentGame() async {
    await _clearCurrentGameState();
    if (!mounted) return;
    _completionSequenceTimer?.cancel();
    _completionSequenceTimer = null;
    _numberPopTimer?.cancel();
    _numberPopTimer = null;
    setState(() {
      _memoFocusNumber = null;
      _completionSequenceStarted = false;
      _showCompletionGlow = false;
      _numberPopDigit = null;
    });
    _effectsController.resetForBoard(
      board: widget.game.board,
      solution: widget.game.solution,
    );
    _presenter.restartGame();
    // 재시작한 보드는 widget.game.board(진행 전 상태) 기준이라, 시작부터
    // 이미 다 채워진 숫자가 있는지 다시 계산해야 한다.
    _primeCelebratedCompleteDigits();
  }

  Future<void> _showResetCurrentGameDialog() async {
    if (!_canResetCurrentGame) return;

    final l10n = AppLocalizations.of(context)!;
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.gameResetDialogTitle),
          content: Text(l10n.gameResetDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.gameResetConfirm),
            ),
          ],
        );
      },
    );

    if (shouldReset != true || !mounted) return;
    await _resetAndRestartCurrentGame();
  }

  Future<void> _exitToLevelSelection() async {
    final levelNavigator = Navigator.of(context);
    await levelNavigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => LevelPickerScreen(level: widget.level),
      ),
      (route) => route.isFirst,
    );
    unawaited(
      _clearCurrentGameState().catchError((error) {
        if (kDebugMode) {
          AppLogger.debug('게임 상태 정리 실패(무시): $error');
        }
      }),
    );
  }

  Future<void> _loadGameSettings() async {
    final settings = await _settingsController.load();
    if (!mounted) return;
    setState(() {
      _isVibrationEnabled = settings.isVibrationEnabled;
      _oneHandModeEnabled = settings.oneHandModeEnabled;
      _memoHighlightEnabled =
          _featurePolicy.memoEnabled && settings.memoHighlightEnabled;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_flushPendingSessionSave());
    _sessionController.dispose();
    unawaited(_settingsController.dispose());
    _effectsController.dispose();
    _hideCompletionFeedback();
    for (final t in _wrongCellTimers.values) {
      t.cancel();
    }
    _wrongCellTimers.clear();
    _completionSequenceTimer?.cancel();
    _numberPopTimer?.cancel();
    _penguinActiveTimer?.cancel();
    _timeNotifier.dispose();
    if (_presenterReady) {
      _presenter.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    _effectsController.reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (!_presenterReady) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          unawaited(_popAfterSaving());
        },
        child: Scaffold(
          backgroundColor: surface,
          appBar: _buildAppBar(),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_popAfterSaving());
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  /// 아이패드 가로 모드일 때만 좌우 분할 레이아웃을 쓰고, 그 외(아이폰 전체,
  /// 아이패드 세로)는 기존 세로 레이아웃을 그대로 사용.
  Widget _buildBody() {
    final mediaQuery = MediaQuery.of(context);
    final isTabletDevice = mediaQuery.size.shortestSide > 600;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    if (isTabletDevice && isLandscape) {
      return _buildLandscapeLayout();
    }
    return _buildMobileLayout();
  }

  /// 앱바 위젯
  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    final titleText =
        '${widget.level.localizedName(l10n)} · ${l10n.gameNumberLabel(widget.game.gameNumber)}';
    return AppBar(
      toolbarHeight: 50,
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      centerTitle: true,
      titleSpacing: 0,
      title: GestureDetector(
        onLongPress: kDebugMode ? _toggleDeveloperAnswerPreview : null,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Text(
            titleText,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
        ),
      ),
      leadingWidth: 52,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        visualDensity: VisualDensity.compact,
        onPressed: _popAfterSaving,
      ),
      actions: [
        if (kDebugMode) _buildDeveloperMenuButton(),
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Center(
            child: _buildTimerPauseButton(
              l10n,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WaddlingPenguinIcon(size: 22, active: _isPenguinActive),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<String>(
                    valueListenable: _timeNotifier,
                    builder: (context, time, _) =>
                        MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.3,
                      child: Text(
                        time,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFB8B8B8)
                              : context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isBoardCovered
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    size: 18,
                    color: _canTogglePause
                        ? context.colors.textSecondary
                        : context.colors.textDisabled,
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildGameMenuButton(l10n),
      ],
    );
  }

  /// 앱바의 펭귄·타이머 묶음 전체를 일시정지/계속 버튼으로 쓴다.
  Widget _buildTimerPauseButton(AppLocalizations l10n,
      {required Widget child}) {
    return Semantics(
      container: true,
      button: true,
      enabled: _canTogglePause,
      label: _isBoardCovered ? l10n.gameResume : l10n.gamePause,
      child: Tooltip(
        message: _isBoardCovered ? l10n.gameResume : l10n.gamePause,
        child: InkWell(
          onTap: _canTogglePause ? _togglePause : null,
          borderRadius: BorderRadius.circular(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// 일시정지 중 보드를 가리는 덮개. 보드 칸과 달리 시스템 글씨 크기를 따른다.
  Widget _buildPauseCover(AppLocalizations l10n) {
    return Container(
      key: const ValueKey('game-pause-cover'),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.border),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pause_circle_outline_rounded,
                size: 44,
                color: context.colors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.gamePausedTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.gamePausedBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _togglePause,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 48),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.gameResume),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 전체 초기화 진입점. 주요 입력 버튼과 떨어뜨려 오조작을 막는다.
  Widget _buildGameMenuButton(AppLocalizations l10n) {
    return PopupMenuButton<String>(
      tooltip: l10n.gameMoreOptions,
      icon: Icon(Icons.more_vert, size: 22, color: context.colors.textPrimary),
      padding: EdgeInsets.zero,
      onSelected: (_) => _showResetCurrentGameDialog(),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'restart',
          enabled: _canResetCurrentGame,
          child: Text(l10n.gameResetDialogTitle),
        ),
      ],
    );
  }

  Widget _buildDeveloperMenuButton() {
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    return PopupMenuButton<_DeveloperCheatAction>(
      tooltip: isKorean ? '개발자 도구' : 'Developer tools',
      icon: const Icon(
        Icons.bug_report_outlined,
        size: 20,
        color: Color(0xFF66776C),
      ),
      onSelected: _handleDeveloperCheatAction,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _DeveloperCheatAction.toggleAnswerPreview,
          child: Text(
            _showDeveloperAnswerPreview
                ? (isKorean ? '정답 미리보기 끄기' : 'Hide answer preview')
                : (isKorean ? '정답 미리보기 켜기' : 'Show answer preview'),
          ),
        ),
        PopupMenuItem(
          value: _DeveloperCheatAction.fillSelected,
          child: Text(
            isKorean ? '선택 셀에 정답 입력' : 'Fill selected cell',
          ),
        ),
        PopupMenuItem(
          value: _DeveloperCheatAction.autoSolve,
          child: Text(
            isKorean ? '모든 셀 자동 완성' : 'Auto-solve board',
          ),
        ),
      ],
    );
  }

  void _handleDeveloperCheatAction(_DeveloperCheatAction action) {
    switch (action) {
      case _DeveloperCheatAction.toggleAnswerPreview:
        _toggleDeveloperAnswerPreview();
      case _DeveloperCheatAction.fillSelected:
        _devFillSelectedCell();
      case _DeveloperCheatAction.autoSolve:
        _devAutoSolveBoard();
    }
  }

  void _devFillSelectedCell() {
    if (!_presenterReady) return;
    if (_presenter.selectedRow == null || _presenter.selectedCol == null) {
      _showDeveloperSnackBar(
        koMessage: '먼저 셀을 선택해 주세요.',
        enMessage: 'Select a cell first.',
      );
      return;
    }
    _presenter.devFillSelectedCellWithAnswer();
    _showDeveloperSnackBar(
      koMessage: '선택한 셀에 정답을 입력했어요.',
      enMessage: 'Filled the selected cell with the answer.',
    );
  }

  void _devAutoSolveBoard() {
    if (!_presenterReady) return;
    _presenter.devAutoSolve();
    _showDeveloperSnackBar(
      koMessage: '모든 셀을 정답으로 채웠어요.',
      enMessage: 'Auto-solved the board.',
    );
  }

  void _showDeveloperSnackBar({
    required String koMessage,
    required String enMessage,
  }) {
    if (!mounted) return;
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isKorean ? koMessage : enMessage),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 모바일 레이아웃
  Widget _buildMobileLayout() {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final bottomSafePadding = math.max(mediaQuery.padding.bottom, 12.0);
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _MobileGameLayoutMetrics.fromConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
              bottomSafePadding: bottomSafePadding,
            );

            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.horizontalPadding,
                    metrics.topPadding,
                    metrics.horizontalPadding,
                    0,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: metrics.boardSize,
                            height: metrics.boardSize,
                            child: _buildBoardGrid(),
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.sectionGap),
                      _withHintPanel(
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < 3; i++)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (int j = 1; j <= 3; j++)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: metrics.numberButtonGap / 2,
                                        vertical: metrics.numberButtonGap / 2,
                                      ),
                                      child: _buildNumberButton(
                                        i * 3 + j,
                                        compact: true,
                                        width: metrics.numberButtonWidth,
                                        height: metrics.numberButtonHeight,
                                        borderRadius:
                                            metrics.numberButtonRadius,
                                      ),
                                    ),
                                ],
                              ),
                            SizedBox(height: metrics.compactGap),
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: metrics.scrollBottomPadding,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildMobileActionButton(
                                        icon: Icons.undo_rounded,
                                        label: l10n.gameUndoShort,
                                        color: AppTheme.lightBlueColor,
                                        onPressed:
                                            _canUndo ? _undoLastInput : null,
                                        compact: true,
                                        size: metrics.actionButtonSize,
                                        labelFontSize:
                                            metrics.actionLabelFontSize,
                                      ),
                                      _buildMobileActionButton(
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
                                        onPressed: _canToggleMemo
                                            ? () {
                                                unawaited(_toggleMemoMode());
                                              }
                                            : null,
                                        onLongPress: _canUseAutoNotes
                                            ? () => unawaited(_applyAutoNotes())
                                            : null,
                                        longPressSemanticsHint:
                                            l10n.gameMemoLongPressHint,
                                        showAutoNotesBadge: true,
                                        compact: true,
                                        size: metrics.actionButtonSize,
                                        labelFontSize:
                                            metrics.actionLabelFontSize,
                                      ),
                                      _buildMobileHintButton(
                                        buttonSize: metrics.actionButtonSize,
                                        labelFontSize:
                                            metrics.actionLabelFontSize,
                                      ),
                                      _buildMobileActionButton(
                                        icon: Icons.backspace_outlined,
                                        label: l10n.gameEraseShort,
                                        color: context.colors.attentionSurface,
                                        onPressed: _canEraseSelection
                                            ? _eraseSelectedCell
                                            : null,
                                        compact: true,
                                        size: metrics.actionButtonSize,
                                        labelFontSize:
                                            metrics.actionLabelFontSize,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        bottomInset: metrics.scrollBottomPadding,
                      ),
                    ],
                  ),
                ),
                if (kDebugMode && _showDeveloperAnswerPreview)
                  Positioned(
                    right: metrics.horizontalPadding,
                    bottom: metrics.scrollBottomPadding +
                        metrics.actionButtonSize +
                        metrics.compactGap +
                        10,
                    child: IgnorePointer(
                      child: _buildDeveloperAnswerPreview(l10n),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ─── 아이패드 가로 모드 우측 패널 튜닝 상수 ─────────────────────────────
  // 통계 카드 블록과 키패드 블록 사이 여백을 위(edge)/가운데(mid)/아래(edge)
  // 세 구간의 Flex 비율로 나눈다. mid : (edge*2+mid) = 3:5 = 60% → 가운데
  // gap을 다시 한번 줄이고, 위아래엔 살짝씩만 남겨 두 블록이 화면 맨
  // 위/맨 아래에 붙지 않도록 균형을 유지한다.
  static const int _kLandscapeEdgeSpacerFlex = 1;
  static const int _kLandscapeMidSpacerFlex = 3;
  // 숫자패드와 메모/힌트/삭제 버튼 행 사이 간격에 더하는 여유분.
  static const double _kLandscapeKeypadActionGapBonus = 10.0;
  // 통계 카드+키패드+액션 버튼 전체를 하나의 컨트롤 패널처럼 보이도록
  // 감싸는 테두리의 내부 여백/모서리 반경. 배경은 채우지 않고 테두리만
  // 둬서(미니멀 유지) 개별 카드 배경과 겹쳐 무거워지지 않게 한다.
  static const double _kLandscapePanelPadding = 16.0;
  static const double _kLandscapePanelBorderRadius = 22.0;

  /// 아이패드 가로 모드 전용 좌우 분할 레이아웃: 왼쪽 보드, 오른쪽 키패드+액션 버튼.
  Widget _buildLandscapeLayout() {
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _TabletLandscapeGameLayoutMetrics.fromConstraints(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          bottomSafePadding: math.max(safePadding.bottom, 12.0),
          horizontalSafePadding: math.max(safePadding.left, safePadding.right),
          panelPadding: _kLandscapePanelPadding,
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(
            metrics.horizontalPadding,
            metrics.verticalPadding,
            metrics.horizontalPadding,
            metrics.verticalPadding + metrics.bottomSafePadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: metrics.boardSize,
                    height: metrics.boardSize,
                    child: _buildBoardGrid(),
                  ),
                ),
              ),
              SizedBox(width: metrics.sectionGap),
              SizedBox(
                width: metrics.keypadColumnWidth,
                child: Container(
                  padding: const EdgeInsets.all(_kLandscapePanelPadding),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(_kLandscapePanelBorderRadius),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: _kLandscapeEdgeSpacerFlex),
                      _buildLandscapeStatsPanel(),
                      const Spacer(flex: _kLandscapeMidSpacerFlex),
                      _withHintPanel(
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < 3; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: i < 2 ? metrics.numberButtonGap : 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (int j = 1; j <= 3; j++)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              metrics.numberButtonGap / 2,
                                        ),
                                        child: _buildNumberButton(
                                          i * 3 + j,
                                          compact: true,
                                          width: metrics.numberButtonWidth,
                                          height: metrics.numberButtonHeight,
                                          borderRadius:
                                              metrics.numberButtonRadius,
                                          largeBadge: true,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            SizedBox(
                              height: metrics.compactGap +
                                  _kLandscapeKeypadActionGapBonus,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildMobileActionButton(
                                  icon: Icons.undo_rounded,
                                  label: AppLocalizations.of(context)!
                                      .gameUndoShort,
                                  color: AppTheme.lightBlueColor,
                                  onPressed: _canUndo ? _undoLastInput : null,
                                  compact: true,
                                  size: metrics.actionButtonSize,
                                  labelFontSize: metrics.actionLabelFontSize,
                                ),
                                _buildMobileActionButton(
                                  icon: Icons.edit_note,
                                  label: _presenter.isMemoMode
                                      ? AppLocalizations.of(context)!
                                          .gameMemoOnShort
                                      : AppLocalizations.of(context)!
                                          .gameMemoShort,
                                  semanticsLabel: AppLocalizations.of(context)!
                                      .gameMemoShort,
                                  toggled: _presenter.isMemoMode,
                                  color: _presenter.isMemoMode
                                      ? AppTheme.mintColor
                                      : AppTheme.lightBlueColor,
                                  isActive: _presenter.isMemoMode,
                                  emphasizeActiveIcon: true,
                                  onPressed: _canToggleMemo
                                      ? () {
                                          unawaited(_toggleMemoMode());
                                        }
                                      : null,
                                  onLongPress: _canUseAutoNotes
                                      ? () => unawaited(_applyAutoNotes())
                                      : null,
                                  longPressSemanticsHint: AppLocalizations.of(
                                    context,
                                  )!
                                      .gameMemoLongPressHint,
                                  showAutoNotesBadge: true,
                                  compact: true,
                                  size: metrics.actionButtonSize,
                                  labelFontSize: metrics.actionLabelFontSize,
                                ),
                                _buildMobileHintButton(
                                  buttonSize: metrics.actionButtonSize,
                                  labelFontSize: metrics.actionLabelFontSize,
                                ),
                                _buildMobileActionButton(
                                  icon: Icons.backspace_outlined,
                                  label: AppLocalizations.of(context)!
                                      .gameEraseShort,
                                  color: context.colors.attentionSurface,
                                  onPressed: _canEraseSelection
                                      ? _eraseSelectedCell
                                      : null,
                                  compact: true,
                                  size: metrics.actionButtonSize,
                                  labelFontSize: metrics.actionLabelFontSize,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: _kLandscapeEdgeSpacerFlex),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 가로 모드 키패드 칼럼 상단에 붙는 현재 게임 상태 요약 카드들.
  /// (SudokuInfoCard는 기존에 만들어져 있었지만 실제로는 아무 화면에서도
  /// 안 쓰이고 있던 위젯이라 여기서 처음 활용한다.)
  ///
  /// 힌트/완성한 줄 카드는 디자인 검토 후 뺐다: 힌트는 바로 아래 힌트 버튼의
  /// 뱃지와 정보가 겹치고(공유 컴포넌트인 버튼 쪽은 그대로 둠), 완성한 줄은
  /// 27이라는 분모가 직관적이지 않고 진행률%와 개념이 겹쳐서 뺐다.
  Widget _buildLandscapeStatsPanel() {
    final maxWrongCount = _featurePolicy.maxWrongCount;
    final wrongCount = _presenter.wrongCount;

    int filledCount = 0;
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_presenter.getCellValue(row, col) != 0) filledCount++;
      }
    }
    final originalFilledCount = 81 - widget.level.emptyCells;
    final playerFilledCount =
        (filledCount - originalFilledCount).clamp(0, widget.level.emptyCells);
    final progressPercent = widget.level.emptyCells == 0
        ? 0
        : ((playerFilledCount / widget.level.emptyCells) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SudokuInfoCard(
          AppLocalizations.of(context)!.gameWrongShort,
          '$wrongCount/$maxWrongCount',
          Icons.close_rounded,
          // 오답 0개일 때까지 경고색으로 보이지 않도록 accentColor를 안 주고
          // 중립 톤(위젯 기본값)으로 떨어뜨림. 1개 이상부터만 경고색 적용.
          accentColor: wrongCount > 0 ? AppTheme.pinkColor : null,
        ),
        const SizedBox(height: 12),
        SudokuInfoCard(
          AppLocalizations.of(context)!.gameProgressShort,
          '$progressPercent%',
          Icons.donut_large_rounded,
          accentColor: AppTheme.statisticsAccent,
          progressValue: progressPercent / 100,
        ),
      ],
    );
  }

  Widget _buildBoardGrid() {
    // 아이패드 애플펜슬 필기 입력(전용 "펜슬 모드" 없이 넘패드와 항상 병행) —
    // 아이폰은 콜백 자체를 안 넘겨 오버레이가 생성되지 않아 기존과 동일.
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
        child: Stack(
          children: [
            // 칸 크기가 고정이라 시스템 글씨 크기를 따라 숫자가 커지면 칸 안에서 잘린다.
            MediaQuery.withNoTextScaling(
              child: SudokuBoardGrid(
                presenter: _presenter,
                waveActive: _effectsController.waveActive,
                lineCompleteActive: _effectsController.lineCompleteActive,
                errorActive: _effectsController.errorActive,
                errorOffset: _effectsController.errorOffset,
                undoActive: _effectsController.undoActive,
                hintAppliedActive: _effectsController.hintAppliedActive,
                digitCompleteActive: _effectsController.digitCompleteActive,
                showCompletionGlow: _showCompletionGlow,
                highlightedMemoNumber:
                    _memoHighlightEnabled && _featurePolicy.memoEnabled
                        ? _memoFocusNumber
                        : null,
                enableMemoHighlights:
                    _memoHighlightEnabled && _featurePolicy.memoEnabled,
                onCellTapped: (row, col) {
                  final previousRow = _presenter.selectedRow;
                  final previousCol = _presenter.selectedCol;
                  _presenter.selectCell(row, col);
                  // 실제로 선택이 바뀐 경우에만 가볍게 알린다(같은 칸 재선택,
                  // 일시정지·완료 상태의 no-op 탭에서는 울리지 않는다).
                  final didSelectionChange =
                      (previousRow != row || previousCol != col) &&
                          _presenter.selectedRow == row &&
                          _presenter.selectedCol == col;
                  if (didSelectionChange && _isVibrationEnabled) {
                    unawaited(HapticFeedback.selectionClick());
                  }
                },
                hintRegionCells: _activeHint?.regionCells ?? const {},
                hintBlockerCells: _hintStep == 2
                    ? _activeHint?.blockerCells ?? const {}
                    : const {},
                hintTargetCell: _visibleHintTarget,
                onPencilDigit:
                    isTablet && !_isBoardCovered ? _insertDigit : null,
              ),
            ),
            if (_isBoardCovered)
              Positioned.fill(
                child: _buildPauseCover(AppLocalizations.of(context)!),
              ),
            if (_autoNotesFlashKey != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: _autoNotesFlashKey,
                    tween: Tween(begin: 1, end: 0),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 150),
                    builder: (context, t, child) => Opacity(
                      opacity: t * 0.12,
                      child: Container(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _placedCountForNumber(int number) {
    int count = 0;
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (_presenter.getCellValue(row, col) == number) {
          count++;
        }
      }
    }
    return count;
  }

  int _remainingCountForNumber(int number) {
    return (9 - _placedCountForNumber(number)).clamp(0, 9);
  }

  int get _visibleHintsRemaining {
    return _featurePolicy.hintEnabled ? _presenter.hintsRemaining : 0;
  }

  bool _isNumberInputEnabled(int number) {
    if (!_hasEditableSelection) {
      return false;
    }
    return _remainingCountForNumber(number) > 0;
  }

  // 넘패드 탭과 아이패드 애플펜슬 필기 입력이 공유하는 실제 입력 처리.
  // 두 경로 모두 같은 검증/부수효과(진동, 오답셀 타이머, 메모 하이라이트)를
  // 거치도록 한곳에 모아둔다.
  void _insertDigit(int number) {
    if (!_isNumberInputEnabled(number)) return;
    setState(() {
      _memoFocusNumber = _presenter.isMemoMode ? number : null;
    });
    if (!_presenter.isMemoMode) {
      _cancelWrongCellTimer(
        _presenter.selectedRow,
        _presenter.selectedCol,
      );
      unawaited(_vibrateOnNumberInput(number));
    }
    _presenter.setSelectedCellValue(number);
  }

  int? _selectedInputNumber() {
    final row = _presenter.selectedRow;
    final col = _presenter.selectedCol;
    if (row == null || col == null) {
      return null;
    }

    final value = _presenter.getCellValue(row, col);
    if (value == 0) {
      return null;
    }
    return value;
  }

  Widget _buildNumberButton(
    int number, {
    bool compact = false,
    double? width,
    double? height,
    double? borderRadius,
    // 아이패드 가로 모드 전용 옵션(호출부에서만 true로 넘김) — 이 버튼은
    // 폰 레이아웃과 공유하는 컴포넌트라, 폰 쪽 크기에는 영향이 없도록
    // 기본값 false로 두고 랜드스케이프 호출부에서만 켠다.
    bool largeBadge = false,
  }) {
    const buttonColor = AppTheme.lightBlueColor;
    final remainingCount = _remainingCountForNumber(number);
    final isEnabled = _isNumberInputEnabled(number);
    final isSelectedNumber = _selectedInputNumber() == number;
    final isCompletedNumber = remainingCount == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompactSmallButton = compact && height != null && height < 56;
    final buttonWidth = width ?? (compact ? 72 : 95);
    // largeBadge(아이패드 가로 모드) 버튼은 밀도 축소 탓에 폭이 좁아서(~80px대),
    // 뱃지를 그냥 키우면 정가운데 정렬된 숫자와 우상단 뱃지가 겹친다. 숫자는
    // 항상 정가운데를 유지하되, 좁은 폭에서는 뱃지를 살짝 줄이고 숫자 폭도
    // 버튼 폭 기준 상한을 둬서 서로 겹치지 않게 한다. 폰(largeBadge=false,
    // buttonWidth가 훨씬 넓음)에서는 이 상한에 걸리지 않아 기존과 동일하다.
    final digitFontSize = isCompactSmallButton
        ? (height * 0.58).clamp(28.0, 34.0)
        : math.min(38.0, buttonWidth * 0.42);
    const digitAlignment = Alignment.center;
    final badgeBaseSize = isCompactSmallButton ? 22.0 : 24.0;
    final badgeBaseInset = isCompactSmallButton ? 7.0 : 10.0;
    final badgeSize =
        largeBadge ? (buttonWidth * 0.23).clamp(18.0, 22.0) : badgeBaseSize;
    final badgeInset =
        largeBadge ? (buttonWidth * 0.08).clamp(6.0, 8.0) : badgeBaseInset;
    final badgeScale = badgeSize / badgeBaseSize;
    final effectiveBackgroundColor = isCompletedNumber
        ? (isDark ? const Color(0xFF232323) : context.colors.surfaceSubtle)
        : isSelectedNumber
            ? (isDark
                ? const Color(0xFF2C4055)
                : buttonColor.withValues(alpha: 0.22))
            : (isDark ? const Color(0xFF323232) : context.colors.surface);

    final button = MediaQuery.withNoTextScaling(
        child: ProgressiveBlurButton(
      onPressed: isEnabled ? () => _insertDigit(number) : null,
      backgroundColor: effectiveBackgroundColor,
      width: width ?? (compact ? 72 : 95),
      height: height ?? (compact ? 56 : 70),
      borderRadius: borderRadius ?? (compact ? 20 : 28),
      enablePressScale: true,
      child: Stack(
        children: [
          if (isSelectedNumber)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    borderRadius ?? (compact ? 20 : 28),
                  ),
                  border: Border.all(
                    color: buttonColor.withValues(alpha: 0.75),
                    width: 1.6,
                  ),
                ),
              ),
            ),
          Align(
            alignment: digitAlignment,
            child: Text(
              number.toString(),
              style: GoogleFonts.notoSans(
                      fontSize: digitFontSize,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary)
                  .copyWith(
                fontWeight: isSelectedNumber ? FontWeight.w800 : null,
              ),
            ),
          ),
          Positioned(
            top: badgeInset,
            right: badgeInset,
            child: Container(
              width: badgeSize,
              height: badgeSize,
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
                  width: 1,
                ),
              ),
              child: AnimatedSwitcher(
                duration: _effectsController.reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: isCompletedNumber
                    ? Icon(
                        Icons.check_rounded,
                        key: const ValueKey('badge-check'),
                        size: (compact ? 16 : 18) * badgeScale,
                        color: isDark
                            ? const Color(0xFF5A8A70)
                            : AppTheme.lightBlueColor,
                      )
                    : Text(
                        '$remainingCount',
                        key: ValueKey('badge-count-$remainingCount'),
                        style: GoogleFonts.notoSans(
                          fontSize:
                              (isCompactSmallButton ? 9 : (compact ? 10 : 11)) *
                                  badgeScale,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? context.colors.textSecondary
                              : context.colors.textPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    ));

    if (number != _numberPopDigit) {
      return button;
    }
    // 이 숫자를 방금 9개 모두 채웠을 때만: 1.0 → 1.08 → 1.0으로 한 번
    // 튀는 완료 반응(220ms). begin==end==1.0이면 Tween 보간이 그대로
    // 상수가 되므로, t(0~1)를 받아 피크(1.08)를 직접 계산한다.
    return TweenAnimationBuilder<double>(
      key: ValueKey('numpad-pop-$number'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      builder: (context, t, child) {
        final scale = t < 0.45
            ? 1.0 + 0.08 * Curves.easeOut.transform(t / 0.45)
            : 1.08 - 0.08 * Curves.easeIn.transform((t - 0.45) / 0.55);
        return Transform.scale(scale: scale, child: child);
      },
      child: button,
    );
  }

  void _scheduleWrongCellAutoClear(int row, int col) {
    final key = '$row,$col';
    _wrongCellTimers[key]?.cancel();
    _wrongCellTimers[key] = Timer(
      const Duration(milliseconds: 800),
      () {
        _wrongCellTimers.remove(key);
        if (!mounted) return;
        _presenter.clearCellValue(row, col);
        setState(() {});
      },
    );
  }

  void _cancelAllWrongCellTimers() {
    for (final timer in _wrongCellTimers.values) {
      timer.cancel();
    }
    _wrongCellTimers.clear();
  }

  void _cancelWrongCellTimer(int? row, int? col) {
    if (row == null || col == null) return;
    final key = '$row,$col';
    _wrongCellTimers[key]?.cancel();
    _wrongCellTimers.remove(key);
  }

  Future<void> _vibrateOnNumberInput(int number) async {
    if (!_isVibrationEnabled || !_presenterReady) return;

    final selectedRow = _presenter.selectedRow;
    final selectedCol = _presenter.selectedCol;
    if (selectedRow == null || selectedCol == null) return;
    if (_presenter.isCellFixed(selectedRow, selectedCol)) return;
    if (_presenter.isHintCell(selectedRow, selectedCol)) return;
    if (_presenter.isPaused ||
        _presenter.isGameComplete ||
        _presenter.isGameOver) {
      return;
    }

    final isCorrectInput =
        number == _presenter.getCorrectValue(selectedRow, selectedCol);
    if (isCorrectInput) {
      await HapticFeedback.lightImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  Widget _buildMobileActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool isActive = false,
    bool compact = false,
    double? size,
    double? labelFontSize,
    // 아이패드 가로 모드 전용 옵션(호출부에서만 true로 넘김) — true면 활성
    // 상태일 때 아이콘 색도 포인트 컬러(color)로 바꿔서 on/off를 더 뚜렷하게
    // 보여준다. 폰 레이아웃 호출부는 그대로 둬서 기존 모습이 안 바뀐다.
    bool emphasizeActiveIcon = false,
    // 스크린리더용 이름(라벨이 "메모 ON"처럼 상태를 포함할 때 기본 이름을 따로 전달)
    // 과 토글 상태. toggled가 null이면 토글 버튼이 아니다.
    String? semanticsLabel,
    bool? toggled,
    // 메모 버튼 전용(호출부에서만 넘김): 길게 누르면 자동 메모를 실행한다.
    // null이면(다른 버튼들) 기존과 완전히 동일하게 동작한다.
    VoidCallback? onLongPress,
    String? longPressSemanticsHint,
    bool showAutoNotesBadge = false,
  }) {
    final buttonSize =
        size ?? (compact ? 52.0 : (_oneHandModeEnabled ? 62.0 : 70.0));
    final iconSize =
        compact ? buttonSize * 0.36 : (_oneHandModeEnabled ? 28.0 : 32.0);
    final hasLabel = label.isNotEmpty;
    Widget button = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 1 : (_oneHandModeEnabled ? 2 : 3),
        vertical: compact ? 0.5 : (_oneHandModeEnabled ? 2 : 3),
      ),
      child: Semantics(
        container: true,
        hint: longPressSemanticsHint,
        button: true,
        enabled: onPressed != null,
        toggled: toggled,
        label: semanticsLabel ?? label,
        excludeSemantics: true,
        onTap: onPressed,
        child: ProgressiveBlurButton(
          onPressed: onPressed,
          width: buttonSize,
          height: buttonSize,
          borderRadius: buttonSize / 2,
          backgroundColor: color,
          isActive: isActive,
          child: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final contentColor = (isActive && isDark)
                  ? const Color(0xFF6DCCA0)
                  : (isActive && emphasizeActiveIcon)
                      ? color
                      : Theme.of(context).colorScheme.onSurface;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: contentColor, size: iconSize - 1),
                  if (hasLabel) ...[
                    SizedBox(height: compact ? 2 : 4),
                    // 큰 글씨/좁은 화면에서도 원형 버튼 안에 이름이 들어오도록
                    // 배율 상한을 두고 폭에 맞춰 줄인다.
                    MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.3,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: buttonSize * 0.86),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            maxLines: 1,
                            style: GoogleFonts.notoSans(
                              color: contentColor,
                              fontSize: labelFontSize ??
                                  (compact
                                      ? 8
                                      : (_oneHandModeEnabled ? 10 : 11)),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
    if (showAutoNotesBadge) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: compact ? 2 : 4,
            right: compact ? 6 : 8,
            child: IgnorePointer(
              child: Icon(
                Icons.auto_awesome,
                size: compact ? 12 : 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }
    if (onLongPress != null) {
      button = GestureDetector(onLongPress: onLongPress, child: button);
    }
    return button;
  }

  Widget _buildMobileHintButton({
    required double buttonSize,
    required double labelFontSize,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildMobileActionButton(
          icon: Icons.lightbulb_outline,
          label: AppLocalizations.of(context)!.gameHintShort,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF8A6820)
              : AppTheme.yellowColor,
          isActive: false,
          onPressed: _canUseHint ? _startHint : null,
          compact: true,
          size: buttonSize,
          labelFontSize: labelFontSize,
        ),
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _featurePolicy.hintEnabled && _presenter.hintsRemaining > 0
                  ? const Color(0xFF457B9D)
                  : const Color(0xFFAAAAAA),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? context.colors.background
                    : Colors.white,
                width: 1.5,
              ),
            ),
            child: Text(
              '$_visibleHintsRemaining',
              // 18px 고정 원 안이므로 시스템 글씨 크기를 따르지 않는다.
              textScaler: TextScaler.noScaling,
              style: GoogleFonts.notoSans(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 게임 완료 다이얼로그 표시
  void _showGameCompleteDialog() async {
    if (!mounted) return;
    await _gameEndFlow.showCompletion(
      context: context,
      level: widget.level,
      game: widget.game,
      clearTimeSeconds: _presenter.seconds,
      wrongCount: _presenter.wrongCount,
      hintsUsed: _featurePolicy.maxHints - _presenter.hintsRemaining,
      autoNotesUsed: _presenter.autoNotesUsed,
      challengeDate: _challengeDate,
      challengeCountsForStreak: widget.challengeCountsForStreak,
      onRestart: _resetAndRestartCurrentGame,
      onGoToLevelSelection: _exitToLevelSelection,
      onNextPuzzle: (nextGame) async {
        if (!mounted) return;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (ctx) => SudokuGameScreen(
              game: nextGame,
              level: widget.level,
              restoreSavedSession: true,
            ),
          ),
        );
      },
    );
  }

  /// 게임 오버 다이얼로그 표시
  void _showGameOverDialog() {
    _gameEndFlow.showGameOver(
      context: context,
      wrongCount: _presenter.wrongCount,
      maxWrongCount: _featurePolicy.maxWrongCount,
      onRestart: _resetAndRestartCurrentGame,
      onGoToLevelSelection: _exitToLevelSelection,
    );
  }

  Widget _buildDeveloperAnswerPreview(AppLocalizations l10n) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }
    if (!_showDeveloperAnswerPreview) {
      return const SizedBox.shrink();
    }

    return SudokuAnswerBox(
      answer: getSelectedCellAnswer(),
      answerLabel: l10n.gameAnswerPreview,
    );
  }

  void _toggleDeveloperAnswerPreview() {
    if (!kDebugMode) return;
    setState(() {
      _showDeveloperAnswerPreview = !_showDeveloperAnswerPreview;
    });

    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    final message = _showDeveloperAnswerPreview
        ? (isKorean
            ? '개발자 정답 미리보기를 켰습니다.'
            : 'Developer answer preview enabled.')
        : (isKorean
            ? '개발자 정답 미리보기를 껐습니다.'
            : 'Developer answer preview disabled.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 선택된 셀의 정답을 반환
  int? getSelectedCellAnswer() {
    if (_presenter.selectedRow == null || _presenter.selectedCol == null) {
      return null;
    }

    final row = _presenter.selectedRow!;
    final col = _presenter.selectedCol!;

    if (kDebugMode) {
      AppLogger.debug('정답 조회: 게임 ${widget.game.gameNumber}, 셀 [$row][$col]');
    }

    try {
      final answer = _presenter.getCorrectValue(row, col);
      if (kDebugMode) {
        AppLogger.debug('정답 조회 성공: [$row][$col] = $answer');
      }
      return answer;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('정답 계산 중 오류: $e');
      }
    }

    if (kDebugMode) {
      AppLogger.debug('정답을 찾을 수 없음');
    }
    return null;
  }
}

enum _DeveloperCheatAction {
  toggleAnswerPreview,
  fillSelected,
  autoSolve,
}

/// 완성 안내 칩의 문구를 고르기 위한 완성 영역 종류.
enum _LineWaveKind { row, col, box }

class _MobileGameLayoutMetrics {
  const _MobileGameLayoutMetrics({
    required this.horizontalPadding,
    required this.topPadding,
    required this.sectionGap,
    required this.compactGap,
    required this.boardSize,
    required this.numberButtonWidth,
    required this.numberButtonHeight,
    required this.numberButtonRadius,
    required this.numberButtonGap,
    required this.actionButtonSize,
    required this.actionLabelFontSize,
    required this.scrollBottomPadding,
  });

  final double horizontalPadding;
  final double topPadding;
  final double sectionGap;
  final double compactGap;
  final double boardSize;
  final double numberButtonWidth;
  final double numberButtonHeight;
  final double numberButtonRadius;
  final double numberButtonGap;
  final double actionButtonSize;
  final double actionLabelFontSize;
  final double scrollBottomPadding;

  factory _MobileGameLayoutMetrics.fromConstraints({
    required double maxWidth,
    required double maxHeight,
    required double bottomSafePadding,
  }) {
    final isIPhoneSELayout = maxWidth <= 375 && maxHeight <= 620;
    final horizontalPadding = isIPhoneSELayout
        ? _clamp(maxWidth * 0.008, 2, 6)
        : _clamp(maxWidth * 0.015, 4, 8);
    final contentWidth = math.max(maxWidth - (horizontalPadding * 2), 220.0);

    final numberButtonGap = isIPhoneSELayout
        ? (contentWidth < 350 ? 2.0 : 3.0)
        : (contentWidth < 350 ? 3.0 : 5.0);
    final numberButtonWidth = _clamp(
      (contentWidth - (numberButtonGap * 6)) / 3,
      74,
      isIPhoneSELayout ? 128 : 180,
    );
    final baseNumberButtonHeight = isIPhoneSELayout
        ? _clamp(numberButtonWidth * 0.32, 36, 40)
        : _clamp(numberButtonWidth * 0.66, 48, 68);
    final numberButtonRadius = isIPhoneSELayout
        ? _clamp(numberButtonWidth * 0.2, 14, 22)
        : _clamp(numberButtonWidth * 0.24, 16, 28);

    final actionButtonGap = contentWidth < 350 ? 3.0 : 4.0;
    final baseActionButtonSize = _clamp(
      (contentWidth - (actionButtonGap * 14)) / 6,
      isIPhoneSELayout ? 34 : 36,
      isIPhoneSELayout ? 40 : 70,
    );

    final sectionGap = isIPhoneSELayout ? 3.0 : (maxHeight < 760 ? 4.0 : 8.0);
    final compactGap = isIPhoneSELayout ? 1.0 : (maxHeight < 760 ? 2.0 : 4.0);

    final estimatedNumberPadHeight =
        (baseNumberButtonHeight * 3) + (numberButtonGap * 4);
    final estimatedActionRowHeight = baseActionButtonSize + 8.0;
    final fixedChromeHeight = estimatedNumberPadHeight +
        estimatedActionRowHeight +
        bottomSafePadding +
        (isIPhoneSELayout ? 0 : 12.0);

    final baseBoardSize =
        _clamp(contentWidth, 292, isIPhoneSELayout ? 520 : 680);
    final estimatedTotalHeight = fixedChromeHeight + baseBoardSize;
    final overflow = math.max(0.0, estimatedTotalHeight - maxHeight);
    final boardSize =
        _clamp(baseBoardSize - overflow, 256, isIPhoneSELayout ? 520 : 680);

    // Grow the keypad/action buttons with height that's genuinely left over
    // after the (width-bound) board and required chrome are placed — never
    // at the board's expense. Applies uniformly across device sizes so
    // leftover space doesn't sit as dead margin around the board on smaller
    // phones (e.g. iPhone SE) the way it's absorbed into the keypad on larger
    // ones.
    final leftoverHeight = math.max(
      0.0,
      maxHeight -
          (boardSize +
              sectionGap +
              estimatedNumberPadHeight +
              compactGap +
              estimatedActionRowHeight +
              bottomSafePadding),
    );
    final extraPerRow = math.min(leftoverHeight / 4, 16.0);
    final numberButtonHeight =
        math.min(baseNumberButtonHeight + extraPerRow, 116.0);
    final actionButtonSize = math.min(baseActionButtonSize + extraPerRow, 82.0);
    final actionLabelFontSize = actionButtonSize <= 50 ? 7.5 : 8.5;

    // 숫자 패드 한 줄(3버튼)의 전체 폭이 보드 폭과 같아지도록 정렬.
    final alignedNumberButtonWidth = isIPhoneSELayout
        ? numberButtonWidth
        : math.max((boardSize - numberButtonGap * 3) / 3, numberButtonWidth);

    return _MobileGameLayoutMetrics(
      horizontalPadding: horizontalPadding,
      topPadding: 0,
      sectionGap: sectionGap,
      compactGap: compactGap,
      boardSize: boardSize,
      numberButtonWidth: alignedNumberButtonWidth,
      numberButtonHeight: numberButtonHeight,
      numberButtonRadius: numberButtonRadius,
      numberButtonGap: numberButtonGap,
      actionButtonSize: actionButtonSize,
      actionLabelFontSize: actionLabelFontSize,
      scrollBottomPadding:
          isIPhoneSELayout ? bottomSafePadding : bottomSafePadding + 4,
    );
  }

  static double _clamp(double value, double min, double max) {
    return math.max(min, math.min(value, max));
  }
}

/// 아이패드 가로 모드(좌: 보드 / 우: 키패드) 전용 레이아웃 치수 계산.
class _TabletLandscapeGameLayoutMetrics {
  const _TabletLandscapeGameLayoutMetrics({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.sectionGap,
    required this.compactGap,
    required this.boardSize,
    required this.keypadColumnWidth,
    required this.numberButtonWidth,
    required this.numberButtonHeight,
    required this.numberButtonRadius,
    required this.numberButtonGap,
    required this.actionButtonSize,
    required this.actionLabelFontSize,
    required this.bottomSafePadding,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double sectionGap;
  final double compactGap;
  final double boardSize;
  final double keypadColumnWidth;
  final double numberButtonWidth;
  final double numberButtonHeight;
  final double numberButtonRadius;
  final double numberButtonGap;
  final double actionButtonSize;
  final double actionLabelFontSize;
  final double bottomSafePadding;

  factory _TabletLandscapeGameLayoutMetrics.fromConstraints({
    required double maxWidth,
    required double maxHeight,
    required double bottomSafePadding,
    required double horizontalSafePadding,
    // 키패드 칼럼을 감싸는 컨트롤 패널 테두리의 내부 여백. 이 여백만큼
    // 숫자패드/액션 버튼이 실제로 쓸 수 있는 폭·높이가 줄어드므로 버튼
    // 크기 계산에 반영해야 오버플로우가 안 난다.
    required double panelPadding,
  }) {
    final horizontalPadding =
        _clamp(maxWidth * 0.02, 16, 28) + horizontalSafePadding;
    final verticalPadding = _clamp(maxHeight * 0.02, 10, 20);
    final sectionGap = _clamp(maxWidth * 0.02, 16, 32);
    final contentHeight = math.max(maxHeight - (verticalPadding * 2), 300.0);

    // 키패드 패널 폭: 전체 폭의 일부를 고정 비율로 확보.
    final keypadColumnWidth = _clamp(maxWidth * 0.30, 240, 340);

    final boardAreaWidth = math.max(
      maxWidth - keypadColumnWidth - sectionGap - (horizontalPadding * 2),
      240.0,
    );
    final boardSize = _clamp(math.min(boardAreaWidth, contentHeight), 300, 680);

    // 키패드 칼럼을 감싸는 패널 테두리 안쪽에서 실제로 쓸 수 있는 폭/높이.
    final usableKeypadWidth = keypadColumnWidth - (panelPadding * 2);
    final keypadContentHeight =
        math.max(contentHeight - (panelPadding * 2), 200.0);

    const numberButtonGap = 8.0;
    // 태블릿 가로 모드에서 숫자패드가 다소 커 보인다는 피드백에 따라
    // 8% 축소(밀도 개선). 버튼 사이 gap/keypadColumnWidth는 그대로 두고
    // 버튼 자체만 살짝 줄이므로, 남는 폭은 각 행이 가운데 정렬되며
    // 자연스러운 여백으로 흡수된다 — 오버플로우 쪽으로는 절대 안 커짐.
    const numberPadDensityFactor = 0.92;
    // 각 버튼이 Padding(horizontal: numberButtonGap / 2)을 개별로 두르고 있어
    // 양 끝 버튼 바깥쪽에도 gap이 생기므로, 실제로 소모되는 간격은 2개가 아니라
    // 버튼 개수(3)만큼이다. 간격을 2개로 잘못 가정하면 항상 8px 오버플로우한다.
    final rawNumberButtonWidth =
        (usableKeypadWidth - numberButtonGap * 3) / 3 * numberPadDensityFactor;
    // 64를 무조건 하한으로 두면(패널 패딩까지 뺀 뒤라 폭이 이미 빠듯한
    // 상황에서) 하한이 실제로 들어갈 수 있는 폭보다 커져 오버플로우가 날 수
    // 있다. rawNumberButtonWidth가 64보다 작을 땐 하한을 그 값 자체로 낮춰서,
    // "정확히 들어맞는 값" 위로는 절대 안 올라가도록 한다.
    final numberButtonWidth = _clamp(
      rawNumberButtonWidth,
      math.min(64.0, rawNumberButtonWidth),
      128,
    );
    final numberButtonRadius = _clamp(numberButtonWidth * 0.22, 14, 26);
    final compactGap = _clamp(maxHeight * 0.015, 8, 18);

    var numberButtonHeight = _clamp(numberButtonWidth * 0.78, 52, 104);
    var actionButtonSize = _clamp(numberButtonWidth * 0.72, 48, 84);

    // 오버플로우 방지: 숫자 패드 3행 + 액션 버튼 행이 사용 가능한 높이를 넘으면 축소.
    final estimatedBlockHeight = (numberButtonHeight * 3) +
        (numberButtonGap * 2) +
        compactGap +
        actionButtonSize;
    if (estimatedBlockHeight > keypadContentHeight) {
      final scale = keypadContentHeight / estimatedBlockHeight;
      numberButtonHeight = math.max(numberButtonHeight * scale, 44.0);
      actionButtonSize = math.max(actionButtonSize * scale, 40.0);
    }

    final actionLabelFontSize = actionButtonSize <= 56 ? 8.0 : 9.0;

    return _TabletLandscapeGameLayoutMetrics(
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      sectionGap: sectionGap,
      compactGap: compactGap,
      boardSize: boardSize,
      keypadColumnWidth: keypadColumnWidth,
      numberButtonWidth: numberButtonWidth,
      numberButtonHeight: numberButtonHeight,
      numberButtonRadius: numberButtonRadius,
      numberButtonGap: numberButtonGap,
      actionButtonSize: actionButtonSize,
      actionLabelFontSize: actionLabelFontSize,
      bottomSafePadding: bottomSafePadding,
    );
  }

  static double _clamp(double value, double min, double max) {
    return math.max(min, math.min(value, max));
  }
}
