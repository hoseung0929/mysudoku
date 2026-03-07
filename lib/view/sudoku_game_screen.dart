import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/sudoku_game.dart';
import '../model/sudoku_level.dart';
import '../presenter/sudoku_game_presenter.dart';
import '../widgets/progressive_blur_button.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/game_complete_dialog.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';

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
  bool _presenterReady = false;

  // 파도 효과 상태
  final Map<String, bool> _waveActive = {};

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  /// 게임 초기화
  Future<void> _initializeGame() async {
    if (kDebugMode) {
      print('=== 게임 초기화 시작 ===');
      print('레벨: ${widget.level.name}');
      print('플레이 게임 game_number: ${widget.game.gameNumber}');
      print('해답 game_number: ${widget.game.gameNumber}');
      print('원본 보드:');
      for (int i = 0; i < widget.game.board.length; i++) {
        print('  ${widget.game.board[i]}');
      }
      print('DB 해답 보드:');
      for (int i = 0; i < widget.game.solution.length; i++) {
        print('  ${widget.game.solution[i]}');
      }
    }

    // 저장된 게임 상태 복원
    List<List<int>>? restoredBoard = await _loadGameState();
    if (restoredBoard != null && kDebugMode) {
      debugPrint('저장된 게임 상태 발견:');
      for (int i = 0; i < restoredBoard.length; i++) {
        debugPrint('  ${restoredBoard[i]}');
      }
    }
    if (restoredBoard != null) {
      // 저장된 게임 상태가 현재 게임과 다른지 확인
      bool isDifferentGame = false;
      if (restoredBoard.length == widget.game.board.length) {
        for (int row = 0; row < restoredBoard.length; row++) {
          for (int col = 0; col < restoredBoard[row].length; col++) {
            if (widget.game.board[row][col] != 0 &&
                restoredBoard[row][col] != widget.game.board[row][col]) {
              isDifferentGame = true;
              if (kDebugMode) {
                print(
                    '다른 게임 감지: [$row][$col] - 원본=${widget.game.board[row][col]}, 저장=${restoredBoard[row][col]}');
              }
              break;
            }
          }
          if (isDifferentGame) break;
        }
      } else {
        isDifferentGame = true;
      }

      if (isDifferentGame) {
        if (kDebugMode) {
          print('저장된 게임 상태를 무시하고 현재 게임 원본 보드로 시작합니다.');
        }
        await _clearGameState();
        restoredBoard = null;
      }
    }

    _presenter = SudokuGamePresenter(
      initialBoard: restoredBoard ?? widget.game.board,
      solution: widget.game.solution, // DB에서 가져온 해답 데이터 사용 (항상 동일)
      level: widget.level,
      onBoardChanged: (board) {
        setState(() {});
        _saveGameState(board); // 보드 변경 시 저장
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
    if (kDebugMode) {
      print('=== 게임 초기화 완료 ===');
    }
  }

  /// 게임 상태 저장
  Future<void> _saveGameState(List<List<int>> board) async {
    final prefs = await SharedPreferences.getInstance();
    final gameKey = 'game_${widget.level.name}_${widget.game.gameNumber}';

    final boardString = board.map((row) => row.join(',')).join(';');
    await prefs.setString(gameKey, boardString);

    if (kDebugMode) {
      print('게임 상태 저장 완료: $gameKey');
    }
  }

  /// 게임 상태 복원
  Future<List<List<int>>?> _loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final gameKey = 'game_${widget.level.name}_${widget.game.gameNumber}';

    if (kDebugMode) {
      print('게임 상태 로딩 시도: $gameKey');
    }

    final boardString = prefs.getString(gameKey);
    if (boardString != null) {
      if (kDebugMode) {
        print('저장된 게임 상태 문자열: $boardString');
      }
      final rows = boardString.split(';');
      final board = rows.map((row) {
        return row.split(',').map((cell) => int.parse(cell)).toList();
      }).toList();
      if (kDebugMode) {
        print('게임 상태 복원 완료');
      }
      return board;
    } else {
      if (kDebugMode) {
        print('저장된 게임 상태 없음');
      }
      return null;
    }
  }

  /// 게임 상태 삭제 (게임 완료 또는 재시작 시)
  Future<void> _clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final gameKey = 'game_${widget.level.name}_${widget.game.gameNumber}';

    await prefs.remove(gameKey);

    if (kDebugMode) {
      print('게임 상태 삭제 완료: $gameKey');
    }
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
                            ? Colors.green.withValues(alpha: 0.4)
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
      onPressed: () async {
        // 진동 효과 추가
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 50); // 50ms 짧은 진동
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

  Widget _buildMenuButton(int menuNumber) {
    final List<IconData> icons = [
      Icons.menu,
      Icons.settings,
      Icons.help_outline,
    ];

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
  void _showGameCompleteDialog() async {
    // 클리어 기록 저장
    await _saveClearRecord();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameCompleteDialog(
          timeInSeconds: _presenter.seconds,
          wrongCount: _presenter.wrongCount,
          onRestart: () async {
            Navigator.of(context).pop();
            await _clearGameState(); // 저장된 상태 삭제
            if (!mounted) return;
            _presenter.restartGame();
          },
          onGoToLevelSelection: () async {
            final levelNavigator = Navigator.of(this.context);
            Navigator.of(context).pop();
            await _clearGameState(); // 저장된 상태 삭제
            if (!mounted) return;
            levelNavigator.pop(); // 게임 화면으로 돌아가기
          },
        );
      },
    );
  }

  /// 클리어 기록 저장
  Future<void> _saveClearRecord() async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.saveClearRecord(
        levelName: widget.level.name,
        gameNumber: widget.game.gameNumber,
        clearTime: _presenter.seconds,
        wrongCount: _presenter.wrongCount,
      );
      if (kDebugMode) {
        print('클리어 기록 저장 완료: ${widget.level.name} 게임 ${widget.game.gameNumber}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('클리어 기록 저장 실패: $e');
      }
    }
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
            await _clearGameState(); // 저장된 상태 삭제
            if (!mounted) return;
            _presenter.restartGame();
          },
          onGoToLevelSelection: () async {
            final levelNavigator = Navigator.of(this.context);
            Navigator.of(context).pop();
            await _clearGameState(); // 저장된 상태 삭제
            if (!mounted) return;
            levelNavigator.pop(); // 게임 화면으로 돌아가기
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
        print('정답 표시 중 오류 발생: $e');
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
      print('=== 정답 조회 로그 ===');
      print('플레이 게임 game_number: ${widget.game.gameNumber}');
      print('해답 game_number: ${widget.game.gameNumber}');
      print('선택된 셀: [$row][$col]');
    }

    try {
      final answer = _presenter.getCorrectValue(row, col);
      if (kDebugMode) {
        print('현재 게임 해답 데이터 사용: [$row][$col] = $answer');
        print('========================');
      }
      return answer;
    } catch (e) {
      if (kDebugMode) {
        print('정답 계산 중 오류: $e');
        print('========================');
      }
    }

    if (kDebugMode) {
      print('정답을 찾을 수 없음');
      print('========================');
    }
    return null;
  }
}
