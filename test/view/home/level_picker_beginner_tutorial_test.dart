import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/database/database_helper.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/onboarding/beginner_tutorial_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/home/level_picker_screen.dart';
import 'package:sudoku159/view/onboarding/beginner_tutorial_screen.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class _NoopWakelockPlatform extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

final _level = SudokuLevel.levels.first;

List<List<int>> _solution() => List.generate(
      9,
      (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1),
    );

List<List<int>> _puzzle() {
  final b = _solution();
  for (var i = 0; i < _level.emptyCells; i++) {
    b[i ~/ 9][i % 9] = 0;
  }
  return b;
}

class _FakeDb implements DatabaseHelper {
  @override
  Future<List<Map<String, dynamic>>> getClearEventsForLevel(
    String levelName,
  ) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());

  _FakeDb(this.games, {this.cleared = const {}});
  final List<int> games;
  final Set<int> cleared;

  @override
  Future<List<int>> getGameNumbersForLevel(String levelName) async => games;

  @override
  Future<List<int>> getClearedGameNumbersForLevel(String levelName) async =>
      cleared.toList();

  @override
  Future<List<Map<String, dynamic>>> getClearRecordsForLevel(
    String levelName,
  ) async =>
      [
        for (final n in cleared)
          {'game_number': n, 'clear_time': 125, 'level_name': levelName},
      ];

  @override
  Future<Map<String, dynamic>?> getGameEntry(
    String levelName,
    int gameNumber,
  ) async =>
      {
        'game_number': gameNumber,
        'board': _puzzle(),
        'solution': _solution(),
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  wakelockPlusPlatformInstance = _NoopWakelockPlatform();
  EditableText.debugDeterministicCursor = true;

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> pumpPicker(
    WidgetTester tester, {
    List<int> games = const [1, 2, 3],
    Set<int> cleared = const {},
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LevelPickerScreen(
          level: _level,
          databaseHelper: _FakeDb(games, cleared: cleared),
        ),
      ),
    );
    await settle(tester);
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the first fresh beginner puzzle opens directly, no guide prompt',
      (tester) async {
    await pumpPicker(tester);
    await tester.tap(find.text('Start puzzle'));
    await settle(tester);

    expect(find.text('New to Sudoku?'), findsNothing);
    expect(find.byType(BeginnerTutorialScreen), findsNothing);
    expect(find.byType(SudokuGameScreen), findsOneWidget);
    // 안내를 보여 주지 않았으므로 완료/건너뜀으로 기록하지 않는다.
    expect(
      await BeginnerTutorialService().getState(),
      BeginnerTutorialState.unseen,
    );
  });

  testWidgets('replaying a completed puzzle never shows the prompt',
      (tester) async {
    await pumpPicker(tester, games: [1, 2, 3], cleared: {1});
    await tester.tap(find.text('001').first);
    await tester.pump();
    await tester.tap(find.text('Replay'));
    await settle(tester);

    expect(find.text('New to Sudoku?'), findsNothing);
    expect(find.byType(SudokuGameScreen), findsOneWidget);
  });
}
