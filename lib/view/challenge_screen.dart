import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../model/sudoku_game.dart';
import '../model/sudoku_level.dart';
import '../services/achievement_service.dart';
import '../services/challenge_progress_service.dart';
import '../services/home_dashboard_service.dart';
import 'achievement_collection_screen.dart';
import 'sudoku_game_screen.dart';

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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _homeDashboardService.load();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = _data;
    if (data == null) {
      return const Center(child: Text('챌린지 정보를 불러올 수 없습니다.'));
    }

    final challenge = data.challengeProgress;
    final todayGame = data.todayChallenge;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '챌린지',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          _ChallengeHeroCard(
            streakDays: challenge.streakDays,
            isTodayCleared: challenge.isTodayChallengeCleared,
            todayLabel:
                '${challenge.todayChallengeLevelName} · 게임 ${challenge.todayChallengeGameNumber}',
            onTap: () => _openGame(todayGame),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 도전',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${todayGame.levelName} 난이도 · 게임 ${todayGame.gameNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    challenge.isTodayChallengeCleared
                        ? '오늘 도전은 이미 완료했어요. 기록을 다시 확인해보세요.'
                        : '오늘의 대표 퍼즐로 연속 플레이를 이어가세요.',
                    style: const TextStyle(
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => _openGame(todayGame),
                    child: Text(
                      challenge.isTodayChallengeCleared ? '다시 보기' : '도전 시작',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _WeeklyGoalCard(challenge: challenge),
          const SizedBox(height: 16),
          _AchievementSection(
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
                  const Text(
                    '추천 액션',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NextMilestoneTile(
                    title: challenge.isWeeklyGoalAchieved
                        ? '이번 주 목표를 달성했어요'
                        : '주간 목표까지 ${challenge.remainingWeeklyGoal}판 남았어요',
                    description: challenge.isWeeklyGoalAchieved
                        ? '이제 퍼펙트 클리어를 늘려서 더 좋은 리듬을 만들어보세요.'
                        : '빠른 시작으로 몇 판만 더 하면 이번 주 목표를 채울 수 있어요.',
                    icon: challenge.isWeeklyGoalAchieved
                        ? Icons.emoji_events
                        : Icons.flag,
                  ),
                  const SizedBox(height: 8),
                  _NextMilestoneTile(
                    title: challenge.perfectClearCount > 0
                        ? '이번 주 퍼펙트 클리어 ${challenge.perfectClearCount}회'
                        : '이번 주 첫 퍼펙트 클리어에 도전해보세요',
                    description: challenge.perfectClearCount > 0
                        ? '오답 없는 클리어를 이어가면 실력 성장이 더 잘 보입니다.'
                        : '메모 기능을 활용하면 오답 없는 클리어에 훨씬 가까워집니다.',
                    icon: Icons.auto_awesome,
                  ),
                  const SizedBox(height: 12),
                  ...data.quickStartOptions.map(
                    (option) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.play_arrow),
                      title: Text(option.label),
                      subtitle: Text(option.description),
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
    required this.challenge,
  });

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
            const Text(
              '주간 목표',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '이번 주 ${challenge.weeklyGoalTarget}판 클리어',
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
                    label:
                        '${challenge.weeklyClearCount}/${challenge.weeklyGoalTarget} 완료',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _GoalStatChip(
                    icon: Icons.auto_awesome,
                    label: '퍼펙트 ${challenge.perfectClearCount}회',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              challenge.isWeeklyGoalAchieved
                  ? '이번 주 목표를 달성했습니다. 기록을 더 멋지게 쌓아보세요.'
                  : '지금 흐름이면 이번 주 목표까지 ${challenge.remainingWeeklyGoal}판 남았습니다.',
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
    required this.summary,
    required this.onViewAll,
  });

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
            const Text(
              '업적 · 배지',
              style: TextStyle(
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
                    '획득 ${summary.unlockedBadges.length}/${summary.badges.length}',
                    style: const TextStyle(
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('전체 보기'),
                ),
              ],
            ),
            if (unlocked.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                '획득한 배지',
                style: TextStyle(
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
              const Text(
                '다음 목표',
                style: TextStyle(
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
                    description:
                        '${badge.description} 현재 진행: ${badge.progressLabel}',
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
            '${badge.progressLabel} · ${badge.rarity.label}',
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
    required this.streakDays,
    required this.isTodayCleared,
    required this.todayLabel,
    required this.onTap,
  });

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
                streakDays > 0 ? '$streakDays일 연속 클리어' : '오늘 첫 클리어 도전',
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
                ? '오늘의 도전을 완료했습니다. 내일도 이어서 기록을 쌓아보세요.'
                : '오늘의 도전이 아직 남아 있어요. 지금 시작하면 스트릭을 이어갈 수 있어요.',
            style: const TextStyle(
              color: Color(0xFF7A642D),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onTap,
            child: Text(isTodayCleared ? '기록 다시 보기' : '오늘의 도전 시작'),
          ),
        ],
      ),
    );
  }
}
