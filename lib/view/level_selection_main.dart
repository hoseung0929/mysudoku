import 'package:flutter/material.dart';
import '../model/sudoku_game.dart';
import '../model/sudoku_level.dart';
import '../view/settings_screen.dart';
import '../view/level_selection_screen.dart';
import '../view/sudoku_game_screen.dart';
import '../database/database_helper.dart';
import '../database/database_manager.dart';
import '../services/level_progress_service.dart';
import '../services/home_dashboard_service.dart';
import '../services/onboarding_service.dart';
import '../services/challenge_progress_service.dart';
import '../services/achievement_service.dart';

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
  int? _selectedIndex;
  final ScrollController _scrollController = ScrollController();
  bool _isTop = true;
  bool _isLoadingHome = true;
  bool _isShowingOnboarding = false;
  /// 레벨별 전체 게임 수 (DB 기준)
  Map<String, int> _levelTotal = {};
  ContinueGameSummary? _continueGame;
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
    _loadHomeDashboard();
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
      final data = await _homeDashboardService.load();
      if (mounted) {
        setState(() {
          _continueGame = data.continueGame;
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
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '처음 오셨네요',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GuideStep(
                icon: Icons.play_circle_fill,
                title: '빠른 시작',
                description: '추천 난이도로 바로 한 판 시작할 수 있어요.',
              ),
              SizedBox(height: 12),
              _GuideStep(
                icon: Icons.bolt,
                title: '오늘의 도전',
                description: '매일 바뀌는 대표 퍼즐로 가볍게 실력을 확인해보세요.',
              ),
              SizedBox(height: 12),
              _GuideStep(
                icon: Icons.history,
                title: '이어하기',
                description: '중단한 게임은 홈 상단 카드에서 곧바로 이어집니다.',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('시작하기'),
            ),
          ],
        ),
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
    final dbHelper = DatabaseHelper();
    final gameCount = await dbHelper.getGameCount(level.name);
    if (gameCount == 0) return;
    final targetGameNumber = (level.clearedGames % gameCount) + 1;
    final board = await dbHelper.getGame(level.name, targetGameNumber);
    final solution = await dbHelper.getSolution(level.name, targetGameNumber);
    if (board.isEmpty || solution.isEmpty) return;

    final game = SudokuGame(
      board: board,
      solution: solution,
      emptyCells: level.emptyCells,
      levelName: level.name,
      gameNumber: targetGameNumber,
    );
    await _openGame(game, level);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                      child: _CatalogProgressBanner(status: status),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isTop ? Colors.white : Colors.grey[300]!,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFB8E6B8),
            child: Icon(Icons.person, size: 36, color: Color(0xFF2C3E50)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '게스트',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '지금 바로 한 판 시작해보세요',
                  style: TextStyle(
                    color: Color(0xFF7F8C8D),
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
            child: const Icon(Icons.chevron_right,
                size: 28, color: Color(0xFF7F8C8D)),
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
    return _HeroActionCard(
      title: '이어하기',
      subtitle:
          '${summary.level.name} · 게임 ${summary.game.gameNumber} · ${summary.elapsedFilledCells}칸 진행',
      description: '중단한 퍼즐을 바로 이어서 플레이할 수 있어요.',
      accentColor: const Color(0xFF8DC6B0),
      actionLabel: '계속하기',
      onTap: () => _openGame(summary.game, summary.level),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: summary.progress,
              backgroundColor: const Color(0xFFE4EFE8),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF8DC6B0)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '진행률 ${(summary.progress * 100).toInt()}%',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayChallengeCard(SudokuGame game) {
    final level = SudokuLevel.levels.firstWhere(
      (item) => item.name == game.levelName,
      orElse: () => SudokuLevel.levels.first,
    );
    final challengeDone = _challengeProgress?.isTodayChallengeCleared ?? false;
    final streakDays = _challengeProgress?.streakDays ?? 0;

    return _HeroActionCard(
      title: '오늘의 도전',
      subtitle: '${game.levelName} · 게임 ${game.gameNumber}',
      description: challengeDone
          ? '오늘의 도전을 완료했어요. 연속 기록을 이어가고 있어요.'
          : '매일 한 판, 가볍게 실력을 확인해보세요.',
      accentColor: const Color(0xFFE6D4B8),
      actionLabel: challengeDone ? '다시 보기' : '도전하기',
      onTap: () => _openGame(game, level),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Icon(
              challengeDone ? Icons.verified : Icons.bolt,
              color: const Color(0xFF8A5A2B),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                challengeDone
                    ? '오늘 도전 완료 · 현재 $streakDays일 연속 기록'
                    : '오늘의 공통 퍼즐로 연속 도전 흐름을 만들어보세요.',
                style: const TextStyle(
                  color: Color(0xFF6B5A45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 시작',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF2C3E50),
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
                _AchievementPreviewCard(summary: _achievementSummary!),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '난이도 탐색',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(5, (index) => _buildLevelCard(index)),
      ],
    );
  }

  Widget _buildLevelGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '난이도 탐색',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF2C3E50),
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
      title: levelTitles[index],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.24),
            Colors.white,
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5F6B6E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7780),
            ),
          ),
          child,
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              foregroundColor: Colors.white,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EAED)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
              option.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7F8C8D),
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
    final streakLabel =
        summary.streakDays > 0 ? '${summary.streakDays}일 연속 클리어' : '오늘 첫 클리어에 도전해보세요';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0D48A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Color(0xFFDA8B00)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streakLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A4C00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.isTodayChallengeCleared
                      ? '오늘의 도전도 완료했어요.'
                      : '오늘의 도전을 완료하면 기록을 이어갈 수 있어요.',
                  style: const TextStyle(
                    color: Color(0xFF7A642D),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFB8E6B8).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2C3E50), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF6B7780),
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
  });

  final AchievementSummary summary;

  @override
  Widget build(BuildContext context) {
    final featured = summary.unlockedBadges.isNotEmpty
        ? summary.unlockedBadges.take(2).toList()
        : summary.inProgressBadges.take(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E4F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.military_tech, color: Color(0xFF476C9B)),
              SizedBox(width: 8),
              Text(
                '배지 진행',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
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
                        ? const Color(0xFF3FAE7C)
                        : const Color(0xFF7F8C8D),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${badge.description} · ${badge.progressLabel}',
                          style: const TextStyle(
                            color: Color(0xFF6B7780),
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
  });

  final PuzzleCatalogStatus status;

  @override
  Widget build(BuildContext context) {
    final progress = status.totalTarget == 0
        ? 0.0
        : (status.totalGenerated / status.totalTarget).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E4F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF476C9B)),
              SizedBox(width: 8),
              Text(
                '퍼즐 카탈로그 준비 중',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${status.totalGenerated}/${status.totalTarget}판 준비됨 · 남은 ${status.remaining}판',
            style: const TextStyle(
              color: Color(0xFF6B7780),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE4EBF5),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6A95CC)),
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
          color: _pressed ? const Color(0xFFF9F8F6) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
              child: Icon(widget.icon, size: 36, color: Colors.white),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        '${widget.completed} / ${widget.remaining}',
                        style: const TextStyle(
                          color: Colors.grey,
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
