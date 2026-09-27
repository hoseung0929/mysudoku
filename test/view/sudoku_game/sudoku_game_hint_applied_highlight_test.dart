// 힌트로 정답이 채워진 칸의 전용 강조 효과 테스트.
// 힌트 패널 자체의 등장·단계 전환은 sudoku_hint_panel_motion_test.dart,
// 정답 계산·저장 등 기능은 sudoku_game_hint_panel_test.dart가 다룬다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
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

  // 공용 puzzleBoard는 빈칸이 (0,1)·(0,2) 둘뿐이라, (0,1)을 힌트로 채우면
  // 세로줄·박스까지 함께 완성돼 줄 완성 효과가 힌트 강조보다 우선하게 된다
  // (의도된 동작, 별도 컨트롤러 단위 테스트로 확인함). "줄과 무관한 단독
  // 힌트 강조"를 확인하는 테스트는 (0,1)의 행·세로줄·박스 각각에 짝이 되는
  // 빈칸을 하나씩 더 둬, (0,1)을 채워도 어느 줄·박스도 완성되지 않는 이
  // 보드를 쓴다. (0,1)을 미리 선택한 채로 힌트를 열어 다른 빈칸이 아닌
  // (0,1)이 확실히 대상이 되게 한다.
  final soloHintBoard = solution.map((row) => List<int>.from(row)).toList()
    ..[0][1] = 0 // 힌트 대상
    ..[0][4] = 0 // 행 0의 짝
    ..[5][1] = 0 // 세로줄 1의 짝
    ..[2][2] = 0; // 박스 0의 짝

  Future<SudokuGamePresenter> pumpGame(
    WidgetTester tester,
    Size size, {
    bool reduceMotion = false,
    List<List<int>>? board,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = SudokuGame(
      board: board ?? puzzleBoard,
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
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: SudokuGameScreen(game: game, level: level),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    return tester
        .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
        .presenter;
  }

  Map<String, bool> hintAppliedActiveOf(WidgetTester tester) => tester
      .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
      .hintAppliedActive;

  Map<String, bool> waveActiveOf(WidgetTester tester) =>
      tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid)).waveActive;

  Future<void> openAndFillHint(WidgetTester tester) async {
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Fill in answer'));
    await tester.pump();
  }

  testWidgets('highlights only the cell the hint just filled', (tester) async {
    final presenter =
        await pumpGame(tester, const Size(390, 844), board: soloHintBoard);
    presenter.selectCell(0, 1);
    await openAndFillHint(tester);
    expect(presenter.getCellValue(0, 1), 3);

    final active = hintAppliedActiveOf(tester)
        .entries
        .where((e) => e.value)
        .map((e) => e.key);
    expect(active, ['0,1']);
    // 일반 정답 강조(초록 wave)는 대신 걸리지 않는다.
    expect(waveActiveOf(tester)['0,1'], isNot(true));

    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('fades out after ~200ms', (tester) async {
    final presenter =
        await pumpGame(tester, const Size(390, 844), board: soloHintBoard);
    presenter.selectCell(0, 1);
    await openAndFillHint(tester);
    expect(hintAppliedActiveOf(tester)['0,1'], isTrue);

    await tester.pump(const Duration(milliseconds: 100));
    expect(hintAppliedActiveOf(tester)['0,1'], isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    expect(hintAppliedActiveOf(tester)['0,1'] ?? false, isFalse);
  });

  testWidgets('the answer and save are not delayed by the highlight',
      (tester) async {
    final presenter = await pumpGame(tester, const Size(390, 844));
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Fill in answer'));
    // 애니메이션이 끝나기 전, 바로 다음 프레임에서 이미 반영돼 있다.
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 3);
    expect(presenter.isHintCell(0, 1), isTrue);

    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('reduce motion still shows the highlight state instantly',
      (tester) async {
    final presenter = await pumpGame(
      tester,
      const Size(390, 844),
      reduceMotion: true,
      board: soloHintBoard,
    );
    presenter.selectCell(0, 1);
    await openAndFillHint(tester);
    expect(presenter.getCellValue(0, 1), 3);
    expect(hintAppliedActiveOf(tester)['0,1'], isTrue);
    expect(tester.takeException(), isNull);
    // 강조 state 자체의 유지 시간(hold, 140ms)은 동작 줄이기와 무관하다 —
    // 위젯 쪽 페이드 전환 시간만 0이 된다. 끝나기 전에 테스트가 끝나지
    // 않도록 마저 흘려보낸다.
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('closing the screen right after filling does not crash',
      (tester) async {
    final presenter =
        await pumpGame(tester, const Size(390, 844), board: soloHintBoard);
    presenter.selectCell(0, 1);
    await openAndFillHint(tester);
    // 강조 타이머(140ms)가 끝나기 전에 화면을 치운다.
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
