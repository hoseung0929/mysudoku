import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/services/settings/keypad_placement_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_board_grid.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class _NoopWakelockPlatform extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

/// 아이패드 키패드 위치 설정: 세로형(가운데·왼쪽·오른쪽), 가로형(왼쪽·오른쪽).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  wakelockPlusPlatformInstance = _NoopWakelockPlatform();
  EditableText.debugDeterministicCursor = true;

  final level = SudokuLevel.levels.first;
  final board = [
    [5, 0, 0, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];
  final solution = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];

  Future<void> pumpGame(
    WidgetTester tester, {
    required Size size,
    Map<String, Object> prefs = const {},
    Locale? locale,
    double textScale = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = SudokuGame(
      board: board,
      solution: solution,
      emptyCells: level.emptyCells,
      levelName: level.name,
      gameNumber: 1,
    );
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme(),
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SudokuGameScreen(game: game, level: level),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  double keypadX(WidgetTester tester) =>
      tester.getCenter(find.byKey(const ValueKey('number-button-5'))).dx;
  double toolsX(WidgetTester tester) =>
      tester.getCenter(find.byKey(const ValueKey('game-action-memo'))).dx;
  double boardX(WidgetTester tester) =>
      tester.getCenter(find.byType(SudokuBoardGrid)).dx;

  const portrait = Size(834, 1194);
  const landscape = Size(1194, 834);

  testWidgets('portrait default: keypad sits between tools and status',
      (tester) async {
    await pumpGame(tester, size: portrait);
    final width = portrait.width;
    expect(toolsX(tester), lessThan(keypadX(tester)));
    expect((keypadX(tester) - width / 2).abs(), lessThan(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait left: keypad on the left, tools on the right',
      (tester) async {
    await pumpGame(tester,
        size: portrait, prefs: {'keypad_placement_portrait_v1': 'left'});
    expect(keypadX(tester), lessThan(toolsX(tester)));
    expect(keypadX(tester), lessThan(portrait.width / 2));
    // 도구(메모·힌트·지우기)는 키패드 반대편 끝으로 간다.
    expect(toolsX(tester), greaterThan(portrait.width / 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait right: keypad on the right, tools on the left',
      (tester) async {
    await pumpGame(tester,
        size: portrait, prefs: {'keypad_placement_portrait_v1': 'right'});
    expect(keypadX(tester), greaterThan(toolsX(tester)));
    expect(keypadX(tester), greaterThan(portrait.width / 2));
    expect(toolsX(tester), lessThan(portrait.width / 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape default: panel on the right of the board',
      (tester) async {
    await pumpGame(tester, size: landscape);
    expect(keypadX(tester), greaterThan(boardX(tester)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape left: panel on the left of the board', (tester) async {
    await pumpGame(tester,
        size: landscape, prefs: {'keypad_placement_landscape_v1': 'left'});
    expect(keypadX(tester), lessThan(boardX(tester)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape ignores a stored "center" and keeps the right side',
      (tester) async {
    await pumpGame(tester,
        size: landscape, prefs: {'keypad_placement_landscape_v1': 'center'});
    expect(keypadX(tester), greaterThan(boardX(tester)));
  });

  testWidgets('iPhone is unaffected by the setting', (tester) async {
    await pumpGame(tester,
        size: const Size(390, 844),
        prefs: {'keypad_placement_portrait_v1': 'left'});
    expect(tester.takeException(), isNull);
    // 아이폰 레이아웃에서도 키패드가 가운데 쪽에 그대로 있다.
    expect((keypadX(tester) - 195).abs(), lessThan(60));
  });

  testWidgets('the game menu changes the keypad position on iPad',
      (tester) async {
    await pumpGame(tester, size: portrait);
    await tester.tap(find.byTooltip('More options'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Keypad position'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(find.byKey(const ValueKey('keypad-option-left')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(keypadX(tester), lessThan(toolsX(tester)));
    expect(await KeypadPlacementService().portrait(), KeypadPlacement.left);
  });

  testWidgets('changing the position slides the blocks instead of jumping',
      (tester) async {
    await pumpGame(tester, size: portrait);
    // 저장값을 불러온 직후엔 애니메이션이 꺼져 있다가, 한 프레임 뒤부터 켜진다.
    await tester.pump(const Duration(milliseconds: 100));
    final start = keypadX(tester);
    await tester.tap(find.byTooltip('More options'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Keypad position'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('keypad-option-left')));
    await tester.pump();
    // 대화상자가 닫히고 위치가 바뀌는 순간까지 진행한 뒤, 이동 중간 지점을 잰다.
    await tester.pump(const Duration(milliseconds: 190));
    await tester.pump(const Duration(milliseconds: 120));
    final mid = keypadX(tester);
    await tester.pump(const Duration(milliseconds: 600));
    final end = keypadX(tester);
    expect(end, lessThan(start));
    expect(mid, lessThan(start));
    expect(mid, greaterThan(end));
  });

  testWidgets('the game menu has no keypad item on iPhone', (tester) async {
    await pumpGame(tester, size: const Size(390, 844));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Keypad position'), findsNothing);
  });

  // 모든 언어·큰 글씨에서 메뉴 항목과 키패드 위치 대화상자가 넘치지 않는지.
  for (final code in ['en', 'ko', 'ja', 'es', 'zh']) {
    for (final size in [portrait, landscape]) {
      testWidgets(
          'keypad dialog fits: $code ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await pumpGame(tester,
            size: size, locale: Locale(code), textScale: 1.3);
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byIcon(Icons.dialpad_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
            find.byKey(const ValueKey('keypad-option-left')), findsOneWidget);
        expect(
            find.byKey(const ValueKey('keypad-option-right')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
