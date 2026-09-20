import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:sudoku159/widgets/press_scale.dart';
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
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/home/level_picker_screen.dart';
import 'package:sudoku159/view/home/saved_games_screen.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:sudoku159/widgets/profile_editor_sheet.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/theme/system_ui_style.dart';
import 'package:sudoku159/widgets/mascot_image.dart';
import 'package:sudoku159/widgets/profile_glass_header.dart';
import 'package:sudoku159/widgets/sudoku_motif.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.homeDashboardService,
    this.levelProgressService,
    this.databaseHelper,
    this.gameStateService,
  });

  /// 테스트에서 저장소를 대체하기 위한 선택적 주입. 기본값은 실제 구현.
  final HomeDashboardService? homeDashboardService;
  final LevelProgressService? levelProgressService;
  final DatabaseHelper? databaseHelper;
  final GameStateService? gameStateService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 프로필 헤더 아래와 스크롤 본문(히어로) 사이 여백.
  static const double _kBelowProfileHeaderGap = 14;

  /// `extendBody` + 플로팅 하단 탭 높이(68) + 여유 공간.
  static const double _kHomeScrollBottomPad = 80;

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
  bool _isTop = true;

  /// 첫 로딩이 끝났는지 / 마지막 로딩이 실패했는지. 로딩 중에는 '진행 중 없음'을
  /// 확정해서 보여주지 않고, 재로딩(복귀·기록 변경) 때는 기존 화면을 유지한다.
  bool _homeLoaded = false;
  bool _homeLoadFailed = false;
  int _dashboardRequestId = 0;
  bool _isOpeningGame = false;
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
  bool _todayChallengeHasSession = false;

  /// 같은 날짜의 도전이 미완료→완료로 바뀐 직후에만 true. 완료 체크가
  /// 나타나는 동안만 유지하고, 앱 시작·날짜 변경으로 이미 완료된 카드에는 쓰지 않는다.
  bool _challengeJustCompleted = false;

  @override
  void initState() {
    super.initState();
    _databaseManager.catalogStatus.addListener(_handleCatalogStatusChanged);
    GameRecordNotifier.instance.version.addListener(_handleRecordsChanged);
    _profileState.addListener(_handleProfileStateChanged);
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
        _todayChallengeHasSession = data.todayChallengeHasSession;
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
        _todayChallengeHasSession = false;
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
    _scrollController.dispose();
    super.dispose();
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
              '${summary.level.localizedName(l10n)} · #${summary.game.gameNumber.toString().padLeft(3, '0')}',
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

  /// "새 게임 시작": 난이도 선택 영역으로 이동한다.
  void _scrollToLevels() {
    final ctx = _levelSectionKey.currentContext;
    if (ctx == null || !_scrollController.hasClients) return;
    final box = ctx.findRenderObject();
    if (box == null) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    // 태블릿 레이아웃은 본문이 고정 헤더 뒤로 스크롤되므로 헤더 높이만큼 비운다.
    // (모바일은 스크롤 영역이 헤더 아래에서 시작한다.)
    final obscured = MediaQuery.sizeOf(context).width > 600
        ? _headerHeight(MediaQuery.paddingOf(context).top)
        : 0.0;
    final position = _scrollController.position;
    final target = (viewport.getOffsetToReveal(box, 0.0).offset - obscured - 8)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// 카드에 표시된 오늘의 도전 타깃을 그대로 연다. 표시와 시작에 같은 스냅샷을
  /// 쓰며, 그사이 날짜가 바뀌었다면 화면을 먼저 갱신하고 다른 문제는 열지 않는다.
  Future<void> _openTodayChallenge() async {
    final game = _todayChallenge;
    final challengeDate = _challengeProgress?.challengeDate;
    if (!_homeLoaded || _isOpeningGame) return;
    if (game == null || challengeDate == null) {
      await _loadHomeDashboard();
      return;
    }
    if (challengeDate !=
        ChallengeProgressService.formatLocalDate(DateTime.now())) {
      await _loadHomeDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.homeTodayChallengeDateChanged,
          ),
        ),
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
      value: systemOverlayStyleFor(Theme.of(context).brightness),
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
            padding: EdgeInsets.fromLTRB(
              24,
              _headerHeight(topInset) + _kBelowProfileHeaderGap,
              24,
              _kHomeScrollBottomPad + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHomeHero(isTablet: true),
                const SizedBox(height: 20),
                _buildLevelExplorer(isTablet: true, isLandscape: isLandscape),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildGlassProfileHeader(),
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
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              _headerHeight(topInset) + _kBelowProfileHeaderGap,
              16,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      bottom: _kHomeScrollBottomPad + bottomInset,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHomeHero(),
                        const SizedBox(height: 8),
                        _buildLevelExplorer(),
                      ],
                    ),
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
          child: _buildGlassProfileHeader(),
        ),
      ],
    );
  }

  /// 스크롤 콘텐츠가 아래로 지나갈 때 블러로 비치는 상단 프로필 바 (상태바 영역까지 동일 글래스)
  Widget _buildGlassProfileHeader() {
    final l10n = AppLocalizations.of(context)!;
    _measureHeader();
    return KeyedSubtree(
      key: _headerKey,
      child: ProfileGlassHeader(
        isTop: _isTop,
        profileName: _profileName,
        guestTitle: l10n.homeGuestTitle,
        profileImagePath: _profileImagePath,
        onTapSettings: _openSettings,
        onTapEditProfile: _openProfileEditor,
      ),
    );
  }

  /// 헤더의 실제 높이. 헤더는 Stack 위에 떠 있고 본문 시작 위치는 이 값으로
  /// 예약하므로, 추정 상수 대신 렌더링된 높이를 그대로 쓴다(큰 글씨·긴 이름 대응).
  double? _measuredHeaderHeight;
  final GlobalKey _headerKey = GlobalKey();

  /// 첫 프레임 전에는 기본 글씨 기준 추정값(상태바 + 64).
  double _headerHeight(double topInset) =>
      _measuredHeaderHeight ?? topInset + 64;

  void _measureHeader() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final height = box.size.height;
      if (_measuredHeaderHeight == null ||
          (_measuredHeaderHeight! - height).abs() > 0.5) {
        setState(() => _measuredHeaderHeight = height);
      }
    });
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
    // 이어하기 카드에 '오늘의 도전' 표시만 붙인다.
    final sameAsChallenge = continueGame != null &&
        challenge != null &&
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              // 큰 글씨: 장식(펭귄·원)을 생략해 공간을 텍스트와 버튼에 쓴다.
              // 기본 글씨: 넓으면 오른쪽 104, 좁으면 위쪽 72.
              final _MascotLayout layout = textScale > 1.3
                  ? _MascotLayout.none
                  : (constraints.maxWidth >= 300
                      ? _MascotLayout.side
                      : _MascotLayout.top);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  switch (layout) {
                    _MascotLayout.side => Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: textBlock),
                          const SizedBox(width: 14),
                          const _WelcomeMascot(size: 104),
                        ],
                      ),
                    _MascotLayout.top => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: _WelcomeMascot(size: 72)),
                          const SizedBox(height: 8),
                          textBlock,
                        ],
                      ),
                    _MascotLayout.none => textBlock,
                  },
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
              );
            },
          ),
        ),
      );
    }

    final level = continueGame.level;
    final levelImage = _levelIdentityImage(level.difficulty);
    final title =
        '${level.localizedName(l10n)} · #${continueGame.game.gameNumber.toString().padLeft(3, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _homeCard(
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
                        l10n.homeContinueTitle,
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
                        _continueDetail(l10n, continueGame),
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
            if (isTodayChallenge) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.calendar_today_rounded, size: 14),
                  label: Text(l10n.challengeTodaysChallengeTitle),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: cs.outlineVariant),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : _openContinueGame,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(l10n.levelContinueButton),
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
      ),
    );
  }

  /// 오늘의 도전: 일반 이어하기와 별도 항목. 미시작 / 진행 중 / 완료를 구분한다.
  Widget _buildTodayChallengeCard(SudokuGame? game) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final done = _challengeProgress?.isTodayChallengeCleared ?? false;
    final busy = _isOpeningGame;
    final title = game == null
        ? l10n.homeTodayChallengeLoadError
        : '${game.levelName.localizedSudokuLevelName(l10n)} · #${game.gameNumber.toString().padLeft(3, '0')}';
    final status = game == null
        ? null
        : done
            ? l10n.levelFilterDone
            : _todayChallengeHasSession
                ? l10n.levelStatusInProgress
                : null;
    final buttonLabel = game == null
        ? l10n.levelTryAgain
        : done
            ? l10n.homeTodayChallengeReviewButton
            : _todayChallengeHasSession
                ? l10n.homeTodayChallengeResumeButton
                : l10n.homeTodayChallengeStartButton;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _homeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // 도전을 불러오지 못했거나, 좁거나 글씨가 크면 장식은 생략한다.
                final showMotif = game != null &&
                    constraints.maxWidth >= 300 &&
                    MediaQuery.textScalerOf(context).scale(1.0) <= 1.3;
                final textBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.challengeTodaysChallengeTitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        if (status != null)
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
                              ),
                              children: [
                                if (done)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: FadeInOnce(
                                        enabled: _challengeJustCompleted,
                                        onEnd: _finishChallengeCompleteFade,
                                        child: Icon(Icons.check_circle_rounded,
                                            size: 16, color: cs.primary),
                                      ),
                                    ),
                                  ),
                                TextSpan(text: status),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                );
                return showMotif
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: textBlock),
                          const SizedBox(width: 12),
                          SudokuMotif(
                            size: 60,
                            checked: done,
                            animateCheck: done && _challengeJustCompleted,
                            onCheckAnimated: _finishChallengeCompleteFade,
                          ),
                        ],
                      )
                    : textBlock;
              },
            ),
            const SizedBox(height: 12),
            // 완료했다면 시작을 재촉하지 않도록 보조 버튼으로 낮춘다.
            if (done && game != null)
              OutlinedButton(
                onPressed: busy ? null : _openTodayChallenge,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                child: Text(buttonLabel, textAlign: TextAlign.center),
              )
            else
              FilledButton.tonal(
                onPressed: busy ? null : _openTodayChallenge,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                ),
                child: Text(buttonLabel, textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
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
    if (!isLandscape) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(4, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
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
          children: List.generate(4, (index) {
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
      badgeImage: levelImages[index],
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
    return IgnorePointer(
      ignoring: !widget.isEnabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
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

enum _MascotLayout { side, top, none }

/// 시작 안내 카드의 마스코트: 옅은 보라 원 위에 웃으며 손 흔드는 펭귄.
class _WelcomeMascot extends StatelessWidget {
  const _WelcomeMascot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final purple = LevelStatusPalette.of(context).primaryPurple;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.86,
            height: size * 0.86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: purple.withValues(alpha: 0.12),
            ),
          ),
          MascotImage(asset: MascotImage.welcome, size: size * 0.94),
        ],
      ),
    );
  }
}
