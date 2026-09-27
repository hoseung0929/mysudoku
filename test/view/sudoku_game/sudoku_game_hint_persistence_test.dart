import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/services/game/game_state_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  wakelockPlusPlatformInstance = _NoopWakelockPlatform();
  EditableText.debugDeterministicCursor = true;

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
    ...puzzleBoard.sublist(1),
  ];

  Future<SudokuGamePresenter> pumpGame(
    WidgetTester tester,
    Size size, {
    double textScale = 1.0,
    Locale? locale,
    bool restore = false,
  }) async {
    if (!restore) SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: SudokuGameScreen(
          game: game,
          level: level,
          restoreSavedSession: restore,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    return tester
        .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
        .presenter;
  }

  // runAsync를 쓰면 google_fonts가 실제 다운로드를 시도하므로, 목 저장소
  // 읽기를 가짜 시간 안에서 끝낸다.
  Future<GameSessionState?> loadSaved(WidgetTester tester) async {
    GameSessionState? saved;
    var done = false;
    GameStateService()
        .loadSession(levelName: level.name, gameNumber: 1)
        .then((value) {
      saved = value;
      done = true;
    });
    for (var i = 0; i < 20 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(done, isTrue);
    return saved;
  }

  Future<void> leaveGame(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_back));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('closing the hint panel and leaving keeps the hint used',
      (tester) async {
    final presenter = await pumpGame(tester, const Size(390, 844));
    final maxHints = presenter.hintsRemaining;
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.tap(find.byTooltip('Close hint'));
    await tester.pump();
    await leaveGame(tester);

    final saved = await loadSaved(tester);
    expect(saved!.hintsRemaining, maxHints - 1);
    expect(saved.isResumable(userFilledCells: 0, emptyCells: 2), isTrue);

    // 다시 열면 차감된 힌트 수가 그대로 복원된다.
    // 첫 화면을 pop해 비어 있는 Navigator를 새 앱 트리로 교체한다.
    await tester.pumpWidget(const SizedBox());
    final reopened =
        await pumpGame(tester, const Size(390, 844), restore: true);
    expect(reopened.hintsRemaining, maxHints - 1);
    expect(reopened.getCellValue(0, 1), 0);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('leaving from hint step two without filling keeps it used',
      (tester) async {
    final presenter = await pumpGame(tester, const Size(390, 844));
    final maxHints = presenter.hintsRemaining;
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.tap(find.text('Tell me more'));
    await tester.pump();
    await leaveGame(tester);

    final saved = await loadSaved(tester);
    expect(saved!.hintsRemaining, maxHints - 1);
    expect(saved.hintCells, isEmpty);
    expect(saved.board[0][1], 0);
  });

  testWidgets('hint used then app backgrounded is saved immediately',
      (tester) async {
    final presenter = await pumpGame(tester, const Size(390, 844));
    final maxHints = presenter.hintsRemaining;
    await tester.tap(find.text('Hint'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    final saved = await loadSaved(tester);
    expect(saved!.hintsRemaining, maxHints - 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('opening a puzzle without a hint leaves no resumable session',
      (tester) async {
    await pumpGame(tester, const Size(390, 844));
    await leaveGame(tester);
    final saved = await loadSaved(tester);
    expect(
      saved == null || !saved.isResumable(userFilledCells: 0, emptyCells: 2),
      isTrue,
    );
  });
}
