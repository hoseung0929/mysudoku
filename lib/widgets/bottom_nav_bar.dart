import 'dart:ui';

import 'package:flutter/material.dart';

/// 하단 네비게이션 바 위젯
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      const _BottomNavItemData(
        icon: Icons.cottage_rounded,
      ),
      const _BottomNavItemData(
        icon: Icons.bar_chart_rounded,
      ),
    ];

    /// 홈 상단 프로필 글래스 바와 동일 톤 (level_selection_main)
    const creamGlass = Color(0xFFFDFBF6);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(52),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF21382A).withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(52),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: creamGlass.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(52),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.28),
                  ),
                ),
                child: SizedBox(
                  height: 68,
                  child: Row(
                    children: [
                      for (var index = 0; index < items.length; index++)
                        Expanded(
                          child: _BottomNavButton(
                            data: items[index],
                            onTap: () => onItemTapped(index),
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
  });

  final IconData icon;
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.data,
    required this.onTap,
  });

  final _BottomNavItemData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const iconColor = Color(0xFF7A857D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          splashColor: colorScheme.primary.withValues(alpha: 0.14),
          highlightColor: colorScheme.primary.withValues(alpha: 0.06),
          child: Center(
            child: Icon(
              data.icon,
              size: 24,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
