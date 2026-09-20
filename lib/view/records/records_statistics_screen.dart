import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sudoku159/constants/records_level_filter.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/navigation/root_nav_scope.dart';
import 'package:sudoku159/services/records/game_record_notifier.dart';
import 'package:sudoku159/services/records/records_statistics_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/time_format.dart';
import 'package:sudoku159/widgets/mascot_image.dart';
import 'package:sudoku159/widgets/sudoku_motif.dart';
import 'package:sudoku159/view/challenge/achievement_collection_screen.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';

class RecordsStatisticsScreen extends StatefulWidget {
  const RecordsStatisticsScreen({super.key, this.statisticsService});

  /// 테스트에서 저장소를 대체하기 위한 선택적 주입. 기본값은 실제 구현.
  final RecordsStatisticsService? statisticsService;

  @override
  State<RecordsStatisticsScreen> createState() =>
      _RecordsStatisticsScreenState();
}

class _RecordsStatisticsScreenState extends State<RecordsStatisticsScreen> {
  /// 하단 플로팅 탭바 여유 — [HomeScreen._kHomeScrollBottomPad] 와 동일.
  static const double _kScrollBottomPad = 116;

  /// 활동 달력이 보여주는 주 수(서비스 호출과 제목 표기를 함께 쓴다).
  static const int _kHeatmapWeeks = 26;

  late final RecordsStatisticsService _statisticsService =
      widget.statisticsService ?? RecordsStatisticsService();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _heatmapScrollController = ScrollController();
  bool _isLoading = true;
  bool _hasLoaded = false;
  int _loadRequestId = 0;
  String? _loadErrorMessage;
  String? _selectedWeekDate;
  String? _selectedLevelName;

