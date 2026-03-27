import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/presenter/sudoku_game_presenter.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/services/onboarding_service.dart';
import 'package:mysudoku/services/app_settings_service.dart';
import 'package:mysudoku/services/result_share_service.dart';
import 'package:mysudoku/theme/app_theme.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/view/sudoku_game/game_completion_coordinator.dart';
import 'package:mysudoku/view/sudoku_game/game_guide_flow.dart';
import 'package:mysudoku/view/sudoku_game/game_over_flow.dart';
import 'package:mysudoku/view/sudoku_game/game_result_actions.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_answer_box.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_board_grid.dart';
import 'package:mysudoku/view/sudoku_game/game_effects_controller.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_game_action_button.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_info_card.dart';
import 'package:mysudoku/widgets/custom_app_bar.dart';
import 'package:mysudoku/widgets/game_complete_dialog.dart';
import 'package:mysudoku/widgets/progressive_blur_button.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 스도쿠 게임의 메인 화면
/// MVP 패턴에서 View 역할을 수행하며, 사용자 인터페이스를 담당
class SudokuGameScreen extends StatefulWidget {
  final SudokuGame game;
  final SudokuLevel level;

  const SudokuGameScreen({
    super.key,
    required this.game,
    required this.level,
  });

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen> {
  final AppSettingsService _appSettingsService = AppSettingsService();
  final GameStateService _gameStateService = GameStateService();
  final OnboardingService _onboardingService = OnboardingService();
  final ResultShareService _resultShareService = ResultShareService();
  late final GameResultActions _resultActions =
      GameResultActions(resultShareService: _resultShareService);
  final GameCompletionCoordinator _completionCoordinator =
      GameCompletionCoordinator();
  late final SudokuGamePresenter _presenter;
  bool _presenterReady = false;
  bool _isVibrationEnabled = true;
  bool _keepScreenAwake = false;
  bool _oneHandModeEnabled = false;
  bool _memoHighlightEnabled = true;
  bool _smartHintHighlightEnabled = true;
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
    if (_presenter.isPaused || _presenter.isGameComplete || _presenter.isGameOver) {
      return false;
    }
    return !_presenter.isCellFixed(row, col);
  }

  bool get _canToggleMemo {
    return _presenterReady && !_presenter.isGameComplete && !_presenter.isGameOver;
  }

  bool get _canUseHint {
    return _hasEditableSelection && _presenter.hintsRemaining > 0;
  }

  bool get _canClearSelectedCell {
    if (!_hasEditableSelection) {
      return false;
    }
    final row = _presenter.selectedRow!;
    final col = _presenter.selectedCol!;
    return _presenter.getCellValue(row, col) != 0;
  }

  Future<void> _persistCurrentSession() async {
    if (!_presenterReady) return;
    if (_presenter.isGameComplete || _presenter.isGameOver) {
      await _clearCurrentGameState();
      return;
    }
    await _gameStateService.saveSession(
      levelName: widget.level.name,
      gameNumber: widget.game.gameNumber,
      board: List.generate(
        9,
        (row) => List.generate(9, (col) => _presenter.getCellValue(row, col)),
      ),
      notes: _presenter.allCellNotes,
      elapsedSeconds: _presenter.seconds,
      hintsRemaining: _presenter.hintsRemaining,
      wrongCount: _presenter.wrongCount,
      isMemoMode: _presenter.isMemoMode,
      hintCells: _presenter.hintCells,
      isGameComplete: _presenter.isGameComplete,
      isGameOver: _presenter.isGameOver,
    );
  }

