import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_game_set.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/presenter/sudoku_game_presenter.dart';
import 'package:mysudoku/services/achievement_service.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/services/game_record_service.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/services/onboarding_service.dart';
import 'package:mysudoku/services/result_share_service.dart';
import 'package:mysudoku/theme/app_theme.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/view/sudoku_game/game_guide_item.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_answer_box.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_board_grid.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_game_action_button.dart';
import 'package:mysudoku/view/sudoku_game/sudoku_info_card.dart';
import 'package:mysudoku/widgets/custom_app_bar.dart';
import 'package:mysudoku/widgets/game_complete_dialog.dart';
import 'package:mysudoku/widgets/game_over_dialog.dart';
import 'package:mysudoku/widgets/progressive_blur_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

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
  static const String _vibrationEnabledKey = 'vibration_enabled';
  final GameStateService _gameStateService = GameStateService();
  final GameRecordService _gameRecordService = GameRecordService();
  final OnboardingService _onboardingService = OnboardingService();
  final ResultShareService _resultShareService = ResultShareService();
  final ChallengeProgressService _challengeProgressService =
      ChallengeProgressService();
  final AchievementService _achievementService = AchievementService();
  late final SudokuGamePresenter _presenter;
  bool _presenterReady = false;
  bool _isVibrationEnabled = true;
  bool _hasShownGameGuide = false;
  Set<int> _completedRows = <int>{};
  Set<int> _completedCols = <int>{};

  // 파도 효과 상태
  final Map<String, bool> _waveActive = {};
  final Map<String, bool> _lineCompleteActive = {};

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

    await _loadVibrationSetting();

    // 저장된 게임 상태 복원
    List<List<int>>? restoredBoard = await _gameStateService.loadBoard(
      levelName: widget.level.name,
      gameNumber: widget.game.gameNumber,
    );
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
    _initializeCompletedLineState(initialBoard);

    _presenter = SudokuGamePresenter(
      initialBoard: initialBoard,
      solution: widget.game.solution, // DB에서 가져온 해답 데이터 사용 (항상 동일)
      level: widget.level,
      onBoardChanged: (board) {
        _checkAndTriggerLineCompletionEffect(board);
        setState(() {});
        _gameStateService.saveBoard(
          levelName: widget.level.name,
          gameNumber: widget.game.gameNumber,
          board: board,
        );
      },
      onFixedNumbersChanged: (fixedNumbers) {
        setState(() {});
      },
      onWrongNumbersChanged: (wrongNumbers) {
        setState(() {});
      },
      onTimeChanged: (time) {
        setState(() {});
      },
      onHintsChanged: (hints) {
        setState(() {});
      },
      onPauseStateChanged: (isPaused) {
        setState(() {});
      },
      onGameCompleteChanged: (isComplete) {
        if (isComplete) {
          _showGameCompleteDialog();
        }
        setState(() {});
      },
      onWrongCountChanged: (wrongCount) {
        setState(() {});
      },
      onGameOver: () {
        _showGameOverDialog();
      },
      onCorrectAnswer: (row, col) {
        _triggerWaveEffect(row, col);
      },
    );
    if (mounted) {
      setState(() {
        _presenterReady = true;
      });
    }
    await _maybeShowGameGuide();
    if (kDebugMode) {
      AppLogger.debug('게임 초기화 완료');
    }
  }

  Future<void> _maybeShowGameGuide() async {
    if (!mounted || _hasShownGameGuide) return;
    final shouldShow = await _onboardingService.shouldShowGameGuide();
    if (!shouldShow || !mounted) return;

    _hasShownGameGuide = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          final l10n = AppLocalizations.of(sheetContext)!;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.gameGuideTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(sheetContext).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                GameGuideItem(
                  title: l10n.gameGuideTapCellTitle,
                  description: l10n.gameGuideTapCellBody,
                ),
                const SizedBox(height: 10),
                GameGuideItem(
                  title: l10n.gameGuideMistakesTitle,
                  description: l10n.gameGuideMistakesBody,
                ),
                const SizedBox(height: 10),
                GameGuideItem(
                  title: l10n.gameGuideColorsTitle,
                  description: l10n.gameGuideColorsBody,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.gameGuidePlayButton),
                  ),
                ),
              ],
            ),
          );
        },
      );
      await _onboardingService.markGameGuideSeen();
    });
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

  Future<void> _loadVibrationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isVibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
    });
  }

  void _initializeCompletedLineState(List<List<int>> board) {
    _completedRows = _getCompletedCorrectRows(board);
    _completedCols = _getCompletedCorrectCols(board);
  }

  Set<int> _getCompletedCorrectRows(List<List<int>> board) {
    if (widget.game.solution.isEmpty) return <int>{};
    final completedRows = <int>{};
    for (int row = 0; row < 9; row++) {
      bool isCorrectLine = true;
      for (int col = 0; col < 9; col++) {
        final value = board[row][col];
        final answer = widget.game.solution[row][col];
        if (value == 0 || value != answer) {
          isCorrectLine = false;
          break;
        }
      }
      if (isCorrectLine) completedRows.add(row);
    }
    return completedRows;
  }

  Set<int> _getCompletedCorrectCols(List<List<int>> board) {
    if (widget.game.solution.isEmpty) return <int>{};
    final completedCols = <int>{};
    for (int col = 0; col < 9; col++) {
      bool isCorrectLine = true;
      for (int row = 0; row < 9; row++) {
        final value = board[row][col];
        final answer = widget.game.solution[row][col];
        if (value == 0 || value != answer) {
          isCorrectLine = false;
          break;
        }
      }
      if (isCorrectLine) completedCols.add(col);
    }
    return completedCols;
  }

  void _checkAndTriggerLineCompletionEffect(List<List<int>> board) {
    final currentCompletedRows = _getCompletedCorrectRows(board);
    final currentCompletedCols = _getCompletedCorrectCols(board);

    final newlyCompletedRows = currentCompletedRows.difference(_completedRows);
    final newlyCompletedCols = currentCompletedCols.difference(_completedCols);

    _completedRows = currentCompletedRows;
    _completedCols = currentCompletedCols;

    if (newlyCompletedRows.isEmpty && newlyCompletedCols.isEmpty) return;
    _triggerLineCompletionEffect(newlyCompletedRows, newlyCompletedCols);
  }

  void _triggerLineCompletionEffect(Set<int> rows, Set<int> cols) {
    final targets = <String>{};
    for (final row in rows) {
      for (int col = 0; col < 9; col++) {
        targets.add('$row,$col');
      }
    }
    for (final col in cols) {
      for (int row = 0; row < 9; row++) {
        targets.add('$row,$col');
      }
    }
    if (targets.isEmpty) return;

    setState(() {
      for (final key in targets) {
        _lineCompleteActive[key] = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        for (final key in targets) {
          _lineCompleteActive[key] = false;
        }
      });
    });
  }

  @override
  void dispose() {
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
                      l10n.gameWrongShort,
                      '${_presenter.wrongCount}/3',
                      Icons.error_outline),
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
                                  onPressed: () {
                                    setState(() {
                                      _presenter.toggleMemoMode();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                SudokuGameActionButton(
                                  icon: Icons.lightbulb,
                                  label: l10n.gameHintShort,
                                  backgroundColor: AppTheme.yellowColor,
                                  onPressed: () {
                                    setState(() {
                                      _presenter.useHint();
                                    });
                                  },
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
                            //const SizedBox(height: 16),
                            // 정답 표시 네모칸
                            SudokuAnswerBox(
                              answer: getSelectedCellAnswer(),
                              answerLabel: l10n.gameAnswerPreview,
                            ),
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
              const SizedBox(height: 20),
              // 정보 카드들을 SingleChildScrollView로 감싸서 오버플로우 방지
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SudokuInfoCard(
                        l10n.gameTimeShort, _presenter.formattedTime, Icons.timer),
                    //const SizedBox(width: 12),
                    // _buildInfoCard(
                    //     '힌트', '${_presenter.hintsRemaining}', Icons.lightbulb),
                    const SizedBox(width: 12),
                    SudokuInfoCard(l10n.gameWrongShort,
                        '${_presenter.wrongCount}/3',
                        Icons.error_outline),
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
                        l10n.gameProgressShort,
                        '${(_presenter.progress * 100).toInt()}%',
                        Icons.emoji_events),
                  ],
                ),
              ),
              // 4x4 그리드 (숫자 + 메뉴)
              for (int i = 0; i < 3; i++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 숫자 버튼 3개
                    for (int j = 1; j <= 3; j++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 3,
                        ),
                        child: _buildNumberButton(i * 3 + j),
                      ),
                    // 메뉴 버튼 1개
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 3,
                      ),
                      child: _buildMenuButton(i + 1),
                    ),
                  ],
                ),
              // 정답 표시 네모칸
              SudokuAnswerBox(
                answer: getSelectedCellAnswer(),
                answerLabel: l10n.gameAnswerPreview,
              )
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
      waveActive: _waveActive,
      lineCompleteActive: _lineCompleteActive,
      onCellTapped: (row, col) {
        setState(() {
          _presenter.selectCell(row, col);
        });
      },
    );
  }

  Widget _buildNumberButton(int number) {
    // 파스텔톤 색상 순환
    final List<Color> pastelColors = [
      AppTheme.mintColor,
      AppTheme.lightBlueColor,
      AppTheme.yellowColor
    ];
    final buttonColor = pastelColors[(number - 1) % pastelColors.length];

    return ProgressiveBlurButton(
      onPressed: () async {
        if (!_presenter.isMemoMode) {
          await _vibrateOnNumberInput(number);
        }

        setState(() {
          _presenter.setSelectedCellValue(number);
        });
      },
      backgroundColor: buttonColor,
      child: Center(
        child: Text(
          number.toString(),
          style: AppTheme.numberButtonStyle,
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

  Widget _buildMenuButton(int menuNumber) {
    final l10n = AppLocalizations.of(context)!;
    final List<IconData> icons = [
      Icons.edit_note,
      Icons.lightbulb,
      _presenter.isPaused ? Icons.play_arrow : Icons.pause,
    ];
    final labels = [
      _presenter.isMemoMode ? l10n.gameMemoOnShort : l10n.gameMemoShort,
      l10n.gameHintShort,
      _presenter.isPaused ? l10n.gameResume : l10n.gamePause,
    ];

    // 메뉴 버튼용 파스텔톤 색상
    final List<Color> menuColors = [
      _presenter.isMemoMode ? AppTheme.mintColor : AppTheme.lightBlueColor,
      AppTheme.yellowColor,
      AppTheme.pinkColor
    ];
    final menuColor = menuColors[(menuNumber - 1) % menuColors.length];

    return ProgressiveBlurButton(
      onPressed: () {
        setState(() {
          switch (menuNumber) {
            case 1:
              _presenter.toggleMemoMode();
              break;
            case 2:
              _presenter.useHint();
              break;
            case 3:
              _presenter.togglePause();
              break;
          }
        });
      },
      width: 70,
      height: 70,
      borderRadius: 35,
      backgroundColor: menuColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icons[menuNumber - 1],
            color: AppTheme.textColor,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            labels[menuNumber - 1],
            style: GoogleFonts.notoSans(
              color: AppTheme.textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// 게임 완료 다이얼로그 표시
  void _showGameCompleteDialog() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final beforeAchievements = await _achievementService.load(l10n);
    // 클리어 기록 저장
    final isNewBestRecord = await _gameRecordService.saveClearRecordIfBest(
      levelName: widget.level.name,
      gameNumber: widget.game.gameNumber,
      clearTime: _presenter.seconds,
      wrongCount: _presenter.wrongCount,
    );
    if (!mounted) return;
    final afterAchievements = await _achievementService.load(l10n);
    if (!mounted) return;
    final newlyUnlockedBadges = _achievementService.getNewlyUnlockedBadges(
      before: beforeAchievements,
      after: afterAchievements,
    );
    final isTodayChallenge = await _challengeProgressService.isTodayChallenge(
      levelName: widget.level.name,
      gameNumber: widget.game.gameNumber,
    );
    if (!mounted) return;

    final gamesInLevel = await SudokuGameSet.create(widget.level.name);
    gamesInLevel.sort((a, b) => a.gameNumber.compareTo(b.gameNumber));
    final currentIndex = gamesInLevel.indexWhere(
      (g) => g.gameNumber == widget.game.gameNumber,
    );
    final SudokuGame? nextGame = currentIndex >= 0 &&
            currentIndex < gamesInLevel.length - 1
        ? gamesInLevel[currentIndex + 1]
        : null;

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
          isNewBestRecord: isNewBestRecord,
          challengeMessage:
              isTodayChallenge ? l10n.challengeCompletedToday : null,
          unlockedBadges: newlyUnlockedBadges,
          onCopyResult: () => _copyClearResult(isNewBestRecord),
          onShareResult: () => _shareClearResult(isNewBestRecord),
          onNextPuzzle: nextGame == null
              ? null
              : () => _openNextPuzzle(dialogContext, nextGame),
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
    final resultText = _resultShareService.buildClearResultText(
      l10n: l10n,
      localizedLevelName: widget.level.localizedName(l10n),
      gameNumber: widget.game.gameNumber,
      clearTimeSeconds: _presenter.seconds,
      wrongCount: _presenter.wrongCount,
      isNewBestRecord: isNewBestRecord,
    );

    await Clipboard.setData(ClipboardData(text: resultText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.shareCopySuccess)),
    );
  }

  Future<void> _shareClearResult(bool isNewBestRecord) async {
    final l10n = AppLocalizations.of(context)!;
    final resultText = _resultShareService.buildClearResultText(
      l10n: l10n,
      localizedLevelName: widget.level.localizedName(l10n),
      gameNumber: widget.game.gameNumber,
      clearTimeSeconds: _presenter.seconds,
      wrongCount: _presenter.wrongCount,
      isNewBestRecord: isNewBestRecord,
    );

    await Share.share(resultText, subject: l10n.shareSubject);
  }

  /// 게임 오버 다이얼로그 표시
  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameOverDialog(
          wrongCount: _presenter.wrongCount,
          onRestart: () async {
            Navigator.of(context).pop();
            await _resetAndRestartCurrentGame();
          },
          onGoToLevelSelection: () async {
            Navigator.of(context).pop();
            await _exitToLevelSelection();
          },
        );
      },
    );
  }

  /// 정답 입력 효과 표시
  /// 정답 입력 효과 표시
  /// 정답 입력 효과 표시
  /// 정답 입력 효과 표시
  void _triggerWaveEffect(int row, int col) {
    const int waveSpeed = 30; // wave가 퍼지는 속도
    const int returnDelay = 100; // 돌아오기 전 대기 시간

    setState(() {
      _waveActive.clear();
    });

    // 최대 거리 계산 (가로 또는 세로 중 더 긴 거리)
    int maxDistance = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (r == row || c == col) {
          final int distance = (r == row) ? (c - col).abs() : (r - row).abs();
          if (distance > maxDistance) maxDistance = distance;
        }
      }
    }

    // 전체 wave가 퍼지는 시간
    final totalWaveTime = waveSpeed * maxDistance;

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (r == row || c == col) {
          final int distance = (r == row) ? (c - col).abs() : (r - row).abs();
          final delay = Duration(milliseconds: waveSpeed * distance);

          // wave ON (퍼지는 효과)
          Future.delayed(delay, () {
            if (mounted) {
              setState(() {
                _waveActive['$r,$c'] = true;
              });
            }
          });

          // wave OFF (돌아오는 효과) - 전체가 퍼진 후 돌아오기
          final returnDelayTime = totalWaveTime +
              returnDelay +
              (waveSpeed * (maxDistance - distance));
          Future.delayed(Duration(milliseconds: returnDelayTime), () {
            if (mounted) {
              setState(() {
                _waveActive['$r,$c'] = false;
              });
            }
          });
        }
      }
    }
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
