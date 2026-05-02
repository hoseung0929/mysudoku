import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysudoku/constants/records_level_filter.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/services/game_record_notifier.dart';
import 'package:mysudoku/services/profile_state_service.dart';
import 'package:mysudoku/services/records_statistics_service.dart';
import 'package:mysudoku/view/settings_screen.dart';
import 'package:mysudoku/widgets/profile_editor_sheet.dart';
import 'package:mysudoku/widgets/profile_glass_header.dart';

class RecordsStatisticsScreen extends StatefulWidget {
  const RecordsStatisticsScreen({super.key});

  @override
  State<RecordsStatisticsScreen> createState() =>
      _RecordsStatisticsScreenState();
}

class _RecordsStatisticsScreenState extends State<RecordsStatisticsScreen> {
  /// 상태바 아래 프로필 바 본문 높이(홈 [LevelSelectionMain]과 동일).
  static const double _kProfileHeaderExtent = 104;

  /// 프로필 헤더와 스크롤 본문 사이 여백.
  static const double _kBelowProfileHeaderGap = 18;

  /// 하단 플로팅 탭바 여유 — [LevelSelectionMain._kHomeScrollBottomPad] 와 동일.
  static const double _kScrollBottomPad = 100;

  final RecordsStatisticsService _statisticsService =
      RecordsStatisticsService();
  final ProfileStateService _profileStateService = ProfileStateService();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isTop = true;
  int _loadRequestId = 0;
  String? _loadErrorMessage;

  Map<String, dynamic> _overall = {};
  List<Map<String, dynamic>> _levels = [];
  List<Map<String, dynamic>> _recent = [];
  String? _profileImagePath;
  String? _profileName;

