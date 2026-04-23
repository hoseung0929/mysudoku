import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/presenter/sudoku_game_presenter.dart';
import 'package:mysudoku/services/onboarding_service.dart';
import 'package:mysudoku/services/result_share_service.dart';
import 'package:mysudoku/theme/app_theme.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/view/sudoku_game/game_end_flow.dart';
import 'package:mysudoku/view/sudoku_game/game_guide_flow.dart';
import 'package:mysudoku/view/sudoku_game/game_session_controller.dart';
import 'package:mysudoku/view/sudoku_game/game_settings_controller.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_answer_box.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_board_grid.dart';
import 'package:mysudoku/view/sudoku_game/game_effects_controller.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_game_action_button.dart';
import 'package:mysudoku/view/level_selection_screen.dart';
import 'package:mysudoku/widgets/custom_app_bar.dart';
import 'package:mysudoku/widgets/progressive_blur_button.dart';
import 'package:vibration/vibration.dart';

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
  final OnboardingService _onboardingService = OnboardingService();
  final ResultShareService _resultShareService = ResultShareService();
  late final GameEndFlow _gameEndFlow =
      GameEndFlow(resultShareService: _resultShareService);
  final GameSessionController _sessionController = GameSessionController();
  final GameSettingsController _settingsController = GameSettingsController();
  late final SudokuGamePresenter _presenter;
  bool _presenterReady = false;
  bool _isVibrationEnabled = true;
  bool _oneHandModeEnabled = false;
  bool _memoHighlightEnabled = true;
  bool _hasShownGameGuide = false;
  bool _showDeveloperAnswerPreview = false;
  int? _memoFocusNumber;
  final GameEffectsController _effectsController = GameEffectsController();

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
        !_presenter.isPaused &&
        !_presenter.isGameComplete &&
        !_presenter.isGameOver;
  }

  bool get _canClearSelectedCell {
    if (!_hasEditableSelection) {
      return false;
    }
    final row = _presenter.selectedRow!;
    final col = _presenter.selectedCol!;
    return _presenter.getCellValue(row, col) != 0;
  }

  bool get _canUndo {
    return _presenterReady &&
        !_presenter.isPaused &&
        !_presenter.isGameComplete &&
        !_presenter.isGameOver &&
        _presenter.canUndo;
  }

  bool get _canRedo {
    return _presenterReady &&
        !_presenter.isPaused &&
        !_presenter.isGameComplete &&
        !_presenter.isGameOver &&
        _presenter.canRedo;
  }

  bool get _canUseHint {
    if (!_presenterReady ||
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

  Future<void> _flushAndSyncCloudSession() async {
    if (!_presenterReady) return;
    await _flushPendingSessionSave();
    await _sessionController.syncToCloud();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeGame();
  }

  /// 게임 초기화
  Future<void> _initializeGame() async {
    if (kDebugMode) {
      AppLogger.debug(
        '게임 초기화 시작: ${widget.level.name} 게임 ${widget.game.gameNumber}',
      );
    }

    await _loadGameSettings();

    final sessionBootstrap = await _sessionController.prepareSession(
      game: widget.game,
      level: widget.level,
      restoreSavedSession: widget.restoreSavedSession,
    );
    final activeSession = sessionBootstrap.activeSession;
    final initialBoard = sessionBootstrap.initialBoard;
    if (activeSession != null && kDebugMode) {
      AppLogger.debug('저장된 게임 상태 발견');
    }
    _effectsController.resetForBoard(
      board: initialBoard,
      solution: widget.game.solution,
    );

    _presenter = SudokuGamePresenter(
      puzzleBoard: widget.game.board,
      initialBoard: initialBoard,
      solution: widget.game.solution,
      initialElapsedSeconds: activeSession?.elapsedSeconds ?? 0,
      initialWrongCount: activeSession?.wrongCount ?? 0,
      initialMemoMode: activeSession?.isMemoMode ?? false,
      initialNotes: activeSession?.notes,
      initialHintsRemaining:
          activeSession?.hintsRemaining ?? SudokuGamePresenter.maxHints,
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
        setState(() {});
        _scheduleSessionSave();
      },
      onPauseStateChanged: (isPaused) {
        setState(() {});
        _scheduleSessionSave();
      },
      onGameCompleteChanged: (isComplete) {
        if (isComplete) {
          _showGameCompleteDialog();
        }
        setState(() {});
      },
      onWrongCountChanged: (wrongCount) {
        setState(() {});
        _scheduleSessionSave();
      },
      onGameOver: () {
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
      },
    );
    if (mounted) {
      setState(() {
        _presenterReady = true;
        _memoFocusNumber = null;
      });
    }
    _presenter.clearSelection();
    await _flushPendingSessionSave();
    await _maybeShowGameGuide();
    if (kDebugMode) {
      AppLogger.debug('게임 초기화 완료');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_flushAndSyncCloudSession());
        return;
      case AppLifecycleState.resumed:
        return;
    }
  }

  Future<void> _maybeShowGameGuide() async {
    if (!mounted) return;
    final started = await GameGuideFlow.showIfNeeded(
      context: context,
      onboardingService: _onboardingService,
      hasShownGuide: _hasShownGameGuide,
    );
    if (!mounted || !started) return;
    _hasShownGameGuide = true;
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

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1100),
        behavior: SnackBarBehavior.floating,
        content: Text(parts.join(' · ')),
      ),
    );
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
    _effectsController.resetForBoard(
      board: widget.game.board,
      solution: widget.game.solution,
    );
    _presenter.restartGame();
  }

  Future<void> _exitToLevelSelection() async {
    final levelNavigator = Navigator.of(context);
    unawaited(
      levelNavigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => LevelSelectionScreen(level: widget.level),
        ),
      ),
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
      _memoHighlightEnabled = settings.memoHighlightEnabled;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_flushPendingSessionSave());
    _sessionController.dispose();
    unawaited(_settingsController.dispose());
    _effectsController.dispose();
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
      return Scaffold(
        backgroundColor: surface,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF6),
      appBar: _buildAppBar(),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDFBF6),
              Color(0xFFF7F4E8),
            ],
          ),
        ),
        child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
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
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
        titleSpacing: 0,
        title: GestureDetector(
          onLongPress: kDebugMode ? _toggleDeveloperAnswerPreview : null,
          child: Text(
            titleText,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF21382A),
            ),
          ),
        ),
        leadingWidth: 52,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          visualDensity: VisualDensity.compact,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          _buildDeveloperMenuButton(),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                _presenterReady ? _presenter.calmFormattedTime : '0m',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF66776C),
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
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      actions: [_buildDeveloperMenuButton()],
    );
  }

  Widget _buildDeveloperMenuButton() {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }
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
    if (!kDebugMode) return;
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
                            value: _presenter.calmFormattedTime,
                          ),
                          _StatusStripItem(
                            icon: Icons.error_outline,
                            label: l10n.gameWrongShort,
                            value: '${_presenter.wrongCount}/3',
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
                          color: Colors.white.withValues(alpha: 0.76),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE4DED3)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF21382A)
                                  .withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
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
                                  icon: Icons.undo,
                                  label: l10n.gameUndoShort,
                                  backgroundColor: AppTheme.lightBlueColor,
                                  onPressed: _canUndo
                                      ? () {
                                          setState(() {
                                            _presenter.undo();
                                          });
                                        }
                                      : null,
                                ),
                                SudokuGameActionButton(
                                  icon: Icons.redo,
                                  label: l10n.gameRedoShort,
                                  backgroundColor: AppTheme.lightBlueColor,
                                  onPressed: _canRedo
                                      ? () {
                                          setState(() {
                                            _presenter.redo();
                                          });
                                        }
                                      : null,
                                ),
                                SudokuGameActionButton(
                                  icon: Icons.edit_note,
                                  label: _presenter.isMemoMode
                                      ? l10n.gameMemoOnShort
                                      : l10n.gameMemoShort,
                                  backgroundColor: _presenter.isMemoMode
                                      ? AppTheme.mintColor
                                      : AppTheme.lightBlueColor,
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
                                  icon: Icons.backspace_outlined,
                                  label: _eraseShortLabel(),
                                  backgroundColor: AppTheme.pinkColor
                                      .withValues(alpha: 0.78),
                                  onPressed: _canClearSelectedCell
                                      ? () {
                                          setState(() {
                                            _presenter.clearSelectedCell();
                                          });
                                        }
                                      : null,
                                ),
                                SudokuGameActionButton(
                                  icon: Icons.lightbulb_outline,
                                  label:
                                      '${l10n.gameHintShort} ${_presenter.hintsRemaining}',
                                  backgroundColor: AppTheme.yellowColor,
                                  onPressed: _canUseHint
                                      ? () {
                                          setState(() {
                                            _presenter.useHint();
                                          });
                                        }
                                      : null,
                                ),
                                SudokuGameActionButton(
                                  icon: _presenter.isPaused
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                  label: _presenter.isPaused
                                      ? l10n.gameResume
                                      : l10n.gamePause,
                                  backgroundColor: AppTheme.pinkColor,
                                  onPressed: () {
                                    setState(() {
                                      _presenter.togglePause();
                                    });
                                  },
                                ),
                              ],
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMobileActionButton(
                              icon: Icons.undo,
                              label: '',
                              color: AppTheme.lightBlueColor,
                              onPressed: _canUndo
                                  ? () {
                                      setState(() {
                                        _presenter.undo();
                                      });
                                    }
                                  : null,
                              compact: true,
                              size: metrics.actionButtonSize,
                              labelFontSize: metrics.actionLabelFontSize,
                            ),
                            _buildMobileActionButton(
                              icon: Icons.redo,
                              label: '',
                              color: AppTheme.lightBlueColor,
                              onPressed: _canRedo
                                  ? () {
                                      setState(() {
                                        _presenter.redo();
                                      });
                                    }
                                  : null,
                              compact: true,
                              size: metrics.actionButtonSize,
                              labelFontSize: metrics.actionLabelFontSize,
                            ),
                            _buildMobileActionButton(
                              icon: Icons.edit_note,
                              label: '',
                              color: _presenter.isMemoMode
                                  ? AppTheme.mintColor
                                  : AppTheme.lightBlueColor,
                              onPressed: () {
                                if (!_canToggleMemo) return;
                                setState(() {
                                  _memoFocusNumber = null;
                                  _presenter.toggleMemoMode();
                                });
                              },
                              compact: true,
                              size: metrics.actionButtonSize,
                              labelFontSize: metrics.actionLabelFontSize,
                            ),
                            _buildMobileActionButton(
                              icon: Icons.backspace_outlined,
                              label: '',
                              color: AppTheme.pinkColor.withValues(alpha: 0.78),
                              onPressed: _canClearSelectedCell
                                  ? () {
                                      setState(() {
                                        _presenter.clearSelectedCell();
                                      });
                                    }
                                  : null,
                              compact: true,
                              size: metrics.actionButtonSize,
                              labelFontSize: metrics.actionLabelFontSize,
                            ),
                            _buildMobileHintButton(metrics),
                            _buildMobileActionButton(
                              icon: _presenter.isPaused
                                  ? Icons.play_arrow
                                  : Icons.pause,
                              label: '',
                              color: AppTheme.pinkColor,
                              onPressed: () {
                                setState(() {
                                  _presenter.togglePause();
                                });
                              },
                              compact: true,
                              size: metrics.actionButtonSize,
                              labelFontSize: metrics.actionLabelFontSize,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showDeveloperAnswerPreview)
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

  Widget _buildBoardGrid() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
        child: SudokuBoardGrid(
          presenter: _presenter,
          waveActive: _effectsController.waveActive,
          lineCompleteActive: _effectsController.lineCompleteActive,
          errorActive: _effectsController.errorActive,
          highlightedMemoNumber:
              _memoHighlightEnabled ? _memoFocusNumber : null,
          enableMemoHighlights: _memoHighlightEnabled,
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
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(compact ? 20 : 22),
        border: Border.all(color: const Color(0xFFE4DED3)),
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
                  color: const Color(0xFFF8F4EA),
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                  border: Border.all(color: const Color(0xFFEAE2D5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon,
                        size: compact ? 13 : 16,
                        color: const Color(0xFF66776C)),
                    SizedBox(width: compact ? 5 : 6),
                    Text(
                      '${item.label} ${item.value}',
                      style: GoogleFonts.notoSans(
                        fontSize: compact ? 10.5 : 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF21382A),
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
    // 파스텔톤 색상 순환
    final List<Color> pastelColors = [
      AppTheme.mintColor,
      AppTheme.lightBlueColor,
      AppTheme.yellowColor
    ];
    final buttonColor = pastelColors[(number - 1) % pastelColors.length];
    final remainingCount = _remainingCountForNumber(number);
    final isEnabled = _isNumberInputEnabled(number);
    final isSelectedNumber = _selectedInputNumber() == number;
    final isCompletedNumber = remainingCount == 0;
    final effectiveBackgroundColor = isSelectedNumber
        ? Color.alphaBlend(
            const Color(0x33FFFFFF),
            buttonColor,
          )
        : buttonColor.withValues(alpha: 0.94);

    return ProgressiveBlurButton(
      onPressed: isEnabled
          ? () {
              setState(() {
                _memoFocusNumber = _presenter.isMemoMode ? number : null;
              });
              if (!_presenter.isMemoMode) {
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
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF457B9D).withValues(alpha: 0.18),
                      blurRadius: 14,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          Center(
            child: Text(
              number.toString(),
              style: AppTheme.numberButtonStyle.copyWith(
                fontWeight: isSelectedNumber ? FontWeight.w800 : null,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1,
                ),
              ),
              child: isCompletedNumber
                  ? Icon(
                      Icons.check_rounded,
                      size: compact ? 16 : 18,
                      color: const Color(0xFF2E7D32),
                    )
                  : Text(
                      '$remainingCount',
                      style: GoogleFonts.notoSans(
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
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

  Future<void> _vibrateOnNumberInput(int number) async {
    if (!_isVibrationEnabled || !_presenterReady) return;
    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) return;

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
      await Vibration.vibrate(duration: 35);
      return;
    }

    final supportsCustomPattern = await Vibration.hasCustomVibrationsSupport();
    if (supportsCustomPattern) {
      await Vibration.vibrate(pattern: [0, 45, 30, 65]);
      return;
    }

    await Vibration.vibrate(duration: 120);
  }

  Widget _buildMobileActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppTheme.textColor,
              size: iconSize - 1,
            ),
            if (hasLabel) ...[
              SizedBox(height: compact ? 2 : 4),
              Text(
                label,
                style: GoogleFonts.notoSans(
                  color: AppTheme.textColor,
                  fontSize: labelFontSize ??
                      (compact ? 8 : (_oneHandModeEnabled ? 10 : 11)),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
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
          color: AppTheme.yellowColor,
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
              color: _presenter.hintsRemaining > 0
                  ? const Color(0xFF457B9D)
                  : const Color(0xFFAAAAAA),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
            ),
            child: Text(
              '${_presenter.hintsRemaining}',
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

  String _eraseShortLabel() {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '지우기'
        : 'Clear';
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
    final horizontalPadding = _clamp(maxWidth * 0.032, 8, 16);
    final contentWidth = math.max(maxWidth - (horizontalPadding * 2), 220.0);

    final numberButtonGap = contentWidth < 350 ? 4.0 : 6.0;
    final numberButtonWidth = _clamp(
      (contentWidth - (numberButtonGap * 6)) / 3,
      74,
      112,
    );
    final numberButtonHeight = _clamp(numberButtonWidth * 0.8, 58, 80);
    final numberButtonRadius = _clamp(numberButtonWidth * 0.28, 18, 28);

    final actionButtonGap = contentWidth < 350 ? 3.0 : 4.0;
    final actionButtonSize = _clamp(
      (contentWidth - (actionButtonGap * 14)) / 6,
      36,
      50,
    );
    final actionLabelFontSize = actionButtonSize <= 50 ? 7.5 : 8.5;

    final estimatedNumberPadHeight =
        (numberButtonHeight * 3) + (numberButtonGap * 4);
    final estimatedActionRowHeight = actionButtonSize + 8.0;
    final fixedChromeHeight = estimatedNumberPadHeight +
        estimatedActionRowHeight +
        bottomSafePadding +
        20.0;

    final baseBoardSize = _clamp(contentWidth, 292, 420);
    final estimatedTotalHeight = fixedChromeHeight + baseBoardSize;
    final overflow = math.max(0.0, estimatedTotalHeight - maxHeight);
    final boardSize = _clamp(baseBoardSize - overflow, 256, 420);

    return _MobileGameLayoutMetrics(
      horizontalPadding: horizontalPadding,
      topPadding: 0,
      sectionGap: maxHeight < 760 ? 6 : 10,
      compactGap: maxHeight < 760 ? 4 : 6,
      boardSize: boardSize,
      numberButtonWidth: numberButtonWidth,
      numberButtonHeight: numberButtonHeight,
      numberButtonRadius: numberButtonRadius,
      numberButtonGap: numberButtonGap,
      actionButtonSize: actionButtonSize,
      actionLabelFontSize: actionLabelFontSize,
      scrollBottomPadding: bottomSafePadding + 4,
    );
  }

  static double _clamp(double value, double min, double max) {
    return math.max(min, math.min(value, max));
  }
}