  @override
  void initState() {
    super.initState();
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

    // 저장된 게임 상태 복원
    final restoredSession = await _gameStateService.loadSession(
      levelName: widget.level.name,
      gameNumber: widget.game.gameNumber,
    );
    final activeSession = restoredSession != null &&
            _shouldDiscardRestoredSession(restoredSession)
        ? null
        : restoredSession;
    if (restoredSession != null && activeSession == null) {
      await _gameStateService.clearBoard(
        levelName: widget.level.name,
        gameNumber: widget.game.gameNumber,
      );
    }
    List<List<int>>? restoredBoard = activeSession?.board;
    if (restoredBoard != null && kDebugMode) {
      AppLogger.debug('저장된 게임 상태 발견');
    }
    if (restoredBoard != null &&
        !_gameStateService.isBoardCompatible(
          originalBoard: widget.game.board,
          restoredBoard: restoredBoard,
        )) {
      if (kDebugMode) {
        for (int row = 0; row < restoredBoard.length; row++) {
          for (int col = 0; col < restoredBoard[row].length; col++) {
            if (row >= widget.game.board.length ||
                col >= widget.game.board[row].length ||
                (widget.game.board[row][col] != 0 &&
                    restoredBoard[row][col] != widget.game.board[row][col])) {
              AppLogger.debug(
                '다른 게임 감지: [$row][$col], 원본=${row < widget.game.board.length && col < widget.game.board[row].length ? widget.game.board[row][col] : 'N/A'}, 저장=${restoredBoard[row][col]}',
              );
              break;
            }
          }
        }
      }
      if (kDebugMode) {
        AppLogger.debug('저장된 게임 상태가 현재 퍼즐과 달라 무시합니다');
      }
      await _gameStateService.clearBoard(
        levelName: widget.level.name,
        gameNumber: widget.game.gameNumber,
      );
      restoredBoard = null;
    }

    final initialBoard = restoredBoard ?? widget.game.board;
    _effectsController.initializeCompletedLineState(
      board: initialBoard,
      solution: widget.game.solution,
    );

    _presenter = SudokuGamePresenter(
      initialBoard: initialBoard,
      solution: widget.game.solution, // DB에서 가져온 해답 데이터 사용 (항상 동일)
      initialElapsedSeconds: activeSession?.elapsedSeconds ?? 0,
      initialHintsRemaining: activeSession?.hintsRemaining ?? 3,
      initialWrongCount: activeSession?.wrongCount ?? 0,
      initialMemoMode: activeSession?.isMemoMode ?? false,
      initialNotes: activeSession?.notes,
      initialHintCells: activeSession?.hintCells ?? const <String>{},
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
        _persistCurrentSession();
      },
      onFixedNumbersChanged: (fixedNumbers) {
        setState(() {});
      },
      onWrongNumbersChanged: (wrongNumbers) {
        setState(() {});
      },
      onTimeChanged: (time) {
        setState(() {});
        _persistCurrentSession();
      },
      onHintsChanged: (hints) {
        setState(() {});
        _persistCurrentSession();
      },
      onPauseStateChanged: (isPaused) {
        setState(() {});
        _persistCurrentSession();
      },
      onGameCompleteChanged: (isComplete) {
        if (isComplete) {
          _showGameCompleteDialog();
        }
        setState(() {});
      },
      onWrongCountChanged: (wrongCount) {
        setState(() {});
        _persistCurrentSession();
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
    await _persistCurrentSession();
    await _maybeShowGameGuide();
    if (kDebugMode) {
      AppLogger.debug('게임 초기화 완료');
    }
  }

  bool _shouldDiscardRestoredSession(GameSessionState session) {
    if (session.isGameComplete || session.isGameOver || session.wrongCount >= 3) {
      return true;
    }

    return _gameStateService.isBoardCompatible(
      originalBoard: widget.game.solution,
      restoredBoard: session.board,
    );
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
    await _gameStateService.clearBoard(
      levelName: widget.level.name,
      gameNumber: widget.game.gameNumber,
    );
  }

  Future<void> _resetAndRestartCurrentGame() async {
    await _clearCurrentGameState();
    if (!mounted) return;
    _presenter.restartGame();
  }

  Future<void> _exitToLevelSelection() async {
    final levelNavigator = Navigator.of(context);
    await _clearCurrentGameState();
    if (!mounted) return;
    levelNavigator.pop();
  }

  Future<void> _loadGameSettings() async {
    final vibrationEnabled = await _appSettingsService.getBool(
      AppSettingsService.vibrationEnabledKey,
      defaultValue: true,
    );
    final keepScreenAwake = await _appSettingsService.getBool(
      AppSettingsService.keepScreenAwakeKey,
      defaultValue: false,
    );
    final oneHandModeEnabled = await _appSettingsService.getBool(
      AppSettingsService.oneHandModeEnabledKey,
      defaultValue: false,
    );
    final memoHighlightEnabled = await _appSettingsService.getBool(
      AppSettingsService.memoHighlightEnabledKey,
      defaultValue: true,
    );
    final smartHintHighlightEnabled = await _appSettingsService.getBool(
      AppSettingsService.smartHintHighlightEnabledKey,
      defaultValue: true,
    );
    await WakelockPlus.toggle(enable: keepScreenAwake);
    if (!mounted) return;
    setState(() {
      _isVibrationEnabled = vibrationEnabled;
      _keepScreenAwake = keepScreenAwake;
      _oneHandModeEnabled = oneHandModeEnabled;
      _memoHighlightEnabled = memoHighlightEnabled;
      _smartHintHighlightEnabled = smartHintHighlightEnabled;
    });
  }

  @override
  void dispose() {
    if (_keepScreenAwake) {
      WakelockPlus.disable();
    }
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
      backgroundColor: surface,
      appBar: _buildAppBar(),
      body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
    );
  }

