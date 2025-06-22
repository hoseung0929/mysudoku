import 'package:flutter/material.dart';
import '../model/sudoku_level.dart';
import '../model/sudoku_game_set.dart';
import '../model/sudoku_game.dart';
import '../widgets/custom_app_bar.dart';
import 'sudoku_game_screen.dart';

/// 난이도 선택 화면
/// 사용자가 스도쿠 게임의 난이도를 선택할 수 있는 화면입니다.
class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  // 게임 데이터 캐시
  final Map<String, List<SudokuGame>> _gameCache = {};

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

    return Scaffold(
      appBar: const CustomAppBar(title: '스도쿠'),
      body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
    );
  }

  /// 태블릿 레이아웃
  Widget _buildTabletLayout() {
    return Column(
      children: [
        // 상단 설명 영역
        Container(
          padding: const EdgeInsets.all(24),
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
    );
  }

  /// 모바일 레이아웃
  Widget _buildMobileLayout() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: SudokuLevel.levels.length + 1, // 제목 섹션을 위해 +1
      itemBuilder: (context, index) {
        // 첫 번째 아이템은 제목과 설명
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '난이도 선택',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '원하는 난이도를 선택하여 게임을 시작하세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // 난이도 카드
        final level = SudokuLevel.levels[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: _buildLevelCard(level, false),
        );
      },
    );
  }

  /// 난이도 카드 위젯
  Widget _buildLevelCard(SudokuLevel level, bool isCompact) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () => _showLevelGames(level),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 난이도 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getLevelColor(level.name).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getLevelIcon(level.name),
                          color: const Color(0xFF2C3E50),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        level.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
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
              const SizedBox(height: 12),
              // 난이도 설명
              Text(
                level.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 16),
                // 게임 목록 (모바일용)
                SizedBox(
                  height: 100,
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
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, gameIndex) {
                          final game = snapshot.data![gameIndex];
                          return _buildGameCard(game, level);
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
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

  /// 난이도 가이드 위젯 (데스크톱용)
  Widget _buildDifficultyGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '난이도 가이드',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),
        _buildGuideItem('초급', '스도쿠를 처음 접하는 분들을 위한 단계', 30),
        _buildGuideItem('중급', '기본 규칙을 익힌 분들을 위한 단계', 40),
        _buildGuideItem('고급', '경험이 있는 분들을 위한 도전 단계', 50),
        _buildGuideItem('전문가', '고급 기술이 필요한 전문가 단계', 60),
        _buildGuideItem('마스터', '최고 수준의 도전을 원하는 분들을 위한 단계', 70),
      ],
    );
  }

  /// 가이드 아이템 위젯
  Widget _buildGuideItem(String title, String description, int emptyCells) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              Text(
                '빈 칸: $emptyCells',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }

  /// 게임 카드 위젯
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
}
