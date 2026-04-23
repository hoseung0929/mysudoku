import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/database/database_manager.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/services/game_record_notifier.dart';
import 'package:mysudoku/services/home_dashboard_service.dart';
import 'package:mysudoku/services/level_progress_service.dart';
import 'package:mysudoku/services/my_pace_service.dart';
import 'package:mysudoku/services/onboarding_service.dart';
import 'package:mysudoku/services/profile_state_service.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:mysudoku/view/level_selection_screen.dart';
import 'package:mysudoku/view/saved_games_screen.dart';
import 'package:mysudoku/view/settings_screen.dart';
import 'package:mysudoku/view/sudoku_game_screen.dart';
import 'package:mysudoku/widgets/profile_editor_sheet.dart';
import 'package:mysudoku/widgets/profile_glass_header.dart';

class LevelSelectionMain extends StatefulWidget {
  const LevelSelectionMain({
    super.key,
    this.showExploreOnly = false,
  });

  final bool showExploreOnly;

  @override
  State<LevelSelectionMain> createState() => _LevelSelectionMainState();
}

class _LevelSelectionMainState extends State<LevelSelectionMain> {
  /// 상태바 아래 프로필 바 본문 높이 (padding 22+18 + 아바타 열 ~56). 상태바 높이는 별도 합산.
  static const double _kProfileHeaderExtent = 96;

  static const Color _cpForest = Color(0xFF285B3F);
  static const Color _cpForestSoft = Color(0xFF5D7A69);
  static const Color _cpInk = Color(0xFF21382A);
  static const Color _cpBlue = Color(0xFF457B9D);

  final DatabaseManager _databaseManager = DatabaseManager();
  final LevelProgressService _levelProgressService = LevelProgressService();
  final HomeDashboardService _homeDashboardService = HomeDashboardService();
  final OnboardingService _onboardingService = OnboardingService();
  final ProfileStateService _profileStateService = ProfileStateService();
  final MyPaceService _myPaceService = MyPaceService();
  int? _selectedIndex;
  final ScrollController _scrollController = ScrollController();
  bool _isTop = true;
  bool _isLoadingHome = true;
  bool _isShowingOnboarding = false;
  bool _hasResolvedHomeOnboarding = false;
  bool _showCatalogIntro = false;
  String? _profileImagePath;
  String? _profileName;
  List<SudokuLevel> _levels = List<SudokuLevel>.from(SudokuLevel.levels);

  /// 레벨별 전체 게임 수 (DB 기준)
  Map<String, int> _levelTotal = {};
  ContinueGameSummary? _continueGame;
  List<ContinueGameSummary> _continueGames = [];
  SudokuGame? _todayChallenge;
  ChallengeProgressSummary? _challengeProgress;

