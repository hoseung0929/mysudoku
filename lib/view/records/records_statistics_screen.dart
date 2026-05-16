import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sudoku159/constants/records_level_filter.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/services/records/game_record_notifier.dart';
import 'package:sudoku159/services/profile/profile_state_service.dart';
import 'package:sudoku159/services/records/records_statistics_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';
import 'package:sudoku159/widgets/profile_editor_sheet.dart';
import 'package:sudoku159/widgets/profile_glass_header.dart';
import 'package:sudoku159/widgets/sudoku_grid_badge.dart';

class RecordsStatisticsScreen extends StatefulWidget {
  const RecordsStatisticsScreen({super.key});

  @override
  State<RecordsStatisticsScreen> createState() =>
      _RecordsStatisticsScreenState();
}

class _RecordsStatisticsScreenState extends State<RecordsStatisticsScreen> {
  /// 상태바 아래 프로필 바 본문 높이(홈 [HomeScreen]과 동일).
  static const double _kProfileHeaderExtent = 104;

  /// 프로필 헤더와 스크롤 본문 사이 여백.
  static const double _kBelowProfileHeaderGap = 18;

  /// 하단 플로팅 탭바 여유 — [HomeScreen._kHomeScrollBottomPad] 와 동일.
  static const double _kScrollBottomPad = 80;

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
          _loadErrorMessage =
              AppLocalizations.of(context)!.recordsStatsLoadError;
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

  bool get _isKorean => Localizations.localeOf(context).languageCode == 'ko';

