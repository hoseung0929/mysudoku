import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/database/database_manager.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/services/home_dashboard_service.dart';
import 'package:mysudoku/services/level_progress_service.dart';
import 'package:mysudoku/services/onboarding_service.dart';
import 'package:mysudoku/services/profile_image_service.dart';
import 'package:mysudoku/view/level_selection_screen.dart';
import 'package:mysudoku/view/saved_games_screen.dart';
import 'package:mysudoku/view/settings_screen.dart';
import 'package:mysudoku/view/sudoku_game_screen.dart';

class LevelSelectionMain extends StatefulWidget {
  const LevelSelectionMain({super.key});

  @override
  State<LevelSelectionMain> createState() => _LevelSelectionMainState();
}

class _LevelSelectionMainState extends State<LevelSelectionMain> {
  static const Color _cpSage = Color(0xFFE7F0E8);
  static const Color _cpOat = Color(0xFFF2E9DA);
  static const Color _cpForest = Color(0xFF285B3F);
  static const Color _cpForestSoft = Color(0xFF5D7A69);
  static const Color _cpInk = Color(0xFF21382A);
  static const Color _cpText = Color(0xFF66776C);
  static const Color _cpLine = Color(0xFFE4DED3);
  static const Color _cpCoral = Color(0xFFF4A261);
  static const Color _cpBlue = Color(0xFF457B9D);

  final DatabaseManager _databaseManager = DatabaseManager();
  final LevelProgressService _levelProgressService = LevelProgressService();
  final HomeDashboardService _homeDashboardService = HomeDashboardService();
  final OnboardingService _onboardingService = OnboardingService();
  final ProfileImageService _profileImageService = ProfileImageService();
  int? _selectedIndex;
  final ScrollController _scrollController = ScrollController();
  bool _isTop = true;
  bool _isLoadingHome = true;
  bool _isShowingOnboarding = false;
  String? _profileImagePath;
  String? _profileName;
  /// 레벨별 전체 게임 수 (DB 기준)
  Map<String, int> _levelTotal = {};
  ContinueGameSummary? _continueGame;
  List<ContinueGameSummary> _continueGames = [];
  SudokuGame? _todayChallenge;
  ChallengeProgressSummary? _challengeProgress;
  int _averageClearTimeSeconds = 0;

