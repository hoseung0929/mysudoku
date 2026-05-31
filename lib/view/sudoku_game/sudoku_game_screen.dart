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
import 'package:sudoku159/view/sudoku_game/game_end_flow.dart';
import 'package:sudoku159/view/sudoku_game/game_session_controller.dart';
import 'package:sudoku159/view/sudoku_game/game_settings_controller.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_answer_box.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_board_grid.dart';
import 'package:sudoku159/view/sudoku_game/game_effects_controller.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_action_button.dart';
import 'package:sudoku159/view/home/level_picker_screen.dart';
import 'package:sudoku159/widgets/custom_app_bar.dart';
import 'package:sudoku159/widgets/progressive_blur_button.dart';

/// 스도쿠 게임의 메인 화면
/// MVP 패턴에서 View 역할을 수행하며, 사용자 인터페이스를 담당
class SudokuGameScreen extends StatefulWidget {
  final SudokuGame game;
  final SudokuLevel level;
  final bool restoreSavedSession;

  const SudokuGameScreen({
    super.key,
    required this.game,
    required this.level,
    this.restoreSavedSession = false,
  });

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen>
    with WidgetsBindingObserver {
  static const double _kReservedBannerAdHeight = 56;
  static const double _kReservedBannerGap = 10;

  late final GameEndFlow _gameEndFlow = GameEndFlow();
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
  final GameEffectsController _effectsController = GameEffectsController();
  OverlayEntry? _completionFeedbackEntry;
  Timer? _completionFeedbackTimer;
  final Map<String, Timer> _wrongCellTimers = {};

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

  bool get _canUseHint {
    if (!_presenterReady ||
        !_featurePolicy.hintEnabled ||
        _presenter.isPaused ||
        _presenter.isGameComplete ||
        _presenter.isGameOver) {
      return false;
    }
    if (_presenter.hintsRemaining <= 0) return false;
    final row = _presenter.selectedRow;
    final col = _presenter.selectedCol;
    if (row == null || col == null) return false;
    if (_presenter.isCellFixed(row, col)) return false;
    return _presenter.getCellValue(row, col) == 0;
  }

  bool get _canResetCurrentGame {
    return _presenterReady &&
        !_presenter.isGameComplete &&
        !_presenter.isGameOver;
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

  String _formatCalmTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
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

    final sessionBootstrap = await _sessionController.prepareSession(
      game: widget.game,
      level: widget.level,
      restoreSavedSession: widget.restoreSavedSession,
      maxWrongCount: _featurePolicy.maxWrongCount,
    );

    final activeSession = sessionBootstrap.activeSession;
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
      level: widget.level,
      onBoardChanged: (board) {
        final completionDelta = _effectsController.handleBoardChanged(
          board: board,
          solution: widget.game.solution,
          setState: setState,
          isMounted: () => mounted,
        );
        setState(() {});
        _showCompletionFeedback(completionDelta);
        _scheduleSessionSave();
      },
      onFixedNumbersChanged: (fixedNumbers) {
        setState(() {});
      },
      onWrongNumbersChanged: (wrongNumbers) {
        setState(() {});
      },
      onTimeChanged: (time) {
        _timeNotifier.value = _formatCalmTime(time);
      },
      onPauseStateChanged: (isPaused) {
        setState(() {});
        _scheduleSessionSave();
      },
      onGameCompleteChanged: (isComplete) {
        if (isComplete) {
          if (_isVibrationEnabled) {
            HapticFeedback.heavyImpact()
                .then((_) => Future<void>.delayed(
                      const Duration(milliseconds: 120),
                    ))
                .then((_) => HapticFeedback.heavyImpact());
          }
          _showGameCompleteDialog();
        }
        setState(() {});
      },
      onWrongCountChanged: (wrongCount) {
        setState(() {});
        _scheduleSessionSave();
      },
      onGameOver: () {
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
        _effectsController.triggerWaveEffect(
          row: row,
          col: col,
          setState: setState,
          isMounted: () => mounted,
        );
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
        unawaited(_flushPendingSessionOnPause());
        return;
      case AppLifecycleState.resumed:
        return;
    }
  }

  void _showCompletionFeedback(BoardCompletionDelta completionDelta) {
    if (!mounted || !completionDelta.hasNewCompletion) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final parts = <String>[];
    if (completionDelta.completedRows > 0) {
      parts.add(l10n.gameRowsCompleted(completionDelta.completedRows));
    }
    if (completionDelta.completedCols > 0) {
      parts.add(l10n.gameColsCompleted(completionDelta.completedCols));
    }
    if (completionDelta.completedBoxes > 0) {
      parts.add(l10n.gameBoxesCompleted(completionDelta.completedBoxes));
    }
    if (parts.isEmpty) {
      return;
    }

    _showTopFeedback(parts.join(' · '));
  }

  void _showTopFeedback(
    String message, {
    Color backgroundColor = const Color(0xFF242B2D),
  }) {
    if (!mounted) {
      return;
    }

    _hideCompletionFeedback();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 600;
    final bottomOffset = mediaQuery.padding.bottom + (isTablet ? 28 : 18);

    _completionFeedbackEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: bottomOffset,
        left: 16,
        right: 16,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
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
    );
    overlay.insert(_completionFeedbackEntry!);
    _completionFeedbackTimer = Timer(
      const Duration(milliseconds: 1100),
      _hideCompletionFeedback,
    );
  }

