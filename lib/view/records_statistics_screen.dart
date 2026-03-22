import 'package:flutter/material.dart';
import 'package:mysudoku/constants/records_level_filter.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/records_statistics_service.dart';
import 'package:mysudoku/view/sudoku_game_screen.dart';

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

  String _selectedLevel = RecordsLevelFilter.allLevels;
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
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.recordsScreenTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterSection(l10n),
          const SizedBox(height: 12),
          _buildOverallSection(l10n),
          const SizedBox(height: 16),
          _buildLevelSection(l10n),
          const SizedBox(height: 16),
          _buildBestSection(l10n),
          const SizedBox(height: 16),
          _buildRecentSection(l10n),
        ],
      ),
    );
  }

  Widget _buildFilterSection(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsFilterSectionTitle,
              style: const TextStyle(
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
                for (final level in [
                  RecordsLevelFilter.allLevels,
                  ...RecordsStatisticsService.levelOrder,
                ])
                  ChoiceChip(
                    label: Text(
                      RecordsLevelFilter.isAllLevels(level)
                          ? l10n.recordsFilterAllLevels
                          : level.localizedSudokuLevelName(l10n),
                    ),
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
              decoration: InputDecoration(
                labelText: l10n.recordsPeriodLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text(l10n.recordsPeriodAll),
                ),
                DropdownMenuItem(
                  value: 7,
                  child: Text(l10n.recordsPeriodLastDays(7)),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text(l10n.recordsPeriodLastDays(30)),
                ),
                DropdownMenuItem(
                  value: 90,
                  child: Text(l10n.recordsPeriodLastDays(90)),
                ),
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

  Widget _buildOverallSection(AppLocalizations l10n) {
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
            Text(
              l10n.recordsSummaryTitle,
              style: const TextStyle(
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
                _metricChip(l10n.recordsMetricClears, '$totalCleared/$totalGames'),
                _metricChip(
                    l10n.recordsMetricClearRate, '${clearRate.toStringAsFixed(1)}%'),
                _metricChip(l10n.recordsMetricAvgTime,
                    _statisticsService.formatSeconds(avgTime)),
                _metricChip(
                    l10n.recordsMetricAvgWrong, avgWrong.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSection(AppLocalizations l10n) {
    final stats = _displayLevelStats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsByLevelTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            if (stats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.recordsByLevelEmpty),
              ),
            ...stats.map((stat) {
              final levelNameKey = stat['level_name'] as String;
              final levelName = levelNameKey.localizedSudokuLevelName(l10n);
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
                      l10n.recordsAvgTimeDetail(avgTime),
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

  Widget _buildRecentSection(AppLocalizations l10n) {
    final records = _filteredRecent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsRecentTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.recordsRecentEmpty),
              ),
            ...records.map((record) {
              final levelNameKey = record['level_name'] as String;
              final levelName = levelNameKey.localizedSudokuLevelName(l10n);
              final gameNumber = record['game_number'] as int;
              final clearTime = record['clear_time'] as int;
              final wrongCount = record['wrong_count'] as int;
              final clearDate = record['clear_date'] as String;
              final timeStr = _statisticsService.formatSeconds(clearTime);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, color: Color(0xFF7F8C8D)),
                title: Text(
                  l10n.recordsGameNumberTitle(levelName, gameNumber),
                ),
                subtitle: Text(
                  l10n.recordsRecentDetail(timeStr, wrongCount, clearDate),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSection(AppLocalizations l10n) {
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
            Text(
              l10n.recordsBestTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            if (topRecords.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.recordsBestEmpty),
              ),
            ...topRecords.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final record = entry.value;
              final levelNameKey = record['level_name'] as String;
              final levelName = levelNameKey.localizedSudokuLevelName(l10n);
              final gameNumber = record['game_number'] as int;
              final clearTime = record['clear_time'] as int;
              final wrongCount = record['wrong_count'] as int;
              final timeStr = _statisticsService.formatSeconds(clearTime);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _rankBadge(rank),
                title: Text(
                  l10n.recordsGameNumberTitle(levelName, gameNumber),
                ),
                subtitle: Text(
                  l10n.recordsBestDetail(timeStr, wrongCount),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.recordsGameLoadError)),
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
