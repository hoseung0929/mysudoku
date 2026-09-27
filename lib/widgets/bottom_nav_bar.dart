import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';

/// 하단 네비게이션 바 위젯
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.isTop = true,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final navColor = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerLow
        : colorScheme.surface;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _BottomNavItemData(
        icon: Icons.home_rounded,
        label: l10n.navHome,
        isTablet: isTablet,
      ),
      _BottomNavItemData(
        icon: Icons.bar_chart_rounded,
        label: l10n.navRecords,
        isTablet: isTablet,
      ),
      _BottomNavItemData(
        icon: Icons.settings_outlined,
        label: l10n.navSettings,
        isTablet: isTablet,
      ),
    ];

    /// 홈 상단 프로필 글래스 바와 동일 톤 (home_screen)
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(46),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(46),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isTop ? navColor : navColor.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(46),
                  border: Border.all(
                    color: isTop
                        ? colorScheme.outlineVariant.withValues(alpha: 0.55)
                        : colorScheme.outlineVariant.withValues(alpha: 0.28),
                  ),
                ),
                // 큰 글씨에서도 라벨이 잘리지 않도록 고정 높이 대신 최소 높이만 둔다.
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: isTablet ? 76 : 64),
                  child: Row(
                    children: [
                      for (var index = 0; index < items.length; index++)
                        Expanded(
                          child: _BottomNavButton(
                            data: items[index],
                            selected: selectedIndex == index,
                            onTap: selectedIndex == index
                                ? null
                                : () => onItemTapped(index),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  const _BottomNavItemData({
    required this.icon,
    required this.label,
    required this.isTablet,
  });

  final IconData icon;
  final String label;
  final bool isTablet;
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _BottomNavItemData data;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final selectedIconColor = Theme.of(context).colorScheme.onSurface;
    final isTablet = data.isTablet;
    final iconSize = isTablet ? 26.0 : 22.0;
    final contentColor = selected ? selectedIconColor : iconColor;

    // 선택 상태는 색뿐 아니라 배경 알약과 굵은 라벨로도 전달한다.
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: data.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 10 : 8,
          vertical: isTablet ? 8 : 6,
        ),
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 12,
                vertical: isTablet ? 6 : 5,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? selectedIconColor.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(data.icon, size: iconSize, color: contentColor),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: contentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
