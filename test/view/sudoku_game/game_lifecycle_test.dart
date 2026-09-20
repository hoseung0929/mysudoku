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
import 'package:sudoku159/utils/board_codec.dart';
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

  final level = SudokuLevel.levels.first;
  final solution = List.generate(
    9,
    (r) => List.generate(9, (c) => (r * 3 + r ~/ 3 + c) % 9 + 1),
  );
  final puzzle = solution.map((r) => List<int>.from(r)).toList();
  for (var i = 0; i < level.emptyCells; i++) {
    puzzle[i ~/ 9][i % 9] = 0;
  }
  final game = SudokuGame(
    board: puzzle,
    solution: solution,
    emptyCells: level.emptyCells,
    levelName: level.name,
    gameNumber: 1,
  );

  Future<SudokuGamePresenter> pumpGame(
    WidgetTester tester, {
    required bool restore,
    String? challengeDate,
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
        home: SudokuGameScreen(
          key: UniqueKey(),
          game: game,
          level: level,
          restoreSavedSession: restore,
          challengeDate: challengeDate,
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

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'backgrounding saves the session, pauses the timer, and a relaunch restores it',
      (tester) async {
    final presenter = await pumpGame(tester, restore: false);
    presenter.selectCell(0, 0);
    presenter.setSelectedCellValue(solution[0][0]);
    presenter.selectCell(0, 1);
    presenter.toggleMemoMode();
    presenter.setSelectedCellValue(6);
    await tester.pump(const Duration(seconds: 3));
    final beforeBackground = presenter.seconds;
    expect(beforeBackground, greaterThanOrEqualTo(3));

    // 백그라운드 전환: 저장 + 타이머 정지.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 5));
    expect(presenter.isPaused, isTrue);
    expect(presenter.seconds, beforeBackground); // 정지 중에는 시간이 흐르지 않음

    // 저장 결과 확인 (디바운스 대기 없이 paused 시점에 즉시 저장되어야 함)
    final saved = await GameStateService()
        .loadSession(levelName: level.name, gameNumber: 1);
    expect(saved, isNotNull);
    expect(saved!.board[0][0], solution[0][0]);
    expect(saved.notes[0][1], {6});
    expect(saved.elapsedSeconds, beforeBackground);
    expect(saved.isGameComplete || saved.isGameOver, isFalse);

    // 복귀: 자동 정지만 풀리고 시간은 이어서 흐른다.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect(presenter.isPaused, isFalse);
    expect(presenter.seconds, greaterThan(beforeBackground));

    // 앱 재실행(새 화면, 저장 세션 복원)
    final relaunched = await pumpGame(tester, restore: true);
    expect(relaunched.getCellValue(0, 0), solution[0][0]);
    expect(relaunched.getCellNotes(0, 1), {6});
    expect(relaunched.seconds, greaterThanOrEqualTo(beforeBackground));
  });

  testWidgets('legacy plain-board save (old format) is restored as a session',
      (tester) async {
    final board = puzzle.map((r) => List<int>.from(r)).toList();
    board[0][0] = solution[0][0];
    SharedPreferences.setMockInitialValues({
      // 구버전: 보드만 문자열로 저장 (JSON 아님)
      'game_${level.name}_1': BoardCodec.encode(board),
    });
    final presenter = await pumpGame(tester, restore: true);
    expect(presenter.getCellValue(0, 0), solution[0][0]);
    expect(presenter.wrongCount, 0);
  });

  testWidgets('board cells expose position, value/notes, and selected state',
      (tester) async {
    final handle = tester.ensureSemantics();
    final presenter = await pumpGame(tester, restore: false);
    // (0,0)은 빈칸, (5,5)는 고정 숫자.
    presenter.selectCell(0, 0);
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Row 1, column 1: empty')),
      isSemantics(isButton: true, isSelected: true),
    );
    presenter.toggleMemoMode();
    presenter.setSelectedCellValue(4);
    await tester.pump();
    expect(find.bySemanticsLabel('Row 1, column 1: notes 4'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Row 9, column 9: \d, given')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets(
      'a challenge started yesterday keeps its date when resumed without one',
      (tester) async {
    final presenter =
        await pumpGame(tester, restore: false, challengeDate: '2026-09-19');
    presenter.selectCell(0, 0);
    presenter.setSelectedCellValue(solution[0][0]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 50));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    // 일반 이어하기 경로(도전 날짜를 넘기지 않음)로 다시 열고, 다시 저장한다.
    final resumed = await pumpGame(tester, restore: true);
    resumed.selectCell(0, 1);
    resumed.setSelectedCellValue(solution[0][1]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 50));

    final saved = await GameStateService()
        .loadSession(levelName: level.name, gameNumber: 1);
    expect(saved!.challengeDate, '2026-09-19');
    expect(saved.board[0][1], solution[0][1]);
    // 남은 디바운스/효과 타이머를 정리한다.
    await tester.pump(const Duration(seconds: 6));
  });
}
