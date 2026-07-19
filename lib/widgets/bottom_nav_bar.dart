import 'dart:ui';

import 'package:flutter/material.dart';

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
    final items = [
      _BottomNavItemData(
        icon: Icons.cottage_rounded,
        isTablet: isTablet,
      ),
      _BottomNavItemData(
        icon: Icons.bar_chart_rounded,
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
                child: SizedBox(
                  height: isTablet ? 76 : 62,
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
    required this.isTablet,
  });

  final IconData icon;
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
    final baseIconSize = isTablet ? 26.0 : 21.0;
    final selectedIconSize = isTablet ? 27.0 : 22.0;
    final dotSize = isTablet ? 5.0 : 4.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10 : 8,
        vertical: isTablet ? 10 : 8,
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
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 6 : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  data.icon,
                  size: selected ? selectedIconSize : baseIconSize,
                  color: selected ? selectedIconColor : iconColor,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(top: 1),
                  width: selected ? dotSize : 0,
                  height: selected ? dotSize : 0,
                  decoration: BoxDecoration(
                    color: selectedIconColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