  @override
  void initState() {
    super.initState();
    _databaseManager.catalogStatus.addListener(_handleCatalogStatusChanged);
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
    _loadLevelTotals();
    _refreshLevels();
    _loadProfile();
    if (widget.showExploreOnly) {
      _isLoadingHome = false;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadHomeDashboard();
      });
      _maybeShowHomeOnboarding();
    }
  }

  @override
  void didUpdateWidget(covariant LevelSelectionMain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showExploreOnly == widget.showExploreOnly) {
      return;
    }

    if (widget.showExploreOnly) {
      if (!mounted) return;
      setState(() {
        _isLoadingHome = false;
        _showCatalogIntro = false;
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadHomeDashboard();
      if (_hasResolvedHomeOnboarding) {
        _syncCatalogIntroVisibility();
      } else {
        _maybeShowHomeOnboarding();
      }
    });
  }

  void _handleRecordsChanged() {
    if (!mounted) return;
    _refreshLevels();
    if (!widget.showExploreOnly) {
      _loadHomeDashboard();
    }
  }

  Future<void> _loadLevelTotals() async {
    final dbHelper = DatabaseHelper();
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

  Future<void> _loadProfile() async {
    final snapshot = await _profileStateService.load();
    if (!mounted) return;
    setState(() {
      _profileImagePath = snapshot.imagePath;
      _profileName = snapshot.name;
    });
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
    setState(() {
      _isLoadingHome = true;
    });

    try {
      if (!mounted) return;
      try {
        await GameStateService().syncBidirectional();
      } catch (e) {
        if (kDebugMode) {
          AppLogger.debug('클라우드 세이브 동기화 실패: $e');
        }
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final data = await _homeDashboardService.load(l10n);
      if (mounted) {
        setState(() {
          _continueGame = data.continueGame;
          _continueGames = data.continueGames;
          _todayChallenge = data.todayChallenge;
          _challengeProgress = data.challengeProgress;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHome = false;
        });
      }
    }
  }

  Future<void> _maybeShowHomeOnboarding() async {
    final shouldShow = await _onboardingService.shouldShowHomeOnboarding();
    if (!mounted) return;
    if (!shouldShow || _isShowingOnboarding) {
      _hasResolvedHomeOnboarding = true;
      _syncCatalogIntroVisibility();
      return;
    }

    _isShowingOnboarding = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final l10n = AppLocalizations.of(dialogContext)!;
          final colorScheme = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              l10n.homeOnboardingWelcomeTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GuideStep(
                  icon: Icons.play_circle_fill,
                  title: l10n.homeOnboardingStepQuickTitle,
                  description: l10n.homeOnboardingStepQuickBody,
                ),
                const SizedBox(height: 12),
                _GuideStep(
                  icon: Icons.bolt,
                  title: l10n.homeOnboardingStepDailyTitle,
                  description: l10n.homeOnboardingStepDailyBody,
                ),
                const SizedBox(height: 12),
                _GuideStep(
                  icon: Icons.history,
                  title: l10n.homeOnboardingStepResumeTitle,
                  description: l10n.homeOnboardingStepResumeBody,
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.homeOnboardingStartButton),
              ),
            ],
          );
        },
      );
      await _onboardingService.markHomeOnboardingSeen();
      _isShowingOnboarding = false;
      _hasResolvedHomeOnboarding = true;
      _syncCatalogIntroVisibility();
    });
  }

  @override
  void dispose() {
    _databaseManager.catalogStatus.removeListener(_handleCatalogStatusChanged);
    GameRecordNotifier.instance.version.removeListener(_handleRecordsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleCatalogStatusChanged() {
    if (!mounted) return;
    _syncCatalogIntroVisibility();
  }

  void _syncCatalogIntroVisibility() {
    final status = _databaseManager.catalogStatus.value;
    final shouldShow = _hasResolvedHomeOnboarding &&
        !_isShowingOnboarding &&
        !widget.showExploreOnly &&
        _databaseManager.shouldShowInitialCatalogIntro &&
        status.isRunning;

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

  void _goToGame(String title) async {
    final level = getLevel(title);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelSelectionScreen(level: level),
      ),
    );
    // 게임 화면에서 돌아온 뒤 클리어 수 갱신
    await _refreshLevels();
    await _loadHomeDashboard();
    if (mounted) setState(() {});
  }

  Future<void> _openGame(
    SudokuGame game,
    SudokuLevel level, {
    bool restoreSavedSession = false,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SudokuGameScreen(
          game: game,
          level: level,
          restoreSavedSession: restoreSavedSession,
        ),
      ),
    );
    await _refreshLevels();
    await _loadHomeDashboard();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openSavedGamesScreen() async {
    final allContinueGames = await _homeDashboardService.loadContinueGames();
    if (allContinueGames.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final selected = await Navigator.of(context).push<ContinueGameSummary>(
      MaterialPageRoute(
        builder: (context) => SavedGamesScreen(
          initialGames: allContinueGames,
          title: _savedGamesTitle(),
          description: _savedGamesDescription(),
          itemTitleBuilder: (summary) => l10n.recordsGameNumberTitle(
            summary.level.localizedName(l10n),
            summary.game.gameNumber,
          ),
          itemSubtitleBuilder: (summary) => _savedGameListSubtitle(summary),
          deleteTooltip: _deleteLabel(),
          onDelete: (summary) async {
            final shouldDelete = await _confirmDeleteSavedGame(summary);
            if (!shouldDelete) {
              return allContinueGames;
            }
            await _deleteSavedGame(summary);
            return _homeDashboardService.loadContinueGames();
          },
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _openGame(
      selected.game,
      selected.level,
      restoreSavedSession: true,
    );
  }

  Future<void> _openMyPaceGame() async {
    final target = await _myPaceService.resolveTarget(
      preferContinueGame: _continueGame,
    );

    if (!mounted) return;

    if (target != null) {
      final uiLevel = _levels.firstWhere(
        (item) => item.name == target.level.name,
        orElse: () => target.level,
      );
      await _openGame(
        target.game,
        uiLevel,
        restoreSavedSession: target.restoreSavedSession,
      );
      return;
    }

    await _showNoPlayableGameDialog();
  }

  Future<void> _showNoPlayableGameDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.myPaceNoPlayableTitle),
          content: Text(l10n.myPaceNoPlayableMessage),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonOk),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDeleteSavedGame(ContinueGameSummary summary) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(_deleteSavedGameTitle()),
          content: Text(
            _deleteSavedGameMessage(
              l10n.recordsGameNumberTitle(
                summary.level.localizedName(l10n),
                summary.game.gameNumber,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_cancelLabel()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_deleteLabel()),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _deleteSavedGame(ContinueGameSummary summary) async {
    final gameStateService = GameStateService();
    await gameStateService.clearBoard(
      levelName: summary.level.name,
      gameNumber: summary.game.gameNumber,
    );
    await _loadHomeDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
      ),
      child: DecoratedBox(
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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              SafeArea(
                top: false,
                bottom: false,
                child: isTablet
                    ? _buildTabletLayout(topInset)
                    : _buildMobileLayout(topInset),
              ),
              if (_showCatalogIntro && !widget.showExploreOnly)
                _buildCatalogIntroOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  /// 태블릿 레이아웃
  Widget _buildTabletLayout(double topInset) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              24,
              topInset + _kProfileHeaderExtent + 12,
              24,
              76 + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.showExploreOnly) ...[
                  _buildHomeHero(),
                  const SizedBox(height: 20),
                ],
                _buildLevelGrid(),
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
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              16,
              topInset + _kProfileHeaderExtent + 12,
              16,
              72 + bottomInset,
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
                if (!widget.showExploreOnly) ...[
                  _buildHomeHero(),
                  const SizedBox(height: 16),
                ],
                _buildLevelExplorer(),
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
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    return ProfileGlassHeader(
      isTop: _isTop,
      profileName: _profileName,
      guestTitle: l10n.homeGuestTitle,
      profileImagePath: _profileImagePath,
      onTapSettings: _openSettings,
      sectionLabel: widget.showExploreOnly ? null : (isKorean ? '홈' : 'Home'),
      onTapEditProfile: _openProfileEditor,
    );
  }

  Widget _buildHomeHero() {
    if (_isLoadingHome) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_todayChallenge != null) _buildTodaySpotlightCard(_todayChallenge!),
        if (_challengeProgress != null) ...[
          const SizedBox(height: 14),
          _buildHomeChallengeSection(_challengeProgress!),
        ],
        if (_continueGame != null) ...[
          const SizedBox(height: 18),
          _buildContinueCard(_continueGame!),
        ],
      ],
    );
  }

  Widget _buildCatalogIntroOverlay() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
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
                      color: const Color(0xFFFDFBF6),
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
                              isKorean
                                  ? '첫 퍼즐 세트를 준비하고 있어요'
                                  : 'Preparing your first puzzle set',
                              style: TextStyle(
                                fontSize: 24,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isKorean
                                  ? '처음 실행에서는 스도쿠 문제를 기기에 저장해요. 잠시만 기다리면 이후부터는 훨씬 빠르게 열려요.'
                                  : 'On your first launch, Sudoku puzzles are saved on your device. After this, the app opens much faster.',
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
                              isKorean
                                  ? '준비는 백그라운드에서도 계속돼요. 지금 바로 둘러봐도 괜찮아요.'
                                  : 'Preparation continues in the background, so you can keep exploring right away.',
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
                                  isKorean ? '홈으로 계속' : 'Continue to home',
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

  Widget _buildTodaySpotlightCard(SudokuGame game) {
    final l10n = AppLocalizations.of(context)!;
    final challengeDone = _challengeProgress?.isTodayChallengeCleared ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cpForest,
            _cpForestSoft,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _cpForest.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 4, top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              Localizations.localeOf(context).languageCode == 'ko'
                  ? 'Today'
                  : 'Today',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            Localizations.localeOf(context).languageCode == 'ko'
                ? '오늘의 퍼즐 하나에\n부드럽게 몰입해보세요.'
                : 'Settle into\ntoday\'s one puzzle.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            challengeDone
                ? l10n.challengeTodayDoneHint
                : l10n.recordsGameNumberTitle(
                    game.levelName.localizedSudokuLevelName(l10n),
                    game.gameNumber,
                  ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 168),
              child: FilledButton(
                onPressed: _openMyPaceGame,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF8F4E8),
                  foregroundColor: _cpForest,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  challengeDone
                      ? l10n.challengeTodayReviewButton
                      : l10n.challengeTodayStartButton,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _continueMatchesTodaySpotlight(ContinueGameSummary summary) {
    final today = _todayChallenge;
    if (today == null) return false;
    return summary.game.levelName == today.levelName &&
        summary.game.gameNumber == today.gameNumber;
  }

  Widget _buildContinueCard(ContinueGameSummary summary) {
    final l10n = AppLocalizations.of(context)!;
    final sameAsSpotlight = _continueMatchesTodaySpotlight(summary);
    final progressPercent = (summary.progress * 100).round().clamp(0, 100);
    return _ResumeActionCard(
      title: Localizations.localeOf(context).languageCode == 'ko'
          ? '마음의 퍼즐 잇기'
          : 'Resume gently',
      subtitle: sameAsSpotlight
          ? l10n.homeProgressPercent(progressPercent)
          : l10n.recordsGameNumberTitle(
              summary.level.localizedName(l10n),
              summary.game.gameNumber,
            ),
      metaLabel: _savedGameListSubtitle(summary),
      supportingLabel: sameAsSpotlight
          ? l10n.homeContinueSameAsSpotlightSupporting
          : (Localizations.localeOf(context).languageCode == 'ko'
              ? '최근 퍼즐'
              : 'Recent puzzle'),
      savedGamesLabel: _continueGames.length > 1
          ? _savedGamesCta(_continueGames.length)
          : null,
      onTap: () => _openGame(
        summary.game,
        summary.level,
        restoreSavedSession: true,
      ),
      onSavedGamesTap: _continueGames.length > 1 ? _openSavedGamesScreen : null,
    );
  }

  Widget _buildHomeChallengeSection(ChallengeProgressSummary challenge) {
    final l10n = AppLocalizations.of(context)!;
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_florist_outlined,
              size: 18,
              color: _cpBlue,
            ),
            const SizedBox(width: 8),
            Text(
              isKorean ? '챌린지 흐름' : 'Challenge rhythm',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _cpBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HomeChallengeMiniStatCard(
                eyebrow: isKorean ? '연속 기록' : 'Streak',
                value: challenge.streakDays > 0
                    ? l10n.challengeStreakDays(challenge.streakDays)
                    : l10n.challengeStreakStartToday,
                tone: const Color(0xFFE7F0E8),
                accent: const Color(0xFF457B9D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HomeChallengeMiniStatCard(
                eyebrow: isKorean ? '이번 주 흐름' : 'This week',
                value: challenge.isWeeklyGoalAchieved
                    ? l10n.challengeWeeklyGoalReachedTitle
                    : l10n.challengeWeeklyGoalRemainingTitle(
                        challenge.remainingWeeklyGoal,
                      ),
                tone: const Color(0xFFF2E9DA),
                accent: const Color(0xFFF4A261),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HomeWeeklyGoalCard(
          l10n: l10n,
          challenge: challenge,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _showChallengeMetricsBasisSheet,
            icon: const Icon(Icons.info_outline, size: 18),
            label: Text(
              isKorean ? '지표 기준 보기' : 'See metric basis',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showChallengeMetricsBasisSheet() async {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKorean ? '챌린지 지표 기준' : 'Challenge metric basis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isKorean
                      ? '주간 진행도: 최근 7일의 완료 이벤트 수를 기준으로 계산됩니다.'
                      : 'Weekly progress: based on clear events from the last 7 days.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isKorean
                      ? '연속 기록: 오늘의 도전을 완료한 날짜 연속성으로 계산됩니다.'
                      : 'Streak: based on consecutive dates when the daily challenge was completed.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _savedGamesTitle() {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '저장된 게임'
        : 'Saved games';
  }

  String _savedGamesDescription() {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '이어하고 싶은 퍼즐을 고르거나 정리할 수 있어요.'
        : 'Choose a puzzle to resume or remove old saves.';
  }

  String _savedGameListSubtitle(ContinueGameSummary summary) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final playedAt = DateFormat.Md(locale).add_Hm().format(
          DateTime.fromMillisecondsSinceEpoch(summary.lastPlayedAtMillis),
        );
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '마지막 플레이 $playedAt'
        : 'Last played $playedAt';
  }

  String _savedGamesCta(int count) {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '저장 게임 $count개'
        : '$count saved';
  }

  String _deleteSavedGameTitle() {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '저장 게임 삭제'
        : 'Delete saved game';
  }

  String _deleteSavedGameMessage(String label) {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '$label 저장 상태를 삭제할까요? 퍼즐 기록은 유지되고 이어하기 정보만 지워집니다.'
        : 'Delete the saved state for $label? Puzzle records stay, but resume data will be removed.';
  }

  String _cancelLabel() {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '취소'
        : 'Cancel';
  }

  String _deleteLabel() {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '삭제'
        : 'Delete';
  }

  Widget _buildLevelExplorer() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.showExploreOnly) ...[
          Text(
            Localizations.localeOf(context).languageCode == 'ko'
                ? 'Explore Levels'
                : 'Explore Levels',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Localizations.localeOf(context).languageCode == 'ko'
                ? '지금 기분에 맞는 난이도를 바로 고를 수 있어요.'
                : 'Pick the difficulty that feels right for this moment.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
        ],
        ...List.generate(5, (index) => _buildLevelCard(index)),
      ],
    );
  }

  Widget _buildLevelGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.showExploreOnly) ...[
          Text(
            Localizations.localeOf(context).languageCode == 'ko'
                ? 'Explore Levels'
                : 'Explore Levels',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Localizations.localeOf(context).languageCode == 'ko'
                ? '차분하게 시작할지, 깊게 몰입할지 고를 수 있어요.'
                : 'Choose between a gentle start or deeper focus.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.45,
          ),
          itemCount: 5,
          itemBuilder: (context, index) => _buildLevelCard(index),
        ),
      ],
    );
  }

  Widget _buildLevelCard(int index) {
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
      const Color(0xFFBFE2D0),
      const Color(0xFFCDE7E0),
      const Color(0xFFE6D4B8),
      const Color(0xFFE6B8C8),
      const Color(0xFFB8D4E6),
    ];
    final icons = [
      Icons.grid_view,
      Icons.diamond,
      Icons.star,
      Icons.flash_on,
      Icons.workspace_premium,
    ];

    return _LevelCard(
      color: colors[index],
      icon: icons[index],
      title: level.localizedName(l10n),
      completed: completed,
      remaining: remaining,
      progressColor: const Color(0xFF8DC6B0),
      isSelected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _goToGame(levelTitles[index]);
      },
    );
  }
}

