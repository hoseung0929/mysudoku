import 'package:flutter/material.dart';
import 'package:mysudoku/database/database_helper.dart';

import 'challenge_progress_service.dart';

class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.progressLabel,
    required this.unlocked,
    required this.rarity,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String description;
  final String progressLabel;
  final bool unlocked;
  final AchievementRarity rarity;
  final int sortOrder;

  IconData get icon {
    switch (id) {
      case 'first_clear':
        return Icons.flag_circle;
      case 'streak_3':
        return Icons.local_fire_department;
      case 'weekly_5':
        return Icons.event_available;
      case 'perfect_clear':
        return Icons.auto_awesome;
      case 'master_clear':
        return Icons.workspace_premium;
      default:
        return Icons.military_tech;
    }
  }

  Color get accentColor {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFF5C8F6E);
      case AchievementRarity.rare:
        return const Color(0xFF476C9B);
      case AchievementRarity.epic:
        return const Color(0xFF9A5CC6);
    }
  }

  Color get surfaceColor {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFFEAF6ED);
      case AchievementRarity.rare:
        return const Color(0xFFEFF4FB);
      case AchievementRarity.epic:
        return const Color(0xFFF6EEFB);
    }
  }
}

enum AchievementRarity {
  common,
  rare,
  epic,
}

extension AchievementRarityX on AchievementRarity {
  String get label {
    switch (this) {
      case AchievementRarity.common:
        return '기본';
      case AchievementRarity.rare:
        return '희귀';
      case AchievementRarity.epic:
        return '에픽';
    }
  }
}

class AchievementSummary {
  const AchievementSummary({
    required this.badges,
  });

  final List<AchievementBadge> badges;

  List<AchievementBadge> get unlockedBadges =>
      badges.where((badge) => badge.unlocked).toList();

  List<AchievementBadge> get inProgressBadges =>
      badges.where((badge) => !badge.unlocked).toList();
}

class AchievementService {
  AchievementService({
    DatabaseHelper? databaseHelper,
    ChallengeProgressService? challengeProgressService,
    Future<Map<String, dynamic>> Function()? loadOverallStatistics,
    Future<List<Map<String, dynamic>>> Function()? loadRecentRecords,
  }) : _challengeProgressService =
            challengeProgressService ?? ChallengeProgressService(databaseHelper: databaseHelper),
        _loadOverallStatistics =
            loadOverallStatistics ??
                (() => (databaseHelper ?? DatabaseHelper()).getOverallStatistics()),
        _loadRecentRecords =
            loadRecentRecords ??
                (() => (databaseHelper ?? DatabaseHelper()).getRecentClearRecords(limit: 10000));

  final ChallengeProgressService _challengeProgressService;
  final Future<Map<String, dynamic>> Function() _loadOverallStatistics;
  final Future<List<Map<String, dynamic>>> Function() _loadRecentRecords;

  Future<AchievementSummary> load() async {
    final overall = await _loadOverallStatistics();
    final records = await _loadRecentRecords();

    final totalCleared = overall['total_cleared'] as int? ?? 0;
    final streakDays = _challengeProgressService.calculateStreakFromRecords(records);
    final weeklyClearCount =
        _challengeProgressService.calculateWeeklyClearCount(records);
    final hasPerfectClear = records.any((record) {
      return (record['wrong_count'] as int? ?? 0) == 0;
    });
    final hasMasterClear = records.any((record) {
      return record['level_name'] == '마스터';
    });

    return AchievementSummary(
      badges: [
        AchievementBadge(
          id: 'first_clear',
          title: '첫 클리어',
          description: '첫 퍼즐을 완주해 스도쿠 여정을 시작했어요.',
          progressLabel: '${_cap(totalCleared, 1)}/1',
          unlocked: totalCleared >= 1,
          rarity: AchievementRarity.common,
          sortOrder: 0,
        ),
        AchievementBadge(
          id: 'streak_3',
          title: '3일 연속',
          description: '3일 연속으로 퍼즐을 클리어해 리듬을 만들어요.',
          progressLabel: '${_cap(streakDays, 3)}/3일',
          unlocked: streakDays >= 3,
          rarity: AchievementRarity.rare,
          sortOrder: 1,
        ),
        AchievementBadge(
          id: 'weekly_5',
          title: '주간 러너',
          description: '최근 7일 동안 5판을 클리어해 꾸준함을 보여주세요.',
          progressLabel: '${_cap(weeklyClearCount, 5)}/5판',
          unlocked: weeklyClearCount >= 5,
          rarity: AchievementRarity.rare,
          sortOrder: 2,
        ),
        AchievementBadge(
          id: 'perfect_clear',
          title: '퍼펙트 클리어',
          description: '오답 없이 한 판을 끝내면 획득합니다.',
          progressLabel: hasPerfectClear ? '완료' : '미달성',
          unlocked: hasPerfectClear,
          rarity: AchievementRarity.epic,
          sortOrder: 3,
        ),
        AchievementBadge(
          id: 'master_clear',
          title: '마스터 첫 승리',
          description: '마스터 난이도를 처음 클리어하면 해금됩니다.',
          progressLabel: hasMasterClear ? '완료' : '도전 중',
          unlocked: hasMasterClear,
          rarity: AchievementRarity.epic,
          sortOrder: 4,
        ),
      ],
    );
  }

  List<AchievementBadge> getNewlyUnlockedBadges({
    required AchievementSummary before,
    required AchievementSummary after,
  }) {
    final previouslyUnlockedIds =
        before.unlockedBadges.map((badge) => badge.id).toSet();

    return after.unlockedBadges
        .where((badge) => !previouslyUnlockedIds.contains(badge.id))
        .toList();
  }

  List<AchievementBadge> sortBadgesByRarity(List<AchievementBadge> badges) {
    final sorted = List<AchievementBadge>.from(badges);
    sorted.sort((a, b) {
      final rarityDiff = b.rarity.index.compareTo(a.rarity.index);
      if (rarityDiff != 0) {
        return rarityDiff;
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return sorted;
  }

  int _cap(int value, int max) => value > max ? max : value;
}
