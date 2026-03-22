import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mysudoku/l10n/app_locale_scope.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/model/sudoku_level.dart';
import 'package:mysudoku/services/level_progress_service.dart';
import 'package:mysudoku/theme/app_theme.dart';
import 'package:mysudoku/theme/app_theme_scope.dart';
import 'package:mysudoku/view/challenge_screen.dart';
import 'package:mysudoku/view/level_selection_main.dart';
import 'package:mysudoku/view/records_statistics_screen.dart';
import 'package:mysudoku/view/settings_screen.dart';
import 'package:mysudoku/widgets/bottom_nav_bar.dart';
import 'package:mysudoku/utils/app_logger.dart';

const String _prefsLocaleKey = 'app_locale';
const String _prefsThemeModeKey = 'app_theme_mode';

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

class MySudokuApp extends StatefulWidget {
  const MySudokuApp({super.key});

  @override
  State<MySudokuApp> createState() => _MySudokuAppState();
}

class _MySudokuAppState extends State<MySudokuApp> {
  Locale? _localeOverride;
  ThemeMode _themeMode = ThemeMode.system;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsLocaleKey);
    final themeCode = prefs.getString(_prefsThemeModeKey);
    if (!mounted) return;
    setState(() {
      if (code == null || code.isEmpty || code == 'system') {
        _localeOverride = null;
      } else {
        _localeOverride = Locale(code);
      }
      _themeMode = _themeModeFromStorage(themeCode);
      _prefsLoaded = true;
    });
  }

  static ThemeMode _themeModeFromStorage(String? code) {
    switch (code) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _setAppLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsLocaleKey);
    } else {
      await prefs.setString(_prefsLocaleKey, locale.languageCode);
    }
    if (!mounted) return;
    setState(() => _localeOverride = locale);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_prefsThemeModeKey, 'light');
      case ThemeMode.dark:
        await prefs.setString(_prefsThemeModeKey, 'dark');
      case ThemeMode.system:
        await prefs.remove(_prefsThemeModeKey);
    }
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AppLocaleScope(
      appLocale: _localeOverride,
      setAppLocale: _setAppLocale,
      child: AppThemeScope(
        themeMode: _themeMode,
        setThemeMode: _setThemeMode,
        child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        locale: _localeOverride,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (locale, supported) {
          if (_localeOverride != null) {
            return _localeOverride;
          }
          if (locale == null) return supported.first;
          for (final supportedLocale in supported) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
          return supported.first;
        },
        home: const MyHomePage(),
        ),
      ),
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
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: List.generate(4, _buildPage),
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
