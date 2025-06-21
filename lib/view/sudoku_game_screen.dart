import 'package:flutter/material.dart';
import '../model/sudoku_game.dart';
import '../model/sudoku_level.dart';
import '../presenter/sudoku_game_presenter.dart';

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
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게임 ${widget.game.gameNumber}'),
      ),
      body: Stack(
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
                Expanded(child: Container()), // 나머지 공간 비움
              ],
            ),
          ),
          // 하단 숫자버튼 영역 (전체 하단에 고정)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  SizedBox(height: 70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Column(
      children: List.generate(9, (row) {
        return Expanded(
          child: Row(
            children: List.generate(9, (col) {
              final value = _presenter.getCellValue(row, col);
              final isFixed = _presenter.isCellFixed(row, col);
              final isSelected = _presenter.isCellSelected(row, col);
              final isSameNumber = _presenter.isSameNumber(row, col);
              final isRelated = _presenter.isRelated(row, col);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _presenter.selectCell(row, col);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.black,
                          width: (col == 2 || col == 5) ? 1.5 : 0.5,
                        ),
                        bottom: BorderSide(
                          color: Colors.black,
                          width: (row == 2 || row == 5) ? 1.5 : 0.5,
                        ),
                      ),
                      color: isSelected
                          ? Colors.blue.withAlpha(180)
                          : isSameNumber
                              ? Colors.blue.withAlpha(26)
                              : isRelated
                                  ? Colors.grey.withAlpha(26)
                                  : null,
                    ),
                    child: Center(
                      child: value != 0
                          ? Text(
                              value.toString(),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: isFixed
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isFixed ? Colors.black : Colors.blue,
                              ),
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
    );
  }

  Widget _buildNumberButton(int number) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _presenter.setSelectedCellValue(number);
        });
      },
      child: Container(
        width: 95,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
              Colors.white.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 28,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
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

    return GestureDetector(
      onTap: () {
        setState(() {
          // 메뉴 기능 구현 필요
        });
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.7),
              Colors.white.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icons[menuNumber - 1],
              color: Colors.grey[800],
              size: 32,
            ),
            const SizedBox(height: 4),
            // Text(
            //   labels[menuNumber - 1],
            //   style: const TextStyle(
            //     color: Colors.white,
            //     fontSize: 12,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
