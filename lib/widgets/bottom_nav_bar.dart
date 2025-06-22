import 'package:flutter/material.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 20.0, vertical: 20.0), // 세로 마진 줄이기
      decoration: BoxDecoration(
        color: Colors.transparent, // 배경색 투명으로 변경
        borderRadius: BorderRadius.circular(50), // 둥근 모서리
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: SizedBox(
          height: 70, // 높이를 50으로 직접 지정
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sports_esports_outlined),
                label: 'Arcade',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_outlined),
                label: '함께 플레이',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined),
                label: '보관함',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