  void _hideCompletionFeedback() {
    _completionFeedbackTimer?.cancel();
    _completionFeedbackTimer = null;
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
    setState(() {
      _memoFocusNumber = null;
    });
    _effectsController.resetForBoard(
      board: widget.game.board,
      solution: widget.game.solution,
    );
    _presenter.restartGame();
  }

  Future<void> _showResetCurrentGameDialog() async {
    if (!_canResetCurrentGame) return;

    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isKorean ? '현재 게임 초기화' : 'Reset current game'),
          content: Text(
            isKorean
                ? '입력한 숫자, 메모, 힌트, 오답 횟수와 시간을 모두 지우고 처음 상태로 돌아갈까요?'
                : 'Clear entered numbers, notes, hints, mistakes, and time, then return to the starting board?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(isKorean ? '취소' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isKorean ? '초기화' : 'Reset'),
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
    _timeNotifier.dispose();
    if (_presenterReady) {
      _presenter.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final surface = Theme.of(context).colorScheme.surface;

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
        body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
      ),
    );
  }

  /// 앱바 위젯
  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.of(context).size.width > 600;
    if (!isTablet) {
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
          child: Text(
            titleText,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
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
          _buildDeveloperMenuButton(),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: ValueListenableBuilder<String>(
                valueListenable: _timeNotifier,
                builder: (context, time, _) => Text(
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
          ),
        ],
      );
    }
    return CustomAppBar(
      title: widget.level.localizedName(l10n),
      showNotificationIcon: false,
      showLogoutIcon: false,
      titleWidget: GestureDetector(
        onLongPress: kDebugMode ? _toggleDeveloperAnswerPreview : null,
        child: Text(widget.level.localizedName(l10n)),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _popAfterSaving,
      ),
      actions: [_buildDeveloperMenuButton()],
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

  /// 태블릿 레이아웃
  Widget _buildTabletLayout() {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // 상단 정보 영역
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.level.localizedName(l10n),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.gameNumberLabel(widget.game.gameNumber),
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // 게임 영역
        Expanded(
          child: Row(
            children: [
              // 왼쪽: 스도쿠 그리드
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    children: [
                      _buildCalmStatusStrip(
                        primaryItems: [
                          _StatusStripItem(
                            icon: Icons.timer_outlined,
                            label: l10n.gameTimeShort,
                            value: _timeNotifier.value,
                          ),
                          _StatusStripItem(
                            icon: Icons.error_outline,
                            label: l10n.gameWrongShort,
                            value:
                                '${_presenter.wrongCount}/${_featurePolicy.maxWrongCount}',
                          ),
                          _StatusStripItem(
                            icon: Icons.emoji_events_outlined,
                            label: l10n.gameProgressShort,
                            value: '${(_presenter.progress * 100).toInt()}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(child: _buildBoardGrid()),
                    ],
                  ),
                ),
              ),
              // 오른쪽: 컨트롤 패널
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // 숫자 입력 패널
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.gameNumberInputTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildNumberInputLegend(),
                            // 3x3 숫자 그리드
                            for (int i = 0; i < 3; i++)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (int j = 1; j <= 3; j++)
                                    Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: _buildNumberButton(i * 3 + j),
                                    ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                SudokuGameActionButton(
                                  icon: Icons.edit_note,
                                  label: _presenter.isMemoMode
                                      ? l10n.gameMemoOnShort
                                      : l10n.gameMemoShort,
                                  backgroundColor: _presenter.isMemoMode
                                      ? AppTheme.mintColor
                                      : AppTheme.lightBlueColor,
                                  isActive: _presenter.isMemoMode,
                                  onPressed: _canToggleMemo
                                      ? () {
                                          setState(() {
                                            _memoFocusNumber = null;
                                            _presenter.toggleMemoMode();
                                          });
                                        }
                                      : null,
                                ),
                                SudokuGameActionButton(
                                  icon: Icons.lightbulb_outline,
                                  label:
                                      '${l10n.gameHintShort} $_visibleHintsRemaining',
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF8A6820)
                                          : AppTheme.yellowColor,
                                  isActive: false,
                                  onPressed: _canUseHint
                                      ? () {
                                          setState(() {
                                            _presenter.useHint();
                                          });
                                        }
                                      : null,
                                ),
                                SudokuGameActionButton(
                                  icon: Icons.backspace_outlined,
                                  label: _resetButtonLabel,
                                  backgroundColor:
                                      context.colors.attentionSurface,
                                  onPressed: _canResetCurrentGame
                                      ? _showResetCurrentGameDialog
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildReservedBannerAdSlot(
                              height: _kReservedBannerAdHeight,
                            ),
                            const SizedBox(height: 12),
                            _buildDeveloperAnswerPreview(l10n),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
                                _buildMobileActionButton(
                                  icon: Icons.edit_note,
                                  label: '',
                                  color: _presenter.isMemoMode
                                      ? AppTheme.mintColor
                                      : AppTheme.lightBlueColor,
                                  isActive: _presenter.isMemoMode,
                                  onPressed: _canToggleMemo
                                      ? () {
                                          setState(() {
                                            _memoFocusNumber = null;
                                            _presenter.toggleMemoMode();
                                          });
                                        }
                                      : null,
                                  compact: true,
                                  size: metrics.actionButtonSize,
                                  labelFontSize: metrics.actionLabelFontSize,
                                ),
                                _buildMobileHintButton(metrics),
                                _buildMobileActionButton(
                                  icon: Icons.backspace_outlined,
                                  label: '',
                                  color: context.colors.attentionSurface,
                                  onPressed: _canResetCurrentGame
                                      ? _showResetCurrentGameDialog
                                      : null,
                                  compact: true,
                                  size: metrics.actionButtonSize,
                                  labelFontSize: metrics.actionLabelFontSize,
                                ),
                              ],
                            ),
                            SizedBox(height: metrics.bannerAdGap),
                            _buildReservedBannerAdSlot(
                              height: metrics.bannerAdHeight,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (kDebugMode && _showDeveloperAnswerPreview)
                  Positioned(
                    right: metrics.horizontalPadding,
                    bottom: metrics.scrollBottomPadding +
                        metrics.bannerAdHeight +
                        metrics.bannerAdGap +
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

  Widget _buildBoardGrid() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
        child: SudokuBoardGrid(
          presenter: _presenter,
          waveActive: _effectsController.waveActive,
          lineCompleteActive: _effectsController.lineCompleteActive,
          errorActive: _effectsController.errorActive,
          errorOffset: _effectsController.errorOffset,
          highlightedMemoNumber:
              _memoHighlightEnabled && _featurePolicy.memoEnabled
                  ? _memoFocusNumber
                  : null,
          enableMemoHighlights:
              _memoHighlightEnabled && _featurePolicy.memoEnabled,
          onCellTapped: (row, col) {
            _presenter.selectCell(row, col);
          },
        ),
      ),
    );
  }

  Widget _buildCalmStatusStrip({
    required List<_StatusStripItem> primaryItems,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 14,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(compact ? 20 : 22),
        border: Border.all(color: context.colors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: compact ? 6 : 8,
        runSpacing: compact ? 6 : 8,
        children: primaryItems
            .map(
              (item) => Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 7 : 9,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                  border: Border.all(color: context.colors.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon,
                        size: compact ? 13 : 16,
                        color: context.colors.textSecondary),
                    SizedBox(width: compact ? 5 : 6),
                    Text(
                      '${item.label} ${item.value}',
                      style: GoogleFonts.notoSans(
                        fontSize: compact ? 10.5 : 12,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
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

  String get _resetButtonLabel {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '초기화'
        : 'Reset';
  }

  bool _isNumberInputEnabled(int number) {
    if (!_hasEditableSelection) {
      return false;
    }
    return _remainingCountForNumber(number) > 0;
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
  }) {
    const buttonColor = AppTheme.lightBlueColor;
    final remainingCount = _remainingCountForNumber(number);
    final isEnabled = _isNumberInputEnabled(number);
    final isSelectedNumber = _selectedInputNumber() == number;
    final isCompletedNumber = remainingCount == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompactSmallButton = compact && height != null && height < 56;
    final digitFontSize =
        isCompactSmallButton ? (height * 0.58).clamp(28.0, 34.0) : 38.0;
    final digitAlignment =
        isCompactSmallButton ? const Alignment(-0.08, -0.06) : Alignment.center;
    final badgeInset = isCompactSmallButton ? 7.0 : 10.0;
    final badgeSize = isCompactSmallButton ? 22.0 : 24.0;
    final effectiveBackgroundColor = isCompletedNumber
        ? (isDark ? const Color(0xFF232323) : context.colors.surfaceSubtle)
        : isSelectedNumber
            ? (isDark
                ? const Color(0xFF2C4055)
                : buttonColor.withValues(alpha: 0.22))
            : (isDark ? const Color(0xFF323232) : context.colors.surface);

    return ProgressiveBlurButton(
      onPressed: isEnabled
          ? () {
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
          : null,
      backgroundColor: effectiveBackgroundColor,
      width: width ?? (compact ? 72 : 95),
      height: height ?? (compact ? 56 : 70),
      borderRadius: borderRadius ?? (compact ? 20 : 28),
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
              child: isCompletedNumber
                  ? Icon(
                      Icons.check_rounded,
                      size: compact ? 16 : 18,
                      color: isDark
                          ? const Color(0xFF5A8A70)
                          : AppTheme.lightBlueColor,
                    )
                  : Text(
                      '$remainingCount',
                      style: GoogleFonts.notoSans(
                        fontSize:
                            isCompactSmallButton ? 9 : (compact ? 10 : 11),
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? context.colors.textSecondary
                            : context.colors.textPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInputLegend() {
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        isKorean
            ? '작은 숫자는 남은 개수, 체크는 완료된 숫자예요.'
            : 'Small numbers show what remains, checks mean completed.',
        style: GoogleFonts.notoSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.58),
        ),
      ),
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
  }) {
    final buttonSize =
        size ?? (compact ? 52.0 : (_oneHandModeEnabled ? 62.0 : 70.0));
    final iconSize =
        compact ? buttonSize * 0.36 : (_oneHandModeEnabled ? 28.0 : 32.0);
    final hasLabel = label.isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 1 : (_oneHandModeEnabled ? 2 : 3),
        vertical: compact ? 0.5 : (_oneHandModeEnabled ? 2 : 3),
      ),
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
                : Theme.of(context).colorScheme.onSurface;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: contentColor, size: iconSize - 1),
                if (hasLabel) ...[
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    label,
                    style: GoogleFonts.notoSans(
                      color: contentColor,
                      fontSize: labelFontSize ??
                          (compact ? 8 : (_oneHandModeEnabled ? 10 : 11)),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileHintButton(_MobileGameLayoutMetrics metrics) {
    final buttonSize = metrics.actionButtonSize;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildMobileActionButton(
          icon: Icons.lightbulb_outline,
          label: '',
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF8A6820)
              : AppTheme.yellowColor,
          isActive: false,
          onPressed: _canUseHint
              ? () {
                  setState(() {
                    _presenter.useHint();
                  });
                }
              : null,
          compact: true,
          size: buttonSize,
          labelFontSize: metrics.actionLabelFontSize,
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

  Widget _buildReservedBannerAdSlot({required double height}) {
    if (!kDebugMode) {
      return SizedBox(height: height);
    }
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    final isDarkAd = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: isDarkAd
            ? const Color(0xFF1E1E1E)
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkAd
              ? const Color(0xFF2A2A2A)
              : Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 14,
              color: Color(0xFF5F5F5F),
            ),
            const SizedBox(width: 4),
            Text(
              isKorean ? '광고' : 'Ad',
              style: GoogleFonts.notoSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5F5F5F),
              ),
            ),
          ],
        ),
      ),
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

class _StatusStripItem {
  const _StatusStripItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
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
    required this.bannerAdHeight,
    required this.bannerAdGap,
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
  final double bannerAdHeight;
  final double bannerAdGap;
  final double scrollBottomPadding;

  factory _MobileGameLayoutMetrics.fromConstraints({
    required double maxWidth,
    required double maxHeight,
    required double bottomSafePadding,
  }) {
    final isIPhoneSELayout = maxWidth <= 375 && maxHeight <= 620;
    final horizontalPadding = isIPhoneSELayout
        ? _clamp(maxWidth * 0.008, 2, 6)
        : _clamp(maxWidth * 0.032, 8, 16);
    final contentWidth = math.max(maxWidth - (horizontalPadding * 2), 220.0);

    final numberButtonGap = isIPhoneSELayout
        ? (contentWidth < 350 ? 2.0 : 3.0)
        : (contentWidth < 350 ? 3.0 : 5.0);
    final numberButtonWidth = _clamp(
      (contentWidth - (numberButtonGap * 6)) / 3,
      74,
      isIPhoneSELayout ? 128 : 112,
    );
    final numberButtonHeight = isIPhoneSELayout
        ? _clamp(numberButtonWidth * 0.32, 36, 40)
        : _clamp(numberButtonWidth * 0.66, 48, 68);
    final numberButtonRadius = isIPhoneSELayout
        ? _clamp(numberButtonWidth * 0.2, 14, 22)
        : _clamp(numberButtonWidth * 0.24, 16, 24);

    final actionButtonGap = contentWidth < 350 ? 3.0 : 4.0;
    final actionButtonSize = _clamp(
      (contentWidth - (actionButtonGap * 14)) / 6,
      isIPhoneSELayout ? 34 : 36,
      isIPhoneSELayout ? 40 : 50,
    );
    final actionLabelFontSize = actionButtonSize <= 50 ? 7.5 : 8.5;
    final bannerAdHeight = isIPhoneSELayout
        ? 48.0
        : _SudokuGameScreenState._kReservedBannerAdHeight;
    final bannerAdGap =
        isIPhoneSELayout ? 8.0 : _SudokuGameScreenState._kReservedBannerGap;

    final estimatedNumberPadHeight =
        (numberButtonHeight * 3) + (numberButtonGap * 4);
    final estimatedActionRowHeight =
        actionButtonSize + bannerAdHeight + bannerAdGap + 8.0;
    final fixedChromeHeight = estimatedNumberPadHeight +
        estimatedActionRowHeight +
        bottomSafePadding +
        (isIPhoneSELayout ? 0 : 12.0);

    final baseBoardSize =
        _clamp(contentWidth, 292, isIPhoneSELayout ? 520 : 420);
    final estimatedTotalHeight = fixedChromeHeight + baseBoardSize;
    final overflow = math.max(0.0, estimatedTotalHeight - maxHeight);
    final boardSize =
        _clamp(baseBoardSize - overflow, 256, isIPhoneSELayout ? 520 : 420);

    return _MobileGameLayoutMetrics(
      horizontalPadding: horizontalPadding,
      topPadding: 0,
      sectionGap: isIPhoneSELayout ? 3 : (maxHeight < 760 ? 4 : 8),
      compactGap: isIPhoneSELayout ? 1 : (maxHeight < 760 ? 2 : 4),
      boardSize: boardSize,
      numberButtonWidth: numberButtonWidth,
      numberButtonHeight: numberButtonHeight,
      numberButtonRadius: numberButtonRadius,
      numberButtonGap: numberButtonGap,
      actionButtonSize: actionButtonSize,
      actionLabelFontSize: actionLabelFontSize,
      bannerAdHeight: bannerAdHeight,
      bannerAdGap: bannerAdGap,
      scrollBottomPadding:
          isIPhoneSELayout ? bottomSafePadding : bottomSafePadding + 4,
    );
  }

  static double _clamp(double value, double min, double max) {
    return math.max(min, math.min(value, max));
  }
}