  /// 앱바 위젯
  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return CustomAppBar(
      title: widget.level.localizedName(l10n),
      showNotificationIcon: false,
      showLogoutIcon: false,
      titleWidget: kDebugMode
          ? GestureDetector(
              onLongPress: _toggleDeveloperAnswerPreview,
              child: Text(widget.level.localizedName(l10n)),
            )
          : null,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  /// 태블릿 레이아웃
  Widget _buildTabletLayout() {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final memoState = _presenter.isMemoMode
        ? l10n.gameMemoStateOn
        : l10n.gameMemoStateOff;
    return Column(
      children: [
        // 상단 정보 영역
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                  Text(
                    l10n.gameNumberLabel(widget.game.gameNumber),
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SudokuInfoCard(
                      l10n.gameTimeShort, _presenter.formattedTime, Icons.timer),
                  const SizedBox(width: 12),
                  SudokuInfoCard(
                      l10n.gameHintShort,
                      '${_presenter.hintsRemaining}',
                      Icons.lightbulb),
                  const SizedBox(width: 12),
                  SudokuInfoCard(
                    l10n.gameMemoShort,
                    memoState,
                    Icons.edit_note,
                    accentColor: _presenter.isMemoMode
                        ? AppTheme.mintColor
                        : null,
                  ),
                  const SizedBox(width: 12),
                  SudokuInfoCard(
                    l10n.gameMemoFocusShort,
                    _memoFocusLabel(l10n),
                    Icons.filter_center_focus,
                    accentColor: _memoFocusColor(),
                  ),
                  const SizedBox(width: 12),
                  SudokuInfoCard(
                      l10n.gameWrongShort,
                      '${_presenter.wrongCount}/3',
                      Icons.error_outline),
                  const SizedBox(width: 12),
                  SudokuInfoCard(
                    l10n.gamePerfectShort,
                    _perfectStatusLabel(l10n),
                    Icons.auto_awesome,
                    accentColor: _perfectStatusColor(),
                  ),
                  const SizedBox(width: 12),
                  SudokuInfoCard(
                      l10n.gameProgressShort,
                      '${(_presenter.progress * 100).toInt()}%',
                      Icons.emoji_events),
                ],
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
                  padding: const EdgeInsets.all(24),
                  child: _buildBoardGrid(),
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
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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
                                const SizedBox(width: 8),
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
                                const SizedBox(width: 8),
                                SudokuGameActionButton(
                                  icon: Icons.lightbulb,
                                  label: l10n.gameHintShort,
                                  backgroundColor: AppTheme.yellowColor,
                                  onPressed: _canUseHint
                                      ? () {
                                          setState(() {
                                            _presenter.useHint();
                                          });
                                        }
                                      : null,
                                ),
                                const SizedBox(width: 8),
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
    final memoState = _presenter.isMemoMode
        ? l10n.gameMemoStateOn
        : l10n.gameMemoStateOff;
    return Stack(
      children: [
        // 그리드 영역
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: _buildBoardGrid(),
              ),
              SizedBox(height: _oneHandModeEnabled ? 12 : 20),
              // 정보 카드들을 SingleChildScrollView로 감싸서 오버플로우 방지
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SudokuInfoCard(
                        l10n.gameTimeShort, _presenter.formattedTime, Icons.timer),
                    const SizedBox(width: 12),
                    SudokuInfoCard(
                      l10n.gameHintShort,
                      '${_presenter.hintsRemaining}',
                      Icons.lightbulb,
                    ),
                    const SizedBox(width: 12),
                    SudokuInfoCard(l10n.gameWrongShort,
                        '${_presenter.wrongCount}/3',
                        Icons.error_outline),
                    const SizedBox(width: 12),
                    SudokuInfoCard(
                      l10n.gamePerfectShort,
                      _perfectStatusLabel(l10n),
                      Icons.auto_awesome,
                      accentColor: _perfectStatusColor(),
                    ),
                    const SizedBox(width: 12),
                    SudokuInfoCard(
                      l10n.gameMemoShort,
                      memoState,
                      Icons.edit_note,
                      accentColor: _presenter.isMemoMode
                          ? AppTheme.mintColor
                          : null,
                    ),
                    const SizedBox(width: 12),
                    SudokuInfoCard(
                      l10n.gameMemoFocusShort,
                      _memoFocusLabel(l10n),
                      Icons.filter_center_focus,
                      accentColor: _memoFocusColor(),
                    ),
                    const SizedBox(width: 12),
                    SudokuInfoCard(
                        l10n.gameProgressShort,
                        '${(_presenter.progress * 100).toInt()}%',
                        Icons.emoji_events),
                  ],
                ),
              ),
              SizedBox(height: _oneHandModeEnabled ? 4 : 8),
              _buildNumberInputLegend(),
              // 4x4 그리드 (숫자 + 메뉴)
              for (int i = 0; i < 3; i++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int j = 1; j <= 3; j++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 3,
                        ),
                        child: _buildNumberButton(
                          i * 3 + j,
                          compact: _oneHandModeEnabled,
                        ),
                      ),
                  ],
                ),
              SizedBox(height: _oneHandModeEnabled ? 6 : 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMobileActionButton(
                    icon: Icons.edit_note,
                    label: _presenter.isMemoMode
                        ? l10n.gameMemoOnShort
                        : l10n.gameMemoShort,
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
                  ),
                  _buildMobileActionButton(
                    icon: Icons.backspace_outlined,
                    label: _eraseShortLabel(),
                    color: AppTheme.pinkColor.withValues(alpha: 0.78),
                    onPressed: _canClearSelectedCell
                        ? () {
                            setState(() {
                              _presenter.clearSelectedCell();
                            });
                          }
                        : null,
                  ),
                  _buildMobileActionButton(
                    icon: Icons.lightbulb,
                    label: l10n.gameHintShort,
                    color: AppTheme.yellowColor,
                    onPressed: _canUseHint
                        ? () {
                            setState(() {
                              _presenter.useHint();
                            });
                          }
                        : null,
                  ),
                  _buildMobileActionButton(
                    icon: _presenter.isPaused ? Icons.play_arrow : Icons.pause,
                    label:
                        _presenter.isPaused ? l10n.gameResume : l10n.gamePause,
                    color: AppTheme.pinkColor,
                    onPressed: () {
                      setState(() {
                        _presenter.togglePause();
                      });
                    },
                  ),
                ],
              ),
              _buildDeveloperAnswerPreview(l10n)
              // Padding(
              //   //padding: const EdgeInsets.symmetric(vertical: 4),
              //   child: _buildAnswerBox(),
              // ),
              //Expanded(child: Container()), // 나머지 공간 비움
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBoardGrid() {
    return SudokuBoardGrid(
      presenter: _presenter,
      waveActive: _effectsController.waveActive,
      lineCompleteActive: _effectsController.lineCompleteActive,
      errorActive: _effectsController.errorActive,
      highlightedMemoNumber: _memoHighlightEnabled ? _memoFocusNumber : null,
      enableMemoHighlights: _memoHighlightEnabled,
      enableSmartHintHighlights: _smartHintHighlightEnabled,
      onCellTapped: (row, col) {
        setState(() {
          _presenter.selectCell(row, col);
        });
      },
    );
  }

  String _perfectStatusLabel(AppLocalizations l10n) {
    return _presenter.wrongCount == 0
        ? l10n.gamePerfectReady
        : l10n.gamePerfectMissed;
  }

  Color _perfectStatusColor() {
    return _presenter.wrongCount == 0
        ? AppTheme.mintColor
        : AppTheme.pinkColor.withValues(alpha: 0.85);
  }

  String _memoFocusLabel(AppLocalizations l10n) {
    if (_memoFocusNumber == null) {
      return l10n.gameMemoFocusIdle;
    }
    return '${_memoFocusNumber!}';
  }

  Color? _memoFocusColor() {
    if (!_presenter.isMemoMode || _memoFocusNumber == null) {
      return null;
    }
    return AppTheme.lightBlueColor;
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

  Widget _buildNumberButton(int number, {bool compact = false}) {
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
            AppTheme.lightBlueColor.withValues(alpha: 0.36),
            buttonColor,
          )
        : buttonColor;

    return ProgressiveBlurButton(
      onPressed: isEnabled
          ? () async {
              if (!_presenter.isMemoMode) {
                await _vibrateOnNumberInput(number);
              }

              setState(() {
                _memoFocusNumber = _presenter.isMemoMode ? number : null;
                _presenter.setSelectedCellValue(number);
              });
            }
          : null,
      backgroundColor: effectiveBackgroundColor,
      width: compact ? 82 : 95,
      height: compact ? 62 : 70,
      borderRadius: compact ? 22 : 28,
      child: Stack(
        children: [
          if (isSelectedNumber)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.95),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightBlueColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
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
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Color(0xFF2E7D32),
                    )
                  : Text(
                      '$remainingCount',
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        isKorean
            ? '작은 숫자는 남은 개수, 체크는 완료된 숫자예요'
            : 'Small numbers show remaining count, check means completed',
        style: GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
        ),
      ),
    );
  }

  Future<void> _vibrateOnNumberInput(int number) async {
    if (!_isVibrationEnabled || !_presenterReady) return;
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;

    final selectedRow = _presenter.selectedRow;
    final selectedCol = _presenter.selectedCol;
    if (selectedRow == null || selectedCol == null) return;
    if (_presenter.isCellFixed(selectedRow, selectedCol)) return;
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

    final supportsCustomPattern =
        await Vibration.hasCustomVibrationsSupport() ?? false;
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
  }) {
    final buttonSize = _oneHandModeEnabled ? 62.0 : 70.0;
    final iconSize = _oneHandModeEnabled ? 28.0 : 32.0;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _oneHandModeEnabled ? 2 : 3,
        vertical: _oneHandModeEnabled ? 2 : 3,
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
              size: iconSize,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.notoSans(
                color: AppTheme.textColor,
                fontSize: _oneHandModeEnabled ? 10 : 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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
    final l10n = AppLocalizations.of(context)!;
    final completionData = await _completionCoordinator.prepare(
      l10n: l10n,
      level: widget.level,
      game: widget.game,
      clearTimeSeconds: _presenter.seconds,
      wrongCount: _presenter.wrongCount,
    );
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return GameCompleteDialog(
          shareSummary: _resultShareService.formatClearSummary(
            l10n: l10n,
            clearTimeSeconds: _presenter.seconds,
            wrongCount: _presenter.wrongCount,
          ),
          timeInSeconds: _presenter.seconds,
          wrongCount: _presenter.wrongCount,
          isNewBestRecord: completionData.isNewBestRecord,
          challengeMessage: completionData.challengeMessage,
          unlockedBadges: completionData.newlyUnlockedBadges,
          onCopyResult: () => _copyClearResult(completionData.isNewBestRecord),
          onShareResult: () => _shareClearResult(completionData.isNewBestRecord),
          onNextPuzzle: completionData.nextGame == null
              ? null
              : () => _openNextPuzzle(dialogContext, completionData.nextGame!),
          onRestart: () async {
            Navigator.of(dialogContext).pop();
            await _resetAndRestartCurrentGame();
          },
          onGoToLevelSelection: () async {
            Navigator.of(dialogContext).pop();
            await _exitToLevelSelection();
          },
        );
      },
    );
  }

  /// 클리어 후 같은 난이도의 다음 퍼즐로 이동합니다.
  Future<void> _openNextPuzzle(
    BuildContext dialogContext,
    SudokuGame next,
  ) async {
    Navigator.of(dialogContext).pop();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (ctx) => SudokuGameScreen(
          game: next,
          level: widget.level,
        ),
      ),
    );
  }

  Future<void> _copyClearResult(bool isNewBestRecord) async {
    final l10n = AppLocalizations.of(context)!;
    final resultText = _resultActions.buildResultText(
      l10n: l10n,
      localizedLevelName: widget.level.localizedName(l10n),
      gameNumber: widget.game.gameNumber,
      clearTimeSeconds: _presenter.seconds,
      wrongCount: _presenter.wrongCount,
      isNewBestRecord: isNewBestRecord,
    );

    await _resultActions.copyResultText(resultText);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.shareCopySuccess)),
    );
  }

  Future<void> _shareClearResult(bool isNewBestRecord) async {
    final l10n = AppLocalizations.of(context)!;
    final resultText = _resultActions.buildResultText(
      l10n: l10n,
      localizedLevelName: widget.level.localizedName(l10n),
      gameNumber: widget.game.gameNumber,
      clearTimeSeconds: _presenter.seconds,
      wrongCount: _presenter.wrongCount,
      isNewBestRecord: isNewBestRecord,
    );

    await _resultActions.shareResultText(
      resultText: resultText,
      subject: l10n.shareSubject,
    );
  }

  /// 게임 오버 다이얼로그 표시
  void _showGameOverDialog() {
    GameOverFlow.show(
      context: context,
      wrongCount: _presenter.wrongCount,
      onRestart: _resetAndRestartCurrentGame,
      onGoToLevelSelection: _exitToLevelSelection,
    );
  }

  Widget _buildDeveloperAnswerPreview(AppLocalizations l10n) {
    if (!kDebugMode || !_showDeveloperAnswerPreview) {
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
        ? (isKorean ? '개발자 정답 미리보기를 켰습니다.' : 'Developer answer preview enabled.')
        : (isKorean ? '개발자 정답 미리보기를 껐습니다.' : 'Developer answer preview disabled.');

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
