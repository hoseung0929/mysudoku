import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mysudoku/l10n/app_locale_scope.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/services/firebase_bootstrap_service.dart';
import 'package:mysudoku/services/firebase_identity_service.dart';
import 'package:mysudoku/services/game_record_notifier.dart';
import 'package:mysudoku/services/notification_service.dart';
import 'package:mysudoku/theme/app_theme.dart';
import 'package:mysudoku/navigation/root_nav_scope.dart';
import 'package:mysudoku/view/level_selection_main.dart';
import 'package:mysudoku/view/records_statistics_screen.dart';
import 'package:mysudoku/view/startup_catalog_preparing_gate.dart';
import 'package:mysudoku/widgets/bottom_nav_bar.dart';
import 'package:mysudoku/utils/app_logger.dart';

const String _prefsLocaleKey = 'app_locale';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseBootstrapService.instance.initialize();
  await FirebaseIdentityService().ensureSignedIn();

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
  final NotificationService _notificationService = NotificationService();
  Locale? _localeOverride;
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsLocaleKey);
    if (!mounted) return;
    setState(() {
      if (code == null || code.isEmpty || code == 'system') {
        _localeOverride = null;
      } else {
        _localeOverride = Locale(code);
      }
      _prefsLoaded = true;
    });

    unawaited(_bootstrapNotificationState());
  }

  Future<void> _bootstrapNotificationState() async {
    try {
      await _notificationService.initialize();
      await _notificationService.resyncFromStoredSettings();
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('알림 초기화 실패: $e');
      }
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
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: AppTheme.lightTheme(),
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
        home: const StartupCatalogPreparingGate(
          child: MyHomePage(),
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
  int _selectedIndex = 0;
  bool _recordsTabLoaded = false;

  void _onItemTapped(int index) {
    final isChanged = _selectedIndex != index;
    if (!isChanged) {
      return;
    }
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _recordsTabLoaded = true;
      }
    });
    if (index == 1) {
      GameRecordNotifier.instance.notifyChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RootNavScope(
      goToTab: _onItemTapped,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            const LevelSelectionMain(),
            _recordsTabLoaded
                ? const RecordsStatisticsScreen()
                : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: Material(
          color: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: BottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
