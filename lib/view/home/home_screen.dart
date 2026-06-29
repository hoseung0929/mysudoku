import 'package:flutter/material.dart';
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
import 'package:sudoku159/services/home/level_progress_service.dart';
import 'package:sudoku159/services/home/my_pace_service.dart';
import 'package:sudoku159/services/profile/profile_state_service.dart';
import 'package:sudoku159/navigation/app_page_route.dart';
import 'package:sudoku159/view/home/level_picker_screen.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:sudoku159/widgets/profile_editor_sheet.dart';
import 'package:sudoku159/widgets/profile_glass_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 상태바 아래 프로필 바 본문 높이 (padding 22+18 + 아바타·테두리 열 ~62). 상태바 높이는 별도 합산.
  static const double _kProfileHeaderExtent = 104;

  /// 프로필 헤더 아래와 스크롤 본문(히어로) 사이 여백.
  static const double _kBelowProfileHeaderGap = 18;

  /// `extendBody` + 플로팅 하단 탭 높이(68) + 여유 공간.
  static const double _kHomeScrollBottomPad = 80;

  final DatabaseManager _databaseManager = DatabaseManager();
  final LevelProgressService _levelProgressService = LevelProgressService();
  final HomeDashboardService _homeDashboardService = HomeDashboardService();
  final ProfileStateService _profileStateService = ProfileStateService();
  final MyPaceService _myPaceService = MyPaceService();
  final ScrollController _scrollController = ScrollController();
  bool _isTop = true;
  bool _isLoadingHome = true;
  bool _isLevelTransitioning = false;
  int? _transitioningLevelIndex;
  bool _showCatalogIntro = false;
  String? _profileImagePath;
  String? _profileName;
  String? _profileBio;
  List<SudokuLevel> _levels = List<SudokuLevel>.from(SudokuLevel.levels);

  /// 레벨별 전체 게임 수 (DB 기준)
  Map<String, int> _levelTotal = {};
  ContinueGameSummary? _continueGame;
  SudokuGame? _todayChallenge;
  ChallengeProgressSummary? _challengeProgress;
  MyPaceTarget? _myPacePreviewTarget;

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
      _profileBio = snapshot.bio;
    });
  }

  Future<void> _saveProfile({
    required String? name,
    required bool removeImage,
    String? pickedImagePath,
    String? bio,
  }) async {
    final snapshot = await _profileStateService.save(
      name: name,
      removeImage: removeImage,
      currentImagePath: _profileImagePath,
      pickedImagePath: pickedImagePath,
      bio: bio,
    );
    if (!mounted) return;
    setState(() {
      _profileName = snapshot.name;
      _profileImagePath = snapshot.imagePath;
      _profileBio = snapshot.bio;
    });
  }

  Future<void> _openProfileEditor() async {
    await showProfileEditorSheet(
      context: context,
      profileImageService: _profileStateService.profileImageService,
      initialProfileName: _profileName,
      initialProfileImagePath: _profileImagePath,
      initialBio: _profileBio,
      onSave: ({
        required String? name,
        required bool removeImage,
        String? pickedImagePath,
        String? bio,
      }) =>
          _saveProfile(
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
    setState(() {
      _isLoadingHome = true;
    });

    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final data = await _homeDashboardService.load(l10n);
      final myPacePreview = await _myPaceService.resolveTarget(
        preferContinueGame: data.continueGame,
      );
      if (mounted) {
        setState(() {
          _continueGame = data.continueGame;
          _todayChallenge = data.todayChallenge;
          _challengeProgress = data.challengeProgress;
          _myPacePreviewTarget = myPacePreview;
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
  }) async {
    await Navigator.push(
      context,
      buildAppPageRoute(
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
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
                    ? _buildTabletLayout(topInset)
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
              topInset + _kProfileHeaderExtent + _kBelowProfileHeaderGap,
              24,
              _kHomeScrollBottomPad + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHomeHero(),
                const SizedBox(height: 20),
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
              topInset + _kProfileHeaderExtent + _kBelowProfileHeaderGap,
              16,
              _kHomeScrollBottomPad + bottomInset,
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
                _buildHomeHero(),
                const SizedBox(height: 16),
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
    return ProfileGlassHeader(
      isTop: _isTop,
      profileName: _profileName,
      guestTitle: l10n.homeGuestTitle,
      profileImagePath: _profileImagePath,
      onTapSettings: _openSettings,
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
      ],
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

  Widget _buildTodaySpotlightCard(SudokuGame game) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final challengeDone = _challengeProgress?.isTodayChallengeCleared ?? false;
    final myPaceLabel = _myPacePreviewLabel(l10n);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/app_logo.png',
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.homeTodayLabel,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.homeTodayPuzzleTitle,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              myPaceLabel ??
                  (challengeDone
                      ? l10n.challengeTodayDoneHint
                      : '${game.levelName.localizedSudokuLevelName(l10n)} · #${game.gameNumber.toString().padLeft(3, '0')}'),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.72,
                child: FilledButton(
                  onPressed: _openMyPaceGame,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF2A3540)
                        : colorScheme.primary,
                    foregroundColor: isDark
                        ? const Color(0xFFDDE8F4)
                        : colorScheme.onPrimary,
                    minimumSize: const Size.fromHeight(54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF3A4A5A)
                            : colorScheme.outlineVariant.withValues(
                                alpha: 0.85,
                              ),
                      ),
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
      ),
    );
  }

  String? _myPacePreviewLabel(AppLocalizations l10n) {
    final target = _myPacePreviewTarget;
    if (target == null) {
      return null;
    }
    return '${target.level.localizedName(l10n)} · #${target.game.gameNumber.toString().padLeft(3, '0')}';
  }

  Widget _buildLevelExplorer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(5, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == 4 ? 0 : 12),
          child: _buildLevelCard(index),
        );
      }),
    );
  }

  Widget _buildLevelGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
      const Color(0xFFBFE7D5), // 초급 - 라이트 민트
      const Color(0xFF7FCFC7), // 중급 - 티얼 (hue 차이로 구분)
      const Color(0xFFD8C08E), // 고급 - 탄/골드
      const Color(0xFFD8A6BE), // 전문가 - 핑크
      const Color(0xFFA8CBE6), // 마스터 - 블루
    ];
    final badgeColors = [
      null,
      const Color(0xFF4FA89F), // 중급 badge - 더 진한 티얼
      const Color(0xFFC4A05A), // 고급 badge - 더 진한 탄
      const Color(0xFFC07898), // 전문가 badge - 더 진한 핑크
      const Color(0xFFC9A227), // 마스터 badge - 골드
    ];
    final badges = <IconData>[
      Icons.eco_rounded,
      Icons.local_fire_department_rounded,
      Icons.star_rounded,
      Icons.diamond_rounded,
      Icons.emoji_events_rounded,
    ];
    final badgeSizes = [34.0, 32.0, 32.0, 32.0, 34.0];

    return _LevelCard(
      color: colors[index],
      badgeColor: badgeColors[index],
      badgeIcon: badges[index],
      badgeSize: badgeSizes[index],
      title: level.localizedName(l10n),
      completed: completed,
      remaining: remaining,
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
  final double badgeSize;
  final String title;
  final int completed;
  final int remaining;
  final bool isEnabled;
  final bool isTransitioning;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.color,
    required this.badgeColor,
    required this.badgeIcon,
    required this.badgeSize,
    required this.title,
    required this.completed,
    required this.remaining,
    required this.isEnabled,
    required this.isTransitioning,
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
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
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
                  badgeColor: widget.badgeColor,
                  badgeSize: widget.badgeSize,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        progressLabel,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: widget.isTransitioning
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.1,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        )
                      : Icon(
                          key: const ValueKey('chevron'),
                          Icons.chevron_right_rounded,
                          size: 28,
                          color: colorScheme.onSurfaceVariant,
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

class _DifficultyIcon extends StatelessWidget {
  const _DifficultyIcon({
    required this.color,
    required this.badgeIcon,
    required this.badgeColor,
    required this.badgeSize,
  });

  final Color color;
  final IconData badgeIcon;
  final Color? badgeColor;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Center(
        child: Icon(badgeIcon, size: badgeSize, color: badgeColor ?? color),
      ),
    );
  }
}
