import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/main.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/home/home_screen.dart';
import 'package:sudoku159/view/records/records_statistics_screen.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';

/// [MyHomePage]는 각 탭에 실제 [HomeScreen]/[RecordsStatisticsScreen]을 주입 없이
/// 생성하므로, 탭 전환(특히 기록 탭 진입 시 알리는 [GameRecordNotifier])이 실제
/// sqflite 경로를 탄다. 위젯 테스트 환경에는 플랫폼 채널이 없어 ffi 구현으로
/// 대체해야 그 경로가 예외 없이 빈 결과를 반환한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory originalCwd;
  late Directory isolatedCwd;

  setUp(() async {
    originalCwd = Directory.current;
    isolatedCwd = await Directory.systemTemp.createTemp(
      'main_bottom_nav_test_',
    );
    Directory.current = isolatedCwd;
  });

  tearDown(() async {
    Directory.current = originalCwd;
    try {
      await isolatedCwd.delete(recursive: true);
    } catch (_) {}
  });

  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MyHomePage(),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  // 하단 탭 아이콘으로 탭한다: 탭이 열리면 그 화면 자신의 제목도 같은 문구를
  // 쓰기 때문에(예: 기록 탭의 "Records" 헤더) 텍스트 탐색은 중의적이다.
  Finder homeTab() => find.byIcon(Icons.home_rounded);
  Finder recordsTab() => find.byIcon(Icons.bar_chart_rounded);
  Finder settingsTab() => find.byIcon(Icons.settings_outlined);

  testWidgets(
      'bottom bar shows home, records, settings; each tap shows the '
      'right screen', (tester) async {
    await pumpApp(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(RecordsStatisticsScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsNothing);

    await tester.tap(recordsTab());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(RecordsStatisticsScreen), findsOneWidget);

    await tester.tap(settingsTab());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SettingsScreen), findsOneWidget);
    // 뒤로가기 버튼 없이 하단 탭으로만 진입한다.
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);

    await tester.tap(homeTab());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
      'records and settings tabs are not built until first selected '
      '(lazy load)', (tester) async {
    await pumpApp(tester);
    // 아직 한 번도 선택되지 않은 탭은 트리에 생성되지 않는다.
    expect(find.byType(RecordsStatisticsScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsNothing);
  });

  testWidgets('re-tapping the same tab does not recreate its screen',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(settingsTab());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final firstState =
        tester.state<State<SettingsScreen>>(find.byType(SettingsScreen));

    await tester.tap(settingsTab());
    await tester.pump();
    expect(find.byType(SettingsScreen), findsOneWidget);
    final secondState =
        tester.state<State<SettingsScreen>>(find.byType(SettingsScreen));
    expect(identical(firstState, secondState), isTrue);
  });

  testWidgets(
      'switching away from and back to the records tab keeps its scroll '
      'state (IndexedStack keeps it alive)', (tester) async {
    await pumpApp(tester);
    await tester.tap(recordsTab());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final recordsStateBefore = tester.state<State<RecordsStatisticsScreen>>(
      find.byType(RecordsStatisticsScreen),
    );

    await tester.tap(homeTab());
    await tester.pump();
    await tester.tap(recordsTab());
    await tester.pump();

    final recordsStateAfter = tester.state<State<RecordsStatisticsScreen>>(
      find.byType(RecordsStatisticsScreen),
    );
    expect(identical(recordsStateBefore, recordsStateAfter), isTrue);
  });
}
