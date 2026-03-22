import 'package:flutter/material.dart';
import 'package:mysudoku/l10n/app_localizations.dart';

/// 하단 네비게이션 바 위젯
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 20.0, vertical: 20.0), // 세로 마진 줄이기
      decoration: BoxDecoration(
        color: Colors.transparent, // 배경색 투명으로 변경
        borderRadius: BorderRadius.circular(50), // 둥근 모서리
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          backgroundColor: Colors.white, // 흰색 배경으로 되돌림
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedItemColor: const Color(0xFF2C3E50), // 어두운 색상으로 변경
          unselectedItemColor: const Color(0xFF7F8C8D), // 어두운 색상으로 변경
          iconSize: 20, // 아이콘 크기 줄이기
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 10), // 폰트 크기 줄이기
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal, fontSize: 10), // 폰트 크기 줄이기
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.emoji_events_outlined),
              label: l10n.navChallenge,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_outlined),
              label: l10n.navRecords,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
