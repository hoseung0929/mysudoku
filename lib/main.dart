import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'view/level_selection_main.dart';
import 'view/settings_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'theme/app_theme.dart';
import 'model/sudoku_level.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DB 경로 출력
  await printDbPath();

  // 클리어된 게임 수 로드
  await SudokuLevel.loadAllClearedGames();

  // 세로 모드로 고정 (필요시 주석 해제)
  // SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);
  runApp(const MySudokuApp());
}

/// DB 경로를 출력하는 함수
Future<void> printDbPath() async {
  try {
    String dbPath = join(await getDatabasesPath(), 'sudoku_games.db');
    print('=== DB 경로 정보 ===');
    print('DB 파일명: sudoku_games.db');
    print('DB 전체 경로: $dbPath');
    print('==================');
  } catch (e) {
    print('DB 경로 출력 중 오류: $e');
  }
}

class MySudokuApp extends StatelessWidget {
  const MySudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Sudoku',
      theme: AppTheme.lightTheme,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const LevelSelectionMain();
      case 1:
        return const Center(child: Text('알 수 없는 페이지'));
      case 2:
        return const SettingsScreen();
      default:
        return const Center(child: Text('알 수 없는 페이지'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 따른 레이아웃 분기
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (isTablet) {
      // 태블릿 레이아웃: 하단 네비게이션 + 더 큰 콘텐츠
      return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(3, (index) => _buildPage(index)),
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      );
    } else {
      // 모바일 레이아웃: 하단 네비게이션
      return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(3, (index) => _buildPage(index)),
        ),
        // bottomNavigationBar: BottomNavBar(
        //   selectedIndex: _selectedIndex,
        //   onItemTapped: _onItemTapped,
        // ),
      );
    }
  }
}
