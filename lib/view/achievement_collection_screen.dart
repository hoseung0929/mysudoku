import 'package:flutter/material.dart';
import 'package:mysudoku/l10n/achievement_l10n.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
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
      final summary = await _achievementService.load(l10n);
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

  String _sectionTitle(AppLocalizations l10n) {
    switch (_filter) {
      case _BadgeFilter.all:
        return l10n.achievementSectionAll;
      case _BadgeFilter.unlocked:
        return l10n.achievementSectionUnlocked;
      case _BadgeFilter.locked:
        return l10n.achievementSectionLocked;
    }
  }

  String _emptyMessage(AppLocalizations l10n) {
    switch (_filter) {
      case _BadgeFilter.all:
        return l10n.achievementEmptyAll;
      case _BadgeFilter.unlocked:
        return l10n.achievementEmptyUnlocked;
      case _BadgeFilter.locked:
        return l10n.achievementEmptyLocked;
    }
  }

  String _filterChipLabel(_BadgeFilter filter, AppLocalizations l10n) {
    switch (filter) {
      case _BadgeFilter.all:
        return l10n.achievementFilterAll;
      case _BadgeFilter.unlocked:
        return l10n.achievementFilterUnlocked;
      case _BadgeFilter.locked:
        return l10n.achievementFilterLocked;
    }
  }

  String _sortLabel(_BadgeSort sort, AppLocalizations l10n) {
    switch (sort) {
      case _BadgeSort.defaultOrder:
        return l10n.achievementSortDefault;
      case _BadgeSort.rarity:
        return l10n.achievementSortRarity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: l10n.achievementCollectionAppBarTitle,
        showNotificationIcon: false,
        showLogoutIcon: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? Center(child: Text(l10n.achievementLoadError))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _CollectionHero(summary: _summary!, l10n: l10n),
                      const SizedBox(height: 16),
                      _buildControls(l10n),
                      const SizedBox(height: 16),
                      _BadgeSection(
                        title: _sectionTitle(l10n),
                        badges: _visibleBadges,
                        emptyMessage: _emptyMessage(l10n),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildControls(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.achievementViewSettings,
              style: const TextStyle(
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
                  label: Text(_filterChipLabel(filter, l10n)),
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
              key: ValueKey(_sort),
              initialValue: _sort,
              decoration: InputDecoration(
                labelText: l10n.achievementSortLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: _BadgeSort.values
                  .map(
                    (sort) => DropdownMenuItem<_BadgeSort>(
                      value: sort,
                      child: Text(_sortLabel(sort, l10n)),
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
}

enum _BadgeFilter {
  all,
  unlocked,
  locked,
}

enum _BadgeSort {
  defaultOrder,
  rarity,
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({
    required this.summary,
    required this.l10n,
  });

  final AchievementSummary summary;
  final AppLocalizations l10n;

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
          Row(
            children: [
              const Icon(Icons.military_tech, color: Color(0xFFDA8B00), size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.achievementHeroTitle,
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
            l10n.achievementHeroProgress(unlockedCount, totalCount),
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
                ? l10n.achievementHeroAllUnlocked
                : l10n.achievementHeroKeepGoing,
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
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.achievementTileProgress(badge.progressLabel),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5C6E7E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.achievementTileRarity(
                    badge.rarity.localizedName(l10n),
                  ),
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
