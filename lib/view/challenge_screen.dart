import 'package:flutter/material.dart';
import 'package:mysudoku/l10n/achievement_l10n.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/quick_start_option_l10n.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/database/database_helper.dart';
import 'package:mysudoku/model/sudoku_game.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/achievement_service.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/services/home_dashboard_service.dart';
import 'package:mysudoku/view/achievement_collection_screen.dart';
import 'package:mysudoku/view/sudoku_game_screen.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final HomeDashboardService _homeDashboardService = HomeDashboardService();
  bool _isLoading = true;
  HomeDashboardData? _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final data = await _homeDashboardService.load(l10n);
      if (mounted) {
        setState(() {
          _data = data;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openGame(SudokuGame game) async {
    final level = SudokuLevel.levels.firstWhere(
      (item) => item.name == game.levelName,
      orElse: () => SudokuLevel.levels.first,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SudokuGameScreen(
          game: game,
          level: level,
        ),
      ),
    );
    await _load();
  }

  Future<void> _startQuickGame(SudokuLevel level) async {
    final dbHelper = DatabaseHelper();
    final gameCount = await dbHelper.getGameCount(level.name);
    if (gameCount == 0) return;
    final targetGameNumber = (level.clearedGames % gameCount) + 1;
    final board = await dbHelper.getGame(level.name, targetGameNumber);
    final solution = await dbHelper.getSolution(level.name, targetGameNumber);
    if (board.isEmpty || solution.isEmpty) return;

    await _openGame(
      SudokuGame(
        board: board,
        solution: solution,
        emptyCells: level.emptyCells,
        levelName: level.name,
        gameNumber: targetGameNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = _data;
    if (data == null) {
      return Center(child: Text(l10n.challengeLoadError));
    }

    final challenge = data.challengeProgress;
    final todayGame = data.todayChallenge;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.challengeScreenTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          _ChallengeHeroCard(
            l10n: l10n,
            streakDays: challenge.streakDays,
            isTodayCleared: challenge.isTodayChallengeCleared,
            todayLabel: l10n.recordsGameNumberTitle(
              challenge.todayChallengeLevelName.localizedSudokuLevelName(l10n),
              challenge.todayChallengeGameNumber,
            ),
            onTap: () => _openGame(todayGame),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.challengeTodaysChallengeTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.recordsGameNumberTitle(
                      todayGame.levelName.localizedSudokuLevelName(l10n),
                      todayGame.gameNumber,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    challenge.isTodayChallengeCleared
                        ? l10n.challengeTodayDoneHint
                        : l10n.challengeTodayPendingHint,
                    style: const TextStyle(
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => _openGame(todayGame),
                    child: Text(
                      challenge.isTodayChallengeCleared
                          ? l10n.challengeTodayReviewButton
                          : l10n.challengeTodayStartButton,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _WeeklyGoalCard(l10n: l10n, challenge: challenge),
          const SizedBox(height: 16),
          _AchievementSection(
            l10n: l10n,
            summary: data.achievementSummary,
            onViewAll: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementCollectionScreen(),
                ),
              );
              await _load();
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.challengeSuggestedActions,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NextMilestoneTile(
                    title: challenge.isWeeklyGoalAchieved
                        ? l10n.challengeWeeklyGoalReachedTitle
                        : l10n.challengeWeeklyGoalRemainingTitle(
                            challenge.remainingWeeklyGoal,
                          ),
                    description: challenge.isWeeklyGoalAchieved
                        ? l10n.challengeWeeklyGoalReachedBody
                        : l10n.challengeWeeklyGoalCatchUpBody,
                    icon: challenge.isWeeklyGoalAchieved
                        ? Icons.emoji_events
                        : Icons.flag,
                  ),
                  const SizedBox(height: 8),
                  _NextMilestoneTile(
                    title: challenge.perfectClearCount > 0
                        ? l10n.challengePerfectThisWeek(
                            challenge.perfectClearCount,
                          )
                        : l10n.challengePerfectThisWeekFirst,
                    description: challenge.perfectClearCount > 0
                        ? l10n.challengePerfectPositiveBody
                        : l10n.challengePerfectZeroBody,
                    icon: Icons.auto_awesome,
                  ),
                  const SizedBox(height: 12),
                  ...data.quickStartOptions.map(
                    (option) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_arrow),
                      title: Text(option.localizedTitle(l10n)),
                      subtitle: Text(option.localizedDescription(l10n)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _startQuickGame(option.level),
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

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({
    required this.l10n,
    required this.challenge,
  });

  final AppLocalizations l10n;
  final ChallengeProgressSummary challenge;

  @override
  Widget build(BuildContext context) {
    final progress = challenge.weeklyGoalTarget == 0
        ? 0.0
        : (challenge.weeklyClearCount / challenge.weeklyGoalTarget)
            .clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.challengeWeeklyGoalHeading,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
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
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: const Color(0xFFE9EEF2),
              valueColor: AlwaysStoppedAnimation<Color>(
                challenge.isWeeklyGoalAchieved
                    ? const Color(0xFF3FAE7C)
                    : const Color(0xFFDAA520),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _GoalStatChip(
                    icon: Icons.check_circle_outline,
                    label: l10n.challengeWeeklyProgressShort(
                      challenge.weeklyClearCount,
                      challenge.weeklyGoalTarget,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GoalStatChip(
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
              style: const TextStyle(
                color: Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalStatChip extends StatelessWidget {
  const _GoalStatChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5C6E7E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextMilestoneTile extends StatelessWidget {
  const _NextMilestoneTile({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF5C6E7E)),
          const SizedBox(width: 10),
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
                    color: Color(0xFF7F8C8D),
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

class _AchievementSection extends StatelessWidget {
  const _AchievementSection({
    required this.l10n,
    required this.summary,
    required this.onViewAll,
  });

  final AppLocalizations l10n;
  final AchievementSummary summary;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final unlocked = summary.unlockedBadges.take(3).toList();
    final upcoming = summary.inProgressBadges.take(2).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.challengeAchievementsHeading,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.challengeBadgesCollected(
                      summary.unlockedBadges.length,
                      summary.badges.length,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text(l10n.challengeViewAllBadges),
                ),
              ],
            ),
            if (unlocked.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                l10n.challengeEarnedBadgesHeading,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: unlocked
                    .map(
                      (badge) => _AchievementBadgeChip(
                        badge: badge,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (upcoming.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.challengeNextBadgeTargets,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 10),
              ...upcoming.map(
                (badge) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NextMilestoneTile(
                    title: badge.title,
                    description: l10n.challengeBadgeProgressLine(
                      badge.description,
                      badge.progressLabel,
                    ),
                    icon: Icons.workspace_premium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AchievementBadgeChip extends StatelessWidget {
  const _AchievementBadgeChip({
    required this.badge,
  });

  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badge.unlocked ? badge.surfaceColor : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.unlocked
              ? badge.accentColor.withValues(alpha: 0.35)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            badge.unlocked ? badge.icon : Icons.workspace_premium_outlined,
            color: badge.unlocked ? badge.accentColor : const Color(0xFF7F8C8D),
          ),
          const SizedBox(height: 8),
          Text(
            badge.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${badge.progressLabel} · ${badge.rarity.localizedName(l10n)}',
            style: TextStyle(
              color: badge.unlocked ? badge.accentColor : const Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeHeroCard extends StatelessWidget {
  const _ChallengeHeroCard({
    required this.l10n,
    required this.streakDays,
    required this.isTodayCleared,
    required this.todayLabel,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final int streakDays;
  final bool isTodayCleared;
  final String todayLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF3D6),
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0D48A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Color(0xFFDA8B00)),
              const SizedBox(width: 8),
              Text(
                streakDays > 0
                    ? l10n.challengeStreakDays(streakDays)
                    : l10n.challengeStreakStartToday,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A4C00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            todayLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isTodayCleared
                ? l10n.challengeHeroDoneCaption
                : l10n.challengeHeroPendingCaption,
            style: const TextStyle(
              color: Color(0xFF7A642D),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onTap,
            child: Text(
              isTodayCleared
                  ? l10n.challengeHeroReviewAction
                  : l10n.challengeHeroStartAction,
            ),
          ),
        ],
      ),
    );
  }
}
