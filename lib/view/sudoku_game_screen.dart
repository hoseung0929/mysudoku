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
              height: 320,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(100),
                      spreadRadius: 1,
                      blurRadius: 10,
                      //offset: const Offset(0, -2)
                    )
                  ]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // 상단 드래그 핸들 추가
                  // Container(
                  //   width: 40,
                  //   height: 4,
                  //   margin: const EdgeInsets.symmetric(vertical: 8),
                  //   decoration: BoxDecoration(
                  //       color: Colors.grey[400],
                  //       borderRadius: BorderRadius.circular(2)),
                  // ),
                  SizedBox(height: 40),
                  Row(
                    children: List.generate(4, (index) {
                      final List<IconData> icons = [
                        Icons.menu,
                        Icons.settings,
                        Icons.help_outline,
                        Icons.more_vert
                      ];
                      final List<String> labels = ['메뉴1', '메뉴2', '메뉴3', '메뉴4'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              // 메뉴 기능 구현 필요
                            });
                          },
                          child: Container(
                            height: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 238, 189, 189),
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icons[index],
                                  color: Colors.white,
                                  size: 24,
                                ),
                                Text(
                                  labels[index],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(9, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _presenter.setSelectedCellValue(index + 1);
                              });
                            },
                            child: Container(
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 2,
                                        offset: const Offset(0, 2))
                                  ]),
                              child: Text(
                                (index + 1).toString(),
                                style: const TextStyle(
                                  height: 1.5,
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
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
                                fontSize: 16,
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
}
