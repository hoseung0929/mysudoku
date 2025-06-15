import 'package:flutter/material.dart';
import 'sudoku_game_screen.dart';
import '../model/sudoku_game.dart';
import '../model/sudoku_level.dart';
import 'package:flutter/services.dart';

class LevelSelectionMain extends StatefulWidget {
  const LevelSelectionMain({super.key});

  @override
  State<LevelSelectionMain> createState() => _LevelSelectionMainState();
}

class _LevelSelectionMainState extends State<LevelSelectionMain> {
  int? _selectedIndex;
  final ScrollController _scrollController = ScrollController();
  bool _isTop = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset <= 0 && !_isTop) {
        setState(() {
          _isTop = true;
        });
      } else if (_scrollController.offset > 0 && _isTop) {
        setState(() {
          _isTop = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 더미 SudokuGame, SudokuLevel (실제 데이터로 교체 필요)
  SudokuGame getDummyGame(String levelName) {
    return SudokuGame(
      board: List.generate(9, (_) => List.generate(9, (_) => 0)),
      solution: List.generate(9, (_) => List.generate(9, (_) => 1)),
      emptyCells: 30,
      levelName: levelName,
      gameNumber: 1,
    );
  }

  SudokuLevel getLevel(String title) {
    return SudokuLevel.levels.firstWhere(
      (level) => level.name == _levelNameKor(title),
      orElse: () => SudokuLevel.levels.first,
    );
  }

  String _levelNameKor(String title) {
    switch (title) {
      case 'Beginner':
        return '초급';
      case 'Intermediate':
        return '중급';
      case 'Advanced':
        return '고급';
      case 'Expert':
        return '전문가';
      case 'Master':
        return '마스터';
      default:
        return '초급';
    }
  }

  void _goToGame(String title) {
    final level = getLevel(title);
    final game = getDummyGame(level.name);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SudokuGameScreen(game: game, level: level),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFFF9F8F6),
      backgroundColor: Colors.white,

      //backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 프로필 영역
            Container(
              //margin: const EdgeInsets.only(top: 8, bottom: ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: _isTop ? Colors.white : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.amber[200],
                    child:
                        const Icon(Icons.person, size: 36, color: Colors.brown),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '게스트',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '스도쿠에 오신 것을 환영합니다 👋',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 28, color: Colors.grey),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //const SizedBox(height: 28),
                      const Text(
                        'Select Level',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      // Divider(
                      //   indent: 10,
                      //   endIndent: 200,
                      //   thickness: 1.5,
                      //   color: Colors.grey[300]!,
                      // ),
                      //const SizedBox(height: 16),
                      // 레벨 카드 리스트
                      _LevelCard(
                        color: const Color(0xFFBFE2D0),
                        icon: Icons.grid_view,
                        title: 'Beginner',
                        completed: 35,
                        remaining: 65,
                        progressColor: const Color(0xFF8DC6B0),
                        isSelected: _selectedIndex == 0,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 0;
                          });
                          _goToGame('Beginner');
                        },
                      ),
                      _LevelCard(
                        color: const Color(0xFFCDE7E0),
                        icon: Icons.diamond,
                        title: 'Intermediate',
                        completed: 20,
                        remaining: 80,
                        progressColor: const Color(0xFF8DC6B0),
                        isSelected: _selectedIndex == 1,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 1;
                          });
                          _goToGame('Intermediate');
                        },
                      ),
                      _LevelCard(
                        color: const Color(0xFFF8D6DA),
                        icon: Icons.star,
                        title: 'Advanced',
                        completed: 10,
                        remaining: 90,
                        progressColor: const Color(0xFFF5AEB5),
                        isSelected: _selectedIndex == 2,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 2;
                          });
                          _goToGame('Advanced');
                        },
                      ),
                      _LevelCard(
                        color: const Color(0xFFF9E6B3),
                        icon: Icons.emoji_events,
                        title: 'Expert',
                        completed: 5,
                        remaining: 95,
                        progressColor: const Color(0xFFF5D06F),
                        isSelected: _selectedIndex == 3,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 3;
                          });
                          _goToGame('Expert');
                        },
                      ),
                      _LevelCard(
                        color: const Color(0xFFF5F1E6),
                        icon: Icons.workspace_premium,
                        title: 'Master',
                        completed: 0,
                        remaining: 100,
                        progressColor: const Color(0xFFD6CBA6),
                        isSelected: _selectedIndex == 4,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 4;
                          });
                          _goToGame('Master');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String title;
  final int completed;
  final int remaining;
  final Color progressColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.completed,
    required this.remaining,
    required this.progressColor,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _pressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _pressed = false;
    });
    if (widget.onTap != null) widget.onTap!();
  }

  void _handleTapCancel() {
    setState(() {
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.completed + widget.remaining;
    final percent = total == 0 ? 0.0 : widget.completed / total;
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFF9F8F6) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(widget.icon, size: 36, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.completed} /, ${widget.remaining} ',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 7,
                      backgroundColor: widget.color.withOpacity(0.25),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(widget.progressColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Container(
            //   width: 36,
            //   height: 36,
            //   decoration: BoxDecoration(
            //     color: Colors.grey.withOpacity(0.12),
            //     shape: BoxShape.circle,
            //   ),
            //   child:
            //       const Icon(Icons.info_outline, color: Colors.grey, size: 22),
            // ),
          ],
        ),
      ),
    );
  }
}
