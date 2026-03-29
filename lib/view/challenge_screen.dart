import 'package:flutter/material.dart';
import 'package:mysudoku/l10n/achievement_l10n.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/services/achievement_service.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/services/home_dashboard_service.dart';
import 'package:mysudoku/view/achievement_collection_screen.dart';
import 'package:mysudoku/view/settings_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    if (_isLoading) {
      return const SafeArea(
        bottom: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _data;
    if (data == null) {
      return SafeArea(
        bottom: false,
        child: Center(child: Text(l10n.challengeLoadError)),
      );
    }

    final challenge = data.challengeProgress;
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
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 112 + bottomInset),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.challengeScreenTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
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
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                colorScheme.outlineVariant.withValues(alpha: 0.85),
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ChallengeHeroCard(
                l10n: l10n,
                streakDays: challenge.streakDays,
                isTodayCleared: challenge.isTodayChallengeCleared,
                todayLabel: l10n.recordsGameNumberTitle(
                  challenge.todayChallengeLevelName.localizedSudokuLevelName(l10n),
                  challenge.todayChallengeGameNumber,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ChallengeMiniStatCard(
                      eyebrow: Localizations.localeOf(context).languageCode == 'ko'
                          ? '연속 기록'
                          : 'Streak',
                      value: challenge.streakDays > 0
                          ? l10n.challengeStreakDays(challenge.streakDays)
                          : l10n.challengeStreakStartToday,
                      tone: const Color(0xFFE7F0E8),
                      accent: const Color(0xFF457B9D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChallengeMiniStatCard(
                      eyebrow: Localizations.localeOf(context).languageCode == 'ko'
                          ? '이번 주 흐름'
                          : 'This week',
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
              const SizedBox(height: 20),
              _WeeklyGoalCard(l10n: l10n, challenge: challenge),
              const SizedBox(height: 22),
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
              const SizedBox(height: 22),
              _CalmSectionCard(
                title: Localizations.localeOf(context).languageCode == 'ko'
                    ? '다음 도전'
                    : 'Next challenge',
                subtitle: Localizations.localeOf(context).languageCode == 'ko'
                    ? '지금 챌린지 흐름을 이어가기 위해 필요한 목표만 남겼어요.'
                    : 'Only the milestones that matter for keeping your challenge flow.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalmSectionCard extends StatelessWidget {
  const _CalmSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChallengeMiniStatCard extends StatelessWidget {
  const _ChallengeMiniStatCard({
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

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({
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
            _LeafProgressRow(
              filledCount: filledSlots,
              totalCount: goalSlots,
              isComplete: challenge.isWeeklyGoalAchieved,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _GoalMetaLabel(
                    icon: Icons.check_circle_outline,
                    label: l10n.challengeWeeklyProgressShort(
                      challenge.weeklyClearCount,
                      challenge.weeklyGoalTarget,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GoalMetaLabel(
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

class _GoalMetaLabel extends StatelessWidget {
  const _GoalMetaLabel({
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

class _LeafProgressRow extends StatelessWidget {
  const _LeafProgressRow({
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
    final filledColor = isComplete
        ? const Color(0xFF7AA874)
        : const Color(0xFF8EBE99);
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
                color: filled ? filledColor.withValues(alpha: 0.16) : emptyColor,
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

class _ChallengeHeroPill extends StatelessWidget {
  const _ChallengeHeroPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colorScheme.onPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 10),
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
    final colorScheme = Theme.of(context).colorScheme;
    final unlocked = summary.unlockedBadges.take(3).toList();
    final upcoming = summary.inProgressBadges.take(2).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.challengeAchievementsHeading,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
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
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
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
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
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
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badge.unlocked
            ? badge.surfaceColor
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.unlocked
              ? badge.accentColor.withValues(alpha: 0.35)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            badge.unlocked ? badge.icon : Icons.workspace_premium_outlined,
            color: badge.unlocked
                ? badge.accentColor
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            badge.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${badge.progressLabel} · ${badge.rarity.localizedName(l10n)}',
            style: TextStyle(
              color: badge.unlocked
                  ? badge.accentColor
                  : colorScheme.onSurfaceVariant,
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
  });

  final AppLocalizations l10n;
  final int streakDays;
  final bool isTodayCleared;
  final String todayLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF285B3F),
            colorScheme.primary.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChallengeHeroPill(
                icon: Icons.local_florist_outlined,
                label: Localizations.localeOf(context).languageCode == 'ko'
                    ? '오늘의 흐름'
                    : 'Today',
              ),
              _ChallengeHeroPill(
                icon: Icons.self_improvement_outlined,
                label: streakDays > 0
                    ? l10n.challengeStreakDays(streakDays)
                    : l10n.challengeStreakStartToday,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            Localizations.localeOf(context).languageCode == 'ko'
                ? '이번 주의 차분한 흐름을\n살펴보세요.'
                : 'Take a calm look at\nthis week’s rhythm.',
            style: TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            todayLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimary.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isTodayCleared
                ? (Localizations.localeOf(context).languageCode == 'ko'
                    ? '오늘 퍼즐을 마쳤어요. 이제 배지와 주간 목표를 천천히 확인해보세요.'
                    : 'Today is complete. Check your badges and weekly goal at an easy pace.')
                : (Localizations.localeOf(context).languageCode == 'ko'
                    ? '오늘 퍼즐은 홈에서 시작하고, 여기서는 흐름만 확인해보세요.'
                    : 'Start today’s puzzle from Home, then return here for progress.'),
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