  String _formatDurationNatural(num seconds) {
    final totalSeconds = seconds.round();
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    if (_isKorean) {
      if (hours > 0) {
        return '$hours시간 $minutes분 $secs초';
      }
      if (minutes > 0) {
        return '$minutes분 $secs초';
      }
      return '$secs초';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    }
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  String _trendDayPrimaryLabel(
      AppLocalizations l10n, Map<String, dynamic> day) {
    if (day['is_today'] == true) {
      return l10n.recordsTrendTodayLabel;
    }
    final parsed = DateTime.parse(day['date'] as String);
    return DateFormat.E(Localizations.localeOf(context).toString())
        .format(parsed);
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
        '${l10n.recordsTrendTodayLabel} $todayClears. '
        '${l10n.recordsTrendA11yMaxClears(maxClears)}. $dayBreakdown';
  }

  Widget _buildSummarySection(
    AppLocalizations l10n,
    Map<String, dynamic> trendSummaryUi,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14.0;
    final stacked = textScale > 1.08;
    final totalClears = trendSummaryUi['total_clears'] as int;
    final averageTime = trendSummaryUi['average_time'] as double;
    final averageTimeLabel = totalClears > 0
        ? _formatDurationNatural(averageTime)
        : l10n.recordsNoAverageTime;

    final clearsChild = _summaryMetricColumn(
      label: l10n.recordsKpiWeeklyClearsLabel,
      value: l10n.recordsInsightClearsValue(totalClears),
    );
    final timeChild = _summaryMetricColumn(
      label: l10n.recordsKpiAvgSolveTimeLabel,
      value: averageTimeLabel,
    );

    final dividerColor = scheme.outlineVariant;

    return Card(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsSummaryTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            if (stacked) ...[
              clearsChild,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: dividerColor),
              ),
              timeChild,
            ] else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: clearsChild),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: dividerColor,
                      ),
                    ),
                    Expanded(child: timeChild),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetricColumn({
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
            height: 1.15,
            fontFeatures: const [FontFeature.tabularFigures()],
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
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: const SafeArea(
          bottom: false,
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.statisticsAccent,
            ),
          ),
        ),
      );
    }

    final dailyTrend = _statisticsService.buildDailyTrend(
      recent: _recent,
      selectedLevel: _selectedLevel,
      thisWeek: true,
    );
    final trendSummaryUi = _statisticsService.buildTrendSummary(
      recent: _recent,
      selectedLevel: _selectedLevel,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadStats,
              color: Theme.of(context).colorScheme.onSurface,
              backgroundColor: Theme.of(context).colorScheme.surface,
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
                  _buildSummarySection(l10n, trendSummaryUi),
                  const SizedBox(height: 20),
                  _buildTrendSection(
                    l10n,
                    trend: dailyTrend,
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      l10n.recordsStatsBasisFootnote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildLevelSection(l10n),
                  const SizedBox(height: 130),
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
                subtitleOverride: l10n.recordsStatsPageSubtitle,
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
    final stats = _displayLevelStats;
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsByLevelTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.recordsByLevelSectionSubtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (stats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.recordsByLevelEmpty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
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
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsPlayInsightsTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            _buildPlayCalendar(l10n, trend),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayCalendar(
    AppLocalizations l10n,
    List<Map<String, dynamic>> trend,
  ) {
    final maxClears = trend.isEmpty
        ? 1
        : trend
            .map((day) => day['clears'] as int)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 99);
    return Semantics(
      container: true,
      label: _trendA11ySummary(l10n, trend),
      child: Column(
        children: [
          Row(
            children: trend.map((day) {
              final clears = day['clears'] as int;
              final ratio = clears == 0 ? 0.0 : clears / maxClears;
              final isPlayed = clears > 0;
              final fillColor = AppTheme.statisticsAccent.withValues(
                alpha: 0.20 + ratio * 0.50,
              );
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        _trendDayCalendarLabel(day),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isPlayed ? fillColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPlayed
                                ? fillColor
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          isPlayed ? '' : '-',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _calendarLegendSwatch(
                fillColor: AppTheme.statisticsAccent.withValues(alpha: 0.28),
                borderColor: AppTheme.statisticsAccent.withValues(alpha: 0.28),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.recordsCalendarPlayedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 28),
              _calendarLegendSwatch(
                fillColor: Colors.transparent,
                borderColor: AppTheme.statisticsAccent.withValues(alpha: 0.64),
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.statisticsAccent.withValues(alpha: 0.84),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.recordsCalendarEmptyLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calendarLegendSwatch({
    required Color fillColor,
    required Color borderColor,
    Widget? child,
  }) {
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: child,
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

  Widget _buildLoadErrorBanner(AppLocalizations l10n, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.lineColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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
        return AppTheme.mintColor;
      case '중급':
        return AppTheme.statisticsAccent;
      case '고급':
        return const Color(0xFFBFB39B);
      case '전문가':
        return const Color(0xFFAEA0B5);
      case '마스터':
        return const Color(0xFF96A08E);
      default:
        return AppTheme.statisticsAccent;
    }
  }

  Widget _buildLevelStatCard(
    AppLocalizations l10n,
    Map<String, dynamic> stat,
  ) {
    final levelNameKey = stat['level_name'] as String;
    final levelName = levelNameKey.localizedSudokuLevelName(l10n);
    final levelAccent = _levelAccent(levelNameKey);
    final cleared = stat['cleared_count'] as int;
    final total = stat['total_count'] as int;
    final clearRate = stat['clear_rate'] as double;
    final perfectRate = stat['perfect_rate'] as double;
    final avgTime = cleared > 0
        ? _formatDurationNatural(stat['average_time'] as double)
        : l10n.recordsNoAverageTime;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: SudokuGridBadge(
                  size: 18,
                  color: levelAccent,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: levelAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$cleared/$total',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.recordsLevelDoneShort,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: Text(
                  l10n.recordsLevelInfographicClearRate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${clearRate.toStringAsFixed(1)}%',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: levelAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: (clearRate / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.hintYellowColor,
              valueColor: AlwaysStoppedAnimation<Color>(levelAccent),
            ),
          ),
          const SizedBox(height: 12),
          _adaptiveMetricRow(
            [
              _levelMetricTile(
                label: l10n.recordsMetricAvgTime,
                value: avgTime,
              ),
              _levelMetricTile(
                label: l10n.recordsMetricPerfectRate,
                value: '${perfectRate.toStringAsFixed(1)}%',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
