import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'view/level_selection_main.dart';
import 'view/challenge_screen.dart';
import 'view/records_statistics_screen.dart';
import 'view/settings_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'theme/app_theme.dart';
import 'model/sudoku_level.dart';
import 'services/level_progress_service.dart';
import 'package:mysudoku/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    try {
      final dbPath = join(await getDatabasesPath(), 'sudoku_games.db');
      AppLogger.debug('DB 경로: $dbPath');
    } catch (e) {
      AppLogger.debug('DB 경로 출력 실패: $e');
    }
  }

  runApp(const MySudokuApp());
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
  final LevelProgressService _levelProgressService = LevelProgressService();
  int _selectedIndex = 0;
  bool _isInitializingApp = true;

  @override
  void initState() {
    super.initState();
    _initializeAppData();
  }

  Future<void> _initializeAppData() async {
    try {
      await _levelProgressService.refreshAllLevels(SudokuLevel.levels);
    } catch (e) {
      AppLogger.debug('앱 초기 진행도 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializingApp = false;
        });
      }
    }
  }

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
        return const ChallengeScreen();
      case 2:
        return const RecordsStatisticsScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const LevelSelectionMain();
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
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: List.generate(4, (index) => _buildPage(index)),
            ),
            if (_isInitializingApp)
              const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      );
    } else {
      // 모바일 레이아웃: 하단 네비게이션
      return Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: List.generate(4, (index) => _buildPage(index)),
            ),
            if (_isInitializingApp)
              const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      );
    }
  }
}
