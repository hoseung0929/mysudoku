import 'dart:ui' show FontFeature;

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
import 'package:mysudoku/widgets/sudoku_grid_badge.dart';

class RecordsStatisticsScreen extends StatefulWidget {
  const RecordsStatisticsScreen({super.key});

  @override
  State<RecordsStatisticsScreen> createState() =>
      _RecordsStatisticsScreenState();
}

class _RecordsStatisticsScreenState extends State<RecordsStatisticsScreen> {
  static const Color _backgroundColor = Color(0xFFFAFAF7);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _primaryTextColor = Color(0xFF1F3328);
  static const Color _secondaryTextColor = Color(0xFF7B857D);
  static const Color _selectedAccentColor = Color(0xFF8FAA91);
  static const Color _lightAccentColor = Color(0xFFDCE8DD);
  static const Color _borderColor = Color(0xFFE6E8E3);

  /// 상태바 아래 프로필 바 본문 높이(홈 [LevelSelectionMain]과 동일).
  static const double _kProfileHeaderExtent = 104;

  /// 프로필 헤더와 스크롤 본문 사이 여백.
  static const double _kBelowProfileHeaderGap = 18;

  /// 하단 플로팅 탭바 여유 — [LevelSelectionMain._kHomeScrollBottomPad] 와 동일.
  static const double _kScrollBottomPad = 130;

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

  bool get _isKorean => Localizations.localeOf(context).languageCode == 'ko';

  String _statsGuestTitle() => _isKorean ? '게스트1' : 'Guest 1';

  String _statsHeaderSubtitle() =>
      _isKorean ? '나의 풀이 기록을 확인해보세요.' : 'Check your solving records.';

  String _insightCardClearsTitle() =>
      _isKorean ? '이번 주 풀이 수' : 'This week\'s clears';

  String _insightCardAverageTimeTitle() =>
      _isKorean ? '평균 풀이 시간' : 'Average solve time';

  String _recentInsightsTitle() =>
      _isKorean ? '최근 플레이 인사이트' : 'Recent play insights';

  String _playCalendarTitle() => _isKorean ? '플레이 캘린더' : 'Play calendar';

  String _difficultySnapshotTitle() =>
      _isKorean ? '난이도별 기록' : 'By difficulty';

  String _bestRecordTitle() => _isKorean ? '최고 기록' : 'Best record';

  String _detailStatsTitle() => _isKorean ? '세부 기록' : 'Detailed stats';

  String _bestRecordEmpty() =>
      _isKorean ? '아직 최고 기록을 표시할 데이터가 없어요.' : 'No best record yet.';

  String _hintUsageLabel() => _isKorean ? '힌트 사용 기록' : 'Hint usage';

  String _hintUsageUnavailable() =>
      _isKorean ? '기록 없음' : 'No record';

  String _mistakeLabel() => _isKorean ? '실수 기록' : 'Mistakes';

  String _streakLabel() => _isKorean ? '연속 플레이 일수' : 'Play streak';

