import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sudoku159/constants/records_level_filter.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/services/records/game_record_notifier.dart';
import 'package:sudoku159/services/profile/profile_state_controller.dart';
import 'package:sudoku159/services/records/records_statistics_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';
import 'package:sudoku159/widgets/profile_editor_sheet.dart';
import 'package:sudoku159/widgets/profile_glass_header.dart';

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
  static const double _kScrollBottomPad = 116;

  final RecordsStatisticsService _statisticsService =
      RecordsStatisticsService();
  final ProfileStateController _profileState = ProfileStateController.instance;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _heatmapScrollController = ScrollController();
  bool _isLoading = true;
  bool _isTop = true;
  int _loadRequestId = 0;
  String? _loadErrorMessage;
  String? _selectedTrendDate;

  Map<String, dynamic> _overall = {};
  List<Map<String, dynamic>> _levels = [];
  List<Map<String, dynamic>> _recent = [];
  Map<String, dynamic> _activitySummary = {};
  List<Map<String, dynamic>> _events = [];
  String? _profileImagePath;
  String? _profileName;
  String? _profileBio;

  static const String _selectedLevel = RecordsLevelFilter.allLevels;
  static const int _selectedPeriodDays = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _profileState.addListener(_handleProfileStateChanged);
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
    _profileState.removeListener(_handleProfileStateChanged);
    _scrollController.dispose();
    _heatmapScrollController.dispose();
    super.dispose();
  }

  void _handleRecordsChanged() {
    if (!mounted) return;
    _loadStats();
  }

  void _handleProfileStateChanged() {
    if (!mounted) return;
    setState(() {
      _profileImagePath = _profileState.imagePath;
      _profileName = _profileState.name;
      _profileBio = _profileState.bio;
    });
  }

  Future<void> _loadProfile() async {
    await _profileState.refresh();
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

  Future<void> _openProfileEditor() async {
    await showProfileEditorSheet(
      context: context,
      profileImageService: _profileState.profileImageService,
      initialProfileName: _profileName,
      initialProfileImagePath: _profileImagePath,
      initialBio: _profileBio,
      onSave: ({
        required String? name,
        required bool removeImage,
        String? pickedImagePath,
        String? bio,
      }) =>
          _profileState.save(
        name: name,
        removeImage: removeImage,
        pickedImagePath: pickedImagePath,
        bio: bio,
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
          _activitySummary = data.activitySummary;
          _events = data.events;
        });
        // 히트맵을 최신 주(오른쪽 끝)로 자동 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_heatmapScrollController.hasClients) {
            _heatmapScrollController.jumpTo(
              _heatmapScrollController.position.maxScrollExtent,
            );
          }
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
    final stats = _statisticsService.buildLevelStats(
      levels: _levels,
      recent: _recentForDisplayedStats,
      selectedLevel: _selectedLevel,
    );
    return stats.where((stat) => stat['level_name'] != '마스터').toList();
  }

  String _formatDurationNatural(num seconds) {
    final totalSeconds = seconds.round();
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ko') {
      if (hours > 0) return '$hours시간 $minutes분 $secs초';
      if (minutes > 0) return '$minutes분 $secs초';
      return '$secs초';
    }
    if (languageCode == 'ja') {
      if (hours > 0) return '$hours時間 $minutes分 $secs秒';
      if (minutes > 0) return '$minutes分 $secs秒';
      return '$secs秒';
    }
    if (hours > 0) return '${hours}h ${minutes}m ${secs}s';
    if (minutes > 0) return '${minutes}m ${secs}s';
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

  // ─── Weekly Activity Card ─────────────────────────────────────────────────

  Widget _buildWeeklyActivityCard(
    AppLocalizations l10n, {
    required List<Map<String, dynamic>> trend,
    required Map<String, dynamic> trendSummaryUi,
  }) {
    final theme = Theme.of(context);
    final totalClears = trendSummaryUi['total_clears'] as int;
    final averageTime = trendSummaryUi['average_time'] as double;
    final selectedDay = _selectedTrendDay(trend);
    final selectedClears = selectedDay?['clears'] as int? ?? totalClears;
    final selectedAverageTime =
        selectedDay?['average_time'] as double? ?? averageTime;
    final selectedDate = selectedDay?['date'] as String?;
    final averageTimeLabel = selectedClears > 0
        ? _formatDurationNatural(selectedAverageTime)
        : l10n.recordsNoAverageTime;

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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildWeekRow(l10n, trend, selectedDate: selectedDate),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Text(
                _selectedTrendLabel(l10n, selectedDay),
                key: ValueKey(selectedDate ?? 'weekly-summary'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatMiniCard(
                    icon: Icons.grid_view_rounded,
                    label: l10n.recordsKpiWeeklyClearsLabel,
                    value: l10n.recordsInsightClearsValue(selectedClears),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatMiniCard(
                    icon: Icons.timer_outlined,
                    label: l10n.recordsKpiAvgSolveTimeLabel,
                    value: averageTimeLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekRow(
    AppLocalizations l10n,
    List<Map<String, dynamic>> trend, {
    required String? selectedDate,
  }) {
    const accent = AppTheme.statisticsAccent;
    return Semantics(
      container: true,
      label: _trendA11ySummary(l10n, trend),
      child: Row(
        children: trend.map((day) {
          final isToday = day['is_today'] == true;
          final isPlayed = (day['clears'] as int) > 0;
          final parsed = DateTime.parse(day['date'] as String);
          final dateNum = parsed.day.toString();
          final dayLetter = _trendDayShortLabel(parsed);
          final dateKey = day['date'] as String;
          final isSelected = selectedDate == dateKey;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedTrendDate = dateKey),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                scale: isSelected ? 1.04 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      dayLetter,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected || isToday
                            ? accent
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: isSelected ? 36 : 32,
                      height: isSelected ? 42 : 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent
                            : isPlayed
                                ? accent.withValues(alpha: 0.15)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : isPlayed
                                  ? Colors.transparent
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.20),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        dateNum,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: isSelected
                              ? Colors.white
                              : isPlayed
                                  ? accent
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                        ),
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

  Widget _buildStatMiniCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.statisticsAccent),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Text(
              value,
              key: ValueKey('$label-$value'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                height: 1.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _selectedTrendDay(List<Map<String, dynamic>> trend) {
    if (trend.isEmpty) return null;
    if (_selectedTrendDate != null) {
      for (final day in trend) {
        if (day['date'] == _selectedTrendDate) {
          return day;
        }
      }
    }
    for (final day in trend) {
      if (day['is_today'] == true) {
        return day;
      }
    }
    return trend.last;
  }

  String _selectedTrendLabel(
    AppLocalizations l10n,
    Map<String, dynamic>? day,
  ) {
    if (day == null) return l10n.recordsTrendTitle;
    if (day['is_today'] == true) return l10n.recordsTrendTodayLabel;
    final parsed = DateTime.parse(day['date'] as String);
    return DateFormat.MMMd(Localizations.localeOf(context).toString())
        .format(parsed);
  }

  String _trendDayShortLabel(DateTime date) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ko') {
      const labels = ['월', '화', '수', '목', '금', '토', '일'];
      return labels[date.weekday - 1];
    }
    if (languageCode == 'ja') {
      const labels = ['月', '火', '水', '木', '金', '土', '日'];
      return labels[date.weekday - 1];
    }
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[date.weekday - 1];
  }

  Widget _buildActivityOverviewCard(
    AppLocalizations l10n, {
    required Map<String, dynamic> activitySummary,
    required Map<String, dynamic> activityHeatmap,
  }) {
    final theme = Theme.of(context);
    final totalClears = activitySummary['total_clears'] as int? ?? 0;
    final currentStreak = activitySummary['current_streak_days'] as int? ?? 0;
    final bestStreak = activitySummary['best_streak_days'] as int? ?? 0;

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
              l10n.recordsActivityOverviewTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActivityKpiItem(
                      label: l10n.recordsActivityTotalClearsLabel,
                      value: '$totalClears',
                    ),
                  ),
                  _buildKpiDivider(),
                  Expanded(
                    child: _buildActivityKpiItem(
                      label: l10n.recordsActivityCurrentStreakLabel,
                      value: l10n.recordsActivityDayCount(currentStreak),
                    ),
                  ),
                  _buildKpiDivider(),
                  Expanded(
                    child: _buildActivityKpiItem(
                      label: l10n.recordsActivityBestStreakLabel,
                      value: l10n.recordsActivityDayCount(bestStreak),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.recordsActivityHeatmapTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildActivityHeatmap(l10n, activityHeatmap),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityKpiItem({
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiDivider() {
    return Container(
      width: 1,
      height: 44,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
    );
  }

  Widget _buildActivityHeatmap(
    AppLocalizations l10n,
    Map<String, dynamic> activityHeatmap,
  ) {
    final weeks =
        (activityHeatmap['weeks'] as List<dynamic>? ?? const <dynamic>[])
            .cast<List<Map<String, dynamic>>>();
    final monthLabels =
        (activityHeatmap['month_labels'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();
    const gap = 4.0;
    const cellSize = 16.0;
    final totalWidth = weeks.isEmpty
        ? 0.0
        : (weeks.length * cellSize) + ((weeks.length - 1) * gap);

    final dayLabels = _heatmapDayLabels(); // 월/수/금 (index 0,2,4)

    // 요일 레이블 컬럼 (스크롤 밖 고정)
    Widget dayLabelColumn = Padding(
      padding: const EdgeInsets.only(right: gap),
      child: Column(
        children: List.generate(7, (i) {
          final label = (i == 0 || i == 2 || i == 4) ? dayLabels[i] : '';
          return Padding(
            padding: EdgeInsets.only(bottom: i < 6 ? gap : 0),
            child: SizedBox(
              width: 14,
              height: cellSize,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.7),
                  height: 1,
                ),
              ),
            ),
          );
        }),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 고정 요일 레이블 (스크롤 안 됨)
            dayLabelColumn,
            // 스크롤 가능한 히트맵 그리드
            Expanded(
              child: SingleChildScrollView(
                controller: _heatmapScrollController,
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int weekIndex = 0;
                            weekIndex < weeks.length;
                            weekIndex++)
                          Padding(
                            padding: EdgeInsets.only(
                              right: weekIndex == weeks.length - 1 ? 0 : gap,
                            ),
                            child: Column(
                              children: [
                                for (int dayIndex = 0;
                                    dayIndex < weeks[weekIndex].length;
                                    dayIndex++) ...[
                                  _buildHeatmapCell(
                                    l10n,
                                    weeks[weekIndex][dayIndex],
                                    size: cellSize,
                                  ),
                                  if (dayIndex != weeks[weekIndex].length - 1)
                                    SizedBox(
                                        height:
                                            gap), // ignore: prefer_const_constructors
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: totalWidth,
                      height: 18,
                      child: Stack(
                        children: [
                          for (final label in _spacedMonthLabels(monthLabels))
                            Positioned(
                              left: (label['week_index'] as int) *
                                  (cellSize + gap),
                              child: Text(
                                _formatHeatmapMonthLabel(
                                    label['date'] as DateTime),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.recordsActivityHeatmapCaption,
          style: TextStyle(
            fontSize: 11.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapCell(
    AppLocalizations l10n,
    Map<String, dynamic> day, {
    required double size,
  }) {
    final theme = Theme.of(context);
    final clears = day['clears'] as int? ?? 0;
    final isToday = day['is_today'] == true;
    return Tooltip(
      message: '${_formatHeatmapTooltipDate(day['date'] as DateTime)} · '
          '${l10n.recordsActivityClearCount(clears)}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _activityHeatColor(day),
          borderRadius: BorderRadius.circular(4),
          border: isToday
              ? Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  width: 1,
                )
              : null,
        ),
      ),
    );
  }

  Color _activityHeatColor(Map<String, dynamic> day) {
    final theme = Theme.of(context);
    if (day['is_future'] == true) {
      return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.14);
    }

    // 다크 배경에서 저채도 보라(statisticsAccent)를 낮은 알파로 겹치면 카드와
    // 거의 같은 밝기로 뭉개져 안 보이므로, 다크모드에서는 더 밝은 보라를 쓴다.
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF9C90E8) : AppTheme.statisticsAccent;

    final intensity = day['intensity'] as int? ?? 0;
    if (day['is_today'] == true) {
      if (intensity <= 0) {
        return accent.withValues(alpha: isDark ? 0.30 : 0.20);
      }
      return accent.withValues(alpha: 0.9);
    }
    switch (intensity) {
      case 1:
        return accent.withValues(alpha: isDark ? 0.32 : 0.22);
      case 2:
        return accent.withValues(alpha: isDark ? 0.50 : 0.42);
      case 3:
        return accent.withValues(alpha: isDark ? 0.68 : 0.62);
      case 4:
        return accent.withValues(alpha: isDark ? 0.86 : 0.82);
      default:
        return theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.38);
    }
  }

  /// 히트맵 요일 레이블 (월~일, index 0=월 … 6=일)
  List<String> _heatmapDayLabels() {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ko') {
      return ['월', '화', '수', '목', '금', '토', '일'];
    }
    if (languageCode == 'ja') {
      return ['月', '火', '水', '木', '金', '土', '日'];
    }
    return ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  }

  List<Map<String, dynamic>> _spacedMonthLabels(
      List<Map<String, dynamic>> labels) {
    if (labels.length <= 1) return labels;
    const minWeekGap = 4;
    final result = <Map<String, dynamic>>[labels.last];
    for (int i = labels.length - 2; i >= 0; i--) {
      final nextIdx = result.last['week_index'] as int;
      final curIdx = labels[i]['week_index'] as int;
      if (nextIdx - curIdx >= minWeekGap) {
        result.add(labels[i]);
      }
    }
    return result;
  }

  String _formatHeatmapMonthLabel(DateTime date) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'ko') return '${date.month}월';
    if (languageCode == 'ja') return '${date.month}月';
    return DateFormat.MMM(Localizations.localeOf(context).toString())
        .format(date);
  }

  String _formatHeatmapTooltipDate(DateTime date) {
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(date);
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
    );
    final trendSummaryUi = _statisticsService.buildTrendSummary(
      recent: _recent,
      selectedLevel: _selectedLevel,
    );
    final activitySummary = _activitySummary;
    final activityHeatmap = _statisticsService.buildActivityHeatmap(
      events: _events,
      selectedLevel: _selectedLevel,
      weeks: 26,
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
                  _buildActivityOverviewCard(
                    l10n,
                    activitySummary: activitySummary,
                    activityHeatmap: activityHeatmap,
                  ),
                  const SizedBox(height: 14),
                  _buildWeeklyActivityCard(
                    l10n,
                    trend: dailyTrend,
                    trendSummaryUi: trendSummaryUi,
                  ),
                  const SizedBox(height: 14),
                  _buildOverallSummaryCard(l10n),
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
                subtitleOverride: _profileBio ?? l10n.recordsStatsPageSubtitle,
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

  Widget _buildOverallSummaryCard(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final totalCleared = (_overall['total_cleared'] as num?)?.toInt() ?? 0;
    final totalGames = (_overall['total_games'] as num?)?.toInt() ?? 0;
    final clearRate = (_overall['total_clear_rate'] as num?)?.toDouble() ?? 0.0;
    final averageTime =
        (_overall['total_average_time'] as num?)?.toDouble() ?? 0.0;
    final averageWrong =
        (_overall['total_average_wrong_count'] as num?)?.toDouble() ?? 0.0;
    final avgTimeLabel = totalCleared > 0
        ? _formatDurationNatural(averageTime)
        : l10n.recordsNoAverageTime;
    final avgWrongLabel = l10n.recordsStatAverageWrongFormatted(
      averageWrong.toStringAsFixed(
        averageWrong == averageWrong.roundToDouble() ? 0 : 1,
      ),
    );

    return Card(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsMetricClearRate,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '$totalCleared/$totalGames',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.statisticsAccent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _formatRate(clearRate),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.statisticsAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.recordsSummaryMetricsFootnote,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            _adaptiveMetricRow([
              _summaryMetricTile(
                icon: Icons.timer_outlined,
                label: l10n.recordsMetricAvgTime,
                value: avgTimeLabel,
              ),
              _summaryMetricTile(
                icon: Icons.close_rounded,
                label: l10n.recordsMetricAvgWrong,
                value: avgWrongLabel,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.statisticsAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            for (int i = 0; i < stats.length; i++)
              _buildLevelStatCard(l10n, stats[i],
                  isLast: i == stats.length - 1),
          ],
        ),
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

  Widget _buildLoadErrorBanner(AppLocalizations l10n, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  String _formatRate(double rate) {
    final rounded = rate.round();
    if ((rate - rounded).abs() < 0.05) return '$rounded%';
    return '${rate.toStringAsFixed(1)}%';
  }

  IconData _levelIcon(String levelNameKey) {
    switch (levelNameKey) {
      case '초급':
        return Icons.eco_rounded;
      case '중급':
        return Icons.local_fire_department_rounded;
      case '고급':
        return Icons.star_rounded;
      case '전문가':
        return Icons.diamond_rounded;
      case '마스터':
        return Icons.emoji_events_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  String? _levelImage(String levelNameKey) {
    switch (levelNameKey) {
      case '초급':
        return 'assets/images/level1.png';
      case '중급':
        return 'assets/images/level2.png';
      case '고급':
        return 'assets/images/level3.png';
      case '전문가':
        return 'assets/images/level4.png';
      default:
        return null;
    }
  }

  Color _levelAccent(String levelNameKey) {
    switch (levelNameKey) {
      case '초급':
        return AppTheme.statisticsAccent;
      case '중급':
        return const Color(0xFF4FA89F);
      case '고급':
        return const Color(0xFFC4A05A);
      case '전문가':
        return const Color(0xFFC07898);
      case '마스터':
        return const Color(0xFFC9A227);
      default:
        return AppTheme.statisticsAccent;
    }
  }

  Widget _buildLevelStatCard(
    AppLocalizations l10n,
    Map<String, dynamic> stat, {
    bool isLast = false,
  }) {
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF4A4A4D)
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _levelImage(levelNameKey) != null
                  ? Image.asset(
                      _levelImage(levelNameKey)!,
                      width: 20,
                      height: 20,
                    )
                  : Icon(
                      _levelIcon(levelNameKey),
                      size: 20,
                      color: levelAccent,
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
                child: Text(
                  '$cleared/$total',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recordsLevelInfographicClearRate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatRate(clearRate),
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
              backgroundColor: levelAccent.withValues(alpha: 0.15),
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
                value: _formatRate(perfectRate),
                alignment: CrossAxisAlignment.end,
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
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
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
    );
  }
}
