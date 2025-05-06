import 'package:flutter/material.dart';
import 'dart:async';
import '../model/sudoku_level.dart';
import '../presenter/sudoku_game_presenter.dart';

/// 스도쿠 게임의 메인 화면
/// MVP 패턴에서 View 역할을 수행하며, 사용자 인터페이스를 담당
class SudokuGameScreen extends StatefulWidget {
  final SudokuLevel level; // 현재 선택된 레벨

  const SudokuGameScreen({super.key, required this.level});

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen> {
  late SudokuGamePresenter _presenter; // 게임 로직을 처리하는 Presenter
  late Timer _timer; // 게임 시간을 관리하는 타이머

  // View의 상태 변수들
  List<List<int>> _board = []; // 9x9 스도쿠 보드
  List<List<bool>> _fixedNumbers = []; // 초기에 주어진 고정 숫자 표시
  List<List<bool>> _wrongNumbers = []; // 잘못된 숫자 표시
  int _seconds = 0; // 게임 진행 시간
  bool _isPaused = false; // 일시정지 상태
  int _hintsRemaining = 3; // 남은 힌트 수
  bool _isGameComplete = false; // 게임 완료 상태
  int? _selectedRow; // 현재 선택된 행
  int? _selectedCol; // 현재 선택된 열

  @override
  void initState() {
    super.initState();
    _initializePresenter();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// Presenter 초기화
  /// Presenter를 생성하고 콜백 함수들을 설정
  void _initializePresenter() {
    _presenter = SudokuGamePresenter(
      level: widget.level,
      onBoardChanged: (board) => setState(() => _board = board),
      onFixedNumbersChanged:
          (fixedNumbers) => setState(() => _fixedNumbers = fixedNumbers),
      onWrongNumbersChanged:
          (wrongNumbers) => setState(() => _wrongNumbers = wrongNumbers),
      onTimeChanged: (seconds) => setState(() => _seconds = seconds),
      onHintsChanged: (hints) => setState(() => _hintsRemaining = hints),
      onPauseStateChanged: (isPaused) => setState(() => _isPaused = isPaused),
      onGameCompleteChanged: (isComplete) {
        setState(() => _isGameComplete = isComplete);
        if (isComplete) {
          _showGameCompleteDialog();
        }
      },
    );
  }

  /// 타이머 시작
  /// 1초마다 게임 시간을 업데이트
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        _presenter.updateTime(_seconds + 1);
      }
    });
  }

  /// 시간 포맷팅
  /// [seconds] 초 단위 시간을 MM:SS 형식의 문자열로 변환
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 셀 선택 처리
  /// [row] 선택된 행
  /// [col] 선택된 열
  void _onCellTap(int row, int col) {
    _presenter.onCellSelected(row, col);
    setState(() {
      _selectedRow = _presenter.selectedRow;
      _selectedCol = _presenter.selectedCol;
    });
  }

  /// 숫자 선택 처리
  /// [number] 선택된 숫자 (1-9)
  void _onNumberSelected(int number) {
    _presenter.onNumberSelected(number);
  }

  /// 게임 완료 다이얼로그 표시
  /// 게임 완료 시 축하 메시지와 소요 시간을 표시
  void _showGameCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('축하합니다!'),
            content: Text('게임을 완료했습니다!\n소요 시간: ${_formatTime(_seconds)}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('레벨 선택으로 돌아가기'),
              ),
            ],
          ),
    );
  }

  /// 메뉴 표시
  /// 게임 메뉴를 모달 바텀 시트로 표시
  void _showMenu() {
    if (_isPaused) {
      _presenter.togglePause();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.black87),
                  title: const Text('게임 재시작'),
                  onTap: () {
                    Navigator.pop(context);
                    _restartGame();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.save, color: Colors.black87),
                  title: const Text('게임 저장'),
                  onTap: () {
                    Navigator.pop(context);
                    _saveGame();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.black87),
                  title: const Text('설정'),
                  onTap: () {
                    Navigator.pop(context);
                    _showSettings();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help, color: Colors.black87),
                  title: const Text('도움말'),
                  onTap: () {
                    Navigator.pop(context);
                    _showHelp();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.black87),
                  title: const Text('레벨 선택으로 돌아가기'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmExit();
                  },
                ),
              ],
            ),
          ),
    );
  }

  /// 게임 재시작
  /// 재시작 확인 다이얼로그를 표시하고 확인 시 게임을 재시작
  void _restartGame() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('게임 재시작'),
            content: const Text('현재 게임을 재시작하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _presenter.restartGame();
                },
                child: const Text('재시작'),
              ),
            ],
          ),
    );
  }

  /// 게임 저장
  /// TODO: 게임 저장 기능 구현
  void _saveGame() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('게임 저장 기능은 아직 구현되지 않았습니다.')));
  }

  /// 설정 화면 표시
  /// 게임 설정을 변경할 수 있는 다이얼로그를 표시
  void _showSettings() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('설정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('소리 효과'),
                  value: true, // TODO: 실제 설정값 연동
                  onChanged: (value) {
                    // TODO: 소리 설정 변경
                  },
                ),
                SwitchListTile(
                  title: const Text('진동 효과'),
                  value: true, // TODO: 실제 설정값 연동
                  onChanged: (value) {
                    // TODO: 진동 설정 변경
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  /// 도움말 표시
  /// 게임 규칙과 기능에 대한 설명을 표시
  void _showHelp() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('도움말'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('스도쿠 게임 규칙:'),
                  SizedBox(height: 8),
                  Text('1. 각 행에는 1-9까지의 숫자가 한 번씩만 나타나야 합니다.'),
                  Text('2. 각 열에는 1-9까지의 숫자가 한 번씩만 나타나야 합니다.'),
                  Text('3. 3x3 박스 안에는 1-9까지의 숫자가 한 번씩만 나타나야 합니다.'),
                  SizedBox(height: 16),
                  Text('게임 기능:'),
                  SizedBox(height: 8),
                  Text('• 숫자 입력: 빈 칸을 선택하고 하단의 숫자 패드에서 숫자를 선택합니다.'),
                  Text('• 힌트: 게임당 3번의 힌트를 사용할 수 있습니다.'),
                  Text('• 일시정지: 상단의 일시정지 버튼으로 게임을 일시 중단할 수 있습니다.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  /// 게임 종료 확인
  /// 게임 종료 확인 다이얼로그를 표시하고 확인 시 레벨 선택 화면으로 이동
  void _confirmExit() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('게임 종료'),
            content: const Text('현재 게임을 종료하고 레벨 선택 화면으로 돌아가시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('종료'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // 상단 정보 표시
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black87),
                        onPressed: _showMenu,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.level.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatTime(_seconds),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.black87,
                          ),
                          onPressed: () => _presenter.togglePause(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 스도쿠 보드
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 9,
                            ),
                        itemCount: 81,
                        itemBuilder: (context, index) {
                          final row = index ~/ 9;
                          final col = index % 9;
                          final isSelected =
                              row == _selectedRow && col == _selectedCol;
                          final isFixed = _fixedNumbers[row][col];
                          final number = _board[row][col];
                          final isWrong = _wrongNumbers[row][col];

                          // 3x3 박스 구분선
                          final isBoxBorder =
                              (row % 3 == 0 && row != 0) ||
                              (col % 3 == 0 && col != 0);

                          return GestureDetector(
                            onTap: () => _onCellTap(row, col),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color:
                                        isBoxBorder
                                            ? Colors.black87
                                            : Colors.grey[300]!,
                                    width: isBoxBorder ? 2 : 1,
                                  ),
                                  bottom: BorderSide(
                                    color:
                                        isBoxBorder
                                            ? Colors.black87
                                            : Colors.grey[300]!,
                                    width: isBoxBorder ? 2 : 1,
                                  ),
                                ),
                                color:
                                    isSelected
                                        ? Colors.blue.withOpacity(0.1)
                                        : isWrong
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.white,
                              ),
                              child: Center(
                                child: Text(
                                  number == 0 ? '' : number.toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        isFixed
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                    color:
                                        isFixed
                                            ? Colors.black87
                                            : isWrong
                                            ? Colors.red
                                            : Colors.blue[700],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 하단 컨트롤
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '힌트: $_hintsRemaining',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        _hintsRemaining > 0 ? () => _presenter.useHint() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('힌트 사용'),
                  ),
                ],
              ),
            ),
            // 숫자 입력 패드
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    onPressed:
                        _isPaused ? null : () => _onNumberSelected(index + 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
