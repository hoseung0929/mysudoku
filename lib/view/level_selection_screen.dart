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
    return Scaffold(
      appBar: const CustomAppBar(title: '스도쿠'),
      body: ListView.builder(
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
            child: Card(
              elevation: 0,
              color: Colors.green[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 난이도 정보 영역
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 난이도 이름 및 게임 수 표시
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  level.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            // 게임 수 표시 배지
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${level.clearedGames}/${level.gameCount}게임',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        //const SizedBox(height: 16),
                        // 난이도 설명
                        Text(
                          level.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 게임 목록 영역
                  Container(
                    height: 120,
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FutureBuilder<List<SudokuGame>>(
                      future: _loadGames(level.name),
                      builder: (context, snapshot) {
                        // 로딩 중 표시
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // 에러 또는 데이터 없음 표시
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('게임을 불러올 수 없습니다.'),
                          );
                        }

                        // 게임 목록 가로 스크롤
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, gameIndex) {
                            final game = snapshot.data![gameIndex];
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              child: InkWell(
                                onTap: () {
                                  // 게임 화면으로 이동
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
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // 게임 번호
                                        Text(
                                          '게임 ${game.gameNumber}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // 빈 칸 수
                                        Text(
                                          '빈 칸: ${game.emptyCells}개',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
