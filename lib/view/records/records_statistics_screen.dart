import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sudoku159/constants/records_level_filter.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/navigation/root_nav_scope.dart';
import 'package:sudoku159/navigation/tab_scroll_controller.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/home/home_dashboard_service.dart';
import 'package:sudoku159/services/records/game_record_notifier.dart';
import 'package:sudoku159/services/records/records_statistics_service.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/theme/system_ui_style.dart';
import 'package:sudoku159/utils/time_format.dart';
import 'package:sudoku159/view/challenge/challenge_monthly_calendar_card.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:sudoku159/widgets/app_snackbar.dart';
import 'package:sudoku159/widgets/loading_skeleton.dart';
import 'package:sudoku159/widgets/mascot_image.dart';
import 'package:sudoku159/widgets/press_scale.dart';
import 'package:sudoku159/widgets/sudoku_motif.dart';

class RecordsStatisticsScreen extends StatefulWidget {
  const RecordsStatisticsScreen({
    super.key,
    this.statisticsService,
    this.challengeProgressService,
    this.homeDashboardService,
    this.databaseHelper,
    this.tabScrollController,
  });

  /// 테스트에서 저장소를 대체하기 위한 선택적 주입. 기본값은 실제 구현.
  final RecordsStatisticsService? statisticsService;
  final ChallengeProgressService? challengeProgressService;
  final HomeDashboardService? homeDashboardService;
  final DatabaseHelper? databaseHelper;

  /// 하단 기록 탭을 다시 눌렀을 때 이 화면을 최상단으로 스크롤하도록
  /// 연결하는 콜백 창구. [MyHomePage]가 탭별로 하나씩 만들어 전달한다.
  final TabScrollController? tabScrollController;

  @override
  State<RecordsStatisticsScreen> createState() =>
      _RecordsStatisticsScreenState();
}

class _RecordsStatisticsScreenState extends State<RecordsStatisticsScreen> {
  /// 하단 플로팅 탭바 여유 — [HomeScreen._kHomeScrollBottomPad] 와 동일.
  static const double _kScrollBottomPad = 116;

  /// 활동 달력이 보여주는 주 수(서비스 호출과 제목 표기를 함께 쓴다).
  static const int _kHeatmapWeeks = 26;

  /// 기록 최상단 히어로 이미지(제목·부제 포함)의 고정 높이(상태바 제외).
  static const double _kRecordsHeroHeightPhone = 185;
  static const double _kRecordsHeroHeightTablet = 220;

  late final RecordsStatisticsService _statisticsService =
      widget.statisticsService ?? RecordsStatisticsService();
  late final ChallengeProgressService _challengeProgressService =
      widget.challengeProgressService ?? ChallengeProgressService();
  late final HomeDashboardService _homeDashboardService =
      widget.homeDashboardService ?? HomeDashboardService();
  late final DatabaseHelper _databaseHelper =
      widget.databaseHelper ?? DatabaseHelper();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _heatmapScrollController = ScrollController();
  bool _isLoading = true;
  bool _hasLoaded = false;
  int _loadRequestId = 0;
  String? _loadErrorMessage;
  String? _selectedWeekDate;
  String? _selectedLevelName;
  String? _selectedHeatmapDateKey;
  int _challengeStreakDays = 0;

  /// 지금까지 완료한 도전이 하나라도 있는지. 일반 퍼즐 기록이 없을 때
  /// 도전 달력을 보여줄지 판단하는 데 쓴다.
  bool _hasChallengeHistory = false;
  bool _isOpeningTodayChallenge = false;
  bool _isOpeningPastChallenge = false;

  /// 히어로 이미지가 스크롤로 완전히 가려지기 전(true)인지 후(false)인지.
  /// 상태 표시줄 아이콘 색을 밝게(사진 위)/테마 기준으로 전환하는 데 쓴다.
  bool _isTop = true;

