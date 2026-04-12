import 'package:flutter/material.dart';
import 'package:mysudoku/constants/records_level_filter.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/records_statistics_service.dart';
import 'package:mysudoku/navigation/root_nav_scope.dart';
import 'package:mysudoku/view/settings_screen.dart';
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
    if (_isLoading) {
      return const SafeArea(
        bottom: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDFBF6),
            Color(0xFFF7F4E8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 112 + bottomInset),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.recordsScreenTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                colorScheme.outlineVariant.withValues(alpha: 0.85),
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _RecordsHeroCard(
                trend: _statisticsService.buildDailyTrend(
                  recent: _recent,
                  selectedLevel: _selectedLevel,
                ),
                title: Localizations.localeOf(context).languageCode == 'ko'
                    ? '차분하게 쌓인 흐름을\n먼저 살펴보세요.'
                    : 'Start with the gentle\nshape of your progress.',
                subtitle: Localizations.localeOf(context).languageCode == 'ko'
                    ? '이번 주의 기록과 리듬을 먼저 보고, 숫자는 그다음에 천천히 확인해보세요.'
                    : 'Take in this week’s rhythm first, then drift into the details when you want to.',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _recordsInsightCard(
                      eyebrow: Localizations.localeOf(context).languageCode == 'ko'
                          ? '이번 주의 발자국'
                          : 'This week',
                      value:
                          '${_statisticsService.buildTrendSummary(recent: _recent, selectedLevel: _selectedLevel)['total_clears'] as int}회',
                      icon: Icons.pets_outlined,
                      tone: const Color(0xFFE7F0E8),
                      accent: const Color(0xFF457B9D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _recordsInsightCard(
                      eyebrow: Localizations.localeOf(context).languageCode == 'ko'
                          ? '평균 호흡'
                          : 'Average pace',
                      value: _statisticsService.formatSeconds(
                        _displayOverall['total_average_time'] as double,
                      ),
                      icon: Icons.cloud_outlined,
                      tone: const Color(0xFFF2E9DA),
                      accent: const Color(0xFFF4A261),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.recordsChallengeTabHint,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () =>
                    RootNavScope.maybeOf(context)?.goToTab(1),
                child: Text(l10n.recordsGoToChallengeTab),
              ),
              const SizedBox(height: 18),
              _buildFilterSection(l10n),
              const SizedBox(height: 20),
              _buildOverallSection(l10n),
              const SizedBox(height: 22),
              _buildTrendSection(l10n),
              const SizedBox(height: 22),
              _buildBestByLevelSection(l10n),
              const SizedBox(height: 22),
              _buildLevelSection(l10n),
              const SizedBox(height: 22),
              _buildBestSection(l10n),
              const SizedBox(height: 22),
              _buildRecentSection(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.recordsFilterSectionTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                _PeriodDropdownChip(
                  label: _periodLabel(l10n, _selectedPeriodDays),
                  children: [
                    _periodMenuItem(l10n, 0),
                    _periodMenuItem(l10n, 7),
                    _periodMenuItem(l10n, 30),
                    _periodMenuItem(l10n, 90),
                  ],
                  onSelected: (value) async {
                    setState(() {
                      _selectedPeriodDays = value;
                    });
                    await _loadStats();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              Localizations.localeOf(context).languageCode == 'ko'
                  ? '필요한 흐름만 조용히 골라서 볼 수 있어요.'
                  : 'Choose only the rhythm you want to focus on.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final level in [
                    RecordsLevelFilter.allLevels,
                    ...RecordsStatisticsService.levelOrder,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
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
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        side: BorderSide(
                          color: _selectedLevel == level
                              ? colorScheme.primary.withValues(alpha: 0.28)
                              : colorScheme.outlineVariant,
                        ),
                        selectedColor:
                            const Color(0xFFE7F0E8).withValues(alpha: 0.9),
                        backgroundColor: colorScheme.surface,
                        labelStyle: TextStyle(
                          color: _selectedLevel == level
                              ? const Color(0xFF285B3F)
                              : colorScheme.onSurfaceVariant,
                          fontWeight: _selectedLevel == level
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<int> _periodMenuItem(AppLocalizations l10n, int value) {
    return PopupMenuItem<int>(
      value: value,
      child: Text(_periodLabel(l10n, value)),
    );
  }

  String _periodLabel(AppLocalizations l10n, int days) {
    switch (days) {
      case 7:
        return l10n.recordsPeriodLastDays(7);
      case 30:
        return l10n.recordsPeriodLastDays(30);
      case 90:
        return l10n.recordsPeriodLastDays(90);
      case 0:
      default:
        return l10n.recordsPeriodAll;
    }
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
        padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 6),
            Text(
              Localizations.localeOf(context).languageCode == 'ko'
                  ? '복잡한 테이블 대신, 지금 상태를 빠르게 읽을 수 있게 정리했습니다.'
                  : 'A compact summary that reads quickly before you dive deeper.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
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
            const SizedBox(height: 10),
            Text(
              l10n.recordsSummaryMetricsFootnote,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: colorScheme.onSurfaceVariant,
              ),
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
        padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 6),
            Text(
              Localizations.localeOf(context).languageCode == 'ko'
                  ? '난이도별로 어느 구간에서 가장 편안해졌는지 볼 수 있어요.'
                  : 'See which levels are starting to feel more comfortable.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.recordsSummaryMetricsFootnote,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
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
        padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 6),
            Text(
              Localizations.localeOf(context).languageCode == 'ko'
                  ? '가장 좋았던 순간만 따로 모아봤어요.'
                  : 'A calm collection of your best puzzle moments.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
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
        padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 6),
            Text(
              Localizations.localeOf(context).languageCode == 'ko'
                  ? '최근 플레이 리듬을 한눈에 보도록 간결하게 정리했습니다.'
                  : 'A concise rhythm view of your recent puzzle days.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
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
        padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 6),
            Text(
              Localizations.localeOf(context).languageCode == 'ko'
                  ? '가장 최근에 마무리한 퍼즐들을 다시 살펴볼 수 있어요.'
                  : 'Revisit the puzzles you completed most recently.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
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
        padding: const EdgeInsets.all(18),
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
            const SizedBox(height: 6),
            Text(
              Localizations.localeOf(context).languageCode == 'ko'
                  ? '기억에 남는 완주들을 조용히 모아봤어요.'
                  : 'Your standout clears, gathered in one quiet place.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
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

  Widget _recordsInsightCard({
    required String eyebrow,
    required String value,
    required IconData icon,
    required Color tone,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4DED3)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 4,
            top: 2,
            child: Icon(
              icon,
              size: 34,
              color: accent.withValues(alpha: 0.18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                eyebrow,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF66776C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF21382A),
                ),
              ),
            ],
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

class _RecordsHeroCard extends StatelessWidget {
  const _RecordsHeroCard({
    required this.title,
    required this.subtitle,
    required this.trend,
  });

  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF285B3F),
            Color(0xFF5D7A69),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF285B3F).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(top: 36),
                child: CustomPaint(
                  painter: _RecordsTrendBackdropPainter(trend: trend),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ko'
                      ? 'Flow'
                      : 'Flow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 72),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodDropdownChip extends StatelessWidget {
  const _PeriodDropdownChip({
    required this.label,
    required this.children,
    required this.onSelected,
  });

  final String label;
  final List<PopupMenuEntry<int>> children;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuButton<int>(
      onSelected: onSelected,
      itemBuilder: (context) => children,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordsTrendBackdropPainter extends CustomPainter {
  const _RecordsTrendBackdropPainter({required this.trend});

  final List<Map<String, dynamic>> trend;

  @override
  void paint(Canvas canvas, Size size) {
    if (trend.isEmpty) {
      return;
    }

    final values = trend
        .map((day) => (day['clears'] as int).toDouble())
        .toList(growable: false);
    final maxValue = values.fold<double>(0, (max, value) => value > max ? value : max);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final horizontalStep = values.length == 1 ? size.width : size.width / (values.length - 1);
    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = horizontalStep * i;
      final normalized = values[i] / safeMax;
      final y = size.height - (normalized * size.height * 0.68) - 8;
      points.add(Offset(x, y));
    }

    final areaPath = Path()..moveTo(points.first.dx, size.height);
    areaPath.lineTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      areaPath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x42FFFFFF),
          Color(0x08FFFFFF),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(areaPath, areaPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    final leafPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.58)
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(-0.45);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 7.5, height: 4.8),
        leafPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RecordsTrendBackdropPainter oldDelegate) {
    return oldDelegate.trend != trend;
  }
}
