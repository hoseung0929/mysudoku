import 'package:flutter/material.dart';
import 'sudoku_game_screen.dart';
import '../model/sudoku_game.dart';
import '../model/sudoku_level.dart';
import '../model/sudoku_game_set.dart';

class LevelSelectionMain extends StatefulWidget {
  const LevelSelectionMain({super.key});

  @override
  State<LevelSelectionMain> createState() => _LevelSelectionMainState();
}

class _LevelSelectionMainState extends State<LevelSelectionMain> {
  int? _selectedIndex;
  final ScrollController _scrollController = ScrollController();
  bool _isTop = true;
  // 게임 데이터 캐시
  final Map<String, List<SudokuGame>> _gameCache = {};

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

  /// 특정 난이도의 게임 목록을 로드합니다.
  /// 캐시된 데이터가 있으면 캐시에서 반환하고,
  /// 없으면 데이터베이스에서 로드하여 캐시에 저장합니다.
  Future<List<SudokuGame>> _loadGames(String level) async {
    if (_gameCache.containsKey(level)) {
      return _gameCache[level]!;
    }
    final games = await SudokuGameSet.create(level);
    _gameCache[level] = games;
    return games;
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

  void _goToGame(String title) async {
    final level = getLevel(title);
    final games = await _loadGames(level.name);

    if (games.isNotEmpty) {
      // 첫 번째 게임으로 이동
      final game = games.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SudokuGameScreen(game: game, level: level),
        ),
      );
    } else {
      // 게임이 없을 경우 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('해당 난이도의 게임을 불러올 수 없습니다.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
      ),
    );
  }

  /// 태블릿 레이아웃
  Widget _buildTabletLayout() {
    return Column(
      children: [
        // 상단 프로필 영역
        _buildProfileSection(),
        // 레벨 카드 영역
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.5,
              ),
              itemCount: 5,
              itemBuilder: (context, index) {
                final levels = [
                  'Beginner',
                  'Intermediate',
                  'Advanced',
                  'Expert',
                  'Master'
                ];
                final colors = [
                  const Color(0xFFBFE2D0),
                  const Color(0xFFCDE7E0),
                  const Color(0xFFE6D4B8),
                  const Color(0xFFE6B8C8),
                  const Color(0xFFB8D4E6),
                ];
                final icons = [
                  Icons.grid_view,
                  Icons.diamond,
                  Icons.star,
                  Icons.flash_on,
                  Icons.workspace_premium,
                ];

                return _LevelCard(
                  color: colors[index],
                  icon: icons[index],
                  title: levels[index],
                  completed: 35 - (index * 3),
                  remaining: 65 + (index * 3),
                  progressColor: const Color(0xFF8DC6B0),
                  isSelected: _selectedIndex == index,
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    _goToGame(levels[index]);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 모바일 레이아웃
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 프로필 영역
        Container(
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
          child: const Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFB8E6B8),
                child: Icon(Icons.person, size: 36, color: Color(0xFF2C3E50)),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '게스트',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '스도쿠에 오신 것을 환영합니다 👋',
                      style: TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 28, color: Color(0xFF7F8C8D)),
            ],
          ),
        ),
        // 레벨 카드 영역
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Level',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),
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
                  color: const Color(0xFFE6D4B8),
                  icon: Icons.star,
                  title: 'Advanced',
                  completed: 15,
                  remaining: 85,
                  progressColor: const Color(0xFF8DC6B0),
                  isSelected: _selectedIndex == 2,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                    _goToGame('Advanced');
                  },
                ),
                _LevelCard(
                  color: const Color(0xFFE6B8C8),
                  icon: Icons.flash_on,
                  title: 'Expert',
                  completed: 8,
                  remaining: 92,
                  progressColor: const Color(0xFF8DC6B0),
                  isSelected: _selectedIndex == 3,
                  onTap: () {
                    setState(() {
                      _selectedIndex = 3;
                    });
                    _goToGame('Expert');
                  },
                ),
                _LevelCard(
                  color: const Color(0xFFB8D4E6),
                  icon: Icons.workspace_premium,
                  title: 'Master',
                  completed: 3,
                  remaining: 97,
                  progressColor: const Color(0xFF8DC6B0),
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
      ],
    );
  }

  /// 프로필 섹션 위젯
  Widget _buildProfileSection() {
    return Container(
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
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFB8E6B8),
            child: Icon(Icons.person, size: 36, color: Color(0xFF2C3E50)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '게스트',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '스도쿠에 오신 것을 환영합니다 👋',
                  style: TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 28, color: Color(0xFF7F8C8D)),
        ],
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
              offset: const Offset(0, 4),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        '${widget.completed} / ${widget.remaining}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