  final String _selectedLevel = RecordsLevelFilter.allLevels;
  final int _selectedPeriodDays = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadProfile();
    GameRecordNotifier.instance.version.addListener(_handleRecordsChanged);
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
    GameRecordNotifier.instance.version.removeListener(_handleRecordsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleRecordsChanged() {
    if (!mounted) return;
    _loadStats();
  }

  Future<void> _loadProfile() async {
    final snapshot = await _profileStateService.load();
    if (!mounted) return;
    setState(() {
      _profileImagePath = snapshot.imagePath;
      _profileName = snapshot.name;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
    if (!mounted) return;
    await _loadProfile();
  }

  Future<void> _saveProfile({
    required String? name,
    required bool removeImage,
    String? pickedImagePath,
  }) async {
    final snapshot = await _profileStateService.save(
      name: name,
      removeImage: removeImage,
      currentImagePath: _profileImagePath,
      pickedImagePath: pickedImagePath,
    );
    if (!mounted) return;
    setState(() {
      _profileName = snapshot.name;
      _profileImagePath = snapshot.imagePath;
    });
  }

  Future<void> _openProfileEditor() async {
    await showProfileEditorSheet(
      context: context,
      profileImageService: _profileStateService.profileImageService,
      initialProfileName: _profileName,
      initialProfileImagePath: _profileImagePath,
      onSave: ({
        required String? name,
        required bool removeImage,
        String? pickedImagePath,
      }) =>
          _saveProfile(
        name: name,
        removeImage: removeImage,
        pickedImagePath: pickedImagePath,
      ),
    );
  }

  Future<void> _loadStats() async {
    final requestId = ++_loadRequestId;
    setState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });

    try {
      final data = await _statisticsService.load(
        selectedPeriodDays: _selectedPeriodDays,
      );

      if (mounted && requestId == _loadRequestId) {
        setState(() {
          _overall = data.overall;
          _levels = data.levels;
          _recent = data.recent;
        });
      }
    } catch (_) {
      if (mounted && requestId == _loadRequestId) {
        setState(() {
          _loadErrorMessage = AppLocalizations.of(context)!.recordsStatsLoadError;
        });
      }
    } finally {
      if (mounted && requestId == _loadRequestId) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _recentForDisplayedStats {
    return _statisticsService.filterRecentToDisplayedPeriod(
      recent: _recent,
      selectedPeriodDays: _selectedPeriodDays,
    );
  }

  List<Map<String, dynamic>> get _displayLevelStats {
    return _statisticsService.buildLevelStats(
      levels: _levels,
      recent: _recentForDisplayedStats,
      selectedLevel: _selectedLevel,
    );
  }

  Map<String, dynamic> get _displayOverall {
    return _statisticsService.buildOverallStats(
      overall: _overall,
      levels: _levels,
      recent: _recentForDisplayedStats,
      selectedLevel: _selectedLevel,
    );
  }

  String _trendDayPrimaryLabel(AppLocalizations l10n, Map<String, dynamic> day) {
    if (day['is_today'] == true) {
      return l10n.recordsTrendTodayLabel;
    }
    final parsed = DateTime.parse(day['date'] as String);
    return DateFormat.E(Localizations.localeOf(context).toString()).format(parsed);
  }

  String _trendDayCalendarLabel(Map<String, dynamic> day) {
    final parsed = DateTime.parse(day['date'] as String);
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ko') {
      const labels = ['월', '화', '수', '목', '금', '토', '일'];
      return labels[parsed.weekday - 1];
    }
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[parsed.weekday - 1];
  }

  String _trendA11ySummary(
    AppLocalizations l10n,
    List<Map<String, dynamic>> trend,
  ) {
    if (trend.isEmpty) return l10n.recordsTrendEmpty;
    final maxClears = trend
        .map((day) => day['clears'] as int)
        .fold<int>(0, (max, value) => value > max ? value : max);
    final today = trend.where((day) => day['is_today'] == true).toList();
    final todayClears = today.isEmpty ? 0 : today.first['clears'] as int;
    final dayBreakdown = trend.map((day) {
      final primary = _trendDayPrimaryLabel(l10n, day);
      final secondary = day['label'] as String;
      final clears = day['clears'] as int;
      return '$primary $secondary, ${l10n.recordsTrendClears} $clears';
    }).join('. ');
    return '${l10n.recordsTrendTitle}. ${l10n.recordsTrendLegendDailyClears}. '
        '${l10n.recordsTrendTodayLabel} $todayClears. 최고 $maxClears. $dayBreakdown';
  }

  Widget _buildInsightCards(
    AppLocalizations l10n,
    Map<String, dynamic> trendSummaryUi,
  ) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14.0;
    final useStackedLayout = textScale > 1.08;
    if (useStackedLayout) {
      return Column(
        children: [
          _recordsInsightCard(
            eyebrow: l10n.recordsInsightThisWeekEyebrow,
            value: l10n.recordsInsightClearsValue(
              trendSummaryUi['total_clears'] as int,
            ),
            icon: Icons.pets_outlined,
            tone: const Color(0xFFE7F0E8),
            accent: const Color(0xFF457B9D),
          ),
          const SizedBox(height: 12),
          _recordsInsightCard(
            eyebrow: l10n.recordsInsightAvgPaceEyebrow,
            value: _statisticsService.formatSeconds(
              _displayOverall['total_average_time'] as double,
            ),
            icon: Icons.cloud_outlined,
            tone: const Color(0xFFF2E9DA),
            accent: const Color(0xFFF4A261),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _recordsInsightCard(
            eyebrow: l10n.recordsInsightThisWeekEyebrow,
            value: l10n.recordsInsightClearsValue(
              trendSummaryUi['total_clears'] as int,
            ),
            icon: Icons.pets_outlined,
            tone: const Color(0xFFE7F0E8),
            accent: const Color(0xFF457B9D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _recordsInsightCard(
            eyebrow: l10n.recordsInsightAvgPaceEyebrow,
            value: _statisticsService.formatSeconds(
              _displayOverall['total_average_time'] as double,
            ),
            icon: Icons.cloud_outlined,
            tone: const Color(0xFFF2E9DA),
            accent: const Color(0xFFF4A261),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final topInset = MediaQuery.paddingOf(context).top;
    if (_isLoading && _overall.isEmpty && _levels.isEmpty && _recent.isEmpty) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAF8),
              Color(0xFFF5F5F1),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final dailyTrend = _statisticsService.buildDailyTrend(
      recent: _recent,
      selectedLevel: _selectedLevel,
    );
    final trendSummaryUi = _statisticsService.buildTrendSummary(
      recent: _recent,
      selectedLevel: _selectedLevel,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAFAF8),
            Color(0xFFF5F5F1),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadStats,
              color: const Color(0xFF285B3F),
              backgroundColor: Colors.white,
              displacement: 28,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  topInset + _kProfileHeaderExtent + _kBelowProfileHeaderGap,
                  20,
                  _kScrollBottomPad + bottomInset,
                ),
                children: [
                  if (_loadErrorMessage != null) ...[
                    _buildLoadErrorBanner(l10n, _loadErrorMessage!),
                    const SizedBox(height: 12),
                  ],
                  _RecordsHeroCard(trend: dailyTrend),
                  const SizedBox(height: 16),
                  _buildInsightCards(l10n, trendSummaryUi),
                  const SizedBox(height: 20),
                  _buildTrendSection(
                    l10n,
                    trend: dailyTrend,
                    summary: trendSummaryUi,
                  ),
                  const SizedBox(height: 22),
                  _buildLevelSection(l10n),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ProfileGlassHeader(
                isTop: _isTop,
                profileName: _profileName,
                guestTitle: l10n.homeGuestTitle,
                profileImagePath: _profileImagePath,
                sectionLabel: l10n.navRecords,
                onTapSettings: _openSettings,
                onTapEditProfile: _openProfileEditor,
              ),
            ),
            if (_isLoading)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
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
        padding: const EdgeInsets.all(20),
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
              l10n.recordsByLevelSectionSubtitle,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (stats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.recordsByLevelEmpty),
              ),
            ...stats.map(
              (stat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLevelStatCard(l10n, stat),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendSection(
    AppLocalizations l10n, {
    required List<Map<String, dynamic>> trend,
    required Map<String, dynamic> summary,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final previousTrend = _statisticsService
        .buildDailyTrend(
          recent: _recent,
          selectedLevel: _selectedLevel,
          days: 14,
        )
        .take(7)
        .toList(growable: false);
    final weekSummary = _buildWindowSummary(trend);
    final previousSummary = _buildWindowSummary(previousTrend);
    final weekRecords = _buildTimelineRecordsForTrend(trend);
    final busiestDay = _busiestTrendDay(trend);
    final perfectRate = weekSummary['perfect_rate'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsPlayInsightsTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            _insightsSectionBlock(
              title: l10n.recordsPlayCalendarTitle,
              child: _buildPlayCalendar(l10n, trend),
            ),
            const SizedBox(height: 12),
            _insightsSectionBlock(
              title: l10n.recordsWeeklyReportTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _adaptiveMetricRow(
                    [
                      _levelMetricTile(
                        label: l10n.recordsTrendClears,
                        value: '${summary['total_clears']}',
                      ),
                      _levelMetricTile(
                        label: l10n.recordsTrendActiveDays,
                        value: '${summary['active_days']}',
                      ),
                      _levelMetricTile(
                        label: l10n.recordsMetricPerfectRate,
                        value: '${perfectRate.toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _weeklyHighlightRow(
                    title: l10n.recordsWeeklyReportBusiestDay,
                    value: busiestDay == null
                        ? l10n.recordsWeeklyReportTopDayFallback
                        : l10n.recordsWeeklyReportTopDayValue(
                            _trendDayPrimaryLabel(l10n, busiestDay),
                            busiestDay['clears'] as int,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _insightsSectionBlock(
              title: l10n.recordsTimelineTitle,
              child: _buildTimelineSection(l10n, weekRecords),
            ),
            const SizedBox(height: 12),
            _insightsSectionBlock(
              title: l10n.recordsPaceTitle,
              child: _buildPaceComparison(
                l10n,
                current: weekSummary,
                previous: previousSummary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayCalendar(
    AppLocalizations l10n,
    List<Map<String, dynamic>> trend,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxClears = trend.isEmpty
        ? 1
        : trend
            .map((day) => day['clears'] as int)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 99);
    return Semantics(
      container: true,
      label: _trendA11ySummary(l10n, trend),
      child: Row(
        children: trend.map((day) {
          final clears = day['clears'] as int;
          final ratio = clears == 0 ? 0.0 : clears / maxClears;
          final isToday = day['is_today'] == true;
          final background = clears == 0
              ? colorScheme.surface
              : colorScheme.primary.withValues(alpha: 0.10 + ratio * 0.28);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isToday
                        ? colorScheme.primary.withValues(alpha: 0.48)
                        : colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _trendDayCalendarLabel(day),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$clears',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineSection(
    AppLocalizations l10n,
    List<Map<String, dynamic>> records,
  ) {
    if (records.isEmpty) {
      return Text(
        l10n.recordsTimelineEmpty,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < records.length; i++) ...[
          _timelineRow(l10n, records[i]),
          if (i != records.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _timelineRow(AppLocalizations l10n, Map<String, dynamic> record) {
    final colorScheme = Theme.of(context).colorScheme;
    final levelNameKey = record['level_name'] as String? ?? '';
    final levelName = levelNameKey.localizedSudokuLevelName(l10n);
    final clearDate = record['clear_date']?.toString() ?? '';
    final date = clearDate.isEmpty ? null : DateTime.tryParse(clearDate);
    final wrongCount = _recordInt(record, 'wrong_count');
    final time = _statisticsService.formatSeconds(
      _recordInt(record, 'clear_time').toDouble(),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14.0;
          final useStackedTime = constraints.maxWidth < 320 || textScale > 1.08;
          final title = date == null
              ? levelName
              : '${DateFormat.Md(Localizations.localeOf(context).toString()).format(date)} · $levelName';
          final subtitle = wrongCount == 0
              ? l10n.recordsTimelinePerfect
              : l10n.recordsTimelineMistakesValue(wrongCount);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: _levelAccent(levelNameKey),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (useStackedTime) ...[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaceComparison(
    AppLocalizations l10n, {
    required Map<String, dynamic> current,
    required Map<String, dynamic> previous,
  }) {
    final previousHasData = (previous['total_clears'] as int) > 0;
    if (!previousHasData) {
      return Text(
        l10n.recordsPaceEmpty,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        _comparisonRow(
          label: l10n.recordsTrendClears,
          currentValue: '${current['total_clears']}',
          previousValue: '${previous['total_clears']}',
          deltaValue: _signedIntDelta(
            current['total_clears'] as int,
            previous['total_clears'] as int,
          ),
          positiveWhenHigher: true,
          currentRaw: (current['total_clears'] as int).toDouble(),
          previousRaw: (previous['total_clears'] as int).toDouble(),
        ),
        const SizedBox(height: 10),
        _comparisonRow(
          label: l10n.recordsTrendWindowAvgTime,
          currentValue: _statisticsService.formatSeconds(
            current['average_time'] as double,
          ),
          previousValue: _statisticsService.formatSeconds(
            previous['average_time'] as double,
          ),
          deltaValue: _signedDurationDelta(
            current['average_time'] as double,
            previous['average_time'] as double,
          ),
          positiveWhenHigher: false,
          currentRaw: current['average_time'] as double,
          previousRaw: previous['average_time'] as double,
        ),
        const SizedBox(height: 10),
        _comparisonRow(
          label: l10n.recordsTrendWindowAvgWrong,
          currentValue: (current['average_wrong'] as double).toStringAsFixed(1),
          previousValue: (previous['average_wrong'] as double).toStringAsFixed(1),
          deltaValue: _signedDoubleDelta(
            current['average_wrong'] as double,
            previous['average_wrong'] as double,
          ),
          positiveWhenHigher: false,
          currentRaw: current['average_wrong'] as double,
          previousRaw: previous['average_wrong'] as double,
        ),
      ],
    );
  }

  Widget _comparisonRow({
    required String label,
    required String currentValue,
    required String previousValue,
    required String deltaValue,
    required bool positiveWhenHigher,
    required double currentRaw,
    required double previousRaw,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final difference = currentRaw - previousRaw;
    final deltaColor = difference == 0
        ? colorScheme.onSurfaceVariant
        : ((difference > 0) == positiveWhenHigher)
        ? const Color(0xFF2A9D8F)
        : const Color(0xFFE76F51);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _comparisonCell(
                  title: AppLocalizations.of(context)!.recordsPaceRecentWindow,
                  value: currentValue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _comparisonCell(
                  title: AppLocalizations.of(context)!.recordsPacePreviousWindow,
                  value: previousValue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _comparisonCell(
                  title: AppLocalizations.of(context)!.recordsPaceDelta,
                  value: deltaValue,
                  valueColor: deltaColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _comparisonCell({
    required String title,
    required String value,
    Color? valueColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightsSectionBlock({
    required String title,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _adaptiveMetricRow(List<Widget> children) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14.0;
    if (textScale > 1.08) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _weeklyHighlightRow({
    required String title,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildWindowSummary(List<Map<String, dynamic>> trend) {
    final filtered = _statisticsService.filterRecentRecords(
      recent: _recent,
      selectedLevel: _selectedLevel,
    );
    final dates = trend
        .map((day) => day['date']?.toString())
        .whereType<String>()
        .toSet();
    final windowRecords = filtered.where((record) {
      final clearDate = record['clear_date']?.toString();
      return clearDate != null && dates.contains(clearDate);
    }).toList(growable: false);
    final totalClears = trend.fold<int>(
      0,
      (sum, day) => sum + ((day['clears'] as int?) ?? 0),
    );
    final activeDays = trend.where((day) => ((day['clears'] as int?) ?? 0) > 0).length;
    final perfectClears = windowRecords
        .where((record) => _recordInt(record, 'wrong_count') == 0)
        .length;
    final perfectRate = windowRecords.isEmpty
        ? 0.0
        : (perfectClears / windowRecords.length) * 100;

    return {
      'total_clears': totalClears,
      'active_days': activeDays,
      'average_time': _averageRecordField(windowRecords, 'clear_time'),
      'average_wrong': _averageRecordField(windowRecords, 'wrong_count'),
      'perfect_clears': perfectClears,
      'perfect_rate': perfectRate,
    };
  }

  List<Map<String, dynamic>> _buildTimelineRecordsForTrend(
    List<Map<String, dynamic>> trend,
  ) {
    final dates = trend
        .map((day) => day['date']?.toString())
        .whereType<String>()
        .toSet();
    final filtered = _statisticsService.filterRecentRecords(
      recent: _recent,
      selectedLevel: _selectedLevel,
    );
    final records = filtered.where((record) {
      final clearDate = record['clear_date']?.toString();
      return clearDate != null && dates.contains(clearDate);
    }).toList()
      ..sort((a, b) {
        final aDate = a['clear_date']?.toString() ?? '';
        final bDate = b['clear_date']?.toString() ?? '';
        final byDate = bDate.compareTo(aDate);
        if (byDate != 0) {
          return byDate;
        }
        final byTime = _recordInt(a, 'clear_time').compareTo(
          _recordInt(b, 'clear_time'),
        );
        if (byTime != 0) {
          return byTime;
        }
        return _recordInt(a, 'wrong_count').compareTo(
          _recordInt(b, 'wrong_count'),
        );
      });
    return records.take(5).toList(growable: false);
  }

  Map<String, dynamic>? _busiestTrendDay(List<Map<String, dynamic>> trend) {
    Map<String, dynamic>? best;
    for (final day in trend) {
      final clears = day['clears'] as int? ?? 0;
      if (best == null || clears > (best['clears'] as int? ?? 0)) {
        best = day;
      }
    }
    if ((best?['clears'] as int? ?? 0) <= 0) {
      return null;
    }
    return best;
  }

  double _averageRecordField(
    List<Map<String, dynamic>> records,
    String field,
  ) {
    if (records.isEmpty) {
      return 0.0;
    }
    final sum = records.fold<double>(
      0,
      (total, record) => total + _recordInt(record, field).toDouble(),
    );
    return sum / records.length;
  }

  int _recordInt(Map<String, dynamic> record, String field) {
    final value = record[field];
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _signedIntDelta(int current, int previous) {
    final delta = current - previous;
    if (delta == 0) {
      return '0';
    }
    return delta > 0 ? '+$delta' : '$delta';
  }

  String _signedDoubleDelta(double current, double previous) {
    final delta = current - previous;
    if (delta.abs() < 0.05) {
      return '0.0';
    }
    final formatted = delta.abs().toStringAsFixed(1);
    return delta > 0 ? '+$formatted' : '-$formatted';
  }

  String _signedDurationDelta(double current, double previous) {
    final deltaSeconds = (current - previous).round();
    if (deltaSeconds == 0) {
      return '00:00:00';
    }
    final sign = deltaSeconds > 0 ? '+' : '-';
    final value = _statisticsService.formatSeconds(deltaSeconds.abs().toDouble());
    return '$sign$value';
  }

  Widget _buildLoadErrorBanner(AppLocalizations l10n, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadStats,
            child: Text(l10n.recordsRetry),
          ),
        ],
      ),
    );
  }

  Color _levelAccent(String levelNameKey) {
    switch (levelNameKey) {
      case '초급':
        return const Color(0xFF2A9D8F);
      case '중급':
        return const Color(0xFF457B9D);
      case '고급':
        return const Color(0xFFF4A261);
      case '전문가':
        return const Color(0xFFE76F51);
      case '마스터':
        return const Color(0xFF7A5C3E);
      default:
        return const Color(0xFF285B3F);
    }
  }

  Widget _buildLevelStatCard(
    AppLocalizations l10n,
    Map<String, dynamic> stat,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final levelNameKey = stat['level_name'] as String;
    final levelName = levelNameKey.localizedSudokuLevelName(l10n);
    final levelAccent = _levelAccent(levelNameKey);
    final cleared = stat['cleared_count'] as int;
    final total = stat['total_count'] as int;
    final clearRate = stat['clear_rate'] as double;
    final perfectRate = stat['perfect_rate'] as double;
    final avgTime = _statisticsService
        .formatSeconds(stat['average_time'] as double);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: levelAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: levelAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$cleared/$total',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.recordsTrendClears,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                l10n.recordsLevelInfographicClearRate,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${clearRate.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: levelAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (clearRate / 100).clamp(0.0, 1.0),
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(levelAccent),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _levelMetricTile(
                  label: l10n.recordsMetricAvgTime,
                  value: avgTime,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _levelMetricTile(
                  label: l10n.recordsMetricPerfectRate,
                  value: '${perfectRate.toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _levelMetricTile({
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  eyebrow,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF21382A),
            ),
          ),
        ],
      ),
    );
  }

}

class _RecordsHeroCard extends StatelessWidget {
  const _RecordsHeroCard({required this.trend});

  final List<Map<String, dynamic>> trend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasClears = trend.any((d) => (d['clears'] as int) > 0);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.recordsHeroTitle,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hasClears) ...[
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 110,
                width: double.infinity,
                color: colorScheme.surfaceContainerLow,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RecordsTrendBackdropPainter(
                      trend: trend,
                      strokeColor: colorScheme.primary.withValues(alpha: 0.46),
                      fillTopColor: colorScheme.primary.withValues(alpha: 0.12),
                      fillBottomColor: colorScheme.primary.withValues(alpha: 0.02),
                      pointColor: colorScheme.primary.withValues(alpha: 0.36),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 16,
              child: Row(
                children: trend.map((day) {
                  final isToday = day['is_today'] == true;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          day['label'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              l10n.recordsHeroChartEmptyHint,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordsTrendBackdropPainter extends CustomPainter {
  const _RecordsTrendBackdropPainter({
    required this.trend,
    required this.strokeColor,
    required this.fillTopColor,
    required this.fillBottomColor,
    required this.pointColor,
  });

  final List<Map<String, dynamic>> trend;
  final Color strokeColor;
  final Color fillTopColor;
  final Color fillBottomColor;
  final Color pointColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (trend.isEmpty) {
      return;
    }

    final values = trend
        .map((day) => (day['clears'] as int).toDouble())
        .toList(growable: false);
    final maxValue =
        values.fold<double>(0, (max, value) => value > max ? value : max);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final horizontalStep =
        values.length == 1 ? size.width : size.width / (values.length - 1);
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
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillTopColor,
          fillBottomColor,
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
      ..color = strokeColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    final leafPaint = Paint()
      ..color = pointColor
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
