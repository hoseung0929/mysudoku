import 'package:flutter/material.dart';
import '../model/sudoku_level.dart';
import '../model/sudoku_game_set.dart';
import '../model/sudoku_game.dart';
import '../widgets/custom_app_bar.dart';
import 'sudoku_game_screen.dart';

/// 난이도 선택 화면
/// 사용자가 스도쿠 게임의 난이도를 선택할 수 있는 화면입니다.
class LevelSelectionScreen extends StatefulWidget {
  final SudokuLevel? level;

  const LevelSelectionScreen({super.key, this.level});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  // 게임 데이터 캐시
  final Map<String, List<SudokuGame>> _gameCache = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 특정 레벨이 전달된 경우 미리 게임 데이터 로딩
    if (widget.level != null) {
      _preloadGames();
    }
  }

  /// 게임 데이터 미리 로딩
  Future<void> _preloadGames() async {
    if (!_gameCache.containsKey(widget.level!.name)) {
      setState(() {
        _isLoading = true;
      });
      try {
        final games = await SudokuGameSet.create(widget.level!.name);
        _gameCache[widget.level!.name] = games;
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // 특정 레벨이 전달된 경우 해당 레벨의 게임들을 카드형으로 표시
    if (widget.level != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildGameSelectionAppBar(),
        body: SafeArea(
          child: isTablet
              ? _buildGameSelectionTabletLayout()
              : _buildGameSelectionMobileLayout(),
        ),
      );
    }

    // 기존 난이도 선택 화면
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 설명 영역
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    width: 2,
                  ),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '난이도 선택',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '원하는 난이도를 선택하여 게임을 시작하세요',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
            // 난이도 카드 영역
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
                  itemCount: SudokuLevel.levels.length,
                  itemBuilder: (context, index) {
                    final level = SudokuLevel.levels[index];
                    return _buildLevelCard(level, true);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 앱바 위젯
  PreferredSizeWidget _buildAppBar() {
    return const CustomAppBar(
      title: '',
      showNotificationIcon: false,
      showLogoutIcon: false,
    );
  }

  /// 게임 선택 화면용 앱바 위젯
  PreferredSizeWidget _buildGameSelectionAppBar() {
    return CustomAppBar(
      title: '',
      showNotificationIcon: false,
      showLogoutIcon: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// 게임 선택 화면용 태블릿 레이아웃
  Widget _buildGameSelectionTabletLayout() {
    return Column(
      children: [
        // 상단 설명 영역
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.level!.name} 게임',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '원하는 게임을 선택하여 시작하세요',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7F8C8D),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getLevelColor(widget.level!.name),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _getLevelIcon(widget.level!.name),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.level!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          widget.level!.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 게임 카드 영역
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          '게임을 불러오는 중...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder<List<SudokuGame>>(
                    future: _loadGames(widget.level!.name),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                '게임을 불러오는 중...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('게임을 불러올 수 없습니다.'),
                        );
                      }
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final game = snapshot.data![index];
                          return _buildGameSelectionCard(game);
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// 게임 선택 화면용 모바일 레이아웃
  Widget _buildGameSelectionMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 설명 영역
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.level!.name} 게임',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '원하는 게임을 선택하여 시작하세요',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getLevelColor(widget.level!.name),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _getLevelIcon(widget.level!.name),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.level!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          widget.level!.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 게임 카드 영역
        Expanded(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          '게임을 불러오는 중...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                      ],
                    ),
                  )
                : FutureBuilder<List<SudokuGame>>(
                    future: _loadGames(widget.level!.name),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                '게임을 불러오는 중...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('게임을 불러올 수 없습니다.'),
                        );
                      }
                      return Column(
                        children: snapshot.data!
                            .map((game) => _buildGameSelectionMobileCard(game))
                            .toList(),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// 게임 선택용 카드 위젯
  Widget _buildGameSelectionCard(SudokuGame game) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  SudokuGameScreen(
                game: game,
                level: widget.level!,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getLevelColor(widget.level!.name),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '게임 ${game.gameNumber}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 게임 선택용 모바일 카드 위젯
  Widget _buildGameSelectionMobileCard(SudokuGame game) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  SudokuGameScreen(
                game: game,
                level: widget.level!,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        borderRadius: BorderRadius.circular(28),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getLevelColor(widget.level!.name),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '게임 ${game.gameNumber}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '클릭하여 게임 시작',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF7F8C8D),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// 난이도 카드 위젯
  Widget _buildLevelCard(SudokuLevel level, bool isCompact) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: InkWell(
        onTap: () => _showLevelGames(level),
        borderRadius: BorderRadius.circular(28),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getLevelColor(level.name),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _getLevelIcon(level.name),
                color: Colors.white,
                size: 36,
              ),
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
                        level.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8E6B8).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${level.clearedGames}/${level.gameCount}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2C3E50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    level.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF7F8C8D),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// 난이도별 색상 반환
  Color _getLevelColor(String levelName) {
    switch (levelName) {
      case '초급':
        return const Color(0xFFBFE2D0);
      case '중급':
        return const Color(0xFFCDE7E0);
      case '고급':
        return const Color(0xFFE6D4B8);
      case '전문가':
        return const Color(0xFFE6B8C8);
      case '마스터':
        return const Color(0xFFB8D4E6);
      default:
        return const Color(0xFFBFE2D0);
    }
  }

  /// 난이도별 아이콘 반환
  IconData _getLevelIcon(String levelName) {
    switch (levelName) {
      case '초급':
        return Icons.grid_view;
      case '중급':
        return Icons.diamond;
      case '고급':
        return Icons.star;
      case '전문가':
        return Icons.flash_on;
      case '마스터':
        return Icons.workspace_premium;
      default:
        return Icons.grid_view;
    }
  }

  /// 난이도별 게임 목록 표시
  void _showLevelGames(SudokuLevel level) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getLevelColor(level.name).withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getLevelIcon(level.name),
                    color: const Color(0xFF2C3E50),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${level.name} 게임',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: const Color(0xFF7F8C8D),
                  ),
                ],
              ),
            ),
            // 게임 목록
            Expanded(
              child: FutureBuilder<List<SudokuGame>>(
                future: _loadGames(level.name),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('게임을 불러올 수 없습니다.'),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final game = snapshot.data![index];
                      return _buildGameCard(game, level);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 게임 카드 위젯 (모달용)
  Widget _buildGameCard(SudokuGame game, SudokuLevel level) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SudokuGameScreen(
                game: game,
                level: level,
              ),
            ),
          );
        },
        child: Card(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '게임 ${game.gameNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8E6B8).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Color(0xFF2C3E50),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
