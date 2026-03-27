import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/quick_start_option_l10n.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/database/database_manager.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/achievement_service.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/services/home_dashboard_service.dart';
import 'package:mysudoku/services/level_progress_service.dart';
import 'package:mysudoku/services/onboarding_service.dart';
import 'package:mysudoku/services/quick_game_service.dart';
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
  final DatabaseManager _databaseManager = DatabaseManager();
  final LevelProgressService _levelProgressService = LevelProgressService();
  final HomeDashboardService _homeDashboardService = HomeDashboardService();
  final OnboardingService _onboardingService = OnboardingService();
  final QuickGameService _quickGameService = QuickGameService();
  int? _selectedIndex;
  final ScrollController _scrollController = ScrollController();
  bool _isTop = true;
  bool _isLoadingHome = true;
  bool _isShowingOnboarding = false;
  /// 레벨별 전체 게임 수 (DB 기준)
  Map<String, int> _levelTotal = {};
  ContinueGameSummary? _continueGame;
  List<ContinueGameSummary> _continueGames = [];
  SudokuGame? _todayChallenge;
  List<QuickStartOption> _quickStartOptions = [];
  ChallengeProgressSummary? _challengeProgress;
  AchievementSummary? _achievementSummary;

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
          _quickStartOptions = data.quickStartOptions;
          _challengeProgress = data.challengeProgress;
          _achievementSummary = data.achievementSummary;
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

  Future<void> _openGame(SudokuGame game, SudokuLevel level) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SudokuGameScreen(
          game: game,
          level: level,
        ),
      ),
    );
    await _levelProgressService.refreshAllLevels(SudokuLevel.levels);
    await _loadHomeDashboard();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startQuickGame(SudokuLevel level) async {
    final game = await _quickGameService.createQuickGame(level);
    if (game == null) return;
    await _openGame(game, level);
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
              _buildSavedGameSubtitle(summary, l10n),
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
    await _openGame(selected.game, selected.level);
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
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
      ),
    );
  }

  /// 태블릿 레이아웃
  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHomeHero(),
                const SizedBox(height: 20),
                _buildQuickStartSection(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                _buildQuickStartSection(),
                const SizedBox(height: 18),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: _isTop ? colorScheme.surface : colorScheme.outlineVariant,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 36,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeGuestTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.homeGuestSubtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            child: Icon(
              Icons.chevron_right,
              size: 28,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
        if (_continueGame != null) _buildContinueCard(_continueGame!),
        if (_continueGame != null) const SizedBox(height: 16),
        if (_todayChallenge != null) _buildTodayChallengeCard(_todayChallenge!),
      ],
    );
  }

  Widget _buildContinueCard(ContinueGameSummary summary) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final memoState = summary.isMemoMode
        ? l10n.gameMemoStateOn
        : l10n.gameMemoStateOff;
    return _HeroActionCard(
      title: l10n.homeContinueTitle,
      subtitle: l10n.homeContinueSubtitle(
        summary.level.localizedName(l10n),
        summary.game.gameNumber,
        summary.elapsedFilledCells,
      ),
      description: l10n.homeContinueDescription,
      accentColor: const Color(0xFF8DC6B0),
      actionLabel: l10n.homeContinueActionButton,
      onTap: () => _openGame(summary.game, summary.level),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          if (_continueGames.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _openSavedGamesScreen,
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(_savedGamesCta(_continueGames.length)),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ContinueInfoChip(
                icon: Icons.timer_outlined,
                label: l10n.gameTimeShort,
                value: _formatDuration(summary.elapsedSeconds),
              ),
              _ContinueInfoChip(
                icon: Icons.lightbulb_outline,
                label: l10n.gameHintShort,
                value: '${summary.hintsRemaining}',
              ),
              _ContinueInfoChip(
                icon: Icons.error_outline,
                label: l10n.gameWrongShort,
                value: '${summary.wrongCount}/3',
              ),
              _ContinueInfoChip(
                icon: Icons.edit_note,
                label: l10n.gameMemoShort,
                value: memoState,
              ),
              if (summary.noteCount > 0)
                _ContinueInfoChip(
                  icon: Icons.apps,
                  label: l10n.gameMemoShort,
                  value: '${summary.noteCount}',
                ),
            ],
          ),
          if (_continueGames.length > 1) ...[
            const SizedBox(height: 14),
            ..._continueGames.skip(1).take(3).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SavedGameTile(
                  summary: item,
                  subtitle: _buildSavedGameSubtitle(item, l10n),
                  onTap: () => _openGame(item.game, item.level),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: summary.progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeProgressPercent((summary.progress * 100).toInt()),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainSeconds.toString().padLeft(2, '0')}';
  }

  String _buildSavedGameSubtitle(
    ContinueGameSummary summary,
    AppLocalizations l10n,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final playedAt = DateFormat.Md(locale).add_Hm().format(
          DateTime.fromMillisecondsSinceEpoch(summary.lastPlayedAtMillis),
        );
    return '${l10n.homeProgressPercent((summary.progress * 100).toInt())} · ${_formatDuration(summary.elapsedSeconds)} · $playedAt';
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

  Widget _buildTodayChallengeCard(SudokuGame game) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final level = SudokuLevel.levels.firstWhere(
      (item) => item.name == game.levelName,
      orElse: () => SudokuLevel.levels.first,
    );
    final challengeDone = _challengeProgress?.isTodayChallengeCleared ?? false;
    final streakDays = _challengeProgress?.streakDays ?? 0;

    return _HeroActionCard(
      title: l10n.challengeTodaysChallengeTitle,
      subtitle: l10n.recordsGameNumberTitle(
        game.levelName.localizedSudokuLevelName(l10n),
        game.gameNumber,
      ),
      description: challengeDone
          ? l10n.homeTodayChallengeCardDoneBody
          : l10n.homeTodayChallengeCardPendingBody,
      accentColor: const Color(0xFFE6D4B8),
      actionLabel: challengeDone
          ? l10n.challengeTodayReviewButton
          : l10n.challengeTodayStartButton,
      onTap: () => _openGame(game, level),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Icon(
              challengeDone ? Icons.verified : Icons.bolt,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                challengeDone
                    ? l10n.homeTodayChallengeFooterDoneStreak(streakDays)
                    : l10n.homeTodayChallengeFooterPending,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartSection() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeQuickStartSectionTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoadingHome)
          const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_challengeProgress != null) ...[
                _StreakCard(summary: _challengeProgress!),
                const SizedBox(height: 12),
              ],
              if (_achievementSummary != null) ...[
                _AchievementPreviewCard(
                  summary: _achievementSummary!,
                  l10n: l10n,
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _quickStartOptions
                    .map(
                      (option) => _QuickStartChip(
                        option: option,
                        onTap: () => _startQuickGame(option.level),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLevelExplorer() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeBrowseLevelsTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(5, (index) => _buildLevelCard(index)),
      ],
    );
  }

  Widget _buildLevelGrid() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeBrowseLevelsTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: colorScheme.onSurface,
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

class _ContinueInfoChip extends StatelessWidget {
  const _ContinueInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedGameTile extends StatelessWidget {
  const _SavedGameTile({
    required this.summary,
    required this.subtitle,
    required this.onTap,
  });

  final ContinueGameSummary summary;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.play_circle_outline,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.recordsGameNumberTitle(
                        summary.level.localizedName(l10n),
                        summary.game.gameNumber,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  const _HeroActionCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    required this.actionLabel,
    required this.onTap,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String description;
  final Color accentColor;
  final String actionLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.24),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          child,
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _QuickStartChip extends StatelessWidget {
  const _QuickStartChip({
    required this.option,
    required this.onTap,
  });

  final QuickStartOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark ? 0.14 : 0.05,
              ),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option.localizedTitle(l10n),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.localizedDescription(l10n),
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.summary,
  });

  final ChallengeProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final streakLabel = summary.streakDays > 0
        ? l10n.challengeStreakDays(summary.streakDays)
        : l10n.challengeStreakStartToday;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streakLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.isTodayChallengeCleared
                      ? l10n.homeStreakTodayDoneLine
                      : l10n.homeStreakTodayPendingLine,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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

class _AchievementPreviewCard extends StatelessWidget {
  const _AchievementPreviewCard({
    required this.summary,
    required this.l10n,
  });

  final AchievementSummary summary;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final featured = summary.unlockedBadges.isNotEmpty
        ? summary.unlockedBadges.take(2).toList()
        : summary.inProgressBadges.take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.homeBadgeProgressTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...featured.map(
            (badge) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    badge.unlocked ? Icons.verified : Icons.radio_button_unchecked,
                    size: 18,
                    color: badge.unlocked
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.challengeBadgeProgressLine(
                            badge.description,
                            badge.progressLabel,
                          ),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
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
        borderRadius: BorderRadius.circular(18),
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
                      Text(
                        '${widget.completed} / ${widget.remaining}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
