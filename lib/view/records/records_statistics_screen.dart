import 'dart:math';
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sudoku159/constants/records_level_filter.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/navigation/root_nav_scope.dart';
import 'package:sudoku159/navigation/tab_scroll_controller.dart';
import 'package:sudoku159/services/records/game_record_notifier.dart';
import 'package:sudoku159/services/records/recent_completions_service.dart';
import 'package:sudoku159/services/records/records_statistics_service.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/theme/system_ui_style.dart';
import 'package:sudoku159/view/records/recent_completion_tile.dart';
import 'package:sudoku159/view/records/recent_completions_screen.dart';
import 'package:sudoku159/widgets/keep_words_text.dart';
import 'package:sudoku159/widgets/loading_skeleton.dart';

/// 문장 안의 숫자 덩어리에만 [numberStyle]을 적용한다(언어와 무관).
List<InlineSpan> _numberSpans(String text, TextStyle numberStyle) {
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in RegExp(r'\d+').allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    spans.add(TextSpan(text: m.group(0), style: numberStyle));
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

/// 문장 안의 숫자만 굵게 만든다(언어와 무관하게 숫자 덩어리를 찾는다).
List<InlineSpan> _boldNumberSpans(String text) {
  final spans = <InlineSpan>[];
  var last = 0;
  for (final m in RegExp(r'\d+').allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start)));
    }
    spans.add(TextSpan(
      text: m.group(0),
      style: const TextStyle(fontWeight: FontWeight.w800),
    ));
    last = m.end;
  }
  if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  return spans;
}

/// 한글 단어 안(한글·숫자 사이)에 줄바꿈 금지 문자(U+2060)를 넣어, 강조 숫자가
/// 섞인 문장도 "풀었/어요"처럼 단어 중간에서 끊기지 않고 띄어쓰기에서만 줄을
/// 바꾸게 한다. 일본어·중국어는 글자 사이 줄바꿈이 자연스러우므로 숫자와 바로
/// 뒤의 단위("17/問")만 붙여 두고, 영어·스페인어는 그대로 둔다.
String _keepWordsTogether(String text) => text.replaceAllMapped(
      RegExp(
          r'(?<=[가-힣])(?=[가-힣0-9])|(?<=[0-9])(?=[가-힣\u3040-\u30FF\u4E00-\u9FFF])'),
      (_) => '\u2060',
    );

class RecordsStatisticsScreen extends StatefulWidget {
  const RecordsStatisticsScreen({
    super.key,
    this.statisticsService,
    this.tabScrollController,
    this.random,
  });

  /// 테스트에서 저장소를 대체하기 위한 선택적 주입. 기본값은 실제 구현.
  final RecordsStatisticsService? statisticsService;

  /// 하단 기록 탭을 다시 눌렀을 때 이 화면을 최상단으로 스크롤하도록
  /// 연결하는 콜백 창구. [MyHomePage]가 탭별로 하나씩 만들어 전달한다.
  final TabScrollController? tabScrollController;

  /// 요약 카드 보조 문장을 고르는 난수. 테스트에서만 고정값을 넣는다.
  @visibleForTesting
  final Random? random;

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
  final ScrollController _scrollController = ScrollController();
  final ScrollController _heatmapScrollController = ScrollController();
  bool _hasLoaded = false;
  int _loadRequestId = 0;
  String? _loadErrorMessage;

  /// 선택한 난이도. 탭할 때 화면 전체가 아니라 난이도 섹션만 다시 그리도록
  /// [ValueNotifier]로 둔다: 전체 화면 리빌드(수백 ms)가 한 프레임에 몰리면 선택
  /// 배경 이동 애니메이션이 시작 시점부터 이미 대부분 지나가 버려 "순간 이동"처럼
  /// 보인다(Ticker는 시작한 프레임의 시각을 기준으로 시간을 센다).
  final ValueNotifier<String?> _selectedLevel = ValueNotifier<String?>(null);
  String? get _selectedLevelName => _selectedLevel.value;

