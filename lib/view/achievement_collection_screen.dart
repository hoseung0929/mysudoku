import 'package:flutter/material.dart';
import 'package:mysudoku/services/achievement_service.dart';
import 'package:mysudoku/widgets/custom_app_bar.dart';

class AchievementCollectionScreen extends StatefulWidget {
  const AchievementCollectionScreen({super.key});

  @override
  State<AchievementCollectionScreen> createState() =>
      _AchievementCollectionScreenState();
}

class _AchievementCollectionScreenState
    extends State<AchievementCollectionScreen> {
  final AchievementService _achievementService = AchievementService();
  bool _isLoading = true;
  AchievementSummary? _summary;
  _BadgeFilter _filter = _BadgeFilter.all;
  _BadgeSort _sort = _BadgeSort.defaultOrder;

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
      final summary = await _achievementService.load();
      if (!mounted) return;
      setState(() {
        _summary = summary;
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const CustomAppBar(
        title: '배지 컬렉션',
        showNotificationIcon: false,
        showLogoutIcon: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? const Center(child: Text('배지 정보를 불러올 수 없습니다.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _CollectionHero(summary: _summary!),
                      const SizedBox(height: 16),
                      _buildControls(),
                      const SizedBox(height: 16),
                      _BadgeSection(
                        title: _sectionTitle,
                        badges: _visibleBadges,
                        emptyMessage: _emptyMessage,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '보기 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _BadgeFilter.values.map((filter) {
                return ChoiceChip(
                  label: Text(filter.label),
                  selected: _filter == filter,
                  onSelected: (_) {
                    setState(() {
                      _filter = filter;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_BadgeSort>(
              initialValue: _sort,
              decoration: const InputDecoration(
                labelText: '정렬',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _BadgeSort.values
                  .map(
                    (sort) => DropdownMenuItem<_BadgeSort>(
                      value: sort,
                      child: Text(sort.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _sort = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  List<AchievementBadge> get _visibleBadges {
    final summary = _summary;
    if (summary == null) return const [];

    List<AchievementBadge> badges;
    switch (_filter) {
      case _BadgeFilter.all:
        badges = List<AchievementBadge>.from(summary.badges);
        break;
      case _BadgeFilter.unlocked:
        badges = List<AchievementBadge>.from(summary.unlockedBadges);
        break;
      case _BadgeFilter.locked:
        badges = List<AchievementBadge>.from(summary.inProgressBadges);
        break;
    }

    switch (_sort) {
      case _BadgeSort.defaultOrder:
        badges.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return badges;
      case _BadgeSort.rarity:
        return _achievementService.sortBadgesByRarity(badges);
    }
  }

  String get _sectionTitle {
    switch (_filter) {
      case _BadgeFilter.all:
        return '전체 배지';
      case _BadgeFilter.unlocked:
        return '획득한 배지';
      case _BadgeFilter.locked:
        return '도전 중인 배지';
    }
  }

  String get _emptyMessage {
    switch (_filter) {
      case _BadgeFilter.all:
        return '표시할 배지가 없습니다.';
      case _BadgeFilter.unlocked:
        return '아직 획득한 배지가 없습니다.';
      case _BadgeFilter.locked:
        return '모든 배지를 획득했어요.';
    }
  }
}

enum _BadgeFilter {
  all('전체'),
  unlocked('획득'),
  locked('도전 중');

  const _BadgeFilter(this.label);
  final String label;
}

enum _BadgeSort {
  defaultOrder('기본순'),
  rarity('희귀도순');

  const _BadgeSort(this.label);
  final String label;
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({
    required this.summary,
  });

  final AchievementSummary summary;

  @override
  Widget build(BuildContext context) {
    final unlockedCount = summary.unlockedBadges.length;
    final totalCount = summary.badges.length;
    final progress =
        totalCount == 0 ? 0.0 : (unlockedCount / totalCount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF7E8),
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
          const Row(
            children: [
              Icon(Icons.military_tech, color: Color(0xFFDA8B00), size: 24),
              SizedBox(width: 8),
              Text(
                '성취 컬렉션',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A4C00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '획득 $unlockedCount / 전체 $totalCount',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF5E8BE),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFDAA520)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            unlockedCount == totalCount
                ? '모든 배지를 모았어요. 정말 멋집니다.'
                : '남은 배지를 하나씩 열면서 플레이 기록을 쌓아보세요.',
            style: const TextStyle(
              color: Color(0xFF7A642D),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeSection extends StatelessWidget {
  const _BadgeSection({
    required this.title,
    required this.badges,
    required this.emptyMessage,
  });

  final String title;
  final List<AchievementBadge> badges;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            if (badges.isEmpty)
              Text(
                emptyMessage,
                style: const TextStyle(
                  color: Color(0xFF7F8C8D),
                ),
              )
            else
              ...badges.map(
                (badge) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CollectionBadgeTile(
                    badge: badge,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CollectionBadgeTile extends StatelessWidget {
  const _CollectionBadgeTile({
    required this.badge,
  });

  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? badge.surfaceColor : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? badge.accentColor.withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            unlocked ? badge.icon : Icons.workspace_premium_outlined,
            color: unlocked ? badge.accentColor : const Color(0xFF7F8C8D),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: const TextStyle(
                    color: Color(0xFF6B7780),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '진행: ${badge.progressLabel}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C6E7E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '희귀도: ${badge.rarity.label}',
                  style: TextStyle(
                    fontSize: 12,
                    color: unlocked ? badge.accentColor : const Color(0xFF7F8C8D),
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
