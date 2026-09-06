import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// wakelock_plus는 macOS에서 네이티브 채널을 쓰는데, `flutter test`는 macOS
/// 호스트에서 돌면서도 그 채널에 응답할 네이티브 쪽이 없어 `WakelockPlus.toggle()`
/// 호출이 영원히 끝나지 않는다(게임 화면 초기화가 이 호출을 기다리다 멈춤).
/// 패키지 자체 문서가 안내하는 대로 테스트용 플랫폼 인스턴스로 교체한다.
class _NoopWakelockPlatform extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  wakelockPlusPlatformInstance = _NoopWakelockPlatform();

  final level = SudokuLevel.levels.first;
  final puzzleBoard = [
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

  Future<void> pumpLandscapeGameScreen(
    WidgetTester tester, {
    required Size size,
  }) async {
    SharedPreferences.setMockInitialValues({});

    final originalSize = tester.view.physicalSize;
    final originalDpr = tester.view.devicePixelRatio;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalDpr;
    });

    final game = SudokuGame(
      board: puzzleBoard,
      solution: solution,
      emptyCells: level.emptyCells,
      levelName: level.name,
      gameNumber: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SudokuGameScreen(game: game, level: level),
      ),
    );
    // 게임 화면에 초 단위로 갱신되는 타이머가 있어 pumpAndSettle()은 끝나지
    // 않는다 — 비동기 초기화(_initializeGame)가 끝날 만큼만 명시적으로 pump.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets(
    'tablet landscape layout does not overflow when keypad column hits its min width clamp',
    (WidgetTester tester) async {
      // 아이패드 가로 폭 중, keypadColumnWidth가 최소 clamp(240)에 걸리는 좁은 쪽
      // (maxWidth * 0.30 <= 240 즉 maxWidth <= 800)을 재현 — 실제로 8px 오버플로우가
      // 나던 경계 조건.
      await pumpLandscapeGameScreen(tester, size: const Size(760, 650));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('OVERFLOWED'), findsNothing);
    },
  );

  testWidgets(
    'tablet landscape layout does not vertically overflow at the shortest realistic tablet height',
    (WidgetTester tester) async {
      // 태블릿 판정 기준(shortestSide > 600)에 거의 걸리는 낮은 높이 —
      // 통계 카드 4장 + Spacer + 숫자패드 + 액션 버튼이 세로로 다 들어가는지 확인.
      await pumpLandscapeGameScreen(tester, size: const Size(1024, 610));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('OVERFLOWED'), findsNothing);
    },
  );
}
