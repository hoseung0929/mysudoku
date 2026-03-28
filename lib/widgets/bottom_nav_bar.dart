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
    final items = [
      const _BottomNavItemData(
        icon: Icons.cottage_rounded,
      ),
      const _BottomNavItemData(
        icon: Icons.local_florist_outlined,
      ),
      const _BottomNavItemData(
        icon: Icons.auto_stories_outlined,
      ),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(52),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF21382A).withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(52),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFDFBF6).withValues(alpha: 0.78),
                border: Border.all(
                  color: const Color(0xFFE7E0D3),
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
                          selected: selectedIndex == index,
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
    required this.selected,
    required this.onTap,
  });

  final _BottomNavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const selectedColor = Color(0xFF285B3F);
    const unselectedColor = Color(0xFF7A857D);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, selected ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE7F0E8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: selected
              ? Border.all(
                  color: const Color(0xFFD3E2D6),
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            splashColor: colorScheme.primary.withValues(alpha: 0.14),
            highlightColor: colorScheme.primary.withValues(alpha: 0.06),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                  color: selected ? selectedColor : unselectedColor,
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  scale: selected ? 1.08 : 1,
                  child: Icon(
                    data.icon,
                    size: selected ? 27 : 24,
                    color: selected ? selectedColor : unselectedColor,
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
