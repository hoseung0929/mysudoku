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

  static const double _kTrendChartHeight = 156;

  /// 막대가 차지할 수 있는 본체 높이(수치 레이블·축 레이블 제외).
  static const double _kTrendBarMaxFill = 86;

  static const double _kTrendBarMinFill = 8;

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
          _loadErrorMessage = _statsLoadErrorMessage();
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

  String _trendDayPrimaryLabel(AppLocalizations l10n, Map<String, dynamic> day) {
    if (day['is_today'] == true) {
      return l10n.recordsTrendTodayLabel;
    }
    final parsed = DateTime.parse(day['date'] as String);
    return DateFormat.E(Localizations.localeOf(context).toString()).format(parsed);
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
              Color(0xFFFDFBF6),
              Color(0xFFF7F4E8),
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
            Color(0xFFFDFBF6),
            Color(0xFFF7F4E8),
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
                  112 + bottomInset,
                ),
                children: [
                  if (_loadErrorMessage != null) ...[
                    _buildLoadErrorBanner(_loadErrorMessage!),
                    const SizedBox(height: 12),
                  ],
                  _RecordsHeroCard(trend: dailyTrend),
                  const SizedBox(height: 16),
                  Row(
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
                  ),
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
              Localizations.localeOf(context).languageCode == 'ko'
                  ? '난이도별로 어느 구간에서 가장 편안해졌는지 볼 수 있어요.'
                  : 'See which levels are starting to feel more comfortable.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
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
              final perfectRate = stat['perfect_rate'] as double;
              final avgWrong = stat['average_wrong'] as double;
              final bestTimeRaw = stat['best_time'] as int;
              final avgTime = _statisticsService
                  .formatSeconds(stat['average_time'] as double);
              final bestTime = bestTimeRaw > 0
                  ? _statisticsService.formatSeconds(bestTimeRaw)
                  : '--:--:--';

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
                        Text(
                          '$cleared/$total · ${clearRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: (clearRate / 100).clamp(0.0, 1.0),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.recordsAvgTimeDetail(avgTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRateComparisonInfographic(
                      clearRate: clearRate,
                      perfectRate: perfectRate,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _miniLevelMetric(
                          icon: Icons.workspace_premium_outlined,
                          label: Localizations.localeOf(context).languageCode ==
                                  'ko'
                              ? '베스트'
                              : 'Best',
                          value: bestTime,
                        ),
                        _miniLevelMetric(
                          icon: Icons.gps_fixed,
                          label: Localizations.localeOf(context).languageCode ==
                                  'ko'
                              ? '퍼펙트율'
                              : 'Perfect',
                          value: '${perfectRate.toStringAsFixed(1)}%',
                        ),
                        _miniLevelMetric(
                          icon: Icons.error_outline_rounded,
                          label: Localizations.localeOf(context).languageCode ==
                                  'ko'
                              ? '평균 오답'
                              : 'Avg wrong',
                          value: avgWrong.toStringAsFixed(1),
                        ),
                      ],
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

  Widget _buildTrendSection(
    AppLocalizations l10n, {
    required List<Map<String, dynamic>> trend,
    required Map<String, dynamic> summary,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxClears = trend.isEmpty
        ? 1
        : trend
            .map((day) => day['clears'] as int)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 99);
    final totalClears = summary['total_clears'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
              l10n.recordsTrendSectionSubtitle,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            if (totalClears == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.recordsTrendEmpty),
              )
            else ...[
              Row(
                children: [
                  _metricChip(l10n.recordsTrendClears, '$totalClears'),
                  const SizedBox(width: 12),
                  _metricChip(
                    l10n.recordsTrendActiveDays,
                    '${summary['active_days']}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _trendLegendItem(
                    color: colorScheme.primary,
                    isLine: false,
                    label: l10n.recordsTrendLegendDailyClears,
                  ),
                  _trendLegendItem(
                    color: colorScheme.tertiary.withValues(alpha: 0.9),
                    isLine: true,
                    label: l10n.recordsTrendLegendMovingAverage,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.recordsTrendMovingAvgFootnote,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: '${l10n.recordsTrendTitle}. ${l10n.recordsTrendLegendDailyClears}, ${l10n.recordsTrendLegendMovingAverage}',
                child: SizedBox(
                  height: _kTrendChartHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        top: 26,
                        bottom: 38,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _TrendMovingAveragePainter(
                              trend: trend,
                              maxClears: maxClears.toDouble(),
                              color: colorScheme.tertiary,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: trend.map((day) {
                          final clears = day['clears'] as int;
                          final ratio = clears / maxClears;
                          final isToday = day['is_today'] == true;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '$clears',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: _kTrendBarMaxFill * ratio +
                                        _kTrendBarMinFill,
                                    decoration: BoxDecoration(
                                      color: clears == 0
                                          ? colorScheme.surfaceContainerHighest
                                          : colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _trendDayPrimaryLabel(l10n, day),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isToday
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isToday
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    day['label'] as String,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.15,
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.76),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          const SizedBox(height: 8),
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

  Widget _buildRateComparisonInfographic({
    required double clearRate,
    required double perfectRate,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _rateBar(
          label: Localizations.localeOf(context).languageCode == 'ko'
              ? '완료율'
              : 'Clear rate',
          value: clearRate,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 6),
        _rateBar(
          label: Localizations.localeOf(context).languageCode == 'ko'
              ? '퍼펙트율'
              : 'Perfect rate',
          value: perfectRate,
          color: const Color(0xFFF4A261),
        ),
      ],
    );
  }

  Widget _rateBar({
    required String label,
    required double value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratio = (value / 100).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: ratio,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            '${value.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniLevelMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendLegendItem({
    required Color color,
    required bool isLine,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: isLine ? 2.5 : 10,
          decoration: BoxDecoration(
            color: isLine ? color : color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _statsLoadErrorMessage() {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '통계 데이터를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.'
        : 'Unable to load statistics right now. Please try again shortly.';
  }

  String _retryLabel() {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '다시 시도'
        : 'Try again';
  }

  Widget _buildLoadErrorBanner(String message) {
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
            child: Text(_retryLabel()),
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

}

class _RecordsHeroCard extends StatelessWidget {
  const _RecordsHeroCard({required this.trend});

  final List<Map<String, dynamic>> trend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.recordsHeroBadgeFlow,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.recordsHeroTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  l10n.recordsHeroSubtitle,
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

class _TrendMovingAveragePainter extends CustomPainter {
  const _TrendMovingAveragePainter({
    required this.trend,
    required this.maxClears,
    required this.color,
  });

  final List<Map<String, dynamic>> trend;
  final double maxClears;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (trend.length < 2 || maxClears <= 0) {
      return;
    }
    final values =
        trend.map((day) => (day['clears'] as int).toDouble()).toList(growable: false);
    final movingAvg = <double>[];
    for (var i = 0; i < values.length; i++) {
      final start = i - 2 < 0 ? 0 : i - 2;
      final end = i + 2 >= values.length ? values.length - 1 : i + 2;
      double sum = 0;
      for (var j = start; j <= end; j++) {
        sum += values[j];
      }
      movingAvg.add(sum / (end - start + 1));
    }

    final horizontalStep =
        movingAvg.length == 1 ? size.width : size.width / (movingAvg.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < movingAvg.length; i++) {
      final x = horizontalStep * i;
      final normalized = (movingAvg[i] / maxClears).clamp(0.0, 1.0);
      final y = size.height - (normalized * size.height);
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final controlX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(
        controlX,
        prev.dy,
        controlX,
        curr.dy,
        curr.dx,
        curr.dy,
      );
    }

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendMovingAveragePainter oldDelegate) {
    return oldDelegate.trend != trend ||
        oldDelegate.maxClears != maxClears ||
        oldDelegate.color != color;
  }
}
