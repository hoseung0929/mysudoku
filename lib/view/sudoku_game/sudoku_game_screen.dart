import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
import 'package:sudoku159/utils/time_format.dart';
import 'package:sudoku159/view/sudoku_game/game_end_flow.dart';
import 'package:sudoku159/view/sudoku_game/game_session_controller.dart';
import 'package:sudoku159/view/sudoku_game/game_settings_controller.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_answer_box.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_board_grid.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_info_card.dart';
import 'package:sudoku159/view/sudoku_game/game_effects_controller.dart';
import 'package:sudoku159/services/game/auto_notes_tip_service.dart';
import 'package:sudoku159/services/game/number_lock_tip_service.dart';
import 'package:sudoku159/view/sudoku_game/game_feedback_resolver.dart';
import 'package:sudoku159/view/home/level_picker_screen.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/widgets/sentence_text.dart';
import 'package:sudoku159/widgets/progressive_blur_button.dart';
import 'package:sudoku159/widgets/waddling_penguin_icon.dart';

/// 되돌리기(다시 실행 포함) 버튼 노출 여부. 현재는 숨긴다. 되돌리기 기록·`undo()`·
/// `redo()` 로직과 저장 구조는 그대로 보존한다.
// TODO: 되돌리기 노출 정책이 정해지면 다시 켠다.
const bool kUndoButtonEnabled = false;

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

  /// 되돌리기 버튼 표시 여부([kUndoButtonEnabled]). 숨겨 둔 되돌리기 동작을 테스트로
  /// 계속 검증할 수 있게 열어 둔 인자다.
  @visibleForTesting
  final bool showUndoButton;

  const SudokuGameScreen({
    super.key,
    required this.game,
    required this.level,
    this.restoreSavedSession = false,
    this.challengeDate,
    this.challengeCountsForStreak = true,
    this.showUndoButton = kUndoButtonEnabled,
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
  int? _lockedInputNumber;
  final Set<int> _celebratedProgressMilestones = <int>{};
  // 자동 메모 적용 직후 보드 전체에 짧게 강조를 준다. 트리거될 때마다 새 키를
  // 줘서 TweenAnimationBuilder가 처음부터 다시 재생하게 한다.
  Key? _autoNotesFlashKey;
  bool _autoNotesTipShown = false;
  bool _numberLockTipShown = false;
  InputFeedbackEvents? _feedbackEvents;
  int _numberInputCount = 0;
  final GameEffectsController _effectsController = GameEffectsController();
  final AutoNotesTipService _autoNotesTipService = AutoNotesTipService();
  final NumberLockTipService _numberLockTipService = NumberLockTipService();
  final Map<String, Timer> _wrongCellTimers = {};
  Set<int> _completedUnitIds = {};
  bool _isPenguinActive = false;
  Timer? _penguinActiveTimer;
  bool _autoPausedByLifecycle = false;

  /// 설명 중인 힌트와 단계(1: 살펴볼 곳, 2: 기법과 이유).

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

  /// 새로 완성된 유닛이 있으면 펭귄이 짧게(약 1.8초) 뒤뚱거리도록 트리거합니다.
  void _checkForNewlyCompletedUnits() {
    final completed = _computeCompletedUnitIds();
    final hasNewCompletion = completed.difference(_completedUnitIds).isNotEmpty;
    _completedUnitIds = completed;
    if (hasNewCompletion) {
      _triggerPenguinBurst();
    }
  }

  void _triggerPenguinBurst({
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    _penguinActiveTimer?.cancel();
    setState(() => _isPenguinActive = true);
    _penguinActiveTimer = Timer(duration, () {
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

  // 자동 메모는 향후 유료 편의 서비스로 제공할 예정입니다.
  // 결제 및 이용 권한 확인 기능이 구현될 때까지 사용자에게 노출하지 않습니다.
  // TODO(premium): 자동 메모는 향후 유료 편의 기능으로 제공한다.
  // 인앱 구매 권한 확인과 보조 기능 사용 기록 정책이 확정되면 다시 활성화한다.
  static const bool _autoNotesEnabled = false;

  /// 자동 메모는 기능이 켜져 있고, 메모 버튼을 쓸 수 있는 상태이면서, 힌트 패널이
  /// 열려 있지 않을 때만 실행한다. 꺼져 있으면 길게 누르기·확인창·안내·배지가
  /// 모두 나타나지 않는다.
  bool get _canUseAutoNotes => _autoNotesEnabled && _canToggleMemo;

  Future<void> _toggleMemoMode() async {
    final wasOff = !_presenter.isMemoMode;
    setState(() {
      _memoFocusNumber = null;
      _presenter.toggleMemoMode();
    });
    if (_autoNotesEnabled && wasOff && _presenter.isMemoMode) {
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

  // TODO(premium): 자동 메모 실행 진입점. 유료 기능 권한 확인과 연결해 다시 연다.
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

  /// 힌트는 사용자가 선택한 칸의 정답을 바로 채워 준다. 남은 힌트가 있고, 선택한
  /// 칸이 고정·힌트 칸이 아니며 아직 정답이 아닐 때만 쓸 수 있다(선택한 칸이 없으면
  /// 비활성).
  bool get _canUseHint {
    if (!_presenterReady ||
        !_featurePolicy.hintEnabled ||
        _presenter.isPaused ||
        _presenter.isGameComplete ||
        _presenter.isGameOver ||
        !_hasEditableSelection) {
      return false;
    }
    final row = _presenter.selectedRow!;
    final col = _presenter.selectedCol!;
    final isCorrect = _presenter.getCellValue(row, col) ==
        _presenter.solutionSnapshot[row][col];
    return _presenter.hintsRemaining > 0 && !isCorrect;
  }

  /// `onCorrectAnswer` 콜백이 [revealHintAt] 안에서 동기적으로 실행되는
  /// 동안만 켠다. 그동안은 일반 정답 강조 대신 힌트 전용 강조를 쓴다.
  bool _isApplyingHintFill = false;

  /// 힌트 버튼: 선택한 칸에 정답을 넣고 그 칸을 힌트 칸으로 고정한다. 힌트는 정답이
  /// 들어가는 이 순간에 1개 차감된다.
  void _startHint() {
    if (!_canUseHint) return;
    final row = _presenter.selectedRow!;
    final col = _presenter.selectedCol!;
    if (!_presenter.consumeHint()) return;
    setState(() {
      _memoFocusNumber = null;
      _lockedInputNumber = null;
    });
    _cancelWrongCellTimer(row, col);
    // 정답 입력과 저장은 동기로 즉시 처리되고, 강조 애니메이션은 기다리지 않는다.
    _isApplyingHintFill = true;
    try {
      _presenter.revealHintAt(row, col);
    } finally {
      _isApplyingHintFill = false;
    }
  }

  bool get _canEraseSelection =>
      _presenterReady && _presenter.canEraseSelectedCell;

  void _eraseSelectedCell() {
    if (!_canEraseSelection) return;
    final row = _presenter.selectedRow!;
    final col = _presenter.selectedCol!;
    _cancelWrongCellTimer(row, col);
    _presenter.eraseSelectedCell();
    _effectsController.triggerEraseEffect(
      row: row,
      col: col,
      setState: setState,
      isMounted: () => mounted,
    );
    if (_isVibrationEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  bool get _canUndo => _presenterReady && _presenter.canUndo;
  bool get _canRedo => _presenterReady && _presenter.canRedo;

  /// presenter.undo()가 동기적으로 실행되는 동안만 켠다. onBoardChanged
  /// 콜백이 이 플래그를 보고 정답·오답·줄 완성 효과를 재실행하지 않는다.
  bool _isApplyingUndo = false;

  /// 퍼즐 완료 연출(보드 글로우) 표시 여부. true인 동안 결과 다이얼로그는
  /// 아직 뜨지 않은 상태다.
  bool _showCompletionGlow = false;

  /// [onGameCompleteChanged]가 두 번 이상 호출되어도 완료 연출·다이얼로그가
  /// 중복 실행되지 않도록 막는 가드.
  bool _completionSequenceStarted = false;

  /// 완료 연출이 끝난 뒤 다이얼로그를 여는 예약 작업. 화면이 닫히면
  /// (뒤로 가기 등으로 dispose되면) 취소해 언마운트된 context로 다이얼로그를
  /// 열려는 시도를 막는다.
  Timer? _completionSequenceTimer;

  /// 연출 오버레이를 끄는 예약 작업([_completionSequenceTimer]와 함께 취소한다).
  Timer? _completionGlowEndTimer;

  /// 글로우 정점에 완료 햅틱을 울리는 예약 작업([_completionSequenceTimer]와
  /// 함께 취소한다).
  Timer? _completionHapticTimer;

  /// 마지막 숫자를 넣은 칸. 완료 연출(팝·빛 번짐·박스 경계)의 출발점이다.
  (int, int)? _lastCorrectCell;

  /// 완료 연출이 진행 중이고 결과 다이얼로그가 아직 뜨기 전인지. 이 동안은
  /// 입력·버튼·뒤로 가기를 막는다.
  bool get _isCompletionEffectRunning => _completionSequenceTimer != null;

  void _cancelCompletionTimers() {
    _completionSequenceTimer?.cancel();
    _completionSequenceTimer = null;
    _completionGlowEndTimer?.cancel();
    _completionGlowEndTimer = null;
    _completionHapticTimer?.cancel();
    _completionHapticTimer = null;
  }

  /// 마지막 칸의 정답 강조(팝) → 보드 글로우+박스 경계+입자 → 완성 보드 잠깐
  /// 유지 → 결과 다이얼로그 순서로 진행하는 퍼즐 완료 연출을 시작한다.
  /// 햅틱은 마지막 숫자 확정 순간(medium)과 글로우 정점(heavy)에 한 번씩 울린다.
  void _beginPuzzleCompleteSequence() {
    if (_completionSequenceStarted) return;
    _completionSequenceStarted = true;
    final reduced = _effectsController.reduceMotion;
    final glow = reduced
        ? GameEffectsController.puzzleCompleteGlowDurationReduced
        : GameEffectsController.puzzleCompleteGlowDuration;
    final hold = reduced
        ? GameEffectsController.puzzleCompleteHoldReduced
        : -GameEffectsController.puzzleCompleteDialogLead;
    setState(() => _showCompletionGlow = true);
    final hapticAt =
        reduced ? glow : GameEffectsController.puzzleCompleteHapticAt;
    _completionHapticTimer = Timer(hapticAt, () {
      _completionHapticTimer = null;
      if (mounted && _isVibrationEnabled) {
        unawaited(HapticFeedback.heavyImpact());
      }
    });
    _completionGlowEndTimer = Timer(glow, () {
      _completionGlowEndTimer = null;
      if (!mounted) return;
      setState(() => _showCompletionGlow = false);
    });
    _completionSequenceTimer = Timer(glow + hold, () {
      _completionSequenceTimer = null;
      if (!mounted) return;
      setState(() {});
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
  /// 이 입력의 피드백 이벤트에 기록한다(숫자 고정은 여기서 푼다). 안내·진동·
  /// 효과는 입력이 끝난 뒤 [_flushFeedback]이 우선순위대로 한 번만 실행한다.
  void _maybeCelebrateDigitCompletion(int row, int col) {
    final value = _presenter.getCellValue(row, col);
    if (value == 0 || _celebratedCompleteDigits.contains(value)) return;
    if (_remainingCountForNumber(value) != 0) return;
    _celebratedCompleteDigits.add(value);

    if (_lockedInputNumber == value) {
      setState(() => _lockedInputNumber = null);
    }
    _recordFeedback((e) => e.completedDigit = value);
  }

  /// 숫자 버튼의 완료 팝(220ms)과 보드의 숫자 9칸 강조를 재생한다. 동작 줄이기에서는
  /// 생략한다(배지의 체크 전환은 그대로 적용된다).
  void _playDigitCompleteEffects(
    int digit, {
    required bool pop,
    required bool boardHighlight,
  }) {
    if (_effectsController.reduceMotion) return;
    if (pop) {
      _numberPopTimer?.cancel();
      setState(() => _numberPopDigit = digit);
      _numberPopTimer = Timer(const Duration(milliseconds: 220), () {
        _numberPopTimer = null;
        if (!mounted) return;
        setState(() => _numberPopDigit = null);
      });
    }
    if (boardHighlight) {
      _effectsController.triggerDigitCompleteEffect(
        digit: digit,
        board: _presenter.boardSnapshot,
        setState: setState,
        isMounted: () => mounted,
      );
    }
  }

  /// 입력 하나에서 발생한 피드백 이벤트를 모은다. 콜백들이 같은 동기 호출 안에서
  /// 호출되므로 마이크로태스크에서 한 번에 정리하면 한 입력의 이벤트가 모두
  /// 모인 뒤 우선순위를 적용할 수 있다.
  void _recordFeedback(void Function(InputFeedbackEvents events) update) {
    var events = _feedbackEvents;
    if (events == null) {
      events = _feedbackEvents = InputFeedbackEvents();
      scheduleMicrotask(_flushFeedback);
    }
    update(events);
  }

  void _flushFeedback() {
    final events = _feedbackEvents;
    _feedbackEvents = null;
    if (events == null || !mounted) return;
    final resolved = GameFeedbackResolver.resolve(events);
    final digit = events.completedDigit;
    if (digit != null && (resolved.digitPop || resolved.digitBoardHighlight)) {
      _playDigitCompleteEffects(
        digit,
        pop: resolved.digitPop,
        boardHighlight: resolved.digitBoardHighlight,
      );
    }
    if (resolved.progressPenguin) {
      _triggerPenguinBurst(duration: const Duration(milliseconds: 1500));
    }
    // 동작 줄이기에서는 완료 햅틱을 글로우 시점의 한 번으로 줄인다.
    final skipForReducedCompletion =
        events.puzzleComplete && _effectsController.reduceMotion;
    if (_isVibrationEnabled && !skipForReducedCompletion) {
      unawaited(_performHaptic(resolved.haptic));
    }
  }

  Future<void> _performHaptic(FeedbackHaptic haptic) async {
    switch (haptic) {
      case FeedbackHaptic.none:
        return;
      case FeedbackHaptic.selectionClick:
        await HapticFeedback.selectionClick();
      case FeedbackHaptic.lightImpact:
        await HapticFeedback.lightImpact();
      case FeedbackHaptic.mediumImpact:
        await HapticFeedback.mediumImpact();
      case FeedbackHaptic.heavyImpact:
        await HapticFeedback.heavyImpact();
      case FeedbackHaptic.gameOver:
        // 3회 연속 강한 진동 대신 짧은 2회 패턴.
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 90));
        await HapticFeedback.mediumImpact();
    }
  }

  static const List<int> _progressMilestones = <int>[25, 50, 75];

  void _primeProgressMilestones() {
    final percent = (_presenter.progress * 100).floor();
    _celebratedProgressMilestones
      ..clear()
      ..addAll(_progressMilestones.where((value) => value <= percent));
  }

  void _maybeCelebrateProgressMilestone() {
    final percent = (_presenter.progress * 100).floor();
    final reached = _progressMilestones
        .where((value) =>
            value <= percent && !_celebratedProgressMilestones.contains(value))
        .toList();
    if (reached.isEmpty) return;
    _celebratedProgressMilestones.addAll(reached);
    final milestone = reached.last;
    _recordFeedback((e) => e.progressMilestone = milestone);
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

  void _redoLastInput() {
    if (!_canRedo) return;
    _cancelAllWrongCellTimers();
    setState(() => _memoFocusNumber = null);
    _isApplyingUndo = true;
    try {
      _presenter.redo();
    } finally {
      _isApplyingUndo = false;
    }

    final cell = _presenter.lastRedoCell;
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
    if (!_isVibrationEnabled) return;
    await HapticFeedback.selectionClick();
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
        if (completionDelta.hasNewCompletion ||
            completionDelta.isPuzzleComplete) {
          _recordFeedback((e) {
            e.lineDelta = completionDelta;
            if (completionDelta.isPuzzleComplete) e.puzzleComplete = true;
          });
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
          _lockedInputNumber = null;
          _recordFeedback((e) => e.puzzleComplete = true);
          _beginPuzzleCompleteSequence();
        }
        setState(() {});
      },
      onWrongCountChanged: (wrongCount) {
        setState(() {});
        _scheduleSessionSave();
        if (_presenterReady &&
            wrongCount > 0 &&
            wrongCount < _featurePolicy.maxWrongCount) {
          final max = _featurePolicy.maxWrongCount;
          _recordFeedback((e) => e.wrongCount = (wrongCount, max));
        }
      },
      onGameOver: () {
        _lockedInputNumber = null;
        _recordFeedback((e) => e.gameOver = true);
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
        _lastCorrectCell = (row, col);
        // 힌트로 채웠든 직접 입력했든, 이 입력으로 어떤 숫자가 9개 모두
        // 채워졌다면 완료 반응을 준다(둘 다 정답 입력이라는 점은 같다).
        _recordFeedback((e) => e.correct = true);
        _maybeCelebrateDigitCompletion(row, col);
        _maybeCelebrateProgressMilestone();
      },
      onInputProcessed: _flushFeedback,
      onIncorrectAnswer: (row, col) {
        _recordFeedback((e) => e.wrong = true);
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
    _primeProgressMilestones();
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

  Future<void> _clearCurrentGameState() async {
    await _sessionController.clear(
      level: widget.level,
      gameNumber: widget.game.gameNumber,
    );
  }

  Future<void> _resetAndRestartCurrentGame() async {
    await _clearCurrentGameState();
    if (!mounted) return;
    _cancelCompletionTimers();
    _numberLockCueTimer?.cancel();
    _numberLockPopTimer?.cancel();
    _numberPopTimer?.cancel();
    _numberPopTimer = null;
    setState(() {
      _memoFocusNumber = null;
      _lockedInputNumber = null;
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
    _primeProgressMilestones();
  }

  /// `⋮` 메뉴의 "처음부터 다시 풀기"를 고르면 앱 톤의 확인창을 띄우고, 확인해야만
  /// 초기화한다.
  Future<void> _showResetCurrentGameDialog() async {
    if (!_canResetCurrentGame) return;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final shouldReset = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) => const _RestartConfirmDialog(),
      transitionBuilder: (context, animation, _, child) {
        if (reduceMotion) return child;
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
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
    for (final t in _wrongCellTimers.values) {
      t.cancel();
    }
    _wrongCellTimers.clear();
    _cancelCompletionTimers();
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
        if (_isCompletionEffectRunning) return;
        unawaited(_popAfterSaving());
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: IgnorePointer(
          ignoring: _isCompletionEffectRunning,
          child: _buildBody(),
        ),
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
    // 짧고 일관된 제목: "중급 001"(번호는 최소 3자리, 1000 이상은 그대로).
    final levelName = widget.level.localizedName(l10n);
    final titleText =
        '$levelName ${widget.game.gameNumber.toString().padLeft(3, '0')}';
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
          // 스크린리더에는 "중급, 1번 퍼즐"처럼 자연스러운 표현을 읽어 준다.
          child: Semantics(
            header: true,
            label:
                '$levelName, ${l10n.levelPuzzleNumber(widget.game.gameNumber)}',
            excludeSemantics: true,
            child: Text(
              titleText,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.notoSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
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
            // 타이머는 정보 표시 영역이다(수동 일시정지는 없다. 앱이 백그라운드로 가면
            // 자동으로 멈추고 돌아오면 이어서 흐른다).
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
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
                ],
              ),
            ),
          ),
        ),
        _buildGameMenuButton(l10n),
      ],
    );
  }

  /// 전체 초기화 진입점. 주요 입력 버튼과 떨어뜨려 오조작을 막는다.
  Widget _buildGameMenuButton(AppLocalizations l10n) {
    final palette = LevelStatusPalette.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.gameMoreOptions,
      enabled: !_isCompletionEffectRunning,
      icon: Icon(Icons.more_vert, size: 22, color: context.colors.textPrimary),
      padding: EdgeInsets.zero,
      // 버튼 아래에서 열어 제목·타이머를 가리지 않는다.
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      // 앱 스타일: 둥근 16 모서리, surface 배경, 약한 그림자.
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.completedBorder),
      ),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 270),
      onSelected: (_) => _showResetCurrentGameDialog(),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'restart',
          enabled: _canResetCurrentGame,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Semantics(
            label: l10n.gameRestartMenuTitle,
            excludeSemantics: true,
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.completedBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.replay_rounded,
                      size: 21,
                      color: palette.primaryPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.gameRestartMenuTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: palette.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                                      borderRadius: metrics.numberButtonRadius,
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
                                    if (widget.showUndoButton)
                                      _buildMobileActionButton(
                                        icon: Icons.undo_rounded,
                                        buttonKey:
                                            const ValueKey('game-action-undo'),
                                        label: l10n.gameUndoShort,
                                        color: AppTheme.lightBlueColor,
                                        onPressed:
                                            _canUndo ? _undoLastInput : null,
                                        onLongPress:
                                            _canRedo ? _redoLastInput : null,
                                        longPressSemanticsHint:
                                            l10n.gameRedoShort,
                                        compact: true,
                                        size: metrics.actionButtonSize,
                                        labelFontSize:
                                            metrics.actionLabelFontSize,
                                      ),
                                    _buildMobileActionButton(
                                      icon: Icons.edit_note,
                                      buttonKey:
                                          const ValueKey('game-action-memo'),
                                      imageDisplaySize: 28,
                                      activeBackgroundColor:
                                          _memoActiveBackground(),
                                      activeBorderColor: _memoActiveBorder(),
                                      activeLabelColor: _memoActiveLabel(),
                                      imageAsset: _memoImage,
                                      label: _presenter.isMemoMode
                                          ? l10n.gameMemoOnShort
                                          : l10n.gameMemoShort,
                                      semanticsLabel: _presenter.isMemoMode
                                          ? l10n.gameMemoModeOnSemantics
                                          : l10n.gameMemoModeOffSemantics,
                                      color: AppTheme.lightBlueColor,
                                      isActive: _presenter.isMemoMode,
                                      onPressed: _canToggleMemo
                                          ? () {
                                              unawaited(_toggleMemoMode());
                                            }
                                          : null,
                                      onLongPress: _canUseAutoNotes
                                          ? () => unawaited(_applyAutoNotes())
                                          : null,
                                      longPressSemanticsHint: _autoNotesEnabled
                                          ? l10n.gameMemoLongPressHint
                                          : null,
                                      showAutoNotesBadge: _autoNotesEnabled,
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
                                      buttonKey:
                                          const ValueKey('game-action-erase'),
                                      imageDisplaySize: 32,
                                      imageAsset: _eraseImage,
                                      dimWhenDisabled: true,
                                      semanticsLabel: _canEraseSelection
                                          ? l10n.gameEraseSemanticsSelected
                                          : l10n.gameEraseShort,
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
                                        horizontal: metrics.numberButtonGap / 2,
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
                              if (widget.showUndoButton)
                                _buildMobileActionButton(
                                  icon: Icons.undo_rounded,
                                  buttonKey: const ValueKey('game-action-undo'),
                                  label: AppLocalizations.of(context)!
                                      .gameUndoShort,
                                  color: AppTheme.lightBlueColor,
                                  onPressed: _canUndo ? _undoLastInput : null,
                                  onLongPress: _canRedo ? _redoLastInput : null,
                                  longPressSemanticsHint:
                                      AppLocalizations.of(context)!
                                          .gameRedoShort,
                                  compact: true,
                                  size: metrics.actionButtonSize,
                                  labelFontSize: metrics.actionLabelFontSize,
                                ),
                              _buildMobileActionButton(
                                icon: Icons.edit_note,
                                buttonKey: const ValueKey('game-action-memo'),
                                imageDisplaySize: 28,
                                activeBackgroundColor: _memoActiveBackground(),
                                activeBorderColor: _memoActiveBorder(),
                                activeLabelColor: _memoActiveLabel(),
                                imageAsset: _memoImage,
                                label: _presenter.isMemoMode
                                    ? AppLocalizations.of(context)!
                                        .gameMemoOnShort
                                    : AppLocalizations.of(context)!
                                        .gameMemoShort,
                                semanticsLabel: _presenter.isMemoMode
                                    ? AppLocalizations.of(context)!
                                        .gameMemoModeOnSemantics
                                    : AppLocalizations.of(context)!
                                        .gameMemoModeOffSemantics,
                                color: AppTheme.lightBlueColor,
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
                                longPressSemanticsHint: _autoNotesEnabled
                                    ? AppLocalizations.of(context)!
                                        .gameMemoLongPressHint
                                    : null,
                                showAutoNotesBadge: _autoNotesEnabled,
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
                                buttonKey: const ValueKey('game-action-erase'),
                                imageDisplaySize: 32,
                                imageAsset: _eraseImage,
                                dimWhenDisabled: true,
                                semanticsLabel: _canEraseSelection
                                    ? AppLocalizations.of(context)!
                                        .gameEraseSemanticsSelected
                                    : AppLocalizations.of(context)!
                                        .gameEraseShort,
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
                eraseActive: _effectsController.eraseActive,
                hintAppliedActive: _effectsController.hintAppliedActive,
                digitCompleteActive: _effectsController.digitCompleteActive,
                showCompletionGlow: _showCompletionGlow,
                completionOrigin: _lastCorrectCell,
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
                  final lockedNumber = _lockedInputNumber;
                  // 이미 숫자가 들어 있는 칸은 건너뛴다(덮어쓰지 않는다).
                  final shouldApplyLockedNumber = lockedNumber != null &&
                      _hasEditableSelection &&
                      _presenter.getCellValue(row, col) == 0;
                  if (shouldApplyLockedNumber) {
                    _insertDigit(lockedNumber, fromLock: true);
                  } else if (didSelectionChange && _isVibrationEnabled) {
                    unawaited(HapticFeedback.selectionClick());
                  }
                },
                onPencilDigit: isTablet ? _insertDigit : null,
              ),
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

  bool _canLockNumber(int number) {
    return _presenterReady &&
        !_presenter.isPaused &&
        !_presenter.isGameComplete &&
        !_presenter.isGameOver &&
        _remainingCountForNumber(number) > 0;
  }

  void _toggleNumberLock(int number) {
    if (!_canLockNumber(number)) return;
    setState(() {
      _lockedInputNumber = _lockedInputNumber == number ? null : number;
      _memoFocusNumber = _presenter.isMemoMode ? _lockedInputNumber : null;
    });
    if (_lockedInputNumber == number && !_effectsController.reduceMotion) {
      _numberLockPopTimer?.cancel();
      setState(() => _numberLockPopNumber = number);
      _numberLockPopTimer = Timer(const Duration(milliseconds: 90), () {
        _numberLockPopTimer = null;
        if (!mounted) return;
        setState(() => _numberLockPopNumber = null);
      });
    }
    // 핀이 걸리거나 풀리는 순간: 누르는 중 신호(selectionClick)보다 확실히 강하게.
    if (_isVibrationEnabled) {
      unawaited(HapticFeedback.heavyImpact());
    }
  }

  /// 숫자 버튼을 길게 눌러 고정할 때까지 걸리는 시간(기본 500ms보다 짧게).
  static const Duration _numberLockPressDuration = Duration(milliseconds: 350);

  /// 누르고 있는 중간에 "계속 누르면 고정된다"를 알리는 약한 진동 시점. 일반 탭
  /// (보통 150ms 안에 끝남)에는 울리지 않는다.
  static const Duration _numberLockCueAt = Duration(milliseconds: 150);

  Timer? _numberLockCueTimer;

  /// 숫자 버튼에 손을 댄 위치. 누른 채 이만큼(kTouchSlop) 벗어나면 길게 누르기가
  /// 취소되므로, 차오르는 효과도 같이 거둬 고정된 것처럼 보이지 않게 한다.
  Offset? _numberLockPressOrigin;

  /// "차오르는" 효과의 전체 길이와 시작 지연(ms). 손을 댄 시점부터 재서
  /// [_numberLockPressDuration](350ms)보다 조금 일찍(320ms) 가득 차도록 맞춰, 핀이
  /// 걸리는 순간에는 이미 다 차 있게 한다. 90ms 안에 끝나는 빠른 탭에는 아무것도
  /// 보이지 않는다.
  static const int _lockFillTotalMs = 320;
  static const int _lockFillStartMs = 90;

  /// 지금 손을 대고 있어 고정·해제 효과를 재생 중인 숫자. null이면 없음.
  int? _lockFillNumber;

  /// 핀이 방금 걸린 숫자: 버튼이 아주 살짝 튀는(1.0 → 1.045 → 1.0) 반응에 쓴다.
  int? _numberLockPopNumber;
  Timer? _numberLockPopTimer;

  void _startNumberLockCue(int number) {
    _cancelNumberLockCue();
    _numberLockCueTimer = Timer(_numberLockCueAt, () {
      _numberLockCueTimer = null;
      if (mounted && _isVibrationEnabled) {
        unawaited(HapticFeedback.selectionClick());
      }
    });
    if (_effectsController.reduceMotion) return;
    setState(() => _lockFillNumber = number);
  }

  void _cancelNumberLockCue() {
    _numberLockCueTimer?.cancel();
    _numberLockCueTimer = null;
    if (_lockFillNumber != null && mounted) {
      setState(() => _lockFillNumber = null);
    }
  }

  /// 짧게 탭하면 입력만 한다. 입력할 칸이 없을 때의 탭은 아무 일도 하지 않고(고정은
  /// 길게 누를 때만 걸리고 풀린다), 버튼은 비활성처럼 흐려지지 않게 그대로 둔다.
  void _handleNumberButtonTap(int number) {
    if (_isNumberInputEnabled(number)) {
      _insertDigit(number);
    }
  }

  // 넘패드 탭과 아이패드 애플펜슬 필기 입력이 공유하는 실제 입력 처리.
  // 두 경로 모두 같은 검증/부수효과(진동, 오답셀 타이머, 메모 하이라이트)를
  // 거치도록 한곳에 모아둔다.
  void _insertDigit(int number, {bool fromLock = false}) {
    if (!_isNumberInputEnabled(number)) return;
    setState(() {
      _memoFocusNumber = _presenter.isMemoMode ? number : null;
    });
    if (!_presenter.isMemoMode) {
      _cancelWrongCellTimer(
        _presenter.selectedRow,
        _presenter.selectedCol,
      );
    }
    _recordFeedback((e) {
      e.fromInput = true;
      e.fromLock = fromLock;
      e.memo = _presenter.isMemoMode;
    });
    final row = _presenter.selectedRow;
    final col = _presenter.selectedCol;
    _presenter.setSelectedCellValue(number);
    if (!_presenter.isMemoMode && row != null && col != null) {
      // 오답이면 연속 오답으로 게임이 끝나지 않도록 고정을 풀어 준다.
      final isWrong = _presenter.getCellValue(row, col) == number &&
          number != _presenter.getCorrectValue(row, col);
      if (isWrong && _lockedInputNumber != null) {
        setState(() => _lockedInputNumber = null);
      }
    }
    unawaited(_maybeShowNumberLockTip());
  }

  /// 숫자패드를 몇 번 써 본 사용자에게 숫자 고정을 한 번만 알려 준다.
  Future<void> _maybeShowNumberLockTip() async {
    if (_numberLockTipShown || _lockedInputNumber != null) return;
    _numberInputCount++;
    if (_numberInputCount < 5) return;
    _numberLockTipShown = true;
    if (await _numberLockTipService.hasShownTip()) return;
    await _numberLockTipService.markTipShown();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.gameNumberLockTipMessage),
      ),
    );
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
    final remainingCount = _remainingCountForNumber(number);
    final isEnabled = _isNumberInputEnabled(number) || _canLockNumber(number);
    final isLockedNumber = _lockedInputNumber == number;
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
    // 고정(핀)한 숫자는 보라(라벤더 배경 + 보라 테두리 + 보라 핀)로 표시한다. 선택한
    // 칸의 숫자는 보드에서 이미 강조되므로 숫자패드에는 따로 표시하지 않는다.
    final lockPalette = LevelStatusPalette.of(context);
    final effectiveBackgroundColor = isCompletedNumber
        ? (isDark ? const Color(0xFF232323) : context.colors.surfaceSubtle)
        : isLockedNumber
            ? lockPalette.completedBackground
            : (isDark ? const Color(0xFF323232) : context.colors.surface);
    // ProgressiveBlurButton은 활성이 아닐 때 배경을 기본 표면색에 22%(다크 40%)만
    // 섞어 보여 준다. 고정 표시가 흐려지지 않도록 완성된 색을 활성 배경으로
    // 직접 넘기고, 차오르는 효과도 같은 색을 써서 끝에서 어긋나지 않게 한다.
    final padBase = Theme.of(context).colorScheme.surface;
    final lockedBg = Color.alphaBlend(
      lockPalette.primaryPurple.withValues(alpha: isDark ? 0.26 : 0.16),
      padBase,
    );
    final holdingLockPress =
        _lockFillNumber == number && !_effectsController.reduceMotion;
    // 해제 효과가 덮는 색: 고정되지 않은 평소 버튼의 실제 표시색.
    final unlockedCover =
        isDark ? Color.lerp(padBase, const Color(0xFF323232), 0.40)! : padBase;

    Widget button = MediaQuery.withNoTextScaling(
        child: ProgressiveBlurButton(
      key: ValueKey('number-button-$number'),
      onPressed: isEnabled ? () => _handleNumberButtonTap(number) : null,
      backgroundColor: effectiveBackgroundColor,
      isActive: !isCompletedNumber && isLockedNumber,
      activeBackgroundColor: lockedBg,
      activeBorderColor: Colors.transparent,
      width: width ?? (compact ? 72 : 95),
      height: height ?? (compact ? 56 : 70),
      borderRadius: borderRadius ?? (compact ? 20 : 28),
      enablePressScale: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: holdingLockPress ? 1.0 : 0.0),
        duration: holdingLockPress
            ? const Duration(milliseconds: _lockFillTotalMs)
            : Duration.zero,
        builder: (context, p, _) {
          final ms = p * _lockFillTotalMs;
          final fillT = Curves.easeOutCubic.transform(
            ((ms - _lockFillStartMs) / (_lockFillTotalMs - _lockFillStartMs))
                .clamp(0.0, 1.0),
          );
          final fadeDuration = _effectsController.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 150);
          return Stack(
            children: [
              // 길게 누르는 동안 채워진다. 고정하는 중에는 라벤더가 바닥에서 차오르고, 이미
              // 고정된 숫자를 눌러 해제하는 중에는 평소 버튼색이 위에서 내려와 라벤더를
              // 덮는다. 앞쪽 가장자리는 살짝 번지게 해서 물처럼 움직이는 느낌을 주고,
              // 끝(가득 찬 상태)에서는 번진 부분이 버튼 밖으로 밀려나 고르게 채워진다.
              if (fillT > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        borderRadius ?? (compact ? 20 : 28),
                      ),
                      child: Align(
                        alignment: isLockedNumber
                            ? Alignment.topCenter
                            : Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          key: ValueKey('number-lock-fill-$number'),
                          widthFactor: 1,
                          heightFactor: fillT * 1.2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: isLockedNumber
                                    ? Alignment.bottomCenter
                                    : Alignment.topCenter,
                                end: isLockedNumber
                                    ? Alignment.topCenter
                                    : Alignment.bottomCenter,
                                colors: [
                                  (isLockedNumber ? unlockedCover : lockedBg)
                                      .withValues(alpha: 0.0),
                                  isLockedNumber ? unlockedCover : lockedBg,
                                  isLockedNumber ? unlockedCover : lockedBg,
                                ],
                                stops: const [0.0, 0.16, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // 고정 테두리는 핀이 걸릴 때 부드럽게 나타나고, 풀릴 때 부드럽게 사라진다.
              // 해제는 고정의 역순이라, 덮는 동안에는 그대로 두었다가 해제가 걸리는 순간
              // 사라진다. 위의 채움이 생기고 빠질 때 다른 자리와 짝지어져 전환 상태를
              // 잃지 않도록 키를 준다.
              Positioned.fill(
                key: const ValueKey('number-lock-border-slot'),
                child: AnimatedSwitcher(
                  duration: fadeDuration,
                  child: isLockedNumber
                      ? Container(
                          key: ValueKey('number-lock-border-$number'),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              borderRadius ?? (compact ? 20 : 28),
                            ),
                            border: Border.all(
                              color: lockPalette.primaryPurple,
                              width: 2.4,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
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
                    fontWeight: isLockedNumber ? FontWeight.w800 : null,
                  ),
                ),
              ),
              // 핀은 걸리는 순간 작게 커지며(0.6 → 1.0) 나타나고, 풀리는 순간 그 역순으로
              // 작아지며 사라진다.
              Positioned(
                left: badgeInset,
                top: badgeInset,
                child: AnimatedSwitcher(
                  duration: fadeDuration,
                  // 곡선은 크기에만 준다(easeOutBack은 1을 넘어 투명도 계산에 쓸 수 없다).
                  // 사라질 때는 같은 곡선을 거꾸로 따라가 나타날 때의 정확한 역순이 된다.
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.0, 0.4),
                    ),
                    child: ScaleTransition(
                      scale: Tween(begin: 0.6, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                  child: isLockedNumber
                      ? Icon(
                          Icons.push_pin_rounded,
                          key: ValueKey('number-lock-$number'),
                          size: (compact ? 14 : 16) * badgeScale,
                          color: lockPalette.primaryPurple,
                        )
                      : const SizedBox.shrink(),
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
                              fontSize: (isCompactSmallButton
                                      ? 9
                                      : (compact ? 10 : 11)) *
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
          );
        },
      ),
    ));

    // 핀이 걸린 직후 버튼이 아주 살짝 튄다(항상 감싸 두어 위젯 구조가 바뀌지 않는다).
    button = AnimatedScale(
      scale: _numberLockPopNumber == number ? 1.045 : 1.0,
      duration: _effectsController.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      child: button,
    );

    if (_canLockNumber(number)) {
      button = Listener(
        onPointerDown: (event) {
          _numberLockPressOrigin = event.position;
          _startNumberLockCue(number);
        },
        onPointerMove: (event) {
          final origin = _numberLockPressOrigin;
          if (origin != null &&
              (event.position - origin).distance > kTouchSlop) {
            _numberLockPressOrigin = null;
            _cancelNumberLockCue();
          }
        },
        onPointerUp: (_) => _cancelNumberLockCue(),
        onPointerCancel: (_) => _cancelNumberLockCue(),
        child: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: _numberLockPressDuration,
              ),
              (recognizer) => recognizer.onLongPress = () {
                _cancelNumberLockCue();
                _toggleNumberLock(number);
              },
            ),
          },
          child: button,
        ),
      );
    }
    final l10n = AppLocalizations.of(context)!;
    if (isLockedNumber) {
      button = Semantics(
        button: true,
        selected: true,
        enabled: isEnabled,
        label: l10n.gameNumberButtonLockedSemantics(number),
        excludeSemantics: true,
        onTap: isEnabled ? () => _handleNumberButtonTap(number) : null,
        onLongPress: () => _toggleNumberLock(number),
        child: button,
      );
    } else if (_canLockNumber(number)) {
      button = Semantics(hint: l10n.gameNumberButtonLockHint, child: button);
    }

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

  // 하단 기능 버튼(메모·힌트·지우기)의 플랫 아이콘 에셋. 상태가 바뀌어도 같은 이미지를
  // 쓰고, 상태는 버튼 배경·테두리·투명도로만 표현한다.
  static const String _memoImage = 'assets/images/game_control_memo_flat.png';
  static const String _hintImage = 'assets/images/game_control_hint_flat.png';
  static const String _eraseImage = 'assets/images/game_control_erase_flat.png';

  // 메모 ON 활성 표현: 옅은 라벤더 배경 + 브랜드 보라 30~40% 테두리(탁한 회녹색 대신).
  Color _memoActiveBackground() =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2E2A52)
          : const Color(0xFFEFEBFF);

  Color _memoActiveBorder() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF9C90E8).withValues(alpha: 0.7)
      : const Color(0xFF4A3F99).withValues(alpha: 0.38);

  Color _memoActiveLabel() => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFD8D2FF)
      : const Color(0xFF3F3586);

  Widget _buildMobileActionButton({
    required IconData icon,
    // 있으면 아이콘 대신 이 이미지(256×256 PNG)를 같은 자리에 contain으로 보여 준다.
    String? imageAsset,
    // 비활성일 때 이미지를 바꾸지 않고 버튼 전체 투명도만 낮춘다.
    bool dimWhenDisabled = false,
    double disabledOpacity = 0.6,
    // false면 라벨 글자를 그리지 않는다(이미지만). 스크린리더 이름은 그대로 전달한다.
    bool showLabel = true,
    // 이미지 표시 크기(라벨이 있을 때). 이미지마다 피사체 크기가 달라 버튼별로 정한다.
    // 버튼이 작으면 버튼 폭에 맞춰 줄어든다.
    double? imageDisplaySize,
    // 활성(켜진) 상태의 배경·테두리·라벨 색을 직접 정한다(메모 ON).
    Color? activeBackgroundColor,
    Color? activeBorderColor,
    Color? activeLabelColor,
    Key? buttonKey,
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
    // 이미지는 약 30pt(작은 버튼에서는 버튼 폭의 절반)로 세 버튼이 같게 보이도록 맞춘다.
    // 라벨이 없으면 이미지가 버튼 가운데에서 조금 더 크게 보인다.
    final hasLabel = showLabel && label.isNotEmpty;
    final imageSize = hasLabel
        ? (imageDisplaySize ?? 30.0).clamp(20.0, buttonSize * 0.56).toDouble()
        : (buttonSize * 0.6).clamp(26.0, 36.0);
    Widget button = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 1 : (_oneHandModeEnabled ? 2 : 3),
        vertical: compact ? 0.5 : (_oneHandModeEnabled ? 2 : 3),
      ),
      child: Semantics(
        container: true,
        hint: longPressSemanticsHint,
        button: true,
        enabled: onPressed != null || onLongPress != null,
        toggled: toggled,
        label: semanticsLabel ?? label,
        excludeSemantics: true,
        onTap: onPressed,
        child: ProgressiveBlurButton(
          key: buttonKey,
          onPressed: onPressed,
          width: buttonSize,
          height: buttonSize,
          borderRadius: buttonSize / 2,
          backgroundColor: color,
          isActive: isActive,
          activeBackgroundColor: activeBackgroundColor,
          activeBorderColor: activeBorderColor,
          // 이미지 버튼의 비활성은 바깥 투명도(dimWhenDisabled)만 쓰고 내용 투명도는
          // 겹쳐 곱하지 않는다(겹치면 이미지가 거의 보이지 않는다).
          disabledContentOpacity: dimWhenDisabled ? 1.0 : null,
          disabledBackgroundColor: dimWhenDisabled
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2C2C2C)
                  : const Color(0xFFEDEDEA))
              : null,
          child: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final contentColor = (isActive && isDark)
                  ? (activeLabelColor ?? const Color(0xFF6DCCA0))
                  : (isActive && emphasizeActiveIcon)
                      ? color
                      : Theme.of(context).colorScheme.onSurface;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imageAsset != null)
                    // 이미지가 바뀌어도(메모 ON/OFF 등) 같은 크기·같은 중심선을 쓴다.
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        excludeFromSemantics: true,
                      ),
                    )
                  else
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
    if (dimWhenDisabled && onPressed == null && onLongPress == null) {
      button = Opacity(opacity: disabledOpacity, child: button);
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
    final hintsLeft = _visibleHintsRemaining;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildMobileActionButton(
          icon: Icons.lightbulb_outline,
          buttonKey: const ValueKey('game-action-hint'),
          imageDisplaySize: 31,
          imageAsset: _hintImage,
          // 비활성(선택한 칸이 유효하지 않거나 힌트 소진)이면 버튼 전체를 흐리게 하고,
          // 소진은 더 옅게 보여 구분한다.
          dimWhenDisabled: true,
          disabledOpacity: hintsLeft > 0 ? 0.6 : 0.4,
          semanticsLabel: hintsLeft > 0
              ? AppLocalizations.of(context)!
                  .gameHintSemanticsRemaining(hintsLeft)
              : AppLocalizations.of(context)!.gameHintSemanticsNone,
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
        // 힌트를 모두 썼으면 개수 배지는 숨긴다(버튼도 더 옅게 비활성으로 보인다).
        if (hintsLeft > 0)
          Positioned(
            // 버튼 오른쪽 위 모서리 안쪽에 걸친다(예전 -2에서 안쪽으로 이동).
            top: 1,
            right: 1,
            child: Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF457B9D),
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

/// 게임 화면의 "처음부터 다시 풀기" 확인창. 완료한 퍼즐을 다시 풀 때의 확인창과 같은
/// 규칙(라벤더 원형 아이콘, 가운데 정렬, 전체 폭 보라 주 버튼, 텍스트 취소, 경고색
/// 없음)을 쓴다. 확인하면 true, 취소·바깥 터치·뒤로가기는 false/null.
class _RestartConfirmDialog extends StatefulWidget {
  const _RestartConfirmDialog();

  @override
  State<_RestartConfirmDialog> createState() => _RestartConfirmDialogState();
}

class _RestartConfirmDialogState extends State<_RestartConfirmDialog> {
  bool _answered = false;

  void _answer(bool value) {
    // 연타해도 첫 응답만 받는다: 초기화가 한 번만 실행되고 대화상자도 한 번만 닫힌다.
    if (_answered) return;
    setState(() => _answered = true);
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LevelStatusPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.completedBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.completedBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.replay_rounded,
                      size: 24,
                      color: colors.primaryPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.gameRestartDialogTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colors.primaryText,
                ),
              ),
              const SizedBox(height: 10),
              // 문장마다 새 줄에서 시작하고, 단어 중간에서는 줄을 바꾸지 않는다.
              SentenceText(
                l10n.gameRestartDialogBody,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _answered ? null : () => _answer(true),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryPurple,
                  foregroundColor:
                      isDark ? const Color(0xFF1F1B3A) : Colors.white,
                  disabledBackgroundColor: colors.primaryPurple,
                  disabledForegroundColor:
                      isDark ? const Color(0xFF1F1B3A) : Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child:
                    Text(l10n.gameRestartConfirm, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _answered ? null : () => _answer(false),
                style: TextButton.styleFrom(
                  foregroundColor: colors.secondaryText,
                  minimumSize: const Size.fromHeight(44),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(l10n.commonCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
