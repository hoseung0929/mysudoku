import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:sudoku159/widgets/animated_progress_bar.dart';
import 'package:sudoku159/widgets/press_scale.dart';
import 'package:sudoku159/widgets/press_scale_listener.dart';
import 'package:sudoku159/utils/light_haptic.dart';
import 'package:flutter/services.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/l10n/sudoku_level_l10n.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/database/database_manager.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/records/game_record_notifier.dart';
import 'package:sudoku159/services/home/home_dashboard_service.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
import 'package:sudoku159/services/home/level_progress_service.dart';
import 'package:sudoku159/services/profile/profile_state_controller.dart';
import 'package:sudoku159/navigation/app_page_route.dart';
import 'package:sudoku159/navigation/tab_scroll_controller.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/home/level_picker_screen.dart';
import 'package:sudoku159/view/home/saved_games_screen.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:sudoku159/widgets/app_snackbar.dart';
import 'package:sudoku159/widgets/profile_editor_sheet.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/theme/system_ui_style.dart';
import 'package:sudoku159/widgets/profile_glass_header.dart';
import 'package:sudoku159/widgets/sudoku_motif.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.homeDashboardService,
    this.levelProgressService,
    this.databaseHelper,
    this.gameStateService,
    this.tabScrollController,
  });

  /// 테스트에서 저장소를 대체하기 위한 선택적 주입. 기본값은 실제 구현.
  final HomeDashboardService? homeDashboardService;
  final LevelProgressService? levelProgressService;
  final DatabaseHelper? databaseHelper;
  final GameStateService? gameStateService;

  /// 하단 홈 탭을 다시 눌렀을 때 이 화면을 최상단으로 스크롤하도록 연결하는
  /// 콜백 창구. [MyHomePage]가 탭별로 하나씩 만들어 전달한다.
  final TabScrollController? tabScrollController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// `extendBody` + 플로팅 하단 탭(패딩·알약 배경 포함 실측 약 86) + 여유 공간.
  /// 난이도 목록 마지막 카드가 하단 탭에 가리지 않도록 여유를 더 둔다.
  static const double _kHomeScrollBottomPad = 104;

  /// 홈 최상단 히어로 이미지(환영 문구 포함, 프로필 행 제외)의 고정 높이.
  /// 핵심 콘텐츠(시작 카드)가 더 빨리 보이도록 기존 값에서 24 줄였다.
  static const double _kHomeHeroHeightPhone = 236;
  static const double _kHomeHeroHeightTablet = 276;

  /// 프로필·설정을 담은 축소 앱바의 콘텐츠 높이(상태바 높이 제외).
  static const double _kCollapsedAppBarContentHeight = 60;

  final DatabaseManager _databaseManager = DatabaseManager();
  late final LevelProgressService _levelProgressService =
      widget.levelProgressService ?? LevelProgressService();
  late final HomeDashboardService _homeDashboardService =
      widget.homeDashboardService ?? HomeDashboardService();
  late final GameStateService _gameStateService =
      widget.gameStateService ?? GameStateService();
  final ProfileStateController _profileState = ProfileStateController.instance;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _levelSectionKey = GlobalKey();

  /// 히어로 이미지가 스크롤로 완전히 가려지기 전(true)인지 후(false)인지.
  /// 축소 앱바가 투명(사진 위 오버레이)인지 불투명(작은 앱바)인지를 정한다.
  bool _isTop = true;

  /// 첫 로딩이 끝났는지 / 마지막 로딩이 실패했는지. 로딩 중에는 '진행 중 없음'을
  /// 확정해서 보여주지 않고, 재로딩(복귀·기록 변경) 때는 기존 화면을 유지한다.
  bool _homeLoaded = false;
  bool _homeLoadFailed = false;
  int _dashboardRequestId = 0;
  bool _isOpeningGame = false;
  bool _isRetryingTodayChallenge = false;
  int _totalContinueCount = 0;
  bool _isLevelTransitioning = false;
  int? _transitioningLevelIndex;
  bool _showCatalogIntro = false;
  String? _profileImagePath;
  String? _profileName;
  List<SudokuLevel> _levels = List<SudokuLevel>.from(SudokuLevel.levels);

  /// 레벨별 전체 게임 수 (DB 기준)
  Map<String, int> _levelTotal = {};
  ContinueGameSummary? _continueGame;
  SudokuGame? _todayChallenge;
  ChallengeProgressSummary? _challengeProgress;
  ContinueGameSummary? _todayChallengeContinue;
  bool get _todayChallengeHasSession => _todayChallengeContinue != null;

  /// 같은 날짜의 도전이 미완료→완료로 바뀐 직후에만 true. 완료 체크가
  /// 나타나는 동안만 유지하고, 앱 시작·날짜 변경으로 이미 완료된 카드에는 쓰지 않는다.
  bool _challengeJustCompleted = false;

  @override
  void initState() {
    super.initState();
    _databaseManager.catalogStatus.addListener(_handleCatalogStatusChanged);
    GameRecordNotifier.instance.version.addListener(_handleRecordsChanged);
    _profileState.addListener(_handleProfileStateChanged);
    _scrollController.addListener(_handleScrollForCollapsingAppBar);
    widget.tabScrollController?.attach(_scrollToTop);
    _loadLevelTotals();
    _refreshLevels();
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadHomeDashboard();
      _syncCatalogIntroVisibility();
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadHomeDashboard();
      _syncCatalogIntroVisibility();
    });
  }

  void _handleRecordsChanged() {
    if (!mounted) return;
    _refreshLevels();
    _loadHomeDashboard();
  }

  Future<void> _loadLevelTotals() async {
    final dbHelper = widget.databaseHelper ?? DatabaseHelper();
    final totals = <String, int>{};
    for (var level in SudokuLevel.levels) {
      totals[level.name] = await dbHelper.getGameCount(level.name);
    }
    if (mounted) {
      setState(() {
        _levelTotal = totals;
      });
    }
  }

  Future<void> _refreshLevels() async {
    final refreshedLevels =
        await _levelProgressService.refreshAllLevels(_levels);
    if (!mounted) return;
    setState(() {
      _levels = refreshedLevels;
    });
  }

  void _handleProfileStateChanged() {
    if (!mounted) return;
    setState(() {
      _profileImagePath = _profileState.imagePath;
      _profileName = _profileState.name;
    });
  }

  Future<void> _loadProfile() async {
    await _profileState.refresh();
  }

  Future<void> _openProfileEditor() async {
    await showProfileEditorSheet(
      context: context,
      profileImageService: _profileState.profileImageService,
      initialProfileName: _profileName,
      initialProfileImagePath: _profileImagePath,
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

  Future<void> _loadHomeDashboard() async {
    if (!mounted) return;
    // 늦게 끝난 이전 요청이 최신 결과를 덮어쓰지 않도록 요청 번호로 구분한다.
    final requestId = ++_dashboardRequestId;
    try {
      final l10n = AppLocalizations.of(context)!;
      final data = await _homeDashboardService.load(l10n);
      if (!mounted || requestId != _dashboardRequestId) return;
      final before = _challengeProgress;
      final after = data.challengeProgress;
      final justCompleted = before != null &&
          before.challengeDate == after.challengeDate &&
          !before.isTodayChallengeCleared &&
          after.isTodayChallengeCleared;
      setState(() {
        _challengeJustCompleted = justCompleted;
        _continueGame = data.continueGame;
        _totalContinueCount = data.totalContinueCount;
        _todayChallenge = data.todayChallenge;
        _todayChallengeContinue = data.todayChallengeContinueGame;
        _challengeProgress = data.challengeProgress;
        _homeLoaded = true;
        _homeLoadFailed = false;
      });
    } catch (e) {
      // 실패 시 이전 정보를 그대로 두면 표시와 시작이 어긋날 수 있어 비우고
      // 오류 상태(재시도)를 보여준다. 다른 문제로 대체하지 않는다.
      if (kDebugMode) AppLogger.debug('홈 대시보드 로드 실패: $e');
      if (!mounted || requestId != _dashboardRequestId) return;
      setState(() {
        _continueGame = null;
        _totalContinueCount = 0;
        _todayChallenge = null;
        _todayChallengeContinue = null;
        _homeLoaded = false;
        _homeLoadFailed = true;
      });
    }
  }

  void _finishChallengeCompleteFade() {
    if (!mounted || !_challengeJustCompleted) return;
    setState(() => _challengeJustCompleted = false);
  }

  Future<void> _retryHomeLoad() async {
    setState(() => _homeLoadFailed = false);
    await _loadHomeDashboard();
  }

  @override
  void dispose() {
    _databaseManager.catalogStatus.removeListener(_handleCatalogStatusChanged);
    GameRecordNotifier.instance.version.removeListener(_handleRecordsChanged);
    _profileState.removeListener(_handleProfileStateChanged);
    _scrollController.removeListener(_handleScrollForCollapsingAppBar);
    widget.tabScrollController?.detach(_scrollToTop);
    _scrollController.dispose();
    super.dispose();
  }

  /// 홈 탭을 다시 눌렀을 때 호출된다. 이미 최상단이면 아무 것도 하지
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

  void _handleCatalogStatusChanged() {
    if (!mounted) return;
    _syncCatalogIntroVisibility();
  }

  void _syncCatalogIntroVisibility() {
    final status = _databaseManager.catalogStatus.value;
    final shouldShow =
        _databaseManager.shouldShowInitialCatalogIntro && status.isRunning;

    if (_showCatalogIntro == shouldShow) {
      return;
    }

    setState(() {
      _showCatalogIntro = shouldShow;
    });
  }

  void _dismissCatalogIntro() {
    _databaseManager.markInitialCatalogIntroSeen();
    setState(() {
      _showCatalogIntro = false;
    });
  }

  SudokuLevel getLevel(String title) {
    return _levels.firstWhere(
      (level) => level.name == _levelNameKor(title),
      orElse: () => _levels.first,
    );
  }

  String _levelNameKor(String title) {
    switch (title) {
      case 'Beginner':
        return '초급';
      case 'Intermediate':
        return '중급';
      case 'Advanced':
        return '고급';
      case 'Expert':
        return '전문가';
      case 'Master':
        return '마스터';
      default:
        return '초급';
    }
  }

  void _goToGame(String title, {int? levelIndex}) async {
    if (_isLevelTransitioning || !mounted) {
      return;
    }
    setState(() {
      _isLevelTransitioning = true;
      _transitioningLevelIndex = levelIndex;
    });
    final level = getLevel(title);

    try {
      await Navigator.push(
        context,
        buildAppPageRoute(
          builder: (context) => LevelPickerScreen(level: level),
        ),
      );
      // 레벨 화면에서 돌아온 뒤 클리어 수 갱신
      await _refreshLevels();
      await _loadHomeDashboard();
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLevelTransitioning = false;
          _transitioningLevelIndex = null;
        });
      } else {
        _isLevelTransitioning = false;
        _transitioningLevelIndex = null;
      }
    }
  }

  Future<void> _openGame(
    SudokuGame game,
    SudokuLevel level, {
    bool restoreSavedSession = false,
    String? challengeDate,
  }) async {
    // 빠른 연속 탭으로 게임 화면이 중복으로 열리지 않게 한다.
    if (_isOpeningGame || !mounted) return;
    setState(() => _isOpeningGame = true);
    try {
      await Navigator.push(
        context,
        buildAppPageRoute(
          builder: (context) => SudokuGameScreen(
            game: game,
            level: level,
            restoreSavedSession: restoreSavedSession,
            challengeDate: challengeDate,
          ),
        ),
      );
      await _refreshLevels();
      await _loadHomeDashboard();
    } finally {
      if (mounted) setState(() => _isOpeningGame = false);
    }
  }

  SudokuLevel _uiLevelFor(String levelName) {
    return _levels.firstWhere(
      (item) => item.name == levelName,
      orElse: () => SudokuLevel.levels.firstWhere(
        (item) => item.name == levelName,
        orElse: () => SudokuLevel.levels.first,
      ),
    );
  }

  /// 가장 최근에 풀던 게임을 저장된 상태 그대로 복원한다.
  Future<void> _openContinueGame() async {
    final summary = _continueGame;
    if (summary == null) return;
    await _openGame(
      summary.game,
      _uiLevelFor(summary.game.levelName),
      restoreSavedSession: true,
    );
  }

  /// 진행 중인 게임 전체 목록. 항목을 고르면 그 게임을 복원한다.
  Future<void> _openSavedGames() async {
    if (_isOpeningGame || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final games = await _homeDashboardService.loadContinueGames();
    if (!mounted || games.isEmpty) return;
    final picked = await Navigator.push<ContinueGameSummary>(
      context,
      MaterialPageRoute(
        builder: (context) => SavedGamesScreen(
          initialGames: games,
          title: l10n.homeSavedGamesTitle,
          description: l10n.homeSavedGamesDescription,
          itemTitleBuilder: (summary) =>
              '${summary.level.localizedName(l10n)} · ${l10n.levelPuzzleNumber(summary.game.gameNumber)}',
          itemSubtitleBuilder: (summary) => _continueDetail(l10n, summary),
          deleteTooltip: l10n.homeSavedGameDeleteTooltip,
          onDelete: (summary) => _deleteSavedGame(summary, games),
        ),
      ),
    );
    if (!mounted) return;
    if (picked == null) {
      // 목록에서 삭제했을 수 있으므로 홈 상태를 갱신한다.
      await _loadHomeDashboard();
      return;
    }
    await _openGame(
      picked.game,
      _uiLevelFor(picked.game.levelName),
      restoreSavedSession: true,
    );
  }

  Future<List<ContinueGameSummary>> _deleteSavedGame(
    ContinueGameSummary summary,
    List<ContinueGameSummary> current,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.homeSavedGameDeleteTitle),
        content: Text(l10n.homeSavedGameDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.homeSavedGameDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return current;
    // 저장된 풀이(세션)만 지운다. 완료 기록은 건드리지 않는다.
    await _gameStateService.clearBoard(
      levelName: summary.game.levelName,
      gameNumber: summary.game.gameNumber,
    );
    return _homeDashboardService.loadContinueGames();
  }

  /// 히어로 이미지도 이제 본문과 함께 스크롤되고, 프로필·설정을 담은 축소
  /// 앱바만 화면 위에 고정되어 스크롤 콘텐츠 맨 위를 항상 가린다.
  double _collapsedAppBarHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top + _kCollapsedAppBarContentHeight;

  double _currentHeroHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).width > 600
          ? _kHomeHeroHeightTablet
          : _kHomeHeroHeightPhone;

  /// 히어로가 축소 앱바 뒤로 완전히 넘어가면 앱바를 사진 위 오버레이(투명)에서
  /// 작은 불투명 앱바로 전환한다.
  void _handleScrollForCollapsingAppBar() {
    if (!mounted) return;
    final threshold =
        _currentHeroHeight(context) - _collapsedAppBarHeight(context);
    final collapsed = _scrollController.offset >= threshold;
    if (collapsed == _isTop) {
      setState(() => _isTop = !collapsed);
    }
  }

  /// "새 게임 시작": 난이도 선택 영역으로 이동한다.
  void _scrollToLevels() {
    final ctx = _levelSectionKey.currentContext;
    if (ctx == null || !_scrollController.hasClients) return;
    final box = ctx.findRenderObject();
    if (box == null) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    // 히어로가 본문과 함께 스크롤되고 축소 앱바만 고정되어 콘텐츠 위를
    // 가리므로, 그 높이만큼 비워서 목표 위치를 계산한다.
    final obscured = _collapsedAppBarHeight(context);
    final position = _scrollController.position;
    final target = (viewport.getOffsetToReveal(box, 0.0).offset - obscured - 8)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(target);
      return;
    }
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// 카드에 표시된 오늘의 도전 타깃을 그대로 연다. 표시와 시작에 같은 스냅샷을
  /// 쓰며, 그사이 날짜가 바뀌었다면 화면을 먼저 갱신하고 다른 문제는 열지 않는다.
  /// 도전 카드의 재시도/날짜 변경 재조회. 진행 중에는 버튼·카드 탭을 막아
  /// 연타해도 조회가 한 번만 실행되게 한다.
  Future<void> _reloadTodayChallenge() async {
    setState(() => _isRetryingTodayChallenge = true);
    try {
      await _loadHomeDashboard();
    } finally {
      if (mounted) setState(() => _isRetryingTodayChallenge = false);
    }
  }

  Future<void> _openTodayChallenge() async {
    final game = _todayChallenge;
    final challengeDate = _challengeProgress?.challengeDate;
    if (!_homeLoaded || _isOpeningGame || _isRetryingTodayChallenge) return;
    if (game == null || challengeDate == null) {
      await _reloadTodayChallenge();
      return;
    }
    if (challengeDate !=
        ChallengeProgressService.formatLocalDate(DateTime.now())) {
      await _reloadTodayChallenge();
      if (!mounted) return;
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.homeTodayChallengeDateChanged,
      );
      return;
    }
    await _openGame(
      game,
      _uiLevelFor(game.levelName),
      restoreSavedSession: _todayChallengeHasSession,
      challengeDate: challengeDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 히어로가 보이는 동안(_isTop)은 사진 위라 앱 테마와 무관하게 밝은
      // 상태바 아이콘을 강제하고, 축소 앱바로 바뀌면 현재 테마를 따른다.
      // 다른 화면은 여전히 테마 기준(systemOverlayStyleFor)을 그대로 쓴다.
      value: systemOverlayStyleFor(
        _isTop ? Brightness.dark : Theme.of(context).brightness,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              SafeArea(
                top: false,
                bottom: false,
                child: isTablet
                    ? _buildTabletLayout(topInset, isLandscape: isLandscape)
                    : _buildMobileLayout(topInset),
              ),
              if (_showCatalogIntro) _buildCatalogIntroOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  /// 태블릿 레이아웃
  Widget _buildTabletLayout(double topInset, {bool isLandscape = false}) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollController,
            // iOS 탄성 스크롤로 최상단에서 히어로 이미지가 아래로 밀려
            // 보이지 않게 클램핑 물리를 쓴다.
            physics: const ClampingScrollPhysics(),
            padding:
                EdgeInsets.only(bottom: _kHomeScrollBottomPad + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 히어로 이미지는 본문과 함께 스크롤되고, 전체 너비를 유지하도록
                // 좌우 패딩 밖에 둔다.
                _buildHomeHeroImage(isTablet: true),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHomeHero(isTablet: true),
                      const SizedBox(height: 20),
                      _buildLevelExplorer(
                        isTablet: true,
                        isLandscape: isLandscape,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildCollapsingAppBar(isTablet: true),
        ),
      ],
    );
  }

  /// 모바일 레이아웃
  Widget _buildMobileLayout(double topInset) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollController,
            // iOS 탄성 스크롤로 최상단에서 히어로 이미지가 아래로 밀려
            // 보이지 않게 클램핑 물리를 쓴다.
            physics: const ClampingScrollPhysics(),
            padding:
                EdgeInsets.only(bottom: _kHomeScrollBottomPad + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 히어로 이미지는 본문과 함께 스크롤되고, 전체 너비를 유지하도록
                // 좌우 패딩 밖에 둔다.
                _buildHomeHeroImage(isTablet: false),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ValueListenableBuilder<PuzzleCatalogStatus>(
                        valueListenable: _databaseManager.catalogStatus,
                        builder: (context, status, child) {
                          if (!status.isRunning) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CatalogProgressBanner(
                              status: status,
                              l10n: AppLocalizations.of(context)!,
                            ),
                          );
                        },
                      ),
                      _buildHomeHero(),
                      const SizedBox(height: 8),
                      _buildLevelExplorer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildCollapsingAppBar(isTablet: false),
        ),
      ],
    );
  }

  /// 홈 최상단 히어로 이미지: 저녁 책상에서 스도쿠를 푸는 캐릭터 일러스트
  /// 위에 시간대별 환영 문구만 겹쳐 보여준다(프로필·설정은 별도의 축소
  /// 앱바로 분리됨). 이제 고정되지 않고 본문과 함께 스크롤된다.
  Widget _buildHomeHeroImage({required bool isTablet}) {
    final height = isTablet ? _kHomeHeroHeightTablet : _kHomeHeroHeightPhone;
    final greeting = ProfileGlassHeader.greetingMessage(
      l10n: AppLocalizations.of(context)!,
      hour: DateTime.now().hour,
    );

    return SizedBox(
      key: const Key('home_hero_header'),
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 폭이 이미지 비율(2:1)보다 좁은 화면(폰 세로 등)에서는 좌우로
          // 크롭되는데, alignment를 살짝 오른쪽으로 밀어 보이는 영역 자체를
          // 오른쪽으로 옮겨서 그 안의 펭귄이 프레임 안에서 왼쪽으로(약
          // 12~20px) 이동해 보이게 한다.
          Image.asset(
            'assets/images/home_hero.webp',
            fit: BoxFit.cover,
            alignment: const Alignment(0.4, 0),
          ),
          // 축소 앱바가 사진 위에 겹칠 때 가독성을 위한 위쪽 어두운 그라데이션.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB3000000), Colors.transparent],
                stops: [0.0, 0.42],
              ),
            ),
          ),
          // 환영 문구 가독성을 위한 좌측 어두운 그라데이션.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x99000000), Colors.transparent],
                stops: [0.0, 0.7],
              ),
            ),
          ),
          // 하단은 화면 배경색으로 자연스럽게 이어진다.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: height * 0.3,
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
            left: 20,
            right: isTablet ? 240 : 130,
            bottom: 18,
            child: Text(
              greeting,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
                shadows: [
                  Shadow(color: Colors.black45, blurRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 프로필(아바타·이름)·연속 기록·설정 버튼을 담은 축소 앱바. 화면 위에
  /// 항상 고정되며, 히어로 이미지가 보이는 동안은 사진 위 투명 오버레이(흰
  /// 글자)로, 히어로가 스크롤로 넘어가면 작은 불투명 앱바(테마 글자색)로
  /// 전환된다.
  Widget _buildCollapsingAppBar({required bool isTablet}) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasProfileImage =
        _profileImagePath != null && File(_profileImagePath!).existsSync();
    final trimmedName = _profileName?.trim() ?? '';
    final displayName =
        trimmedName.isNotEmpty ? trimmedName : l10n.homeGuestTitle;
    final streakDays = _challengeProgress?.activityStreakDays ?? 0;
    final streakPlayedToday = _challengeProgress?.lastClearDate ==
        ChallengeProgressService.formatLocalDate(DateTime.now());
    final onPhoto = _isTop;
    final contentColor = onPhoto ? Colors.white : colorScheme.onSurface;
    final textShadows =
        onPhoto ? const [Shadow(color: Colors.black45, blurRadius: 6)] : null;

    return AnimatedContainer(
      key: const Key('home_collapsing_app_bar'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: onPhoto ? Colors.transparent : colorScheme.surface,
        boxShadow: onPhoto
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openProfileEditor,
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: onPhoto
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : colorScheme.outlineVariant,
                                  width: 1.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 19,
                                backgroundColor: onPhoto
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : colorScheme.primaryContainer,
                                backgroundImage: hasProfileImage
                                    ? FileImage(File(_profileImagePath!))
                                    : const AssetImage(
                                        'assets/images/character.png',
                                      ) as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: contentColor,
                                  shadows: textShadows,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (streakDays > 0) ...[
                  const SizedBox(width: 4),
                  _HeroStreakBadge(
                    days: streakDays,
                    playedToday: streakPlayedToday,
                    l10n: l10n,
                    onPhoto: onPhoto,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeHero({bool isTablet = false}) {
    final l10n = AppLocalizations.of(context)!;
    if (!_homeLoaded) {
      // 로딩 중과 조회 실패를 구분한다. 어느 쪽도 '진행 중 없음'을 확정하지 않는다.
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _homeCard(
          child: _homeLoadFailed
              ? Column(
                  children: [
                    Text(
                      l10n.homeLoadError,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: _retryHomeLoad,
                      child: Text(l10n.levelTryAgain),
                    ),
                  ],
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                ),
        ),
      );
    }

    final continueGame = _continueGame;
    final challenge = _todayChallenge;
    // 최근 이어하기와 오늘의 도전이 같은 문제면 큰 카드를 두 번 반복하지 않고
    // 이어하기 카드가 도전 카드 역할을 한다. 단, 도전을 이미 완료했다면(완료 후
    // 다시 풀다 남은 재도전 세션) 완료 상태가 우선이라 합치지 않는다: 이어하기
    // 카드는 재도전 진행을, 도전 카드는 "오늘 도전 완료"를 각각 보여준다.
    final sameAsChallenge = continueGame != null &&
        challenge != null &&
        !(_challengeProgress?.isTodayChallengeCleared ?? false) &&
        continueGame.game.levelName == challenge.levelName &&
        continueGame.game.gameNumber == challenge.gameNumber;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isTablet ? 640 : double.infinity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPrimaryStartCard(continueGame, sameAsChallenge),
          if (!sameAsChallenge) _buildTodayChallengeCard(challenge),
        ],
      ),
    );
  }

  /// 얇은 테두리의 흰색 카드 (sudoku-design-guide: 그림자 최소화, 카드 수 최소화).
  Widget _homeCard({required Widget child}) {
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

  String _continueDetail(AppLocalizations l10n, ContinueGameSummary summary) {
    final pct = (summary.progress * 100).round();
    // 확정 숫자 없이 메모만 있는 게임은 0% 대신 상태를 설명한다.
    if (pct == 0 && summary.noteCount > 0) return l10n.levelNotesInProgress;
    return '$pct%';
  }

  /// 주요 시작 영역: 이어할 게임이 있으면 '이어서 풀기', 없으면 '새 게임 시작'.
  Widget _buildPrimaryStartCard(
    ContinueGameSummary? continueGame,
    bool isTodayChallenge,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final busy = _isOpeningGame;

    if (continueGame == null) {
      final firstTime = _challengeProgress?.lastClearDate == null;
      final textBlock = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstTime ? l10n.homeFirstStartTitle : l10n.homeNewPuzzleTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeChooseLevelBody,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _homeCard(
          // 캐릭터는 최상단 히어로 이미지에 이미 나오므로, 캐릭터 중복을
          // 줄이기 위해 이 카드에서는 마스코트 장식 없이 문구만 보여준다.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              textBlock,
              const SizedBox(height: 14),
              // 실제로 게임을 시작하지 않고 아래 난이도 선택 영역으로 이동한다.
              FilledButton(
                onPressed: _scrollToLevels,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(
                  l10n.homeChooseLevelButton,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final level = continueGame.level;
    final levelImage = _levelIdentityImage(level.difficulty);
    final title =
        '${level.localizedName(l10n)} · ${l10n.levelPuzzleNumber(continueGame.game.gameNumber)}';
    final continuePct = (continueGame.progress * 100).round();
    // 오늘의 도전과 같은 문제면 이 카드가 도전 카드 역할을 한다: 분류 라벨은
    // '오늘의 도전', 상태는 "36% 진행"(메모만 있으면 메모 상태), 진행바 포함.
    final detail = isTodayChallenge
        ? _challengeProgressText(l10n, continueGame)
        : _continueDetail(l10n, continueGame);
    final card = _homeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (levelImage != null)
                Image.asset(levelImage, width: 52, height: 52)
              else
                Icon(_levelIdentityIcon(level.difficulty), size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTodayChallenge
                          ? l10n.challengeTodaysChallengeTitle
                          : l10n.homeContinueTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isTodayChallenge && continuePct > 0) ...[
            const SizedBox(height: 10),
            AnimatedProgressBar(
              key: const Key('home_challenge_progress'),
              value: continuePct / 100,
              fillColor: LevelStatusPalette.of(context).primaryPurple,
              trackColor: const Color.fromRGBO(83, 69, 164, 0.14),
            ),
          ],
          const SizedBox(height: 12),
          PressScaleListener(
            child: FilledButton(
              onPressed: busy
                  ? null
                  : () {
                      unawaited(lightHaptic());
                      _openContinueGame();
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(l10n.levelContinueButton),
            ),
          ),
          if (_totalContinueCount > 1)
            TextButton(
              onPressed: busy ? null : _openSavedGames,
              child: Text(
                l10n.homeViewAllInProgress(_totalContinueCount),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
    // 오늘의 도전과 같은 문제면 카드 전체를 눌러도 이어서 풀기가 실행된다.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isTodayChallenge
          ? _tappableCard(
              onTap: busy ? null : _openContinueFromCard, child: card)
          : card,
    );
  }

  /// "36% 진행", 메모만 있으면 메모 상태.
  String _challengeProgressText(
    AppLocalizations l10n,
    ContinueGameSummary summary,
  ) {
    final pct = (summary.progress * 100).round();
    if (pct == 0 && summary.noteCount > 0) return l10n.levelNotesInProgress;
    return l10n.homeChallengeProgress(pct);
  }

  /// 카드 전체를 탭 영역으로 만든다. 눌림 축소는 포인터만 듣고, 안쪽 버튼의
  /// 탭은 그대로 처리된다. 스크린리더에는 버튼만 노출한다(중복 방지).
  Widget _tappableCard({required VoidCallback? onTap, required Widget child}) {
    return PressScaleListener(
      child: GestureDetector(
        onTap: onTap,
        excludeFromSemantics: true,
        child: child,
      ),
    );
  }

  Future<void> _openContinueFromCard() async {
    unawaited(lightHaptic());
    await _openContinueGame();
  }

  Future<void> _startChallengeWithHaptic() async {
    unawaited(lightHaptic());
    await _openTodayChallenge();
  }

  /// 오늘의 도전: 일반 이어하기와 별도 항목.
  /// 시작 전 / 진행 중 / 완료 / 불러오기 실패를 구분한다.
  /// 탭 정책: 시작 전·진행 중은 카드 전체가 탭 대상, 완료·실패는 버튼만.
  Widget _buildTodayChallengeCard(SudokuGame? game) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final palette = LevelStatusPalette.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final session = _todayChallengeContinue;
    final isError = game == null;
    final done =
        !isError && (_challengeProgress?.isTodayChallengeCleared ?? false);
    final inProgress = !isError && !done && session != null;
    final busy = _isOpeningGame || _isRetryingTodayChallenge;
    // 완료 카드는 성과만 보여 주는 상태 카드다: 재도전 버튼과 탭 동작이 없어
    // 저장된 재도전 세션은 이어하기 카드에서만 다룬다.
    final showButton = !done;
    final tappable = !isError && !done;

    final puzzleTitle = isError
        ? ''
        : '${game.levelName.localizedSudokuLevelName(l10n)} · '
            '${l10n.levelPuzzleNumber(game.gameNumber)}';
    final String sub;
    if (isError) {
      sub = l10n.homeChallengeLoadErrorBody;
    } else if (inProgress) {
      sub = _challengeProgressText(l10n, session);
    } else {
      // 추천 이벤트(첫 도전·승급)가 있는 날의 시작 전 상태에만 안내 문구를 쓴다.
      switch (_challengeProgress?.recommendationEvent) {
        case ChallengeRecommendationEvent.firstChallenge:
          sub = l10n.homeChallengeFirstLine;
          break;
        case ChallengeRecommendationEvent.promoted:
          sub = l10n.homeChallengePromotedLine(
            game.levelName.localizedSudokuLevelName(l10n),
          );
          break;
        case null:
          sub = l10n.homeChallengeNotStarted;
      }
    }
    final progressPct = inProgress ? (session.progress * 100).round() : 0;
    final buttonLabel = isError
        ? l10n.levelTryAgain
        : inProgress
            ? l10n.levelContinueButton
            : l10n.homeChallengeStartButton;
    final showArtwork = !isError &&
        MediaQuery.sizeOf(context).width >= 300 &&
        MediaQuery.textScalerOf(context).scale(1.0) <= 1.3;
    final headingColor =
        showArtwork ? const Color(0xFF625D69) : cs.onSurfaceVariant;
    final titleColor = showArtwork ? const Color(0xFF27242C) : cs.onSurface;
    final stateKey = isError
        ? 'error'
        : done
            ? 'done'
            : inProgress
                ? 'progress'
                : 'start';

    Widget titleText(String text) => Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        );
    Widget subText(String text, {bool strong = false}) => Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
            color: headingColor,
          ),
        );

    final List<Widget> textChildren;
    if (done) {
      // 체크 아이콘은 장식이고, 완료 상태는 텍스트로 전달한다.
      textChildren = [
        Semantics(
          container: true,
          excludeSemantics: true,
          label: '${l10n.homeChallengeDoneLine} $puzzleTitle',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  FadeInOnce(
                    enabled: _challengeJustCompleted,
                    onEnd: _finishChallengeCompleteFade,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: palette.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: titleText(l10n.homeChallengeDoneLine)),
                ],
              ),
              const SizedBox(height: 4),
              subText(puzzleTitle),
            ],
          ),
        ),
      ];
    } else if (isError) {
      textChildren = [
        titleText(l10n.homeChallengeLoadErrorTitle),
        const SizedBox(height: 2),
        subText(sub),
      ];
    } else {
      // 시작 전·진행 중은 같은 구조(머리줄 / 퍼즐 이름 / 보조 한 줄)를 써서
      // 상태가 바뀌어도 카드 높이와 버튼 위치가 달라지지 않는다.
      textChildren = [
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: headingColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.challengeTodaysChallengeTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: headingColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        titleText(puzzleTitle),
        subText(sub),
        if (progressPct > 0) ...[
          const SizedBox(height: 8),
          AnimatedProgressBar(
            key: const Key('home_challenge_progress'),
            value: progressPct / 100,
            fillColor: palette.primaryPurple,
            trackColor: const Color.fromRGBO(83, 69, 164, 0.14),
          ),
        ],
      ];
    }

    final content = Padding(
      key: ValueKey(stateKey),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: ConstrainedBox(
        // 완료 카드는 버튼이 빠져도 그림이 답답하지 않도록 최소 높이를 두고
        // 시작 전 카드보다 약 25pt 낮게 맞춘다.
        constraints: BoxConstraints(minHeight: done && showArtwork ? 146 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: showArtwork ? 0.62 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: textChildren,
                ),
              ),
            ),
            if (showButton) const SizedBox(height: 8),
            // 오른쪽 그림(펭귄·편지)을 가리지 않도록 버튼 폭을 왼쪽으로 제한한다.
            // 좁아서 글이 잘릴 수 있으면 전체 폭으로 되돌린다.
            if (showButton)
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow =
                      showArtwork && constraints.maxWidth * 0.62 >= 180;
                  final VoidCallback? onPressed = busy
                      ? null
                      : isError
                          ? _openTodayChallenge
                          : _startChallengeWithHaptic;
                  // '난이도 선택'(주 버튼, 검은색)과 위계를 구분하기 위해 연한 보라색
                  // 배경의 보조 버튼으로 모든 상태에서 같게 표시한다.
                  final button = PressScaleListener(
                    child: FilledButton(
                      onPressed: onPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.completedBackground,
                        foregroundColor: palette.primaryPurple,
                        // 탭 직후 busy 상태에서도 배경이 비치지 않도록 유지한다.
                        disabledBackgroundColor: palette.completedBackground,
                        disabledForegroundColor: palette.primaryPurple,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: isError && _isRetryingTodayChallenge
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(buttonLabel, textAlign: TextAlign.center),
                    ),
                  );
                  return narrow
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.62,
                            child: button,
                          ),
                        )
                      : button;
                },
              ),
          ],
        ),
      ),
    );

    final card = Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Stack(
        children: [
          if (showArtwork)
            Positioned.fill(
              child: ExcludeSemantics(
                child: Image.asset(
                  'assets/images/home_daily_challenge_card_bg.png',
                  key: const Key('home_today_challenge_artwork'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          if (showArtwork)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.fromRGBO(255, 255, 255, 0.52),
                      Color.fromRGBO(255, 255, 255, 0.16),
                      Color.fromRGBO(255, 255, 255, 0),
                    ],
                    stops: [0, 0.38, 0.65],
                  ),
                ),
              ),
            ),
          // 상태가 바뀔 때 텍스트·버튼만 짧게 크로스페이드한다.
          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: content,
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: tappable
          ? _tappableCard(
              onTap: busy ? null : _startChallengeWithHaptic,
              child: card,
            )
          : card,
    );
  }

  Widget _buildCatalogIntroOverlay() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.28),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 20),
                        ),
                      ],
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.65),
                      ),
                    ),
                    child: ValueListenableBuilder<PuzzleCatalogStatus>(
                      valueListenable: _databaseManager.catalogStatus,
                      builder: (context, status, child) {
                        final progress = status.totalTarget == 0
                            ? 0.0
                            : (status.totalGenerated / status.totalTarget)
                                .clamp(0.0, 1.0);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              l10n.homeCatalogFirstTitle,
                              style: TextStyle(
                                fontSize: 24,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.homeCatalogFirstBody,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: 0.72),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.homeCatalogProgressDetail(
                                      status.totalGenerated,
                                      status.totalTarget,
                                      status.remaining,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 10,
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l10n.homeCatalogFirstNote,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: _dismissCatalogIntro,
                                child: Text(
                                  l10n.homeCatalogFirstContinue,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 레벨 목록/그리드에서 쓰는 것과 동일한 아이콘 세트로 레벨 아이덴티티를 통일.
  // 레벨 목록/피커 화면과 동일한 이미지 에셋으로 레벨 아이덴티티를 통일 (마스터는 이미지가 없어 아이콘으로 대체).
  String? _levelIdentityImage(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'assets/images/level1.png';
      case 2:
        return 'assets/images/level2.png';
      case 3:
        return 'assets/images/level3.png';
      case 4:
        return 'assets/images/level4.png';
      default:
        return null;
    }
  }

  IconData _levelIdentityIcon(int difficulty) {
    switch (difficulty) {
      case 1:
        return Icons.eco_rounded;
      case 2:
        return Icons.local_fire_department_rounded;
      case 3:
        return Icons.star_rounded;
      case 4:
        return Icons.diamond_rounded;
      case 5:
        return Icons.emoji_events_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  Widget _buildLevelExplorer(
      {bool isTablet = false, bool isLandscape = false}) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: _levelSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            l10n.homeNewGameSectionTitle,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        _buildLevelCards(isTablet: isTablet, isLandscape: isLandscape),
      ],
    );
  }

  Widget _buildLevelCards({bool isTablet = false, bool isLandscape = false}) {
    // 마스터는 아직 준비 중이라 우선 홈 화면에서만 숨긴다(기록/필터 등 다른
    // 화면은 이미 마스터를 노출하지 않는 기존 관례를 그대로 따름).
    final levelCount = _levels.length > 4 ? 4 : _levels.length;
    if (!isLandscape) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(levelCount, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == levelCount - 1 ? 0 : 12),
            child: _buildLevelCard(index, isTablet: isTablet),
          );
        }),
      );
    }

    // 아이패드 가로 모드: 카드가 폭 전체로 늘어나 속 빈 느낌이 나던 걸
    // 2열로 바꿔서 가로 공간을 활용.
    const columnGap = 16.0;
    const rowGap = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - columnGap) / 2;
        return Wrap(
          spacing: columnGap,
          runSpacing: rowGap,
          children: List.generate(levelCount, (index) {
            return SizedBox(
              width: cardWidth,
              child: _buildLevelCard(index, isTablet: isTablet),
            );
          }),
        );
      },
    );
  }

  Widget _buildLevelCard(int index, {bool isTablet = false}) {
    final l10n = AppLocalizations.of(context)!;
    final levelTitles = [
      'Beginner',
      'Intermediate',
      'Advanced',
      'Expert',
      'Master'
    ];
    final level = _levels[index];
    final total = _levelTotal[level.name] ?? 100;
    final completed = level.clearedGames;
    final remaining = total - completed;
    final colors = [
      const Color(0xFFBFE7D5), // 초급 - 라이트 민트
      const Color(0xFF7FCFC7), // 중급 - 티얼 (hue 차이로 구분)
      const Color(0xFFD8C08E), // 고급 - 탄/골드
      const Color(0xFFD8A6BE), // 전문가 - 핑크
      const Color(0xFFA8CBE6), // 마스터 - 블루
    ];
    final badgeColors = <Color?>[null, null, null, null, null];
    final badges = <IconData>[
      Icons.eco_rounded,
      Icons.local_fire_department_rounded,
      Icons.star_rounded,
      Icons.diamond_rounded,
      Icons.emoji_events_rounded,
    ];
    final badgeSizes = isTablet
        ? [98.0, 96.0, 96.0, 96.0, 98.0]
        : [80.0, 78.0, 78.0, 78.0, 80.0];
    final levelImages = [
      'assets/images/level1.png',
      'assets/images/level2.png',
      'assets/images/level3.png',
      'assets/images/level4.png',
    ];

    return _LevelCard(
      color: colors[index],
      badgeColor: badgeColors[index],
      badgeIcon: badges[index],
      // 마스터(index 4)는 이미지 에셋이 없어 기존 트로피 아이콘(badgeIcon)으로
      // 대체한다.
      badgeImage: index < levelImages.length ? levelImages[index] : null,
      badgeSize: badgeSizes[index],
      title: level.localizedName(l10n),
      description: l10n.homeLevelBlankCells(level.emptyCells),
      completed: completed,
      remaining: remaining,
      isTablet: isTablet,
      isEnabled: !_isLevelTransitioning,
      isTransitioning:
          _isLevelTransitioning && _transitioningLevelIndex == index,
      onTap: () {
        if (_isLevelTransitioning) {
          return;
        }
        _goToGame(levelTitles[index], levelIndex: index);
      },
    );
  }
}