  String _levelSectionSubtitle() => _isKorean
      ? '난이도별 클리어 수와 완료율을 확인해보세요.'
      : 'Review clears and completion rate by difficulty.';

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
    final totalClears = trendSummaryUi['total_clears'] as int;
    final averageTime = trendSummaryUi['average_time'] as double;
    if (useStackedLayout) {
      return Column(
        children: [
          _recordsInsightCard(
            eyebrow: _insightCardClearsTitle(),
            value: _isKorean ? '$totalClears회' : '$totalClears',
            icon: Icons.grid_view_rounded,
            tone: _lightAccentColor,
            accent: _selectedAccentColor,
            emphasized: true,
          ),
          const SizedBox(height: 12),
          _recordsInsightCard(
            eyebrow: _insightCardAverageTimeTitle(),
            value: _formatDurationNatural(averageTime),
            icon: Icons.schedule_rounded,
            tone: _lightAccentColor,
            accent: _selectedAccentColor,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _recordsInsightCard(
            eyebrow: _insightCardClearsTitle(),
            value: _isKorean ? '$totalClears회' : '$totalClears',
            icon: Icons.grid_view_rounded,
            tone: _lightAccentColor,
            accent: _selectedAccentColor,
            emphasized: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _recordsInsightCard(
            eyebrow: _insightCardAverageTimeTitle(),
            value: _formatDurationNatural(averageTime),
            icon: Icons.schedule_rounded,
            tone: _lightAccentColor,
            accent: _selectedAccentColor,
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
              _backgroundColor,
              _backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: CircularProgressIndicator(
              color: _selectedAccentColor,
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

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _backgroundColor,
            _backgroundColor,
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
              color: _primaryTextColor,
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
                guestTitle: _statsGuestTitle(),
                profileImagePath: _profileImagePath,
                sectionLabel: l10n.navRecords,
                titleOverride: _statsGuestTitle(),
                subtitleOverride: _statsHeaderSubtitle(),
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

    return Card(
      color: _cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recordsByLevelTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryTextColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _levelSectionSubtitle(),
              style: const TextStyle(
                color: _secondaryTextColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (stats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.recordsByLevelEmpty,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _secondaryTextColor,
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
    final weekSummary = _buildWindowSummary(trend);
    final bestRecord = _bestRecord();
    final streakDays = _currentPlayStreakDays(trend);

    return Card(
      color: _cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _recentInsightsTitle(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _primaryTextColor,
              ),
            ),
            const SizedBox(height: 14),
            _insightsSectionBlock(
              title: _playCalendarTitle(),
              child: _buildPlayCalendar(l10n, trend),
            ),
            const SizedBox(height: 12),
            _insightsSectionBlock(
              title: _bestRecordTitle(),
              child: _buildBestRecordSection(l10n, bestRecord),
            ),
            const SizedBox(height: 12),
            _insightsSectionBlock(
              title: _difficultySnapshotTitle(),
              child: _buildDifficultySnapshot(l10n),
            ),
            const SizedBox(height: 12),
            _insightsSectionBlock(
              title: _detailStatsTitle(),
              child: _buildDetailStatsSection(weekSummary, streakDays),
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
              ? _cardColor
              : _selectedAccentColor.withValues(alpha: 0.12 + ratio * 0.22);
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
                        ? _selectedAccentColor
                        : _borderColor,
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
                        color: isToday ? _selectedAccentColor : _secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$clears',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primaryTextColor,
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

  Widget _buildDifficultySnapshot(AppLocalizations l10n) {
    final stats = _displayLevelStats
        .where((stat) => (stat['cleared_count'] as int? ?? 0) > 0)
        .toList(growable: false);
    if (stats.isEmpty) {
      return Text(
        _isKorean ? '아직 난이도별 기록이 없어요.' : 'No difficulty stats yet.',
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: _secondaryTextColor,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stats.map((stat) {
        final levelNameKey = stat['level_name'] as String;
        final levelName = levelNameKey.localizedSudokuLevelName(l10n);
        final clears = stat['cleared_count'] as int;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: _lightAccentColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SudokuGridBadge(
                size: 14,
                color: _levelAccent(levelNameKey),
              ),
              const SizedBox(width: 8),
              Text(
                '$levelName ${_isKorean ? '$clears회' : '$clears'}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBestRecordSection(
    AppLocalizations l10n,
    Map<String, dynamic>? bestRecord,
  ) {
    if (bestRecord == null) {
      return Text(
        _bestRecordEmpty(),
        style: const TextStyle(
          fontSize: 13,
          height: 1.4,
          color: _secondaryTextColor,
        ),
      );
    }

    final levelNameKey = bestRecord['level_name'] as String? ?? '';
    final levelName = levelNameKey.localizedSudokuLevelName(l10n);
    final gameNumber = _recordInt(bestRecord, 'game_number');
    final wrongCount = _recordInt(bestRecord, 'wrong_count');
    final clearTime = _formatDurationNatural(
      _recordInt(bestRecord, 'clear_time').toDouble(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isKorean
                ? '$levelName · 게임 $gameNumber'
                : '$levelName · Game $gameNumber',
            style: const TextStyle(
              fontSize: 12.5,
              color: _secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            clearTime,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            wrongCount == 0
                ? (_isKorean ? '실수 없이 클리어' : 'Cleared without mistakes')
                : (_isKorean ? '오답 $wrongCount회' : '$wrongCount mistakes'),
            style: const TextStyle(
              fontSize: 13,
              color: _secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStatsSection(
    Map<String, dynamic> weekSummary,
    int streakDays,
  ) {
    return _adaptiveMetricRow(
      [
        _levelMetricTile(
          label: _hintUsageLabel(),
          value: _hintUsageUnavailable(),
        ),
        _levelMetricTile(
          label: _mistakeLabel(),
          value: _isKorean
              ? '${(weekSummary['average_wrong'] as double).toStringAsFixed(1)}회'
              : (weekSummary['average_wrong'] as double).toStringAsFixed(1),
        ),
        _levelMetricTile(
          label: _streakLabel(),
          value: _isKorean ? '$streakDays일' : '$streakDays days',
        ),
      ],
    );
  }

  Widget _insightsSectionBlock({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: _lightAccentColor.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor,
              fontFeatures: [FontFeature.tabularFigures()],
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

  Map<String, dynamic>? _bestRecord() {
    final records = _statisticsService.buildTopRecords(
      recent: _recentForDisplayedStats,
      selectedLevel: _selectedLevel,
      limit: 1,
    );
    if (records.isEmpty) {
      return null;
    }
    return records.first;
  }

  int _currentPlayStreakDays(List<Map<String, dynamic>> trend) {
    var streak = 0;
    for (final day in trend.reversed) {
      final clears = day['clears'] as int? ?? 0;
      if (clears > 0) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
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

  Widget _buildLoadErrorBanner(AppLocalizations l10n, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF0D6CF),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB45E4A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _primaryTextColor,
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
        return const Color(0xFFAFC7B0);
      case '중급':
        return const Color(0xFF8FAA91);
      case '고급':
        return const Color(0xFFC7B692);
      case '전문가':
        return const Color(0xFFB79DAE);
      case '마스터':
        return const Color(0xFF8F9E86);
      default:
        return _selectedAccentColor;
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
    final avgTime = _formatDurationNatural(stat['average_time'] as double);

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _primaryTextColor,
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _primaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isKorean ? '완료' : 'Done',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: _secondaryTextColor,
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
              Text(
                l10n.recordsLevelInfographicClearRate,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _secondaryTextColor,
                ),
              ),
              const Spacer(),
              Text(
                '${clearRate.toStringAsFixed(1)}%',
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
              backgroundColor: _lightAccentColor,
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
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor,
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
    bool emphasized = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: emphasized ? _lightAccentColor.withValues(alpha: 0.72) : _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: emphasized
              ? _selectedAccentColor.withValues(alpha: 0.34)
              : _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: emphasized ? _cardColor : tone,
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
                    fontSize: emphasized ? 12.5 : 12,
                    fontWeight: FontWeight.w600,
                    color: _secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: emphasized ? 24 : 22,
              fontWeight: FontWeight.w700,
              color: _primaryTextColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

}

class _RecordsHeroCard extends StatelessWidget {
  const _RecordsHeroCard({required this.trend});

  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _primaryTextColor = Color(0xFF1F3328);
  static const Color _secondaryTextColor = Color(0xFF7B857D);
  static const Color _selectedAccentColor = Color(0xFF8FAA91);
  static const Color _lightAccentColor = Color(0xFFDCE8DD);
  static const Color _borderColor = Color(0xFFE6E8E3);

  final List<Map<String, dynamic>> trend;

  @override
  Widget build(BuildContext context) {
    final hasClears = trend.any((d) => (d['clears'] as int) > 0);
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SudokuGridBadge(
                size: 18,
                color: _selectedAccentColor,
              ),
              const SizedBox(width: 8),
              Text(
                isKorean ? '이번 주 기록' : 'THIS WEEK',
                style: const TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isKorean
                ? '이번 주 스도쿠 기록을\n확인해보세요.'
                : 'Check your Sudoku\nstats for this week.',
            style: const TextStyle(
              color: _primaryTextColor,
              fontSize: 26,
              height: 1.16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hasClears) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 104,
                width: double.infinity,
                color: _lightAccentColor.withValues(alpha: 0.34),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Opacity(
                        opacity: 0.38,
                        child: SudokuGridBadge(
                          size: 26,
                          color: _selectedAccentColor.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _RecordsTrendBackdropPainter(
                          trend: trend,
                          strokeColor: _selectedAccentColor.withValues(alpha: 0.74),
                          fillTopColor: _selectedAccentColor.withValues(alpha: 0.20),
                          fillBottomColor: _selectedAccentColor.withValues(alpha: 0.05),
                          pointColor: _selectedAccentColor.withValues(alpha: 0.42),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 14,
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
                            fontSize: 10.5,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isToday ? _selectedAccentColor : _secondaryTextColor,
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
              isKorean
                  ? '이번 주에 퍼즐을 완료하면 여기에 기록 그래프가 표시됩니다.'
                  : 'Complete a puzzle this week to see your graph here.',
              style: const TextStyle(
                color: _secondaryTextColor,
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
