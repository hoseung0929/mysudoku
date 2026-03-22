import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../model/sudoku_game.dart';
import '../model/sudoku_level.dart';
import '../services/records_statistics_service.dart';
import 'sudoku_game_screen.dart';

class RecordsStatisticsScreen extends StatefulWidget {
  const RecordsStatisticsScreen({super.key});

  @override
  State<RecordsStatisticsScreen> createState() => _RecordsStatisticsScreenState();
}

class _RecordsStatisticsScreenState extends State<RecordsStatisticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final RecordsStatisticsService _statisticsService = RecordsStatisticsService();
  bool _isLoading = true;

  Map<String, dynamic> _overall = {};
  List<Map<String, dynamic>> _levels = [];
  List<Map<String, dynamic>> _recent = [];

  String _selectedLevel = '전체';
  int _selectedPeriodDays = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _statisticsService.load(
        selectedPeriodDays: _selectedPeriodDays,
      );

      if (mounted) {
        setState(() {
          _overall = data.overall;
          _levels = data.levels;
          _recent = data.recent;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRecent {
    return _statisticsService.filterRecentRecords(
      recent: _recent,
      selectedLevel: _selectedLevel,
    );
  }

  Map<String, dynamic> get _displayOverall {
    return _statisticsService.buildOverallStats(
      overall: _overall,
      levels: _levels,
      recent: _recent,
      selectedLevel: _selectedLevel,
    );
  }

  List<Map<String, dynamic>> get _displayLevelStats {
    return _statisticsService.buildLevelStats(
      levels: _levels,
      recent: _recent,
      selectedLevel: _selectedLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '기록 · 통계',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterSection(),
          const SizedBox(height: 12),
          _buildOverallSection(),
          const SizedBox(height: 16),
          _buildLevelSection(),
          const SizedBox(height: 16),
          _buildBestSection(),
          const SizedBox(height: 16),
          _buildRecentSection(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '필터',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in ['전체', ...RecordsStatisticsService.levelOrder])
                  ChoiceChip(
                    label: Text(level),
                    selected: _selectedLevel == level,
                    onSelected: (_) {
                      setState(() {
                        _selectedLevel = level;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              key: ValueKey(_selectedPeriodDays),
              initialValue: _selectedPeriodDays,
              decoration: const InputDecoration(
                labelText: '기간',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('전체 기간')),
                DropdownMenuItem(value: 7, child: Text('최근 7일')),
                DropdownMenuItem(value: 30, child: Text('최근 30일')),
                DropdownMenuItem(value: 90, child: Text('최근 90일')),
              ],
              onChanged: (value) async {
                if (value == null) return;
                setState(() {
                  _selectedPeriodDays = value;
                });
                await _loadStats();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSection() {
    final stats = _displayOverall;
    final totalCleared = stats['total_cleared'] as int;
    final totalGames = stats['total_games'] as int;
    final clearRate = stats['total_clear_rate'] as double;
    final avgTime = stats['total_average_time'] as double;
    final avgWrong = stats['total_average_wrong_count'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '요약 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricChip('클리어', '$totalCleared/$totalGames'),
                _metricChip('클리어율', '${clearRate.toStringAsFixed(1)}%'),
                _metricChip('평균 시간', _statisticsService.formatSeconds(avgTime)),
                _metricChip('평균 오답', avgWrong.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSection() {
    final stats = _displayLevelStats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '레벨별 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            if (stats.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('표시할 레벨 통계가 없습니다.'),
              ),
            ...stats.map((stat) {
              final levelName = stat['level_name'] as String;
              final cleared = stat['cleared_count'] as int;
              final total = stat['total_count'] as int;
              final clearRate = stat['clear_rate'] as double;
              final avgTime =
                  _statisticsService.formatSeconds(stat['average_time'] as double);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          levelName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text('$cleared/$total · ${clearRate.toStringAsFixed(1)}%'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: (clearRate / 100).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFECEFF1),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF8DC6B0)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '평균 시간 $avgTime',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection() {
    final records = _filteredRecent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '최근 클리어',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('선택한 조건의 클리어 기록이 없습니다.'),
              ),
            ...records.map((record) {
              final levelName = record['level_name'] as String;
              final gameNumber = record['game_number'] as int;
              final clearTime = record['clear_time'] as int;
              final wrongCount = record['wrong_count'] as int;
              final clearDate = record['clear_date'] as String;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, color: Color(0xFF7F8C8D)),
                title: Text('$levelName · 게임 $gameNumber'),
                subtitle: Text(
                  '시간 ${_statisticsService.formatSeconds(clearTime)} · 오답 $wrongCount · $clearDate',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSection() {
    final topRecords = _statisticsService.buildTopRecords(
      recent: _recent,
      selectedLevel: _selectedLevel,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '최고기록 Top 5',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            if (topRecords.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('선택한 조건의 최고기록이 없습니다.'),
              ),
            ...topRecords.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final record = entry.value;
              final levelName = record['level_name'] as String;
              final gameNumber = record['game_number'] as int;
              final clearTime = record['clear_time'] as int;
              final wrongCount = record['wrong_count'] as int;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _rankBadge(rank),
                title: Text('$levelName · 게임 $gameNumber'),
                subtitle: Text(
                  '시간 ${_statisticsService.formatSeconds(clearTime)} · 오답 $wrongCount',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF7F8C8D),
                ),
                onTap: () => _openGameFromRecord(record),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _rankBadge(int rank) {
    IconData icon;
    Color color;
    switch (rank) {
      case 1:
        icon = Icons.workspace_premium;
        color = const Color(0xFFFFD700);
        break;
      case 2:
        icon = Icons.workspace_premium;
        color = const Color(0xFFC0C0C0);
        break;
      case 3:
        icon = Icons.workspace_premium;
        color = const Color(0xFFCD7F32);
        break;
      default:
        icon = Icons.emoji_events;
        color = const Color(0xFF7F8C8D);
        break;
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGameFromRecord(Map<String, dynamic> record) async {
    final levelName = record['level_name'] as String?;
    final gameNumber = record['game_number'] as int?;
    if (levelName == null || gameNumber == null) {
      return;
    }

    final level = SudokuLevel.levels.firstWhere(
      (item) => item.name == levelName,
      orElse: () => SudokuLevel.levels.first,
    );

    final board = await _dbHelper.getGame(levelName, gameNumber);
    if (board.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게임 데이터를 불러올 수 없습니다.')),
      );
      return;
    }

    final solution = await _dbHelper.getSolution(levelName, gameNumber);
    final game = SudokuGame(
      board: board,
      solution: solution,
      emptyCells: level.emptyCells,
      levelName: levelName,
      gameNumber: gameNumber,
    );

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SudokuGameScreen(
          game: game,
          level: level,
        ),
      ),
    );
  }
}