class _ResumeActionCard extends StatelessWidget {
  const _ResumeActionCard({
    required this.title,
    required this.subtitle,
    required this.metaLabel,
    required this.supportingLabel,
    required this.onTap,
    this.savedGamesLabel,
    this.onSavedGamesTap,
  });

  final String title;
  final String subtitle;
  final String metaLabel;
  final String supportingLabel;
  final VoidCallback onTap;
  final String? savedGamesLabel;
  final VoidCallback? onSavedGamesTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.64),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE4DED3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _LevelSelectionMainState._cpBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                supportingLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _LevelSelectionMainState._cpInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metaLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (savedGamesLabel != null && onSavedGamesTap != null) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onSavedGamesTap,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: Text(savedGamesLabel!),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerLow,
                      alignment: Alignment.center,
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.outlineVariant),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeChallengeMiniStatCard extends StatelessWidget {
  const _HomeChallengeMiniStatCard({
    required this.eyebrow,
    required this.value,
    required this.tone,
    required this.accent,
  });

  final String eyebrow;
  final String value;
  final Color tone;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4DED3)),
      ),
      child: Column(
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
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF21382A),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HomeWeeklyGoalCard extends StatelessWidget {
  const _HomeWeeklyGoalCard({
    required this.l10n,
    required this.challenge,
  });

  final AppLocalizations l10n;
  final ChallengeProgressSummary challenge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final goalSlots = challenge.weeklyGoalTarget.clamp(1, 7);
    final filledSlots = challenge.weeklyClearCount.clamp(0, goalSlots);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.challengeWeeklyGoalHeading,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.challengeWeeklyClearsLine(challenge.weeklyGoalTarget),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _HomeLeafProgressRow(
              filledCount: filledSlots,
              totalCount: goalSlots,
              isComplete: challenge.isWeeklyGoalAchieved,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HomeGoalMetaLabel(
                    icon: Icons.check_circle_outline,
                    label: l10n.challengeWeeklyProgressShort(
                      challenge.weeklyClearCount,
                      challenge.weeklyGoalTarget,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HomeGoalMetaLabel(
                    icon: Icons.auto_awesome,
                    label: l10n.challengeWeeklyPerfectShort(
                      challenge.perfectClearCount,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              challenge.isWeeklyGoalAchieved
                  ? l10n.challengeWeeklyCongratsFooter
                  : l10n.challengeWeeklyAlmostFooter(
                      challenge.remainingWeeklyGoal,
                    ),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeGoalMetaLabel extends StatelessWidget {
  const _HomeGoalMetaLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeLeafProgressRow extends StatelessWidget {
  const _HomeLeafProgressRow({
    required this.filledCount,
    required this.totalCount,
    required this.isComplete,
  });

  final int filledCount;
  final int totalCount;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filledColor =
        isComplete ? const Color(0xFF7AA874) : const Color(0xFF8EBE99);
    final emptyColor = colorScheme.surfaceContainerHighest;

    return Row(
      children: List.generate(totalCount, (index) {
        final filled = index < filledCount;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == totalCount - 1 ? 0 : 8),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color:
                    filled ? filledColor.withValues(alpha: 0.16) : emptyColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: filled
                      ? filledColor.withValues(alpha: 0.28)
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Center(
                child: Transform.rotate(
                  angle: filled ? -0.25 : 0,
                  child: Icon(
                    filled ? Icons.spa_rounded : Icons.eco_outlined,
                    size: 22,
                    color: filled ? filledColor : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.onSurface, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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
  final IconData icon;
  final String title;
  final int completed;
  final int remaining;
  final Color progressColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.completed,
    required this.remaining,
    required this.progressColor,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _pressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final total = widget.completed + widget.remaining;
    final percent = total == 0 ? 0.0 : widget.completed / total;
    final solvedLabel = Localizations.localeOf(context).languageCode == 'ko'
        ? '${widget.completed}개 완료'
        : '${widget.completed} solved';
    final remainingLabel = Localizations.localeOf(context).languageCode == 'ko'
        ? '${widget.remaining}개 남음'
        : '${widget.remaining} left';
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              _pressed ? colorScheme.surfaceContainerLow : colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.16
                    : 0.08,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                widget.icon,
                size: 36,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    solvedLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remainingLabel,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 7,
                      backgroundColor: widget.color.withValues(alpha: 0.25),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(widget.progressColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Container(
            //   width: 36,
            //   height: 36,
            //   decoration: BoxDecoration(
            //     color: Colors.grey.withValues(alpha: 0.12),
            //     shape: BoxShape.circle,
            //   ),
            //   child:
            //       const Icon(Icons.info_outline, color: Colors.grey, size: 22),
            // ),
          ],
        ),
      ),
    );
  }
}