  String? _selectedHeatmapDateKey;

  /// 히어로 이미지가 스크롤로 완전히 가려지기 전(true)인지 후(false)인지.
  /// 상태 표시줄 아이콘 색을 밝게(사진 위)/테마 기준으로 전환하는 데 쓴다.
  bool _isTop = true;

  Map<String, dynamic> _overall = {};
  List<Map<String, dynamic>> _levels = [];
  List<Map<String, dynamic>> _recent = [];
  Map<String, dynamic> _activitySummary = {};

  /// 요약 카드 보조 문장 후보 중 무엇을 보일지. 불러올 때마다 새로 고른다.
  late final Random _random = widget.random ?? Random();
  int _summarySupportPick = 0;
  List<Map<String, dynamic>> _events = [];
  List<RecentCompletion> _recentCompletions = const [];

  /// 최근 완료 한 줄을 연 뒤 확인창·게임 화면이 닫힐 때까지 중복 실행을 막는다.
  bool _openingRecent = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
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
    _selectedLevel.dispose();
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
  }

  Future<void> _loadStats() async {
    final requestId = ++_loadRequestId;
    setState(() {
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
          _recentCompletions = data.recentCompletions;
          _summarySupportPick = _random.nextInt(1 << 16);
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
      content = _buildLoadError(l10n, _loadErrorMessage!);
    } else if (!_hasLoaded) {
      content = _buildInitialLoadingSkeleton(l10n, sectionGap);
    } else if (_recent.isEmpty) {
      // 기록이 없으면 요약 카드가 빈 상태 안내 역할을 한다(아래 카드 없음).
      content = const SizedBox.shrink();
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
                          if (_hasLoaded && _loadErrorMessage == null) ...[
                            _buildSummaryCard(l10n),
                            if (_recent.isNotEmpty)
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
              child: KeepWordsText(
                l10n.recordsHeroImageSubtitle,
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
    // 난이도 선택은 이 섹션만 다시 그린다(위 설명 참고).
    final levels = ValueListenableBuilder<String?>(
      valueListenable: _selectedLevel,
      builder: (context, _, __) => _buildLevelSection(l10n),
    );
    final calendar = _buildCalendarSection(l10n, heatmap);
    final recent =
        _recentCompletions.isEmpty ? null : _buildRecentSection(l10n);

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
                  children: [
                    week,
                    const SizedBox(height: 24),
                    levels,
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    calendar,
                    if (recent != null) ...[
                      const SizedBox(height: 24),
                      recent,
                    ],
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
            if (recent != null) ...[
              const SizedBox(height: 20),
              recent,
            ],
          ],
        );
      },
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

  /// 기록 상단 요약 카드: 상세 통계가 아니라 "지금까지 쌓은 성과"를 한 문장으로
  /// 전하는 카드. 배경 이미지(기록장·메달)는 오른쪽 약 45%에서 분위기를 보조하고
  /// 글은 왼쪽 55% 안에 둔다(메달이 카드 폭의 55~62%에 있다). 값 비교용 상세
  /// 수치는 아래 기록 카드들이 맡는다. 기록이 없으면 같은 카드가 빈 상태가 된다.
  Widget _buildSummaryCard(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final palette = LevelStatusPalette.of(context);
    final isEmpty = _recent.isEmpty;
    final totalCleared = (_overall['total_cleared'] as num?)?.toInt() ?? 0;
    final perfectClears = (_overall['perfect_clears'] as num?)?.toInt() ?? 0;
    final currentStreak =
        (_activitySummary['current_streak_days'] as num?)?.toInt() ?? 0;
    final activeDays = (_activitySummary['active_days'] as num?)?.toInt() ?? 0;

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
            // 카드 안쪽 폭(패딩 16×2 제외). 큰 글씨·좁은 화면에서는 글이 전체
            // 폭을 쓰고 이미지는 이미지를 숨기지 않고 옅은 배경으로만 남긴다.
            final innerWidth = constraints.maxWidth - 32;
            final faintImage = textScale > 1.3 || innerWidth < 300;
            final reduceMotion = MediaQuery.disableAnimationsOf(context);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final overlay = palette.completedBackground;

            // ── 문구(전체 문장은 번역 키로 받는다) ──────────────────────────
            // 완료 수의 의미로 고른다: 첫 완료 → 10의 배수 달성 → 2~9 → 11~29 → 30+.
            final heroSentence = totalCleared == 1
                ? l10n.recordsSummaryHeroFirst
                : (totalCleared > 0 && totalCleared % 10 == 0)
                    ? l10n.recordsSummaryHeroMilestone(totalCleared)
                    : totalCleared <= 9
                        ? l10n.recordsSummaryHeroSentence(totalCleared)
                        : totalCleared <= 29
                            ? l10n.recordsSummaryHeroGrowing(totalCleared)
                            : l10n.recordsSummaryHeroStacked(totalCleared);
            // 보조 문장 후보: 실수 없이 완료(없으면 제외)와 플레이 습관. 문장과
            // 짧은 표기가 한 줄에 섞이지 않도록 둘 중 한 문장만 보여 주고,
            // 불러올 때마다 무작위로 고른다.
            final String? qualityText = perfectClears <= 0
                ? null
                : (totalCleared > 0 && perfectClears >= totalCleared)
                    ? l10n.recordsSummaryAllPerfect
                    : l10n.recordsSummaryPartialPerfect(perfectClears);
            // 연속 2일 이상이면 연속, 아니면 플레이 일수.
            final String? habitText = currentStreak >= 2
                ? l10n.recordsSummaryStreakPlaying(currentStreak)
                : (activeDays > 0
                    ? l10n.recordsSummaryPlayDays(activeDays)
                    : null);
            final supportCandidates = [
              if (qualityText != null) qualityText,
              if (habitText != null) habitText,
            ];
            final supportTexts = supportCandidates.isEmpty
                ? const <String>[]
                : [
                    supportCandidates[
                        _summarySupportPick % supportCandidates.length],
                  ];

            final labelStyle = TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            );
            final supportStyle = TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.85),
            );

            Widget headBlock;
            Widget? supportBlock;
            String switchKey;
            if (isEmpty) {
              // 빈 상태: 0개를 크게 보이지 않고 첫 기록을 권한다(버튼은 여기 한 곳).
              switchKey = 'empty';
              headBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.recordsSummaryEmptyTitle, style: labelStyle),
                  const SizedBox(height: 6),
                  KeepWordsText(
                    l10n.recordsSummaryEmptyBody,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => RootNavScope.maybeOf(context)?.goToTab(0),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      l10n.recordsEmptyAction,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            } else {
              switchKey = '$heroSentence|${supportTexts.join('|')}';
              // 숫자만 크게(30~32px), 나머지는 같은 문장 안에서 17px.
              final heroStyle = TextStyle(
                fontSize: 17,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.85),
              );
              headBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.recordsMyRecordTitle, style: labelStyle),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: heroStyle,
                      children: _numberSpans(
                        _keepWordsTogether(heroSentence),
                        TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: palette.primaryPurple,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ],
              );
              if (supportTexts.isNotEmpty) {
                supportBlock = Text.rich(
                  TextSpan(
                    style: supportStyle,
                    children: _boldNumberSpans(
                      _keepWordsTogether(supportTexts.single),
                    ),
                  ),
                );
              }
            }

            Widget body = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: faintImage ? 1 : 0.55,
                    child: headBlock,
                  ),
                ),
                if (supportBlock != null) ...[
                  const SizedBox(height: 14),
                  supportBlock,
                ],
              ],
            );
            if (!isEmpty) {
              body = Semantics(
                container: true,
                label: [heroSentence, ...supportTexts].join('. '),
                excludeSemantics: true,
                child: body,
              );
            }
            // 데이터가 바뀌었을 때만 짧게 페이드: 같은 값으로 재조회하면 그대로.
            final content = Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: KeyedSubtree(key: ValueKey(switchKey), child: body),
              ),
            );

            // ── 배경: 이미지는 유지하되 글을 덮는 쪽만 진하게 ────────────────
            final LinearGradient sideOverlay;
            if (isDark) {
              sideOverlay = LinearGradient(
                colors: faintImage
                    ? [
                        overlay.withValues(alpha: 0.95),
                        overlay.withValues(alpha: 0.95),
                      ]
                    : [
                        overlay.withValues(alpha: 0.97),
                        overlay.withValues(alpha: 0.92),
                        overlay.withValues(alpha: 0.88),
                      ],
              );
            } else if (faintImage) {
              // 큰 글씨: 이미지는 워터마크 수준으로만 남긴다.
              sideOverlay = LinearGradient(
                colors: [
                  overlay.withValues(alpha: 0.9),
                  overlay.withValues(alpha: 0.9),
                ],
              );
            } else {
              // 왼쪽 글 영역은 진하게, 55~62% 구간에서 빠르게 낮춰 메달과
              // 기록장이 오른쪽에서 선명하게 보이게 한다.
              sideOverlay = LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  overlay.withValues(alpha: 0.96),
                  overlay.withValues(alpha: 0.84),
                  overlay.withValues(alpha: 0.45),
                  overlay.withValues(alpha: 0.40),
                ],
                stops: const [0.0, 0.5, 0.62, 1.0],
              );
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: Image.asset(
                      'assets/images/records_summary_card_bg.png',
                      key: const Key('records_summary_card_bg'),
                      fit: BoxFit.cover,
                      // 카드가 낮아져 세로가 잘릴 때 꽃보다 노트·메달이 남도록 중앙보다
                      // 조금 아래를 기준으로 한다.
                      alignment: const Alignment(1.0, 0.3),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: sideOverlay),
                  ),
                ),
                // 하단 보조 문구가 이미지 위에서도 읽히도록 아래쪽만 옅게 덮는다.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          overlay.withValues(alpha: 0),
                          overlay.withValues(alpha: 0.5),
                        ],
                        stops: const [0.55, 1.0],
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

  /// 선택된 난이도 이름. 선택이 없으면 기록이 있는 첫 난이도(없으면 첫 난이도).
  /// 링 선택기와 아래 기록이 같은 값을 쓴다.
  String _resolveSelectedLevelName(List<Map<String, dynamic>> stats) {
    return stats.any((s) => s['level_name'] == _selectedLevelName)
        ? _selectedLevelName!
        : (stats.firstWhere(
            (s) => (s['cleared_count'] as int? ?? 0) > 0,
            orElse: () => stats.first,
          )['level_name'] as String);
  }

  // ─── 난이도 선택 링 ───────────────────────────────────────────────────────

  /// 난이도마다 완료 비율을 원형 링 하나로 보여주고, 누르면 아래 기록이 그
  /// 난이도로 바뀌는 선택기. 링 중앙에는 완료 개수, 아래에는 난이도 이름만
  /// 둔다. 한 줄에 들어가지 않으면 2×2로 바꾼다.
  Widget _buildLevelRingSelector(
    AppLocalizations l10n,
    List<Map<String, dynamic>> stats,
    String selectedName,
  ) {
    final cs = Theme.of(context).colorScheme;
    final palette = LevelStatusPalette.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final maxRing = isTablet ? 84.0 : 60.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 난이도마다 채움색을 달리한다(알 수 없는 난이도는 기본 보라색).
    Color levelColor(String levelName) {
      final (light, dark) = switch (levelName) {
        '초급' => (const Color(0xFF3FA77A), const Color(0xFF5BC79A)),
        '중급' => (const Color(0xFF2E78B7), const Color(0xFF5AB4ED)),
        '고급' => (const Color(0xFFE08A2E), const Color(0xFFF0A24F)),
        '전문가' => (const Color(0xFFD0506B), const Color(0xFFEF7C93)),
        _ => (palette.primaryPurple, palette.primaryPurple),
      };
      return isDark ? dark : light;
    }

    final names = [
      for (final st in stats)
        (st['level_name'] as String).localizedSudokuLevelName(l10n),
    ];
    final labelStyle = DefaultTextStyle.of(context).style.copyWith(
          fontSize: 13,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        );
    final selectDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 180);

    return KeyedSubtree(
      key: const Key('records_level_rings'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 칸 바깥 여백(한쪽) + 선택 배경 안쪽 여백(한쪽).
          const cellMargin = 2.0;
          const cellPadding = 4.0;
          const cellInset = (cellMargin + cellPadding) * 2;
          // 한 줄 배치에서 모든 이름이 2줄 안에 단어 중간이 잘리지 않고
          // 들어오지 않으면 2×2로 바꾼다(글자는 줄이지 않는다).
          final rowLabelWidth = constraints.maxWidth / stats.length - cellInset;
          // 선택된 이름은 더 굵게 그리므로 굵은 글꼴 기준으로 잰다.
          final useGrid = !_levelLabelsFit(
            names,
            style: labelStyle.copyWith(fontWeight: FontWeight.w800),
            scaler: scaler,
            width: rowLabelWidth,
            direction: direction,
          );
          final columns = useGrid ? 2 : stats.length;
          final cellWidth = constraints.maxWidth / columns;

          Widget ring(int i) {
            final stat = stats[i];
            final levelName = stat['level_name'] as String;
            final cleared = stat['cleared_count'] as int? ?? 0;
            final total = stat['total_count'] as int? ?? 0;
            final ratio = total > 0 ? (cleared / total).clamp(0.0, 1.0) : 0.0;
            final size = (cellWidth - cellInset).clamp(0.0, maxRing);
            final isSelected = levelName == selectedName;
            return Semantics(
              container: true,
              button: true,
              selected: isSelected,
              label: l10n.recordsLevelRingSemantics(names[i], cleared, total),
              excludeSemantics: true,
              child: GestureDetector(
                key: Key('records_level_ring_$levelName'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (levelName == _selectedLevelName) return;
                  _selectedLevel.value = levelName;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: cellMargin),
                  child: AnimatedContainer(
                    duration: selectDuration,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: cellPadding,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.filterSelectedBackground
                          : palette.filterSelectedBackground
                              .withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: ratio),
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => SizedBox(
                            width: size,
                            height: size,
                            child: CustomPaint(
                              painter: _ProgressRingPainter(
                                progress: value,
                                trackColor: palette.progressTrack,
                                progressColor: levelColor(levelName),
                                strokeWidth: isTablet ? 8 : 6,
                              ),
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$cleared',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: isTablet ? 17 : 15,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 색만이 아니라 굵기로도 선택을 구분한다.
                        Text(
                          names[i],
                          // 한 줄 배치는 2줄, 2×2에서는 큰 글씨용으로 3줄까지.
                          maxLines: useGrid ? 3 : 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? palette.primaryPurple
                                : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          Widget row(int from, int to) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = from; i < to; i++) Expanded(child: ring(i)),
                ],
              );

          if (!useGrid) return row(0, stats.length);
          return Column(
            children: [
              for (var i = 0; i < stats.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 8),
                row(i, (i + 2).clamp(0, stats.length)),
              ],
            ],
          );
        },
      ),
    );
  }

  /// [names]가 모두 [width] 안에서 단어 중간이 잘리지 않고 2줄 안에 들어오는가.
  bool _levelLabelsFit(
    List<String> names, {
    required TextStyle style,
    required TextScaler scaler,
    required double width,
    required ui.TextDirection direction,
  }) {
    if (width <= 0) return false;
    for (final name in names) {
      final painter = TextPainter(
        text: TextSpan(text: name, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 2,
        ellipsis: '\u2026',
      )..layout(maxWidth: width);
      final exceeds = painter.didExceedMaxLines;
      painter.dispose();
      if (exceeds) return false;
      for (final word in name.split(RegExp(r'\s+'))) {
        final wordPainter = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final tooWide = wordPainter.width > width;
        wordPainter.dispose();
        if (tooWide) return false;
      }
    }
    return true;
  }

  // ─── 이번 주 활동 ─────────────────────────────────────────────────────────

  /// 이번 주(월~일) 7칸. 완료한 날은 체크, 하루 2판 이상은 횟수 배지로 보여
  /// 주므로 합계 줄이나 요일 선택 없이 칸만 둔다.
  Widget _buildWeekSection(
    AppLocalizations l10n,
    Map<String, dynamic> heatmap,
  ) {
    final weeks = (heatmap['weeks'] as List<dynamic>? ?? const <dynamic>[])
        .cast<List<Map<String, dynamic>>>();
    // 마지막 열이 이번 주(월~일).
    final days = weeks.isEmpty ? const <Map<String, dynamic>>[] : weeks.last;
    final locale = Localizations.localeOf(context).toString();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RecordCardHeader(
            title: l10n.recordsPlayInsightsTitle,
            trailing: _sectionIcon(
              Icons.query_stats_rounded,
              const Key('records_week_artwork'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final day in days)
                Expanded(child: _buildWeekDay(l10n, day, locale)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDay(
    AppLocalizations l10n,
    Map<String, dynamic> day,
    String locale,
  ) {
    final date = day['date'] as DateTime;
    final clears = day['clears'] as int? ?? 0;
    final isToday = day['is_today'] == true;
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
      done: done,
      clears: clears,
      semanticsLabel: semantics,
      todayLabel: l10n.recordsTrendTodayLabel,
    );
  }

  // ─── 난이도별 기록 ────────────────────────────────────────────────────────

  Widget _buildLevelSection(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final statTransitionDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 170);
    final stats = _displayLevelStats;
    if (stats.isEmpty) return const SizedBox.shrink();
    final selectedName = _resolveSelectedLevelName(stats);
    final stat = stats.firstWhere((s) => s['level_name'] == selectedName);
    final hasRecords = (stat['cleared_count'] as int? ?? 0) > 0;
    // 빠르기보다 "스스로·정확하게" 풀었는지를 본다. 시간은 다음 판을 고를 때
    // 참고하도록 한 판에 보통 걸리는 시간(중앙값)만 둔다.
    final insight = RecordsStatisticsService.buildLevelInsight(
      levelName: selectedName,
      clearRecords: _recent,
      completions: _recentCompletions,
    );
    final typical = insight.typicalSeconds;

    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
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
                // 값은 오른쪽 끝에 붙인다. "약 7분"처럼 길어질 수 있어 큰 글씨에서는
                // 행의 절반 안에서 줄을 바꾼다.
                ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: constraints.maxWidth / 2),
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
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
          _buildLevelRingSelector(l10n, stats, selectedName),
          const SizedBox(height: 12),
          Divider(height: 1, color: cs.outlineVariant),
          const SizedBox(height: 4),
          _maybeAnimatedSize(
            reduceMotion: reduceMotion,
            duration: statTransitionDuration,
            child: AnimatedSwitcher(
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
                      style:
                          TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                    ),
                  ],
                  if (hasRecords) ...[
                    row(
                      Icons.lightbulb_outline_rounded,
                      l10n.recordsMetricHintFree,
                      '${insight.hintFree} / ${insight.completed}',
                    ),
                    row(
                      Icons.check_circle_outline_rounded,
                      l10n.recordsMetricMistakeFree,
                      '${insight.mistakeFree} / ${insight.completed}',
                    ),
                    if (typical != null)
                      row(
                        Icons.timer_outlined,
                        l10n.recordsMetricTypicalTime,
                        l10n.recordsTypicalTimeValue(
                          (typical / 60).round().clamp(1, 1 << 20),
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 최근 완료 ────────────────────────────────────────────────────────────

  static const int _kRecentVisibleCount = 5;

  Future<void> _openRecent(RecentCompletion entry) async {
    if (_openingRecent) return;
    _openingRecent = true;
    try {
      await openRecentCompletion(context, entry);
    } finally {
      _openingRecent = false;
    }
  }

  /// 최근 완료 5판(다시 푼 판 포함). 더 있으면 전체 목록으로 이어진다.
  Widget _buildRecentSection(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final entries = _recentCompletions;
    final visible = entries.take(_kRecentVisibleCount).toList();
    return KeyedSubtree(
      key: const Key('records_recent'),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RecordCardHeader(
              title: l10n.recordsRecentTitle,
              subtitle: l10n.recordsRecentSubtitle,
              trailing: _sectionIcon(
                Icons.history_rounded,
                const Key('records_recent_artwork'),
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) Divider(height: 1, color: cs.outlineVariant),
              RecentCompletionTile(
                entry: visible[i],
                onTap: () => _openRecent(visible[i]),
              ),
            ],
            if (entries.length > _kRecentVisibleCount) ...[
              Divider(height: 1, color: cs.outlineVariant),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('records_recent_view_all'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RecentCompletionsScreen(),
                    ),
                  ),
                  child: Text(l10n.recordsRecentViewAll(entries.length)),
                ),
              ),
            ],
          ],
        ),
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
            title: l10n.recordsCalendarTitle(_kHeatmapWeeks),
            subtitle: l10n.recordsCalendarSubtitle,
            trailing: _sectionIcon(
              Icons.grid_view_rounded,
              const Key('records_calendar_artwork'),
            ),
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
                                  // 오른쪽 끝 열에서 시작하는 달 라벨은 잘리지 않게
                                  // 오른쪽 끝에 맞춘다.
                                  left: (label['week_index'] as int) >=
                                          weeks.length - 2
                                      ? null
                                      : (label['week_index'] as int) *
                                          (cellSize + gap),
                                  right: (label['week_index'] as int) >=
                                          weeks.length - 2
                                      ? 0
                                      : null,
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

/// '이번 주' 요일 칸(표시 전용). 완료한 날은 채움+체크, 오늘은 테두리, 하루
/// 2판 이상은 횟수 배지.
class _WeekDayCell extends StatelessWidget {
  const _WeekDayCell({
    required this.date,
    required this.locale,
    required this.isToday,
    required this.done,
    required this.clears,
    required this.semanticsLabel,
    required this.todayLabel,
  });

  final DateTime date;
  final String locale;
  final bool isToday;
  final bool done;
  final int clears;
  final String semanticsLabel;
  final String todayLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = LevelStatusPalette.of(context).primaryPurple;

    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(vertical: 6),
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? accent : Colors.transparent,
                    border: Border.all(
                      color: isToday
                          ? cs.onSurface
                          : done
                              ? accent
                              : cs.outlineVariant,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white)
                      : null,
                ),
                // 하루 2회 이상 완료한 날만 횟수 배지를 붙인다.
                if (clears >= 2)
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
                        '$clears',
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
              isToday ? todayLabel : '',
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
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        arcRect, 0, 2 * 3.141592653589793, false, paint..color = trackColor);
    if (progress > 0) {
      canvas.drawArc(
          arcRect,
          -3.141592653589793 / 2,
          2 * 3.141592653589793 * progress,
          false,
          paint..color = progressColor);
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.strokeWidth != strokeWidth;
}
