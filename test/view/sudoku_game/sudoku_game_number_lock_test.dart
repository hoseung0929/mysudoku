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
import 'package:sudoku159/widgets/progressive_blur_button.dart';
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
  // 3이 들어갈 빈칸이 (0,1)·(1,6) 두 곳이고, (0,2)는 정답이 4, (4,4)는 5다.
  final puzzle = solution.map((row) => List<int>.from(row)).toList()
    ..[0][1] = 0
    ..[0][2] = 0
    ..[1][6] = 0
    ..[4][4] = 0;

  Future<SudokuGamePresenter> pumpGame(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
    Size size = const Size(390, 844),
    double textScale = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: SudokuGameScreen(
          game: SudokuGame(
            board: puzzle,
            solution: solution,
            emptyCells: level.emptyCells,
            levelName: level.name,
            gameNumber: 1,
          ),
          level: level,
          showUndoButton: true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return tester
        .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
        .presenter;
  }

  Finder pin(int n) => find.byKey(ValueKey('number-lock-$n'));

  // 숫자 버튼을 길게 눌러 고정한다(선택한 칸이 있으면 짧게 누르는 건 입력이다).
  Future<void> lock(WidgetTester tester, int n) => tester.longPress(
        find.byKey(ValueKey('number-button-$n')),
        warnIfMissed: false,
      );

  void tapCell(WidgetTester tester, int row, int col) {
    tester
        .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
        .onCellTapped(row, col);
  }

  // 안내 오버레이·줄 완성 연출 타이머를 흘려보낸다.
  Future<void> settle(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 5));

  testWidgets('one lock fills several cells and stays until the digit is done',
      (tester) async {
    final presenter = await pumpGame(tester);
    await lock(tester, 3);
    await tester.pump();
    expect(pin(3), findsOneWidget);
    // 상단 안내 문구는 없고 버튼의 고정 표시만 보인다.
    expect(find.textContaining('locked ·'), findsNothing);

    tapCell(tester, 0, 1);
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 3);
    expect(pin(3), findsOneWidget); // 입력 후에도 고정 유지

    tapCell(tester, 1, 6);
    await tester.pump();
    expect(presenter.getCellValue(1, 6), 3);
    expect(pin(3), findsNothing); // 3을 모두 채우면 자동 해제
    await settle(tester);
  });

  testWidgets('never overwrites a filled cell or a given number',
      (tester) async {
    final presenter = await pumpGame(tester);
    tapCell(tester, 0, 2);
    presenter.setSelectedCellValue(4);
    await tester.pump();
    expect(presenter.getCellValue(0, 2), 4);

    await lock(tester, 3);
    await tester.pump();
    tapCell(tester, 0, 2); // 직접 입력한 칸
    await tester.pump();
    expect(presenter.getCellValue(0, 2), 4);
    tapCell(tester, 0, 0); // 기본 제공 숫자
    await tester.pump();
    expect(presenter.getCellValue(0, 0), 5);
    expect(presenter.wrongCount, 0);
    expect(pin(3), findsOneWidget);
    await settle(tester);
  });

  testWidgets('a wrong answer releases the lock', (tester) async {
    final presenter = await pumpGame(tester);
    await lock(tester, 3);
    await tester.pump();
    tapCell(tester, 0, 2); // 정답은 4
    await tester.pump();
    expect(presenter.wrongCount, 1);
    expect(pin(3), findsNothing);
    await settle(tester);
  });

  testWidgets('notes mode adds and removes candidates, lock survives toggling',
      (tester) async {
    final presenter = await pumpGame(tester);
    await lock(tester, 3);
    presenter.toggleMemoMode();
    await tester.pump();
    expect(pin(3), findsOneWidget);

    tapCell(tester, 0, 1);
    await tester.pump();
    expect(presenter.getCellNotes(0, 1), contains(3));
    expect(presenter.getCellValue(0, 1), 0);
    tapCell(tester, 0, 2);
    await tester.pump();
    expect(presenter.getCellNotes(0, 2), contains(3));

    tapCell(tester, 0, 1); // 같은 후보가 있으면 제거
    await tester.pump();
    expect(presenter.getCellNotes(0, 1), isNot(contains(3)));

    presenter.toggleMemoMode(); // 메모 모드를 꺼도 고정 유지
    await tester.pump();
    expect(pin(3), findsOneWidget);
    expect(presenter.wrongCount, 0);
    await settle(tester);
  });

  testWidgets('backgrounding and resuming keep the lock', (tester) async {
    await pumpGame(tester);
    await lock(tester, 3);
    await tester.pump();
    expect(pin(3), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(pin(3), findsOneWidget);
    await settle(tester);
  });

  testWidgets('using a hint releases the lock', (tester) async {
    final presenter = await pumpGame(tester);
    await lock(tester, 3);
    await tester.pump();
    presenter.selectCell(0, 1); // 칸을 직접 선택해야 힌트를 쓸 수 있다.
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('game-action-hint')));
    await tester.pump();
    expect(pin(3), findsNothing);
    await settle(tester);
  });

  testWidgets('screen readers get locked state and how to release it',
      (tester) async {
    await pumpGame(tester);
    final handle = tester.ensureSemantics();
    await lock(tester, 3);
    await tester.pump();
    expect(
      find.bySemanticsLabel('3, locked, long press to unlock'),
      findsOneWidget,
    );
    handle.dispose();
    await settle(tester);
  });

  testWidgets('first-use tip shows once after a few number inputs',
      (tester) async {
    final presenter = await pumpGame(tester);
    tapCell(tester, 4, 4);
    presenter.toggleMemoMode();
    await tester.pump();
    const tip =
        'Long-press a number to lock it and fill it into several cells quickly.';
    for (var i = 0; i < 4; i++) {
      tester
          .widget<ProgressiveBlurButton>(
              find.byKey(const ValueKey('number-button-5')))
          .onPressed!();
      await tester.pump();
    }
    expect(find.text(tip), findsNothing);
    tester
        .widget<ProgressiveBlurButton>(
            find.byKey(const ValueKey('number-button-5')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(tip), findsOneWidget);
    await settle(tester);
  });

  testWidgets('first-use tip does not show again once it was shown',
      (tester) async {
    final presenter = await pumpGame(
      tester,
      prefs: {'number_lock_tip_shown_v1': true},
    );
    tapCell(tester, 4, 4);
    presenter.toggleMemoMode();
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      tester
          .widget<ProgressiveBlurButton>(
              find.byKey(const ValueKey('number-button-5')))
          .onPressed!();
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.text(
          'Long-press a number to lock it and fill it into several cells quickly.'),
      findsNothing,
    );
    await settle(tester);
  });

  testWidgets('undo, redo and erase keep the lock', (tester) async {
    final presenter = await pumpGame(tester);
    await lock(tester, 3);
    await tester.pump();
    tapCell(tester, 0, 1);
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 3);
    expect(pin(3), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('game-action-undo')));
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 0);
    expect(pin(3), findsOneWidget);

    presenter.redo();
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 3);
    expect(pin(3), findsOneWidget);

    presenter.selectCell(0, 1);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('game-action-erase')));
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 0);
    expect(pin(3), findsOneWidget);
    await settle(tester);
  });

  testWidgets('tapping several cells in one frame enters each exactly once',
      (tester) async {
    final presenter = await pumpGame(tester);
    await lock(tester, 3);
    await tester.pump();
    tapCell(tester, 0, 1);
    tapCell(tester, 1, 6);
    tapCell(tester, 0, 1); // 이미 채운 칸을 다시 눌러도 그대로
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 3);
    expect(presenter.getCellValue(1, 6), 3);
    expect(presenter.wrongCount, 0);
    expect(pin(3), findsNothing); // 3을 모두 채워 자동 해제
    await settle(tester);
  });

  for (final config in [
    ('small phone, 2x text', const Size(320, 568), 2.0),
    ('phone', const Size(390, 844), 1.0),
    ('iPad landscape', const Size(1180, 820), 1.0),
  ]) {
    testWidgets('pin, digit and remaining badge do not overlap: ${config.$1}',
        (tester) async {
      await pumpGame(tester, size: config.$2, textScale: config.$3);
      await lock(tester, 3);
      await tester.pump();
      expect(pin(3), findsOneWidget);
      expect(tester.takeException(), isNull);

      final button = find.byKey(const ValueKey('number-button-3'));
      final pinRect = tester.getRect(pin(3));
      final badge = find.descendant(
        of: button,
        matching: find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey &&
              '${(w.key as ValueKey).value}'.startsWith('badge-'),
        ),
      );
      final digit = find.descendant(of: button, matching: find.text('3'));
      expect(badge, findsOneWidget);
      expect(pinRect.overlaps(tester.getRect(badge)), isFalse);
      expect(pinRect.overlaps(tester.getRect(digit.first)), isFalse);
      await settle(tester);
    });
  }

  testWidgets('Apple Pencil digit input works alongside a lock on iPad',
      (tester) async {
    final presenter =
        await pumpGame(tester, size: const Size(1180, 820)); // 가로 iPad
    await lock(tester, 3);
    await tester.pump();
    expect(pin(3), findsOneWidget);

    // 펜슬로 다른 칸에 다른 숫자를 써도 고정은 그대로고 입력도 정상이다.
    presenter.selectCell(4, 4);
    await tester.pump();
    final grid = tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid));
    expect(grid.onPencilDigit, isNotNull);
    grid.onPencilDigit!(5);
    await tester.pump();
    expect(presenter.getCellValue(4, 4), 5);
    expect(pin(3), findsOneWidget);
    expect(presenter.wrongCount, 0);
    await settle(tester);
  });
}