class _CatalogProgressBanner extends StatelessWidget {
  const _CatalogProgressBanner({
    required this.status,
    required this.l10n,
  });

  final PuzzleCatalogStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = status.totalTarget == 0
        ? 0.0
        : (status.totalGenerated / status.totalTarget).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.homeCatalogPreparingTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeCatalogProgressDetail(
              status.totalGenerated,
              status.totalTarget,
              status.remaining,
            ),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  final Color color;
  final Color? badgeColor;
  final IconData badgeIcon;
  final String? badgeImage;
  final double badgeSize;
  final String title;
  final String description;
  final int completed;
  final int remaining;
  final bool isEnabled;
  final bool isTransitioning;
  final bool isTablet;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.color,
    required this.badgeColor,
    required this.badgeIcon,
    this.badgeImage,
    required this.badgeSize,
    required this.title,
    required this.description,
    required this.completed,
    required this.remaining,
    required this.isEnabled,
    required this.isTransitioning,
    this.isTablet = false,
    this.onTap,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;
    setState(() {
      _pressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isEnabled) return;
    setState(() {
      _pressed = false;
    });
    if (widget.onTap != null) widget.onTap!();
  }

  void _handleTapCancel() {
    setState(() {
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final total = widget.completed + widget.remaining;
    final progressLabel = l10n.homeLevelProgressSolved(widget.completed, total);
    final isTablet = widget.isTablet;
    final cardMinHeight = isTablet ? 96.0 : 72.0;
    final cardVerticalPadding = isTablet ? 24.0 : 16.0;
    final iconGap = isTablet ? 28.0 : 24.0;
    final titleFontSize = isTablet ? 20.0 : 17.0;
    final progressLabelFontSize = isTablet ? 15.0 : 13.0;
    final afterTitleGap = isTablet ? 8.0 : 6.0;
    final progressBarHeight = isTablet ? 8.0 : 6.0;
    final beforeChevronGap = isTablet ? 18.0 : 16.0;
    final loadingSize = isTablet ? 24.0 : 20.0;
    final loadingStrokeWidth = isTablet ? 2.4 : 2.1;
    final chevronSize = isTablet ? 32.0 : 28.0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      ignoring: !widget.isEnabled,
      child: AnimatedOpacity(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        opacity: widget.isEnabled ? 1.0 : 0.78,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: PressScale(
            pressed: _pressed,
            child: Container(
              constraints: BoxConstraints(minHeight: cardMinHeight),
              padding: EdgeInsets.symmetric(
                horizontal: 22,
                vertical: cardVerticalPadding,
              ),
              decoration: BoxDecoration(
                color: _pressed
                    ? colorScheme.surfaceContainerLow
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.055),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _DifficultyIcon(
                    color: widget.color,
                    badgeIcon: widget.badgeIcon,
                    badgeImage: widget.badgeImage,
                    badgeColor: widget.badgeColor,
                    badgeSize: widget.badgeSize,
                    isTablet: isTablet,
                  ),
                  SizedBox(width: iconGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: titleFontSize,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              progressLabel,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: progressLabelFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: afterTitleGap),
                        Text(
                          widget.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: progressLabelFontSize - 1,
                          ),
                        ),
                        SizedBox(height: afterTitleGap),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: total > 0 ? widget.completed / total : 0,
                            minHeight: progressBarHeight,
                            backgroundColor: colorScheme.outlineVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.badgeColor ?? const Color(0xFF4A3F99),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: beforeChevronGap),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: widget.isTransitioning
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: loadingSize,
                            height: loadingSize,
                            child: CircularProgressIndicator(
                              strokeWidth: loadingStrokeWidth,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          )
                        : Icon(
                            key: const ValueKey('chevron'),
                            Icons.chevron_right_rounded,
                            size: chevronSize,
                            color: colorScheme.onSurfaceVariant,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyIcon extends StatelessWidget {
  const _DifficultyIcon({
    required this.color,
    required this.badgeIcon,
    this.badgeImage,
    required this.badgeColor,
    required this.badgeSize,
    this.isTablet = false,
  });

  final Color color;
  final IconData badgeIcon;
  final String? badgeImage;
  final Color? badgeColor;
  final double badgeSize;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final boxSize = isTablet ? 76.0 : 62.0;
    return ClipRect(
      child: SizedBox(
        width: boxSize,
        height: boxSize,
        child: badgeImage != null
            ? Align(
                alignment: const Alignment(0, -0.6),
                child: Image.asset(
                  badgeImage!,
                  width: badgeSize,
                  height: badgeSize,
                  fit: BoxFit.contain,
                ),
              )
            : Center(
                child: Icon(badgeIcon,
                    size: badgeSize, color: badgeColor ?? color),
              ),
      ),
    );
  }
}

/// 홈 히어로 배너용 연속 기록 배지. `ProfileGlassHeader`의 연속 기록 칩과
/// 같은 데이터(연속 일수/오늘 완료 여부)를 쓰지만, 밝은 카드 배경이 아니라
/// 사진 위에 올라가므로 반투명 검정 배경 + 흰 글자로 색만 다르게 맞춘다.
class _HeroStreakBadge extends StatelessWidget {
  const _HeroStreakBadge({
    required this.days,
    required this.playedToday,
    required this.l10n,
    required this.onPhoto,
  });

  final int days;
  final bool playedToday;
  final AppLocalizations l10n;

  /// true면 히어로 사진 위(반투명 검정 알약 + 흰 글자), false면 축소된
  /// 불투명 앱바 위(테마 색 알약 + 테마 글자)에 맞춘 배색을 쓴다.
  final bool onPhoto;

  static const _flameColor = Color(0xFFE8833A);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final message =
        playedToday ? l10n.homeStreakActive(days) : l10n.homeStreakAtRisk(days);
    final pillColor = onPhoto
        ? Colors.black.withValues(alpha: 0.38)
        : (playedToday
            ? _flameColor.withValues(alpha: 0.14)
            : Colors.transparent);
    final borderColor = onPhoto
        ? Colors.white.withValues(alpha: 0.4)
        : (playedToday ? Colors.transparent : colorScheme.outlineVariant);
    final textColor = onPhoto
        ? Colors.white
        : (playedToday ? colorScheme.onSurface : colorScheme.onSurfaceVariant);
    final iconColor = onPhoto
        ? (playedToday ? _flameColor : Colors.white70)
        : (playedToday
            ? _flameColor
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.7));
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        container: true,
        label: message,
        excludeSemantics: true,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 16,
                  color: iconColor,
                ),
                const SizedBox(width: 3),
                Text(
                  l10n.homeStreakChip(days),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
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