  @override
  void initState() {
    super.initState();
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
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadHomeDashboard();
    });
    _maybeShowHomeOnboarding();
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

  Future<void> _loadProfile() async {
    final profileImagePath = await _profileImageService.getProfileImagePath();
    final profileName = await _profileImageService.getProfileName();
    if (!mounted) return;
    setState(() {
      _profileImagePath = profileImagePath;
      _profileName = profileName;
    });
  }

  Future<void> _saveProfile({
    required String? name,
    required bool removeImage,
    String? pickedImagePath,
  }) async {
    await _profileImageService.saveProfileName(name);
    if (removeImage) {
      await _profileImageService.clearProfileImage();
    }
    if (!mounted) return;
    setState(() {
      final trimmedName = name?.trim() ?? '';
      _profileName = trimmedName.isEmpty ? null : trimmedName;
      _profileImagePath = removeImage ? null : (pickedImagePath ?? _profileImagePath);
    });
  }

  Future<void> _openProfileEditor() async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: _profileName ?? '');
    var draftImagePath = _profileImagePath;
    var removeImage = false;
    final hasSavedImage =
        _profileImagePath != null && File(_profileImagePath!).existsSync();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final effectiveImagePath = removeImage ? null : draftImagePath;
            final hasImage =
                effectiveImagePath != null && File(effectiveImagePath).existsSync();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Localizations.localeOf(context).languageCode == 'ko'
                          ? '프로필 편집'
                          : 'Edit profile',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Localizations.localeOf(context).languageCode == 'ko'
                          ? '사진과 이름을 한 번에 바꿀 수 있어요.'
                          : 'Update your photo and name together.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: colorScheme.primaryContainer,
                            backgroundImage:
                                hasImage ? FileImage(File(effectiveImagePath)) : null,
                            child: hasImage
                                ? null
                                : Icon(
                                    Icons.person,
                                    size: 46,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.photo_camera,
                                size: 14,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pickedPath =
                                  await _profileImageService.pickAndSaveProfileImage();
                              if (pickedPath == null) return;
                              setSheetState(() {
                                draftImagePath = pickedPath;
                                removeImage = false;
                              });
                            },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(
                              Localizations.localeOf(context).languageCode == 'ko'
                                  ? '사진 변경'
                                  : 'Change photo',
                            ),
                          ),
                        ),
                        if (hasSavedImage || hasImage) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                removeImage = true;
                                draftImagePath = null;
                              });
                            },
                            child: Text(
                              Localizations.localeOf(context).languageCode == 'ko'
                                  ? '사진 제거'
                                  : 'Remove',
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLength: 20,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: Localizations.localeOf(context).languageCode == 'ko'
                            ? '이름'
                            : 'Name',
                        hintText: l10n.homeGuestTitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'ko'
                                ? '취소'
                                : 'Cancel',
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () async {
                            await _saveProfile(
                              name: controller.text,
                              removeImage: removeImage,
                              pickedImagePath: draftImagePath,
                            );
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                          },
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'ko'
                                ? '저장'
                                : 'Save',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadHomeDashboard() async {
    setState(() {
      _isLoadingHome = true;
    });

    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final data = await _homeDashboardService.load(l10n);
      if (mounted) {
        setState(() {
          _continueGame = data.continueGame;
          _continueGames = data.continueGames;
          _todayChallenge = data.todayChallenge;
          _challengeProgress = data.challengeProgress;
          _averageClearTimeSeconds = data.averageClearTimeSeconds;
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
    if (!shouldShow || !mounted || _isShowingOnboarding) return;

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
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  SudokuLevel getLevel(String title) {
    return SudokuLevel.levels.firstWhere(
      (level) => level.name == _levelNameKor(title),
      orElse: () => SudokuLevel.levels.first,
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
    await _levelProgressService.refreshAllLevels(SudokuLevel.levels);
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
    await _levelProgressService.refreshAllLevels(SudokuLevel.levels);
    await _loadHomeDashboard();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openSavedGamesScreen() async {
    if (_continueGames.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final selected = await Navigator.of(context).push<ContinueGameSummary>(
      MaterialPageRoute(
        builder: (context) => SavedGamesScreen(
          initialGames: _continueGames,
          title: _savedGamesTitle(),
          description: _savedGamesDescription(),
          itemTitleBuilder: (summary) => l10n.recordsGameNumberTitle(
            summary.level.localizedName(l10n),
            summary.game.gameNumber,
          ),
          itemSubtitleBuilder: (summary) =>
              _savedGameListSubtitle(summary),
          deleteTooltip: _deleteLabel(),
          onDelete: (summary) async {
            final shouldDelete = await _confirmDeleteSavedGame(summary);
            if (!shouldDelete) {
              return _continueGames;
            }
            await _deleteSavedGame(summary);
            return _continueGames;
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  /// 태블릿 레이아웃
  Widget _buildTabletLayout() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(24, 24, 24, 76 + bottomInset),
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
      ],
    );
  }

  /// 모바일 레이아웃
  Widget _buildMobileLayout() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 72 + bottomInset),
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
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasProfileImage =
        _profileImagePath != null && File(_profileImagePath!).existsSync();
    final displayName = (_profileName?.trim().isNotEmpty ?? false)
        ? _profileName!
        : l10n.homeGuestTitle;
    final subtitleText = (_profileName?.trim().isNotEmpty ?? false)
        ? (Localizations.localeOf(context).languageCode == 'ko'
            ? '안녕, $displayName! 오늘 하루는 어땠나요?'
            : '$displayName, ready for one calm puzzle today?')
        : (Localizations.localeOf(context).languageCode == 'ko'
            ? '안녕! 오늘 하루는 어땠나요?'
            : 'One calm puzzle for today.');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        border: Border(
          bottom: BorderSide(
            color: _isTop ? colorScheme.surface : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: hasProfileImage
                            ? FileImage(File(_profileImagePath!))
                            : null,
                        child: hasProfileImage
                            ? null
                            : Icon(
                                Icons.person,
                                size: 28,
                                color: colorScheme.onPrimaryContainer,
                              ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openProfileEditor,
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 10,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildHomeHero() {
    final l10n = AppLocalizations.of(context)!;
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
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _EditorialMiniStatCard(
                eyebrow: Localizations.localeOf(context).languageCode == 'ko'
                    ? '마음의 준비'
                    : 'Gentle focus',
                value: _focusSummaryValue(),
                detail: Localizations.localeOf(context).languageCode == 'ko'
                    ? '이전 평균 몰입 시간'
                    : 'Your recent average focus',
                valueIcon: Icons.spa_outlined,
                tone: _cpSage,
                accent: _cpBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _EditorialMiniStatCard(
                eyebrow: Localizations.localeOf(context).languageCode == 'ko'
                    ? '오늘의 차분함'
                    : 'Calm streak',
                value: _calmStreakValue(l10n),
                detail: (_challengeProgress?.isTodayChallengeCleared ?? false)
                    ? (Localizations.localeOf(context).languageCode == 'ko'
                        ? '오늘 퍼즐을 마쳤어요'
                        : 'Today is complete')
                    : (Localizations.localeOf(context).languageCode == 'ko'
                        ? '차분한 흐름을 이어가보세요'
                        : 'Keep the calm rhythm going'),
                valueIcon: Icons.self_improvement_outlined,
                tone: _cpOat,
                accent: _cpCoral,
              ),
            ),
          ],
        ),
        if (_continueGame != null) ...[
          const SizedBox(height: 18),
          _buildContinueCard(_continueGame!),
        ],
      ],
    );
  }

  Widget _buildTodaySpotlightCard(SudokuGame game) {
    final l10n = AppLocalizations.of(context)!;
    final level = SudokuLevel.levels.firstWhere(
      (item) => item.name == game.levelName,
      orElse: () => SudokuLevel.levels.first,
    );
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
                onPressed: () => _openGame(game, level),
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

  Widget _buildContinueCard(ContinueGameSummary summary) {
    final l10n = AppLocalizations.of(context)!;
    return _ResumeActionCard(
      title: Localizations.localeOf(context).languageCode == 'ko'
          ? '마음의 퍼즐 잇기'
          : 'Resume gently',
      subtitle: l10n.recordsGameNumberTitle(
        summary.level.localizedName(l10n),
        summary.game.gameNumber,
      ),
      metaLabel: _savedGameListSubtitle(summary),
      supportingLabel: Localizations.localeOf(context).languageCode == 'ko'
          ? '최근 퍼즐'
          : 'Recent puzzle',
      savedGamesLabel:
          _continueGames.length > 1 ? _savedGamesCta(_continueGames.length) : null,
      onTap: () => _openGame(
        summary.game,
        summary.level,
        restoreSavedSession: true,
      ),
      onSavedGamesTap: _continueGames.length > 1 ? _openSavedGamesScreen : null,
    );
  }

  String _savedGamesTitle() {
    return Localizations.localeOf(context).languageCode == 'ko'
        ? '저장된 게임'
        : 'Saved games';
  }

  String _focusSummaryValue() {
    final roundedMinutes = _averageClearTimeSeconds <= 0
        ? 10
        : ((_averageClearTimeSeconds / 60).round()).clamp(1, 99);
    if (Localizations.localeOf(context).languageCode == 'ko') {
      return '$roundedMinutes분 준비됨';
    }
    return '$roundedMinutes min ready';
  }

  String _calmStreakValue(AppLocalizations l10n) {
    final streakDays = _challengeProgress?.streakDays ?? 0;
    if (Localizations.localeOf(context).languageCode == 'ko') {
      return streakDays > 0 ? '$streakDays일 차' : '오늘 시작';
    }
    return streakDays > 0 ? 'Day $streakDays' : 'Start today';
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
        ...List.generate(5, (index) => _buildLevelCard(index)),
      ],
    );
  }

  Widget _buildLevelGrid() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    final level = SudokuLevel.levels[index];
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

class _EditorialMiniStatCard extends StatelessWidget {
  const _EditorialMiniStatCard({
    required this.eyebrow,
    required this.value,
    required this.detail,
    required this.valueIcon,
    required this.tone,
    required this.accent,
  });

  final String eyebrow;
  final String value;
  final String detail;
  final IconData valueIcon;
  final Color tone;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _LevelSelectionMainState._cpLine),
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
          const SizedBox(height: 10),
          Text(
            eyebrow,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _LevelSelectionMainState._cpText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                valueIcon,
                size: 16,
                color: accent.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _LevelSelectionMainState._cpInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.35,
              color: _LevelSelectionMainState._cpText,
            ),
          ),
        ],
      ),
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
          color: _pressed
              ? colorScheme.surfaceContainerLow
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.08,
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
