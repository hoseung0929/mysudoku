import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../services/game_record_service.dart';
import '../services/game_state_service.dart';
import '../services/onboarding_service.dart';
import '../services/result_share_service.dart';
import '../services/challenge_progress_service.dart';
import '../services/achievement_service.dart';
import '../model/sudoku_game.dart';
import '../model/sudoku_level.dart';
import '../presenter/sudoku_game_presenter.dart';
import '../widgets/progressive_blur_button.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/game_complete_dialog.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import 'package:mysudoku/utils/app_logger.dart';

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
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '게임 가이드',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 14),
                const _GameGuideItem(
                  title: '칸을 먼저 선택하세요',
                  description: '비어 있는 칸을 누른 뒤 아래 숫자 버튼으로 입력합니다.',
                ),
                const SizedBox(height: 10),
                const _GameGuideItem(
                  title: '오답은 3번까지',
                  description: '틀린 숫자를 3번 입력하면 해당 판은 종료됩니다.',
                ),
                const SizedBox(height: 10),
                const _GameGuideItem(
                  title: '색상 힌트를 활용하세요',
                  description: '선택 칸, 같은 숫자, 관련 칸이 함께 강조되어 흐름을 읽기 쉽습니다.',
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('바로 플레이'),
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

    if (!_presenterReady) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
    );
  }

  /// 앱바 위젯
  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: widget.level.name,
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
                    widget.level.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  Text(
                    '게임 ${widget.game.gameNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.lightTextColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildInfoCard('', _presenter.formattedTime, Icons.timer),
                  const SizedBox(width: 12),
                  _buildInfoCard(
                      '힌트', '${_presenter.hintsRemaining}', Icons.lightbulb),
                  const SizedBox(width: 12),
                  _buildInfoCard(
                    '메모',
                    _presenter.isMemoMode ? 'ON' : 'OFF',
                    Icons.edit_note,
                    accentColor: _presenter.isMemoMode
                        ? AppTheme.mintColor
                        : null,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoCard(
                      '오답', '${_presenter.wrongCount}/3', Icons.error_outline),
                  const SizedBox(width: 12),
                  _buildInfoCard(
                      '진행율',
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
                  child: _buildGrid(),
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
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '숫자 입력',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textColor,
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
                                _buildActionButton(
                                  icon: Icons.edit_note,
                                  label: _presenter.isMemoMode ? '메모 ON' : '메모',
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
                                _buildActionButton(
                                  icon: Icons.lightbulb,
                                  label: '힌트',
                                  backgroundColor: AppTheme.yellowColor,
                                  onPressed: () {
                                    setState(() {
                                      _presenter.useHint();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  icon: _presenter.isPaused
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                  label: _presenter.isPaused ? '계속' : '일시정지',
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
                            _buildAnswerBox(),
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
    return Stack(
      children: [
        // 그리드 영역
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: _buildGrid(),
              ),
              const SizedBox(height: 20),
              // 정보 카드들을 SingleChildScrollView로 감싸서 오버플로우 방지
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildInfoCard('시간', _presenter.formattedTime, Icons.timer),
                    //const SizedBox(width: 12),
                    // _buildInfoCard(
                    //     '힌트', '${_presenter.hintsRemaining}', Icons.lightbulb),
                    const SizedBox(width: 12),
                    _buildInfoCard('오답', '${_presenter.wrongCount}/3',
                        Icons.error_outline),
                    const SizedBox(width: 12),
                    _buildInfoCard(
                      '메모',
                      _presenter.isMemoMode ? 'ON' : 'OFF',
                      Icons.edit_note,
                      accentColor: _presenter.isMemoMode
                          ? AppTheme.mintColor
                          : null,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoCard(
                        '진행율',
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
              _buildAnswerBox()
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

  /// 정보 카드 위젯
  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon, {
    Color? accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor ?? AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.lightTextColor),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return ProgressiveBlurButton(
      onPressed: onPressed,
      width: 92,
      height: 64,
      borderRadius: 20,
      backgroundColor: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.textColor, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(9, (row) {
          return Expanded(
            child: Row(
              children: List.generate(9, (col) {
                final value = _presenter.getCellValue(row, col);
                final isFixed = _presenter.isCellFixed(row, col);
                final isSelected = _presenter.isCellSelected(row, col);
                final isSameNumber = _presenter.isSameNumber(row, col);
                final isRelated = _presenter.isRelated(row, col);
                final isWrong = _presenter.isWrongNumber(row, col);
                final isHint = _presenter.isHintNumber(row, col);
                final notes = _presenter.getCellNotes(row, col);

                // 파도 효과
                final isWave = _waveActive['$row,$col'] == true;
                final isLineComplete = _lineCompleteActive['$row,$col'] == true;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _presenter.selectCell(row, col);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade300,
                            width:
                                (row == 0 || row == 3 || row == 6) ? 1.5 : 0.5,
                          ),
                          left: BorderSide(
                            color: Colors.grey.shade300,
                            width:
                                (col == 0 || col == 3 || col == 6) ? 1.5 : 0.5,
                          ),
                          right: BorderSide(
                            color: Colors.grey.shade300,
                            width:
                                (col == 2 || col == 5 || col == 8) ? 1.5 : 0.5,
                          ),
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width:
                                (row == 2 || row == 5 || row == 8) ? 1.5 : 0.5,
                          ),
                        ),
                        color: isWave
                            ? Colors.green.withValues(alpha: 0.4)
                            : isLineComplete
                                ? Colors.amber.withValues(alpha: 0.35)
                            : isSelected
                                ? AppTheme.sudokuSelectedNumberColor
                                : isWrong
                                    ? AppTheme.sudokuWrongNumberColor
                                        .withValues(alpha: 0.3)
                                    : isHint
                                        ? AppTheme.sudokuHintNumberColor
                                        : isSameNumber
                                            ? AppTheme.sudokuSameNumberColor
                                            : isRelated
                                                ? Colors.grey.shade100
                                                : null,
                      ),
                      child: Center(
                        child: value != 0
                            ? Text(
                                value.toString(),
                                style: isWrong
                                    ? AppTheme.sudokuWrongNumberStyle
                                    : isHint
                                        ? GoogleFonts.notoSans(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade700,
                                          )
                                        : isFixed
                                            ? AppTheme.sudokuFixedNumberStyle
                                            : AppTheme.sudokuNumberStyle,
                              )
                            : _buildMemoGrid(notes),
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
  }

  Widget _buildMemoGrid(Set<int> notes) {
    if (notes.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: List.generate(9, (index) {
          final noteValue = index + 1;
          final isVisible = notes.contains(noteValue);
          return Center(
            child: Text(
              isVisible ? '$noteValue' : '',
              style: GoogleFonts.notoSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTextColor.withValues(alpha: 0.75),
              ),
            ),
          );
        }),
      ),
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
    final List<IconData> icons = [
      Icons.edit_note,
      Icons.lightbulb,
      _presenter.isPaused ? Icons.play_arrow : Icons.pause,
    ];
    final labels = [
      _presenter.isMemoMode ? '메모 ON' : '메모',
      '힌트',
      _presenter.isPaused ? '계속' : '일시정지',
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
    final beforeAchievements = await _achievementService.load();
    // 클리어 기록 저장
    final isNewBestRecord = await _gameRecordService.saveClearRecordIfBest(
      levelName: widget.level.name,
      gameNumber: widget.game.gameNumber,
      clearTime: _presenter.seconds,
      wrongCount: _presenter.wrongCount,
    );
    if (!mounted) return;
    final afterAchievements = await _achievementService.load();
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameCompleteDialog(
          shareSummary: _resultShareService.formatClearSummary(
            clearTimeSeconds: _presenter.seconds,
            wrongCount: _presenter.wrongCount,
          ),
          timeInSeconds: _presenter.seconds,
          wrongCount: _presenter.wrongCount,
          isNewBestRecord: isNewBestRecord,
          challengeMessage:
              isTodayChallenge ? '오늘의 도전을 완료했어요.' : null,
          unlockedBadges: newlyUnlockedBadges,
          onCopyResult: () => _copyClearResult(isNewBestRecord),
          onShareResult: () => _shareClearResult(isNewBestRecord),
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

  Future<void> _copyClearResult(bool isNewBestRecord) async {
    final resultText = _resultShareService.buildClearResultText(
      levelName: widget.level.name,
      gameNumber: widget.game.gameNumber,
      clearTimeSeconds: _presenter.seconds,
      wrongCount: _presenter.wrongCount,
      isNewBestRecord: isNewBestRecord,
    );

    await Clipboard.setData(ClipboardData(text: resultText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('결과 문구를 복사했어요.')),
    );
  }

  Future<void> _shareClearResult(bool isNewBestRecord) async {
    final resultText = _resultShareService.buildClearResultText(
      levelName: widget.level.name,
      gameNumber: widget.game.gameNumber,
      clearTimeSeconds: _presenter.seconds,
      wrongCount: _presenter.wrongCount,
      isNewBestRecord: isNewBestRecord,
    );

    await Share.share(resultText, subject: 'My Sudoku 결과');
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

  /// 정답 표시 네모칸
  Widget _buildAnswerBox() {
    try {
      if (_presenter.selectedRow != null && _presenter.selectedCol != null) {
        final answer = getSelectedCellAnswer();

        if (answer != null) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              border: Border.all(color: Colors.grey.shade400, width: 2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '정답',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  answer.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('정답 표시 중 오류 발생: $e');
      }
    }

    // 셀이 선택되지 않았거나 예외가 발생한 경우 빈 네모칸 표시
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          '?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
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

class _GameGuideItem extends StatelessWidget {
  const _GameGuideItem({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF8DC6B0),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF6B7780),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
