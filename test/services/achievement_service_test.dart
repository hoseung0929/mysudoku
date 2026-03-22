import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/l10n/app_localizations_ko.dart';
import 'package:mysudoku/services/achievement_service.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:mysudoku/utils/app_logger.dart';

void main() {
  AppLogger.setMuted(true);
  final l10nKo = AppLocalizationsKo();

  group('AchievementService', () {
    test('unlocks badges from overall clears, streaks, weekly progress, and master wins', () async {
      final today = DateTime.now();
      String format(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

      final service = AchievementService(
        challengeProgressService: ChallengeProgressService(),
        loadOverallStatistics: () async => {
          'total_cleared': 7,
        },
        loadRecentRecords: () async => [
          {'clear_date': format(today), 'wrong_count': 0, 'level_name': '마스터'},
          {'clear_date': format(today.subtract(const Duration(days: 1))), 'wrong_count': 1, 'level_name': '중급'},
          {'clear_date': format(today.subtract(const Duration(days: 2))), 'wrong_count': 2, 'level_name': '초급'},
          {'clear_date': format(today.subtract(const Duration(days: 3))), 'wrong_count': 1, 'level_name': '고급'},
          {'clear_date': format(today.subtract(const Duration(days: 4))), 'wrong_count': 0, 'level_name': '전문가'},
        ],
      );

      final summary = await service.load(l10nKo);

      expect(summary.badges.where((badge) => badge.unlocked).length, 5);
      expect(summary.inProgressBadges, isEmpty);
    });

    test('keeps progress badges locked when conditions are not met', () async {
      final today = DateTime.now();
      String format(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

      final service = AchievementService(
        challengeProgressService: ChallengeProgressService(),
        loadOverallStatistics: () async => {
          'total_cleared': 0,
        },
        loadRecentRecords: () async => [
          {'clear_date': format(today), 'wrong_count': 2, 'level_name': '초급'},
        ],
      );

      final summary = await service.load(l10nKo);
      final firstClear = summary.badges.firstWhere((badge) => badge.id == 'first_clear');
      final perfectClear =
          summary.badges.firstWhere((badge) => badge.id == 'perfect_clear');
      final masterClear =
          summary.badges.firstWhere((badge) => badge.id == 'master_clear');

      expect(firstClear.unlocked, isFalse);
      expect(firstClear.progressLabel, '0/1');
      expect(perfectClear.unlocked, isFalse);
      expect(masterClear.unlocked, isFalse);
      expect(summary.inProgressBadges.length, 5);
    });

    test('finds only newly unlocked badges between two summaries', () {
      const before = AchievementSummary(
        badges: [
          AchievementBadge(
            id: 'first_clear',
            title: '첫 클리어',
            description: 'desc',
            progressLabel: '1/1',
            unlocked: true,
            rarity: AchievementRarity.common,
            sortOrder: 0,
          ),
          AchievementBadge(
            id: 'weekly_5',
            title: '주간 러너',
            description: 'desc',
            progressLabel: '3/5',
            unlocked: false,
            rarity: AchievementRarity.rare,
            sortOrder: 2,
          ),
        ],
      );
      const after = AchievementSummary(
        badges: [
          AchievementBadge(
            id: 'first_clear',
            title: '첫 클리어',
            description: 'desc',
            progressLabel: '1/1',
            unlocked: true,
            rarity: AchievementRarity.common,
            sortOrder: 0,
          ),
          AchievementBadge(
            id: 'weekly_5',
            title: '주간 러너',
            description: 'desc',
            progressLabel: '5/5',
            unlocked: true,
            rarity: AchievementRarity.rare,
            sortOrder: 2,
          ),
        ],
      );

      final service = AchievementService(
        challengeProgressService: ChallengeProgressService(),
      );

      final unlocked = service.getNewlyUnlockedBadges(
        before: before,
        after: after,
      );

      expect(unlocked.length, 1);
      expect(unlocked.first.id, 'weekly_5');
    });

    test('sorts badges by rarity before default order', () async {
      final service = AchievementService(
        challengeProgressService: ChallengeProgressService(),
      );
      const badges = [
        AchievementBadge(
          id: 'first_clear',
          title: '첫 클리어',
          description: 'desc',
          progressLabel: '1/1',
          unlocked: true,
          rarity: AchievementRarity.common,
          sortOrder: 0,
        ),
        AchievementBadge(
          id: 'master_clear',
          title: '마스터 첫 승리',
          description: 'desc',
          progressLabel: '완료',
          unlocked: false,
          rarity: AchievementRarity.epic,
          sortOrder: 4,
        ),
        AchievementBadge(
          id: 'weekly_5',
          title: '주간 러너',
          description: 'desc',
          progressLabel: '5/5',
          unlocked: true,
          rarity: AchievementRarity.rare,
          sortOrder: 2,
        ),
      ];

      final sorted = service.sortBadgesByRarity(badges);

      expect(sorted.map((badge) => badge.id).toList(), [
        'master_clear',
        'weekly_5',
        'first_clear',
      ]);
    });
  });
}