  Map<String, dynamic> _overall = {};
  List<Map<String, dynamic>> _levels = [];
  List<Map<String, dynamic>> _recent = [];
  Map<String, dynamic> _activitySummary = {};
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    GameRecordNotifier.instance.version.addListener(_handleRecordsChanged);
  }

  @override
  void dispose() {
    GameRecordNotifier.instance.version.removeListener(_handleRecordsChanged);
    _scrollController.dispose();
    _heatmapScrollController.dispose();
    super.dispose();
  }

  void _handleRecordsChanged() {
    if (!mounted) return;
    _loadStats();
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Future<void> _loadStats() async {
    final requestId = ++_loadRequestId;
    setState(() {
      _isLoading = true;
      _loadErrorMessage = null;
    });

    try {
      final data = await _statisticsService.load(selectedPeriodDays: 0);

      if (mounted && requestId == _loadRequestId) {
        setState(() {
          _overall = data.overall;
          _levels = data.levels;
          _recent = data.recent;
          _activitySummary = data.activitySummary;
          _events = data.events;
          _hasLoaded = true;
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
      // 조회 실패를 '기록 없음'으로 보이지 않도록 별도 오류 상태로 둔다.
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

  /// 마스터 레벨은 홈에서 숨겨져 있으므로 기록에서도 제외한다.
  List<Map<String, dynamic>> get _displayLevelStats {
    final stats = _statisticsService.buildLevelStats(
      levels: _levels,
      recent: _recent,
      selectedLevel: RecordsLevelFilter.allLevels,
    );
    return stats.where((stat) => stat['level_name'] != '마스터').toList();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;

    Widget content;
    if (!_hasLoaded && _loadErrorMessage != null) {
      content = _buildLoadError(l10n, _loadErrorMessage!);
    } else if (!_hasLoaded) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.statisticsAccent),
        ),
      );
    } else if (_recent.isEmpty) {
      content = _buildNoRecords(l10n);
    } else {
      content = _buildSections(l10n);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadStats,
            color: Theme.of(context).colorScheme.onSurface,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                topInset + 12,
                20,
                _kScrollBottomPad + bottomInset,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(l10n),
                        const SizedBox(height: 16),
                        if (_hasLoaded && _loadErrorMessage != null) ...[
                          _buildLoadError(l10n, _loadErrorMessage!),
                          const SizedBox(height: 16),
                        ],
                        content,
                      ],
                    ),
                  ),
                ),
              ],
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
    );
  }

  /// 화면 제목 '기록'과 설정 진입. (프로필 편집은 홈에서 접근하므로 여기서는
  /// 강조하지 않는다.)
  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              l10n.navRecords,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _openSettings,
          tooltip: l10n.navSettings,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  Widget _buildSections(AppLocalizations l10n) {
    final heatmap = _statisticsService.buildActivityHeatmap(
      events: _events,
      selectedLevel: RecordsLevelFilter.allLevels,
      weeks: _kHeatmapWeeks,
    );
    final week = _buildWeekSection(l10n, heatmap);
    final levels = _buildLevelSection(l10n);
    final calendar = _buildCalendarSection(l10n, heatmap);
    final achievements = _buildAchievementRow(l10n);
    final overall = _buildOverallNote(l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 넓은 화면에서만 2칼럼. 좁아지면 단일 칼럼으로 돌아간다.
        if (constraints.maxWidth >= 860) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [week, const SizedBox(height: 24), levels],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        calendar,
                        const SizedBox(height: 24),
                        achievements,
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              overall,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            week,
            const SizedBox(height: 24),
            levels,
            const SizedBox(height: 24),
            calendar,
            const SizedBox(height: 24),
            achievements,
            const SizedBox(height: 24),
            overall,
          ],
        );
      },
    );
  }

  // ─── 공통 조각 ────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text, {String? trailing}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                trailing,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }

  // ─── 이번 주 활동 ─────────────────────────────────────────────────────────

  Widget _buildWeekSection(
    AppLocalizations l10n,
    Map<String, dynamic> heatmap,
  ) {
    final cs = Theme.of(context).colorScheme;
    final weeks = (heatmap['weeks'] as List<dynamic>? ?? const <dynamic>[])
        .cast<List<Map<String, dynamic>>>();
    // 마지막 열이 이번 주(월~일).
    final days = weeks.isEmpty ? const <Map<String, dynamic>>[] : weeks.last;
    final activeDays =
        days.where((day) => (day['clears'] as int? ?? 0) > 0).length;
    // 활동 = 완료 이벤트가 있는 날, 판수 = 반복 완료를 포함한 완료 횟수.
    final completions =
        days.fold<int>(0, (sum, day) => sum + (day['clears'] as int? ?? 0));
    final selected = days.where((d) => d['date_key'] == _selectedWeekDate);
    final locale = Localizations.localeOf(context).toString();

    final summary = selected.isNotEmpty
        ? (() {
            final day = selected.first;
            final name =
                DateFormat.EEEE(locale).format(day['date'] as DateTime);
            final n = day['clears'] as int? ?? 0;
            return n > 0
                ? l10n.recordsWeekDayDone(name, n)
                : l10n.recordsWeekDayNone(name);
          })()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(l10n.recordsPlayInsightsTitle),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (final day in days)
                    Expanded(child: _buildWeekDay(l10n, day, locale)),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: cs.outlineVariant),
              const SizedBox(height: 12),
              if (summary != null)
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                )
              else
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text(
                      l10n.recordsWeekActiveDays(activeDays),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      l10n.recordsWeekCompletions(completions),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDay(
    AppLocalizations l10n,
    Map<String, dynamic> day,
    String locale,
  ) {
    final cs = Theme.of(context).colorScheme;
    final date = day['date'] as DateTime;
    final clears = day['clears'] as int? ?? 0;
    final isToday = day['is_today'] == true;
    final isSelected = day['date_key'] == _selectedWeekDate;
    final done = clears > 0;
    final fullName = DateFormat.EEEE(locale).format(date);
    final semantics = [
      done
          ? l10n.recordsWeekDayDone(fullName, clears)
          : l10n.recordsWeekDayNone(fullName),
      if (isToday) l10n.recordsTrendTodayLabel,
    ].join(', ');

    return Semantics(
      button: true,
      selected: isSelected,
      label: semantics,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          _selectedWeekDate = isSelected ? null : day['date_key'] as String?;
        }),
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.surfaceContainerHighest.withValues(alpha: 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat.E(locale).format(date),
                maxLines: 1,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              // 오늘은 테두리, 완료 여부는 채움+체크 아이콘(색만으로 구분하지 않음).
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppTheme.statisticsAccent : Colors.transparent,
                  border: Border.all(
                    color: isToday
                        ? cs.onSurface
                        : done
                            ? AppTheme.statisticsAccent
                            : cs.outlineVariant,
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                isToday ? l10n.recordsTrendTodayLabel : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 난이도별 기록 ────────────────────────────────────────────────────────

  Widget _buildLevelSection(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final stats = _displayLevelStats;
    if (stats.isEmpty) return const SizedBox.shrink();
    final selectedName = stats.any((s) => s['level_name'] == _selectedLevelName)
        ? _selectedLevelName!
        : (stats.firstWhere(
            (s) => (s['cleared_count'] as int? ?? 0) > 0,
            orElse: () => stats.first,
          )['level_name'] as String);
    final stat = stats.firstWhere((s) => s['level_name'] == selectedName);
    final cleared = stat['cleared_count'] as int? ?? 0;
    final total = stat['total_count'] as int? ?? 0;
    final hasRecords = cleared > 0;
    String time(num? seconds) =>
        hasRecords ? formatElapsedSeconds((seconds ?? 0).round()) : '—';
    final avgWrong = (stat['average_wrong'] as num?)?.toDouble() ?? 0.0;
    final avgWrongLabel = hasRecords
        ? l10n.recordsStatAverageWrongFormatted(
            avgWrong.toStringAsFixed(
              avgWrong == avgWrong.roundToDouble() ? 0 : 1,
            ),
          )
        : '—';

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(l10n.recordsByLevelTitle),
        // 긴 번역에서는 가로 스크롤.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in stats) ...[
                ChoiceChip(
                  label: Text(
                    (s['level_name'] as String).localizedSudokuLevelName(l10n),
                  ),
                  selected: s['level_name'] == selectedName,
                  onSelected: (_) => setState(
                    () => _selectedLevelName = s['level_name'] as String,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                selectedName.localizedSudokuLevelName(l10n),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.recordsMetricClearRate,
                      style:
                          TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                    ),
                  ),
                  Text(
                    '$cleared / $total',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: total > 0 ? (cleared / total).clamp(0.0, 1.0) : 0,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.statisticsAccent,
                  ),
                ),
              ),
              if (!hasRecords) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.recordsLevelEmpty,
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ],
              row(l10n.recordsRowBestTime, time(stat['best_time'] as num?)),
              row(l10n.recordsMetricAvgTime,
                  time(stat['average_time'] as num?)),
              row(l10n.recordsMetricAvgWrong, avgWrongLabel),
              const SizedBox(height: 14),
              Text(
                l10n.recordsAverageBasisNote,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 활동 달력 ────────────────────────────────────────────────────────────

  Widget _buildCalendarSection(
    AppLocalizations l10n,
    Map<String, dynamic> heatmap,
  ) {
    final cs = Theme.of(context).colorScheme;
    final current = _activitySummary['current_streak_days'] as int? ?? 0;
    final best = _activitySummary['best_streak_days'] as int? ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          l10n.recordsCalendarTitle,
          trailing: l10n.recordsCalendarPeriod(_kHeatmapWeeks),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildActivityHeatmap(l10n, heatmap),
              const SizedBox(height: 12),
              Divider(height: 1, color: cs.outlineVariant),
              const SizedBox(height: 12),
              // 연속 기록은 달력 아래 작은 요약 행으로.
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text(
                    '${l10n.recordsActivityCurrentStreakLabel} ${l10n.recordsActivityDayCount(current)}',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    '${l10n.recordsActivityBestStreakLabel} ${l10n.recordsActivityDayCount(best)}',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 업적 / 전체 요약 ─────────────────────────────────────────────────────

  Widget _buildAchievementRow(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l10n.recordsViewAchievements,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AchievementCollectionScreen(),
          ),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.recordsViewAchievements,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  /// 별도 대형 요약 카드 대신 하단 보조 문장 한 줄.
  Widget _buildOverallNote(AppLocalizations l10n) {
    final cleared = (_overall['total_cleared'] as num?)?.toInt() ?? 0;
    final total = (_overall['total_games'] as num?)?.toInt() ?? 0;
    return Text(
      l10n.recordsOverallNote(cleared, total),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  // ─── 상태 화면 ────────────────────────────────────────────────────────────

  /// 전체 완료 기록이 하나도 없을 때: 0 수치·빈 카드 대신 문구와 시작 행동.
  Widget _buildNoRecords(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 펭귄 옆에 작은 스도쿠 종이: 첫 기록을 기다리는 장면(장식).
              ExcludeSemantics(
                child: SizedBox(
                  width: 156,
                  height: 128,
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 0,
                        bottom: 0,
                        child: MascotImage(
                          asset: MascotImage.welcome,
                          size: 116,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 6,
                        child: Transform.rotate(
                          angle: 0.09,
                          child: const SudokuMotif(size: 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.recordsEmptyTitle,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 16, height: 1.4, color: cs.onSurface),
              ),
              const SizedBox(height: 20),
              FilledButton(
                // 홈의 실제 게임 시작 경로(홈 탭)로 이동한다.
                onPressed: () => RootNavScope.maybeOf(context)?.goToTab(0),
                style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                child: Text(l10n.recordsEmptyAction),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadError(AppLocalizations l10n, String message) {
    final cs = Theme.of(context).colorScheme;
    return _card(
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          TextButton(
            onPressed: _loadStats,
            child: Text(l10n.recordsRetry),
          ),
        ],
      ),
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
    final isTablet = MediaQuery.of(context).size.width > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final baseGap = isTablet ? 5.0 : 4.0;
    final baseCellSize = isTablet ? 20.0 : 16.0;
    final dayLabelWidth = isTablet ? 17.0 : 14.0;

    final dayLabels = _heatmapDayLabels(); // 월/수/금 (index 0,2,4)

    return LayoutBuilder(
      builder: (context, constraints) {
        // 아이패드 가로 모드에서는 남는 폭만큼 셀을 키워서 히트맵이 꽉 차 보이게 함
        // (세로/아이폰은 기존 고정 셀 크기 그대로).
        var gap = baseGap;
        var cellSize = baseCellSize;
        if (isLandscape && weeks.isNotEmpty && constraints.maxWidth.isFinite) {
          final availableWidth = constraints.maxWidth - dayLabelWidth - baseGap;
          final filledCellSize =
              (availableWidth - (weeks.length - 1) * gap) / weeks.length;
          cellSize = filledCellSize.clamp(baseCellSize, 30.0);
        }
        final totalWidth = weeks.isEmpty
            ? 0.0
            : (weeks.length * cellSize) + ((weeks.length - 1) * gap);

        // 고정 요일 레이블 (스크롤 밖)
        final dayLabelColumn = Padding(
          padding: EdgeInsets.only(right: gap),
          child: Column(
            children: List.generate(7, (i) {
              final label = (i == 0 || i == 2 || i == 4) ? dayLabels[i] : '';
              return Padding(
                padding: EdgeInsets.only(bottom: i < 6 ? gap : 0),
                child: SizedBox(
                  width: dayLabelWidth,
                  height: cellSize,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isTablet ? 11 : 9,
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
                                  right:
                                      weekIndex == weeks.length - 1 ? 0 : gap,
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
                                      if (dayIndex !=
                                          weeks[weekIndex].length - 1)
                                        SizedBox(
                                            height:
                                                gap), // ignore: prefer_const_constructors
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 13 : 10),
                        SizedBox(
                          width: totalWidth,
                          height: isTablet ? 22 : 18,
                          child: Stack(
                            children: [
                              for (final label
                                  in _spacedMonthLabels(monthLabels))
                                Positioned(
                                  left: (label['week_index'] as int) *
                                      (cellSize + gap),
                                  child: Text(
                                    _formatHeatmapMonthLabel(
                                        label['date'] as DateTime),
                                    style: TextStyle(
                                      fontSize: isTablet ? 13.5 : 11.5,
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
            SizedBox(height: isTablet ? 13 : 10),
            Text(
              l10n.recordsActivityHeatmapCaption,
              style: TextStyle(
                fontSize: isTablet ? 13.5 : 11.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        );
      },
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
    if (languageCode == 'zh') {
      return ['一', '二', '三', '四', '五', '六', '日'];
    }
    if (languageCode == 'es') {
      return ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
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
    if (languageCode == 'zh') return '${date.month}月';
    return DateFormat.MMM(Localizations.localeOf(context).toString())
        .format(date);
  }

  String _formatHeatmapTooltipDate(DateTime date) {
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(date);
  }
}
