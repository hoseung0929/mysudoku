import 'package:flutter/material.dart';

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
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '메뉴1'),
        BottomNavigationBarItem(icon: Icon(Icons.business), label: '메뉴2'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: '메뉴3'),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.deepPurple,
      onTap: onItemTapped,
    );
  }
}
