import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/sudoku_game.dart';
import '../model/sudoku_level.dart';
import '../presenter/sudoku_game_presenter.dart';
import '../widgets/progressive_blur_button.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/game_complete_dialog.dart';
import '../theme/app_theme.dart';

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
  late final SudokuGamePresenter _presenter;

  // 정답 입력 효과 상태
  int? _correctAnswerRow;
  int? _correctAnswerCol;
  bool _showCorrectAnswerEffect = false;

  // 파도 효과 상태
  Map<String, bool> _waveActive = {};

  @override
  void initState() {
    super.initState();
    _presenter = SudokuGamePresenter(
      initialBoard: widget.game.board,
      solution: widget.game.solution,
      level: widget.level,
      onBoardChanged: (board) {
        setState(() {});
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
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.level.name,
          style: GoogleFonts.notoSans(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppTheme.cardColor,
        elevation: 2,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: AppTheme.textColor,
            ),
            onPressed: () {
              _presenter.restartWithNewGame();
            },
            tooltip: '재시작',
          ),
        ],
      ),
      body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
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
                              color: Colors.black.withOpacity(0.1),
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
              Expanded(child: Container()), // 나머지 공간 비움
            ],
          ),
        ),
      ],
    );
  }

  /// 정보 카드 위젯
  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
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

  /// 통계 카드 위젯
  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.lightTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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

                // 파도 효과
                final isWave = _waveActive['$row,$col'] == true;

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
                            ? Colors.green.withOpacity(0.4)
                            : isWrong
                                ? AppTheme.sudokuWrongNumberColor
                                    .withOpacity(0.3)
                                : isHint
                                    ? AppTheme.sudokuHintNumberColor
                                    : isSelected
                                        ? AppTheme.sudokuSelectedNumberColor
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
                            : const SizedBox(),
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

  Widget _buildNumberButton(int number) {
    // 파스텔톤 색상 순환
    final List<Color> pastelColors = [
      AppTheme.mintColor,
      AppTheme.lightBlueColor,
      AppTheme.yellowColor
    ];
    final buttonColor = pastelColors[(number - 1) % pastelColors.length];

    return ProgressiveBlurButton(
      onPressed: () {
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

  Widget _buildMenuButton(int menuNumber) {
    final List<IconData> icons = [
      Icons.menu,
      Icons.settings,
      Icons.help_outline,
    ];
    final List<String> labels = ['메뉴1', '메뉴2', '메뉴3'];

    // 메뉴 버튼용 파스텔톤 색상
    final List<Color> menuColors = [
      AppTheme.lightBlueColor,
      AppTheme.yellowColor,
      AppTheme.mintColor
    ];
    final menuColor = menuColors[(menuNumber - 1) % menuColors.length];

    return ProgressiveBlurButton(
      onPressed: () {
        setState(() {
          // 메뉴 기능 구현 필요
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
          // Text(
          //   labels[menuNumber - 1],
          //   style: const TextStyle(
          //         color: Colors.white,
          //         fontSize: 12,
          //         fontWeight: FontWeight.w500,
          //       ),
          // ),
        ],
      ),
    );
  }

  /// 게임 완료 다이얼로그 표시
  void _showGameCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameCompleteDialog(
          timeInSeconds: _presenter.seconds,
          wrongCount: _presenter.wrongCount,
          onRestart: () {
            Navigator.of(context).pop();
            _presenter.restartWithNewGame();
          },
          onGoToLevelSelection: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // 게임 화면으로 돌아가기
          },
        );
      },
    );
  }

  /// 게임 오버 다이얼로그 표시
  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameOverDialog(
          wrongCount: _presenter.wrongCount,
          onRestart: () {
            Navigator.of(context).pop();
            _presenter.restartWithNewGame();
          },
          onGoToLevelSelection: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // 게임 화면으로 돌아가기
          },
        );
      },
    );
  }

  /// 정답 입력 효과 표시
  void _triggerWaveEffect(int row, int col) {
    const int waveSpeed = 30; // wave가 퍼지는 속도
    const int waveOnDuration = 200; // wave가 켜져있는 시간
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
}