  Map<String, dynamic> _overall = {};
  List<Map<String, dynamic>> _levels = [];
  List<Map<String, dynamic>> _recent = [];
  Map<String, dynamic> _activitySummary = {};
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadChallengeStreak();
    GameRecordNotifier.instance.version.addListener(_handleRecordsChanged);
    _scrollController.addListener(_handleScrollForStatusBar);
    widget.tabScrollController?.attach(_scrollToTop);
  }

  @override
  void dispose() {
    GameRecordNotifier.instance.version.removeListener(_handleRecordsChanged);
    _scrollController.removeListener(_handleScrollForStatusBar);
    widget.tabScrollController?.detach(_scrollToTop);
    _scrollController.dispose();
    _heatmapScrollController.dispose();
    super.dispose();
  }

  /// 기록 탭을 다시 눌렀을 때 호출된다. 이미 최상단이면 아무 것도 하지
  /// 않고, '동작 줄이기'가 켜져 있으면 애니메이션 없이 바로 이동한다.
  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= 0) return;

    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(0);
      return;
    }

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  double _currentHeroHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).width > 600
          ? _kRecordsHeroHeightTablet
          : _kRecordsHeroHeightPhone;

  /// 히어로가 상태바 영역 뒤로 완전히 넘어가면 밝은(사진 위) 아이콘에서
  /// 테마 기준 아이콘으로 전환한다. [HomeScreen]과 같은 방식.
  void _handleScrollForStatusBar() {
    if (!mounted) return;
    final topInset = MediaQuery.paddingOf(context).top;
    final threshold = _currentHeroHeight(context) - topInset;
    final collapsed = _scrollController.offset >= threshold;
    if (collapsed == _isTop) {
      setState(() => _isTop = !collapsed);
    }
  }

  void _handleRecordsChanged() {
    if (!mounted) return;
    _loadStats();
    _loadChallengeStreak();
  }

  /// 도전 연속은 일반 기록 통계와 별개로 불러온다 — 한쪽이 실패해도 다른
  /// 쪽 표시에 영향을 주지 않게 하기 위함.
  Future<void> _loadChallengeStreak() async {
    try {
      final summary = await _challengeProgressService.load();
      final hasHistory =
          await _challengeProgressService.hasCompletedAnyChallenge();
      if (!mounted) return;
      setState(() {
        _challengeStreakDays = summary.streakDays;
        _hasChallengeHistory = hasHistory;
      });
    } catch (_) {
      // 도전 연속 조회 실패는 조용히 무시한다(0으로 유지).
    }
  }

  SudokuLevel? _levelForName(String levelName) {
    for (final level in SudokuLevel.levels) {
      if (level.name == levelName) return level;
    }
    return null;
  }

  /// 오늘 날짜를 골랐을 때: 탭 시점에 스냅샷을 새로 불러와 오늘의 도전을
  /// 연다. 이어서 날짜가 바뀌었으면 임의로 다른 문제를 열지 않고 새로고침만
  /// 안내한다(`HomeScreen._openTodayChallenge()`와 같은 정책).
  Future<void> _openTodayChallenge() async {
    if (_isOpeningTodayChallenge) return;
    _isOpeningTodayChallenge = true;
    try {
      final l10n = AppLocalizations.of(context)!;
      final data = await _homeDashboardService.load(l10n);
      if (!mounted) return;
      final game = data.todayChallenge;
      final challengeDate = data.challengeProgress.challengeDate;
      final level = game == null ? null : _levelForName(game.levelName);
      if (game == null || challengeDate == null || level == null) {
        showAppSnackBar(context, l10n.homeTodayChallengeLoadError);
        return;
      }
      if (challengeDate !=
          ChallengeProgressService.formatLocalDate(DateTime.now())) {
        showAppSnackBar(context, l10n.homeTodayChallengeDateChanged);
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SudokuGameScreen(
            game: game,
            level: level,
            restoreSavedSession: data.todayChallengeHasSession,
            challengeDate: challengeDate,
          ),
        ),
      );
      if (mounted) {
        _loadStats();
        _loadChallengeStreak();
      }
    } finally {
      _isOpeningTodayChallenge = false;
    }
  }

  /// 월간 달력에서 미래가 아닌 날짜를 눌렀을 때. 오늘 날짜는 오늘의 도전
  /// 흐름을 그대로 쓴다. 과거 날짜는 그 날짜의 실제 타깃 문제를 불러와 열고,
  /// 연속 일수에는 반영되지 않게 표시한다(달력 완료 표시에는 반영됨).
  Future<void> _openChallengeForDate(DateTime date) async {
    final todayStr = ChallengeProgressService.formatLocalDate(DateTime.now());
    final dateStr = ChallengeProgressService.formatLocalDate(date);
    if (dateStr == todayStr) {
      await _openTodayChallenge();
      return;
    }
    if (_isOpeningPastChallenge) return;
    _isOpeningPastChallenge = true;
    try {
      final l10n = AppLocalizations.of(context)!;
      final target = await _challengeProgressService
          .getChallengeTargetForCalendarDay(date);
      final level = _levelForName(target.levelName);
      if (!mounted) return;
      if (level == null) {
        showAppSnackBar(context, l10n.challengePuzzleLoadFailed);
        return;
      }
      final entry = await _databaseHelper.getGameEntry(
        target.levelName,
        target.gameNumber,
      );
      if (!mounted) return;
      if (entry == null) {
        showAppSnackBar(context, l10n.challengePuzzleLoadFailed);
        return;
      }
      final game = SudokuGame(
        board: entry['board'] as List<List<int>>,
        solution: entry['solution'] as List<List<int>>,
        emptyCells: level.emptyCells,
        levelName: target.levelName,
        gameNumber: target.gameNumber,
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SudokuGameScreen(
            game: game,
            level: level,
            restoreSavedSession: true,
            challengeDate: dateStr,
            challengeCountsForStreak: false,
          ),
        ),
      );
      if (mounted) {
        _loadStats();
        _loadChallengeStreak();
      }
    } finally {
      _isOpeningPastChallenge = false;
    }
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

  /// 아직 공개하지 않은 마스터 난이도는 기록 화면에서도 노출하지 않는다.
  List<Map<String, dynamic>> get _displayLevelStats {
    return _statisticsService
        .buildLevelStats(
          levels: _levels,
          recent: _recent,
          selectedLevel: RecordsLevelFilter.allLevels,
        )
        .where((stat) => stat['level_name'] != '마스터')
        .toList(growable: false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final horizontalPad = isTablet ? 24.0 : 16.0;

    final sectionGap = isTablet ? 24.0 : 20.0;

    Widget content;
    if (!_hasLoaded && _loadErrorMessage != null) {
      // 통계 조회 실패는 도전 기록과 별개의 오류다. 통계만 오류로 대체하고
      // 도전 달력은 그대로 쓸 수 있게 둔다.
      content = _buildStatsUnavailableBody(
        l10n,
        _buildLoadError(l10n, _loadErrorMessage!),
        sectionGap,
      );
    } else if (!_hasLoaded) {
      content = _buildInitialLoadingSkeleton(l10n, sectionGap);
    } else if (_recent.isEmpty) {
      // 일반 퍼즐 기록은 없어도 과거에 완료한 도전이 있으면, "기록 없음"
      // 안내 아래에 도전 달력을 이어서 보여준다. 둘 다 없으면 안내 카드만.
      content = _hasChallengeHistory
          ? _buildStatsUnavailableBody(
              l10n, _buildNoGeneralRecords(l10n), sectionGap)
          : _buildNoRecords(l10n);
    } else {
      content = _buildSections(l10n);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 히어로가 보이는 동안(_isTop)은 사진 위라 밝은 상태바 아이콘을
      // 강제하고, 스크롤로 넘어가면 현재 테마 기준으로 전환한다.
      value: systemOverlayStyleFor(
        _isTop ? Brightness.dark : Theme.of(context).brightness,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Stack(
          children: [
            ListView(
              controller: _scrollController,
              // iOS 탄성 스크롤로 최상단에서 히어로 이미지가 아래로 밀려
              // 보이지 않게 클램핑 물리를 쓴다. 당겨서 새로고침은 없애도
              // 되는데, 기록 탭 진입·게임 완료·도전 화면 복귀·기록 변경
              // 알림 경로로 이미 항상 최신 상태를 불러오기 때문이다.
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: _kScrollBottomPad + bottomInset,
              ),
              children: [
                _buildHeaderBanner(l10n, horizontalPad, topInset, isTablet),
                Padding(
                  key: const Key('records_content_padding'),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    isTablet ? 24 : 16,
                    horizontalPad,
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_hasLoaded && _loadErrorMessage != null) ...[
                            _buildLoadError(l10n, _loadErrorMessage!),
                            SizedBox(height: isTablet ? 24 : 16),
                          ],
                          if (_hasLoaded &&
                              _loadErrorMessage == null &&
                              _recent.isNotEmpty) ...[
                            _buildSummaryCard(l10n),
                            SizedBox(height: sectionGap),
                          ],
                          content,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading && _hasLoaded)
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

  /// 기록 최상단 히어로 이미지: 보관실에서 완료 기록을 살펴보는 캐릭터
  /// 일러스트 위에 '기록' 제목과 부제를 겹쳐 보여준다. 상태바 영역까지
  /// 이미지를 확장하고, 본문과 함께 스크롤된다.
  Widget _buildHeaderBanner(
    AppLocalizations l10n,
    double horizontalPad,
    double topInset,
    bool isTablet,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentHeight = _currentHeroHeight(context);
    final height = topInset + contentHeight;

    return SizedBox(
      key: const Key('records_hero_header'),
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              'assets/images/records_hero.webp',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
          // 상태 표시줄 가독성을 위한 위쪽 어두운 그라데이션. 다크 모드에서는
          // 오버레이를 10~15%p 더 진하게 적용한다.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: isDark ? 0.58 : 0.45),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.42],
              ),
            ),
          ),
          // 제목·부제 가독성을 위한 좌측 어두운 그라데이션.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: isDark ? 0.55 : 0.42),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.68],
              ),
            ),
          ),
          // 하단은 화면 배경색으로 자연스럽게 이어진다.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: contentHeight * 0.34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: horizontalPad,
            right: isTablet ? 260 : 150,
            bottom: 20,
            child: Semantics(
              header: true,
              child: Text(
                l10n.recordsHeroImageSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                ),
              ),
            ),
          ),
        ],
      ),
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
    final challenge = _buildChallengeSection(l10n);
    final calendar = _buildCalendarSection(l10n, heatmap);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 넓은 화면에서만 2칼럼. 좁아지면 단일 칼럼으로 돌아간다.
        if (constraints.maxWidth >= 860) {
          return Row(
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
                    challenge,
                  ],
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            week,
            const SizedBox(height: 20),
            levels,
            const SizedBox(height: 20),
            calendar,
            const SizedBox(height: 20),
            challenge,
          ],
        );
      },
    );
  }

  /// 통계(요약·이번 주·난이도별·플레이 활동)를 보여줄 수 없는 상태에서도
  /// 도전 기록은 그대로 쓸 수 있게 둔다.
  Widget _buildStatsUnavailableBody(
    AppLocalizations l10n,
    Widget statsBody,
    double sectionGap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        statsBody,
        SizedBox(height: sectionGap),
        _buildChallengeSection(l10n),
      ],
    );
  }

  Widget _buildInitialLoadingSkeleton(
    AppLocalizations l10n,
    double sectionGap,
  ) {
    return Column(
      key: const Key('records_initial_skeleton'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeletonPulse(
          key: const Key('records_skeleton_pulse'),
          builder: (context, color) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummarySkeleton(color),
              SizedBox(height: sectionGap),
              _buildWeekSkeleton(color),
              SizedBox(height: sectionGap),
              _buildSectionSkeleton(color, rows: 3),
            ],
          ),
        ),
        SizedBox(height: sectionGap),
        _buildChallengeSection(l10n),
        SizedBox(height: sectionGap),
        LoadingSkeletonPulse(
          builder: (context, color) => _buildSectionSkeleton(color, rows: 4),
        ),
      ],
    );
  }

  Widget _buildSummarySkeleton(Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(color: color, width: 96, height: 18),
              const Spacer(),
              SkeletonBox(
                key: const Key('records_skeleton_sample'),
                color: color,
                width: 56,
                height: 56,
                borderRadius: 28,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(color: color, width: 48, height: 24),
                      const SizedBox(height: 6),
                      SkeletonBox(color: color, height: 12),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// '이번 주' 카드와 같은 모양(헤더 + 요일 7개)의 스켈레톤.
  Widget _buildWeekSkeleton(Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: SkeletonBox(color: color, width: 96, height: 18)),
              const SizedBox(width: 12),
              SkeletonBox(
                  color: color, width: 64, height: 56, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: SkeletonBox(
                    color: color,
                    height: 30,
                    borderRadius: 15,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 실제 카드(제목·안내 문구·우측 아이콘이 카드 안에 있는 구조)와 같은
  /// 자리에 제목·설명·아이콘 스켈레톤을 두어, 로딩이 끝나도 제목과 카드가
  /// 크게 움직이지 않게 한다.
  Widget _buildSectionSkeleton(Color color, {required int rows}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SkeletonBox(color: color, width: 116, height: 18),
              ),
              const SizedBox(width: 12),
              SkeletonBox(color: color, width: 20, height: 20, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 4),
          SkeletonBox(color: color, width: 180, height: 14),
          const SizedBox(height: 16),
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: [
                SkeletonBox(color: color, width: 32, height: 32),
                const SizedBox(width: 12),
                Expanded(child: SkeletonBox(color: color, height: 14)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// '도전 기록' 섹션: 재사용된 [ChallengeMonthlyCalendarCard] + 도전
  /// 연속만 보여준다(일반 퍼즐 연속 기록과 구분). 제목·이미지는 카드 바깥에
  /// 중복 표시하지 않고 카드 내부 헤더로 넣는다.
  Widget _buildChallengeSection(AppLocalizations l10n) {
    return ChallengeMonthlyCalendarCard(
      challengeProgressService: _challengeProgressService,
      onOpenDate: _openChallengeForDate,
      headerImage: _sectionIcon(
        Icons.calendar_month_rounded,
        const Key('records_challenge_artwork'),
      ),
      footerText: '${l10n.recordsChallengeStreakLabel} '
          '${l10n.recordsActivityDayCount(_challengeStreakDays)}',
    );
  }

  /// "나의 기록" 요약 카드: 홈 히어로와 다른 화풍의 캐릭터를 반복하지 않고,
  /// 테마 색상을 따르는 스도쿠·체크 모티프로 기록 화면의 성격을 보여준다.
  Widget _buildSummaryCard(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final palette = LevelStatusPalette.of(context);
    final totalCleared = (_overall['total_cleared'] as num?)?.toInt() ?? 0;
    final perfectClears = (_overall['perfect_clears'] as num?)?.toInt() ?? 0;
    final currentStreak =
        (_activitySummary['current_streak_days'] as num?)?.toInt() ?? 0;

    final title = Text(
      l10n.recordsMyRecordTitle,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    );

    return ClipRRect(
      key: const Key('records_summary_card'),
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.completedBackground,
          border: Border.all(color: palette.completedBorder),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            // LayoutBuilder가 카드 내부 Padding(16)보다 바깥이라, 패딩
            // 안쪽 폭 기준 임계값과 맞추려면 양쪽 패딩만큼 뺀다.
            final innerWidth = constraints.maxWidth - 32;
            final stackStats = textScale > 1.3 || innerWidth < 300;
            // 좁은 화면·큰 글자에서는 배경 이미지 없이 기존 단색 카드로.
            final showBackgroundImage = !stackStats;
            final reduceMotion = MediaQuery.disableAnimationsOf(context);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final overlayColor = palette.completedBackground;
            final overlayStops =
                isDark ? const [0.97, 0.92, 0.88] : const [0.94, 0.86, 0.70];
            final chipBackground =
                cs.surface.withValues(alpha: isDark ? 0.75 : 0.65);
            final chipTextColor = cs.onSurface.withValues(alpha: 0.85);

            Widget chip(String text) => Container(
                  constraints: const BoxConstraints(minHeight: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: chipBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: chipTextColor,
                    ),
                  ),
                );

            final heroCountText = l10n.recordsSummaryHeroCount(totalCleared);
            final heroDescText = l10n.recordsSummaryHeroDescription;
            final perfectChipText =
                l10n.recordsSummaryPerfectChip(perfectClears);
            final streakChipText = l10n.recordsSummaryStreakChip(currentStreak);
            final heroSemanticLabel =
                l10n.recordsSummaryHeroSemanticLabel(totalCleared);

            final body = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                title,
                const SizedBox(height: 12),
                // 대표 기록(완료한 퍼즐 수)이 가장 먼저 눈에 들어오도록 한
                // 덩어리로 묶고, 접근성 라벨도 하나의 문장으로 합친다.
                Semantics(
                  label: heroSemanticLabel,
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 150),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeOut,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Text(
                            heroCountText,
                            key: ValueKey(heroCountText),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: palette.primaryPurple,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          heroDescText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    chip(perfectChipText),
                    chip(streakChipText),
                  ],
                ),
              ],
            );

            final content = Padding(
              padding: const EdgeInsets.all(16),
              child: showBackgroundImage
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        // 오른쪽 30%는 배경 이미지(메달·노트)가 보이는
                        // 여백으로 비워, 텍스트와 이미지가 겹치지 않게 한다.
                        widthFactor: 0.7,
                        child: body,
                      ),
                    )
                  : body,
            );

            if (!showBackgroundImage) return content;

            return Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: Image.asset(
                      'assets/images/records_summary_card_bg.png',
                      key: const Key('records_summary_card_bg'),
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          overlayColor.withValues(alpha: overlayStops[0]),
                          overlayColor.withValues(alpha: overlayStops[1]),
                          overlayColor.withValues(alpha: overlayStops[2]),
                        ],
                      ),
                    ),
                  ),
                ),
                content,
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── 공통 조각 ────────────────────────────────────────────────────────────

  /// 히어로에 이미 캐릭터가 있으므로, 섹션 제목 옆에는 캐릭터를 반복하지
  /// 않고 성격을 나타내는 아이콘만 20px로 보여준다.
  Widget _sectionIcon(IconData icon, Key key) {
    return ExcludeSemantics(
      key: key,
      child: Icon(
        icon,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// 동작 줄이기에서는 AnimatedSize 자체를 쓰지 않는다(지속 시간 0인
  /// AnimatedSize 안에 지속 시간 0인 AnimatedSwitcher/TweenAnimationBuilder를
  /// 중첩하면, 레이아웃 단계에서 자기 자신을 다시 더럽히는 Flutter의
  /// 재진입 오류가 난다 — 애니메이션이 없을 땐 감쌀 이유도 없다).
  Widget _maybeAnimatedSize({
    required bool reduceMotion,
    required Duration duration,
    required Widget child,
  }) {
    if (reduceMotion) return child;
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: child,
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
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

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RecordCardHeader(
            title: l10n.recordsPlayInsightsTitle,
            subtitle: l10n.recordsWeekSubtitle,
            trailing: _sectionIcon(
              Icons.query_stats_rounded,
              const Key('records_week_artwork'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: _buildWeekDay(l10n, day, locale, reduceMotion),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: cs.outlineVariant),
          const SizedBox(height: 12),
          _maybeAnimatedSize(
            reduceMotion: reduceMotion,
            duration: const Duration(milliseconds: 180),
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 170),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: summary != null
                  ? Text(
                      summary,
                      key: ValueKey('week-summary-$_selectedWeekDate'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    )
                  : Wrap(
                      key: const ValueKey('week-summary-overall'),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDay(
    AppLocalizations l10n,
    Map<String, dynamic> day,
    String locale,
    bool reduceMotion,
  ) {
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

    return _WeekDayCell(
      date: date,
      locale: locale,
      isToday: isToday,
      isSelected: isSelected,
      done: done,
      clears: clears,
      reduceMotion: reduceMotion,
      semanticsLabel: semantics,
      todayLabel: l10n.recordsTrendTodayLabel,
      onTap: () => setState(() {
        _selectedWeekDate = isSelected ? null : day['date_key'] as String?;
      }),
    );
  }

  // ─── 난이도별 기록 ────────────────────────────────────────────────────────

  Widget _buildLevelChip(
    AppLocalizations l10n, {
    required String levelName,
    required bool isSelected,
    required LevelStatusPalette palette,
    required ColorScheme cs,
  }) {
    return ChoiceChip(
      label: Text(levelName.localizedSudokuLevelName(l10n)),
      labelStyle: TextStyle(
        color: isSelected ? palette.primaryPurple : cs.onSurfaceVariant,
      ),
      selected: isSelected,
      checkmarkColor: palette.primaryPurple,
      backgroundColor: cs.surface,
      selectedColor: palette.completedBackground,
      side: BorderSide(
        color: isSelected ? palette.completedBorder : cs.outlineVariant,
      ),
      onSelected: (_) => setState(() => _selectedLevelName = levelName),
    );
  }

  Widget _buildLevelSection(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final palette = LevelStatusPalette.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final statTransitionDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 170);
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

    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
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
                // 평균 실수는 경고색이 아니라 다른 값과 같은 중립색을 쓴다.
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RecordCardHeader(
            title: l10n.recordsByLevelTitle,
            subtitle: l10n.recordsByLevelSubtitle,
            trailing: _sectionIcon(
              Icons.leaderboard_rounded,
              const Key('records_level_artwork'),
            ),
          ),
          const SizedBox(height: 16),
          // 긴 번역에서는 가로 스크롤.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in stats) ...[
                  _buildLevelChip(
                    l10n,
                    levelName: s['level_name'] as String,
                    isSelected: s['level_name'] == selectedName,
                    palette: palette,
                    cs: cs,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: cs.outlineVariant),
          const SizedBox(height: 16),
          _maybeAnimatedSize(
            reduceMotion: reduceMotion,
            duration: statTransitionDuration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 난이도 이름·완료/전체 수만 크로스페이드한다. 진행률 바는
                // 아래에서 별도로(재생성 없이) 이전 값→새 값 채움 전환한다.
                AnimatedSwitcher(
                  duration: statTransitionDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Column(
                    key: ValueKey('level-stat-header-$selectedName'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.recordsMetricClearRate,
                              style: TextStyle(
                                  fontSize: 14, color: cs.onSurfaceVariant),
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
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  // 크로스페이드 블록 밖의 안정된 위젯이라, 재생성 없이
                  // 난이도를 바꿀 때마다 이전 값에서 새 값으로 채움이
                  // 부드럽게 전환된다(숫자 카운트업은 쓰지 않음).
                  child: TweenAnimationBuilder<double>(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(
                      end: total > 0 ? (cleared / total).clamp(0.0, 1.0) : 0,
                    ),
                    builder: (context, value, _) => LinearProgressIndicator(
                      minHeight: 6,
                      value: value,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        palette.primaryPurple,
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: statTransitionDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Column(
                    key: ValueKey('level-stat-rows-$selectedName'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!hasRecords) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.recordsLevelEmpty,
                          style: TextStyle(
                              fontSize: 14, color: cs.onSurfaceVariant),
                        ),
                      ],
                      row(Icons.emoji_events_outlined, l10n.recordsRowBestTime,
                          time(stat['best_time'] as num?)),
                      row(Icons.timer_outlined, l10n.recordsMetricAvgTime,
                          time(stat['average_time'] as num?)),
                      row(Icons.rule_rounded, l10n.recordsMetricAvgWrong,
                          avgWrongLabel),
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
            ),
          ),
        ],
      ),
    );
  }

  // ─── 활동 달력 ────────────────────────────────────────────────────────────

  Widget _buildCalendarSection(
    AppLocalizations l10n,
    Map<String, dynamic> heatmap,
  ) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final best = _activitySummary['best_streak_days'] as int? ?? 0;
    final weeks = (heatmap['weeks'] as List<dynamic>? ?? const <dynamic>[])
        .cast<List<Map<String, dynamic>>>();
    Map<String, dynamic>? selectedDay;
    for (final week in weeks) {
      for (final d in week) {
        if (d['date_key'] == _selectedHeatmapDateKey) selectedDay = d;
      }
    }
    final locale = Localizations.localeOf(context).toString();
    final selectionText = selectedDay == null
        ? null
        : '${_formatHeatmapTooltipDate(selectedDay['date'] as DateTime)} · '
            '${l10n.recordsActivityClearCount(selectedDay['clears'] as int? ?? 0)}';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RecordCardHeader(
            title: l10n.recordsCalendarTitle,
            subtitle: l10n.recordsCalendarSubtitle,
            trailing: _sectionIcon(
              Icons.grid_view_rounded,
              const Key('records_calendar_artwork'),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.recordsCalendarPeriod(_kHeatmapWeeks),
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _buildActivityHeatmap(l10n, heatmap),
          const SizedBox(height: 10),
          _buildHeatmapLegend(l10n),
          const SizedBox(height: 12),
          Divider(height: 1, color: cs.outlineVariant),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 150),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: selectionText != null
                ? Text(
                    selectionText,
                    key: ValueKey('heatmap-selection-$locale-'
                        '$_selectedHeatmapDateKey'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  )
                // 현재 연속은 위쪽 요약 카드에 이미 있으므로, 여기는 최고
                // 연속만.
                : Text(
                    '${l10n.recordsActivityBestStreakLabel} '
                    '${l10n.recordsActivityDayCount(best)}',
                    key: const ValueKey('heatmap-selection-none'),
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
          ),
        ],
      ),
    );
  }

  /// 완료 횟수별 색상 범례. 0(없음)부터 4+(가장 많음)까지 다섯 단계를
  /// 실제 셀과 같은 색으로 보여준다.
  Widget _buildHeatmapLegend(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    Widget swatch(int intensity, String label) {
      final color = _activityHeatColorForIntensity(intensity);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      );
    }

    return ExcludeSemantics(
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: [
          swatch(0, '0'),
          swatch(1, '1'),
          swatch(2, '2'),
          swatch(3, '3'),
          swatch(4, '4+'),
        ],
      ),
    );
  }

  // ─── 상태 화면 ────────────────────────────────────────────────────────────

  /// 전체 완료 기록이 하나도 없을 때: 화면 중앙에 떠 있는 큰 블록 대신,
  /// 다른 섹션과 같은 카드 하나로 줄여서 보여준다.
  Widget _buildNoRecords(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 펭귄 옆에 작은 스도쿠 종이: 첫 기록을 기다리는 장면(장식).
            ExcludeSemantics(
              child: SizedBox(
                width: 110,
                height: 90,
                child: Stack(
                  children: [
                    const Positioned(
                      left: 0,
                      bottom: 0,
                      child: MascotImage(
                        asset: MascotImage.welcome,
                        size: 82,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 4,
                      child: Transform.rotate(
                        angle: 0.09,
                        child: const SudokuMotif(size: 34),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.recordsEmptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.4, color: cs.onSurface),
            ),
            const SizedBox(height: 16),
            FilledButton(
              // 홈의 실제 게임 시작 경로(홈 탭)로 이동한다.
              onPressed: () => RootNavScope.maybeOf(context)?.goToTab(0),
              style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
              child: Text(l10n.recordsEmptyAction),
            ),
          ],
        ),
      ),
    );
  }

  /// 일반 퍼즐 기록은 없지만 과거 도전 완료 기록은 있는 경우: "기록이 전혀
  /// 없다"는 [_buildNoRecords]와 다른 문구를 쓰고, 아래에 도전 달력이
  /// 이어진다는 걸 보조 문구로 알려준다.
  Widget _buildNoGeneralRecords(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: SizedBox(
                width: 110,
                height: 90,
                child: Stack(
                  children: [
                    const Positioned(
                      left: 0,
                      bottom: 0,
                      child: MascotImage(
                        asset: MascotImage.welcome,
                        size: 82,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 4,
                      child: Transform.rotate(
                        angle: 0.09,
                        child: const SudokuMotif(size: 34),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.recordsEmptyGeneralOnlyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.recordsEmptyGeneralOnlySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => RootNavScope.maybeOf(context)?.goToTab(0),
              style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
              child: Text(l10n.recordsEmptyAction),
            ),
          ],
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
    final isFuture = day['is_future'] == true;
    final dateKey = day['date_key'] as String?;
    final isSelected = dateKey != null && dateKey == _selectedHeatmapDateKey;
    final label = '${_formatHeatmapTooltipDate(day['date'] as DateTime)} · '
        '${l10n.recordsActivityClearCount(clears)}';

    return Tooltip(
      message: label,
      child: Semantics(
        button: !isFuture,
        enabled: !isFuture,
        selected: isSelected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isFuture
              ? null
              : () => setState(() {
                    _selectedHeatmapDateKey = isSelected ? null : dateKey;
                  }),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _activityHeatColor(day),
              borderRadius: BorderRadius.circular(4),
              border: isSelected
                  ? Border.all(
                      color: LevelStatusPalette.of(context).primaryPurple,
                      width: 1.5,
                    )
                  : isToday
                      ? Border.all(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                          width: 1,
                        )
                      : null,
            ),
          ),
        ),
      ),
    );
  }

  /// 0(없음)~4+(가장 많음) 강도별 색. 범례와 실제 셀이 같은 색을 쓴다.
  Color _activityHeatColorForIntensity(int intensity) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = LevelStatusPalette.of(context).primaryPurple;
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

  Color _activityHeatColor(Map<String, dynamic> day) {
    final theme = Theme.of(context);
    if (day['is_future'] == true) {
      return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.14);
    }

    final isDark = theme.brightness == Brightness.dark;
    final accent = LevelStatusPalette.of(context).primaryPurple;

    final intensity = day['intensity'] as int? ?? 0;
    if (day['is_today'] == true) {
      if (intensity <= 0) {
        return accent.withValues(alpha: isDark ? 0.30 : 0.20);
      }
      return accent.withValues(alpha: 0.9);
    }
    return _activityHeatColorForIntensity(intensity);
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

/// 기록 화면 카드 공통 헤더(제목 + 안내 문구 + 우측 장식 아이콘). 기록
/// 페이지 안에서만 쓰는 용도로, 다른 화면에서 재사용할 범용 컴포넌트로
/// 확장하지 않는다.
class _RecordCardHeader extends StatelessWidget {
  const _RecordCardHeader({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// '이번 주' 요일 칸. 누르는 동안만 살짝 줄어들고(PressScale), 놓으면
/// 복원된다 — 요일 자체는 애니메이션 없는 정적 이미지가 아니라 눌림
/// 피드백만 준다.
class _WeekDayCell extends StatefulWidget {
  const _WeekDayCell({
    required this.date,
    required this.locale,
    required this.isToday,
    required this.isSelected,
    required this.done,
    required this.clears,
    required this.reduceMotion,
    required this.semanticsLabel,
    required this.todayLabel,
    required this.onTap,
  });

  final DateTime date;
  final String locale;
  final bool isToday;
  final bool isSelected;
  final bool done;
  final int clears;
  final bool reduceMotion;
  final String semanticsLabel;
  final String todayLabel;
  final VoidCallback onTap;

  @override
  State<_WeekDayCell> createState() => _WeekDayCellState();
}

class _WeekDayCellState extends State<_WeekDayCell> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = LevelStatusPalette.of(context).primaryPurple;

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: PressScale(
          pressed: _pressed,
          child: AnimatedContainer(
            duration: widget.reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? LevelStatusPalette.of(context).completedBackground
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.E(widget.locale).format(widget.date),
                  maxLines: 1,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                // 오늘은 테두리, 완료 여부는 채움+체크 아이콘(색만으로 구분하지 않음).
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.done ? accent : Colors.transparent,
                        border: Border.all(
                          color: widget.isToday
                              ? cs.onSurface
                              : widget.done
                                  ? accent
                                  : cs.outlineVariant,
                          width: widget.isToday ? 2 : 1,
                        ),
                      ),
                      child: widget.done
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                    // 하루 2회 이상 완료한 날만 횟수 배지를 붙인다.
                    if (widget.clears >= 2)
                      Positioned(
                        top: -5,
                        right: -7,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: accent, width: 1),
                          ),
                          child: Text(
                            '${widget.clears}',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isToday ? widget.todayLabel : '',
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
      ),
    );
  }
}
