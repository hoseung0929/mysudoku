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
    final colorScheme = Theme.of(context).colorScheme;
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildFilterSection(l10n),
          const SizedBox(height: 12),
          _buildOverallSection(l10n),
          const SizedBox(height: 16),
          _buildTrendSection(l10n),
          const SizedBox(height: 16),
          _buildBestByLevelSection(l10n),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsFilterSectionTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    final stats = _displayOverall;
    final totalCleared = stats['total_cleared'] as int;
    final totalGames = stats['total_games'] as int;
    final clearRate = stats['total_clear_rate'] as double;
    final perfectRate = stats['perfect_clear_rate'] as double;
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
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
                _metricChip(
                    l10n.recordsMetricPerfectRate, '${perfectRate.toStringAsFixed(1)}%'),
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
    final colorScheme = Theme.of(context).colorScheme;
    final stats = _displayLevelStats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsByLevelTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
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
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.recordsAvgTimeDetail(avgTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
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

  Widget _buildBestByLevelSection(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final bestByLevel = _statisticsService.buildBestByLevel(
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
              l10n.recordsBestByLevelTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (bestByLevel.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.recordsBestByLevelEmpty),
              ),
            ...bestByLevel.map((record) {
              final levelNameKey = record['level_name'] as String;
              final levelName = levelNameKey.localizedSudokuLevelName(l10n);
              final gameNumber = record['game_number'] as int;
              final clearTime = record['clear_time'] as int;
              final wrongCount = record['wrong_count'] as int;
              final isPerfect = record['is_perfect'] as bool;
              final timeStr = _statisticsService.formatSeconds(clearTime);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Text(
                    levelName.substring(0, 1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                title: Text(
                  l10n.recordsGameNumberTitle(levelName, gameNumber),
                ),
                subtitle: Text(
                  l10n.recordsBestByLevelDetail(timeStr, wrongCount),
                ),
                trailing: isPerfect
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.recordsPerfectBadge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                onTap: () => _openGameFromRecord(record),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendSection(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final trend = _statisticsService.buildDailyTrend(
      recent: _recent,
      selectedLevel: _selectedLevel,
    );
    final summary = _statisticsService.buildTrendSummary(
      recent: _recent,
      selectedLevel: _selectedLevel,
    );
    final maxClears = trend.isEmpty
        ? 1
        : trend
            .map((day) => day['clears'] as int)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 99);
    final totalClears = summary['total_clears'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsTrendTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (totalClears == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.recordsTrendEmpty),
              )
            else ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metricChip(
                    l10n.recordsTrendClears,
                    '$totalClears',
                  ),
                  _metricChip(
                    l10n.recordsTrendActiveDays,
                    '${summary['active_days']}',
                  ),
                  _metricChip(
                    l10n.recordsMetricAvgTime,
                    _statisticsService
                        .formatSeconds(summary['average_time'] as double),
                  ),
                  _metricChip(
                    l10n.recordsMetricAvgWrong,
                    (summary['average_wrong'] as double).toStringAsFixed(1),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 132,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: trend.map((day) {
                    final clears = day['clears'] as int;
                    final ratio = clears / maxClears;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '$clears',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 72 * ratio + 8,
                              decoration: BoxDecoration(
                                color: clears == 0
                                    ? colorScheme.surfaceContainerHighest
                                    : colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              day['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final records = _filteredRecent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsRecentTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
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
                leading: Icon(Icons.history, color: colorScheme.onSurfaceVariant),
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
    final colorScheme = Theme.of(context).colorScheme;
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
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
                trailing: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
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
        color = colorScheme.onSurfaceVariant;
        break;
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _metricChip(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
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
