import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:sudoku159/widgets/waddling_penguin_icon.dart';
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
    bool reduceMotion = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        // 되돌리기 버튼은 기본적으로 숨겨져 있어, 되돌리기 동작 테스트는 버튼을 켜서 돌린다.
        home: SudokuGameScreen(game: game, level: level, showUndoButton: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    return tester
        .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
        .presenter;
  }

  Map<String, bool> undoActiveOf(WidgetTester tester) =>
      tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid)).undoActive;

  Map<String, bool> lineCompleteActiveOf(WidgetTester tester) => tester
      .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
      .lineCompleteActive;

  // 공용 puzzleBoard/solution은 빈칸이 (0,1)·(0,2) 둘뿐이라, 그중 하나만
  // 입력해도 이미 다른 줄(세로줄)을 완성시키고 둘 다 입력하면 퍼즐 전체가
  // 끝나 버린다. (4,4)도 함께 비운 이 보드는 행 0을 완성해도 퍼즐이 끝나지
  // 않아, 여러 칸을 연달아 입력·되돌리는 테스트에 안전하게 쓸 수 있다.
  final safeBoard = solution.map((row) => List<int>.from(row)).toList()
    ..[0][1] = 0
    ..[0][2] = 0
    ..[4][4] = 0;

  Future<SudokuGamePresenter> pumpSafeGame(
    WidgetTester tester,
    Size size, {
    bool reduceMotion = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
        home: SudokuGameScreen(
          game: SudokuGame(
            board: safeBoard,
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

  // 셀 탭 자체는 기존 화면 테스트가 다루므로, 선택은 프레젠터로 직접 한다.
  Future<void> selectCell(
    WidgetTester tester,
    SudokuGamePresenter presenter,
    int index,
  ) async {
    presenter.selectCell(index ~/ 9, index % 9);
    await tester.pump();
  }

  ProgressiveBlurButton buttonWithLabel(WidgetTester tester, String label) {
    return tester.widget<ProgressiveBlurButton>(
      find.byKey(ValueKey('game-action-${label.toLowerCase()}')),
    );
  }

  const sizes = {
    'phone': Size(390, 844),
    'phone SE': Size(320, 568),
    'tablet landscape': Size(1024, 768),
  };

  for (final entry in sizes.entries) {
    group(entry.key, () {
      testWidgets('undo button reverts the last input without refunding',
          (tester) async {
        final presenter = await pumpGame(tester, entry.value);
        expect(find.byKey(const ValueKey('game-action-undo')), findsOneWidget);
        expect(buttonWithLabel(tester, 'Undo').onPressed, isNull);

        await selectCell(tester, presenter, 1);
        presenter.setSelectedCellValue(4); // 오답
        await tester.pump();
        expect(presenter.wrongCount, 1);
        expect(buttonWithLabel(tester, 'Undo').onPressed, isNotNull);

        await tester.tap(find.byKey(const ValueKey('game-action-undo')));
        await tester.pump();
        expect(presenter.getCellValue(0, 1), 0);
        expect(presenter.wrongCount, 1);

        // 되돌린 뒤 오답 자동삭제 타이머가 남아 다른 값을 지우지 않는다.
        await selectCell(tester, presenter, 1);
        presenter.setSelectedCellValue(3);
        await tester.pump(const Duration(milliseconds: 1000));
        expect(presenter.getCellValue(0, 1), 3);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('OVERFLOWED'), findsNothing);
      });

      testWidgets(
          'the timer is plain info (no pause button); backgrounding still '
          'pauses and resumes it', (tester) async {
        final presenter = await pumpGame(tester, entry.value);
        await selectCell(tester, presenter, 1);
        presenter.setSelectedCellValue(3);
        await tester.pump();

        // 수동 일시정지 UI는 없다: 툴팁·아이콘·덮개가 모두 없고 타이머를 눌러도 멈추지 않는다.
        expect(find.byTooltip('Pause'), findsNothing);
        expect(find.byTooltip('Resume'), findsNothing);
        expect(find.byIcon(Icons.pause_rounded), findsNothing);
        expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
        expect(find.byKey(const ValueKey('game-pause-cover')), findsNothing);
        await tester.tap(find.byType(WaddlingPenguinIcon), warnIfMissed: false);
        await tester.pump();
        expect(presenter.isPaused, isFalse);

        // 앱 생명주기에 따른 자동 정지·재개는 그대로다(보드는 가리지 않는다).
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(presenter.isPaused, isTrue);
        expect(find.byKey(const ValueKey('game-pause-cover')), findsNothing);
        expect(buttonWithLabel(tester, 'Memo').onPressed, isNull);
        final secondsAtPause = presenter.seconds;
        await tester.pump(const Duration(seconds: 3));
        expect(presenter.seconds, secondsAtPause);

        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        expect(presenter.isPaused, isFalse);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('long-pressing Undo reapplies the last undone input',
      (tester) async {
    final presenter = await pumpSafeGame(tester, const Size(390, 844));
    await selectCell(tester, presenter, 1);
    presenter.setSelectedCellValue(3);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('game-action-undo')));
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 0);

    await tester.longPress(find.byKey(const ValueKey('game-action-undo')));
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 3);
    await tester.pump(const Duration(milliseconds: 1200));
  });

  testWidgets('selecting a number first locks it and a cell tap enters it',
      (tester) async {
    final presenter = await pumpSafeGame(tester, const Size(390, 844));

    tester
        .widget<ProgressiveBlurButton>(
          find.byKey(const ValueKey('number-button-3')),
        )
        .onPressed!();
    await tester.pump();
    expect(find.byKey(const ValueKey('number-lock-3')), findsOneWidget);

    tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid)).onCellTapped(
          0,
          1,
        );
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 3);
    expect(find.byKey(const ValueKey('number-lock-3')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1200));
  });

  group('undo result-cell highlight', () {
    testWidgets('highlights only the restored cell, then clears',
        (tester) async {
      final presenter = await pumpGame(tester, const Size(390, 844));
      await selectCell(tester, presenter, 1); // (0,1)
      presenter.setSelectedCellValue(3);
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('game-action-undo')));
      await tester.pump();
      final active =
          undoActiveOf(tester).entries.where((e) => e.value).map((e) => e.key);
      expect(active, ['0,1']);

      // hold(140ms) 동안은 유지되고, 끝나면 꺼진다.
      await tester.pump(const Duration(milliseconds: 100));
      expect(undoActiveOf(tester)['0,1'], isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(undoActiveOf(tester)['0,1'] ?? false, isFalse);
      // (0,1) 입력이 세로줄도 완성시켜 예약된 줄 완성 타이머를 마저 흘려보낸다.
      await tester.pump(const Duration(milliseconds: 1200));
    });

    testWidgets(
        'consecutive undos move the highlight without waiting for the '
        'previous cell to finish', (tester) async {
      final presenter = await pumpSafeGame(tester, const Size(390, 844));
      await selectCell(tester, presenter, 1); // (0,1)
      presenter.setSelectedCellValue(3);
      await selectCell(tester, presenter, 2); // (0,2)
      presenter.setSelectedCellValue(4); // 행 0 완성(퍼즐은 (4,4)가 남아 안 끝남)
      await tester.pump();

      await tester
          .tap(find.byKey(const ValueKey('game-action-undo'))); // (0,2) 되돌림
      await tester.pump();
      expect(undoActiveOf(tester)['0,2'], isTrue);

      await tester
          .tap(find.byKey(const ValueKey('game-action-undo'))); // (0,1) 되돌림
      await tester.pump();
      final active =
          undoActiveOf(tester).entries.where((e) => e.value).map((e) => e.key);
      expect(active, ['0,1']);
      // 행 0 완성으로 예약된 줄 완성 타이머(490ms)를 마저 흘려보낸다.
      await tester.pump(const Duration(milliseconds: 1200));
    });

    testWidgets('no highlight or vibration when there is nothing to undo',
        (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await pumpGame(tester, const Size(390, 844));
      expect(buttonWithLabel(tester, 'Undo').onPressed, isNull);
      expect(undoActiveOf(tester).values.any((v) => v), isFalse);
      expect(
        calls.where((c) => c.method == 'HapticFeedback.vibrate'),
        isEmpty,
      );
    });

    testWidgets('vibrates once when vibration is on and reduce motion is off',
        (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final presenter = await pumpGame(tester, const Size(390, 844));
      await selectCell(tester, presenter, 1);
      presenter.setSelectedCellValue(3);
      await tester.pump();
      calls.clear();

      await tester.tap(find.byKey(const ValueKey('game-action-undo')));
      await tester.pump();

      final vibrateCalls =
          calls.where((c) => c.method == 'HapticFeedback.vibrate').toList();
      expect(vibrateCalls, hasLength(1));
      expect(
          vibrateCalls.single.arguments, 'HapticFeedbackType.selectionClick');
      await tester.pump(const Duration(milliseconds: 1200));
    });

    testWidgets('reduce motion does not turn the vibration off',
        (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final presenter =
          await pumpGame(tester, const Size(390, 844), reduceMotion: true);
      await selectCell(tester, presenter, 1);
      presenter.setSelectedCellValue(3);
      await tester.pump();
      calls.clear();

      await tester.tap(find.byKey(const ValueKey('game-action-undo')));
      await tester.pump();

      // 동작 줄이기와 진동 설정은 분리돼 있어, 진동 설정이 켜져 있으면 유지된다.
      final vibrateCalls =
          calls.where((c) => c.method == 'HapticFeedback.vibrate').toList();
      expect(vibrateCalls, hasLength(1));
      expect(
          vibrateCalls.single.arguments, 'HapticFeedbackType.selectionClick');
      await tester.pump(const Duration(milliseconds: 1200));
    });

    testWidgets(
        'restoring a value that completes a row does not replay the line '
        'completion effect', (tester) async {
      final presenter = await pumpSafeGame(tester, const Size(390, 844));

      // 행 0을 8/9까지 채운다: (0,2)=4(정답), 그다음 (0,1)=3(정답)으로 완성.
      await selectCell(tester, presenter, 2);
      presenter.setSelectedCellValue(4);
      await selectCell(tester, presenter, 1);
      presenter.setSelectedCellValue(3); // 행 0 완성 → 정상적인 줄 완성 효과
      await tester.pump();
      expect(lineCompleteActiveOf(tester).values.any((v) => v), isTrue);
      // 상단 안내 문구는 더 이상 없다.
      expect(find.textContaining('cleared'), findsNothing);
      expect(find.textContaining('filled in all the 3s'), findsNothing);

      // 효과가 자연히 사라질 때까지 기다린다.
      await tester.pump(const Duration(milliseconds: 1300));
      expect(lineCompleteActiveOf(tester).values.any((v) => v), isFalse);
      expect(find.textContaining('filled in all the 3s'), findsNothing);

      // (0,1)을 지워 행을 다시 미완성으로 만든다.
      await tester.tap(find.byKey(const ValueKey('game-action-erase')));
      await tester.pump();
      expect(presenter.getCellValue(0, 1), 0);
      expect(lineCompleteActiveOf(tester).values.any((v) => v), isFalse);

      // 되돌리기로 (0,1)이 복원되며 행이 다시 완성되지만, 효과는
      // 재실행되지 않는다.
      await tester.tap(find.byKey(const ValueKey('game-action-undo')));
      await tester.pump();
      expect(presenter.getCellValue(0, 1), 3);
      expect(lineCompleteActiveOf(tester).values.any((v) => v), isFalse);
      expect(find.textContaining('filled in all the 3s'), findsNothing);
      expect(undoActiveOf(tester)['0,1'], isTrue);
      await tester.pump(const Duration(milliseconds: 1200));
    });

    testWidgets('no effect while paused, completed, or game-over',
        (tester) async {
      final presenter = await pumpGame(tester, const Size(390, 844));
      await selectCell(tester, presenter, 1);
      presenter.setSelectedCellValue(3);
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(buttonWithLabel(tester, 'Undo').onPressed, isNull);
      expect(undoActiveOf(tester).values.any((v) => v), isFalse);
      // (0,1) 입력이 세로줄을 완성시켜 예약된 줄 완성 타이머를 마저 흘려보낸다.
      await tester.pump(const Duration(milliseconds: 1200));
    });

    testWidgets('a stale undo-highlight timer does not crash after dispose',
        (tester) async {
      final presenter = await pumpGame(tester, const Size(390, 844));
      await selectCell(tester, presenter, 1);
      presenter.setSelectedCellValue(3);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('game-action-undo')));
      await tester.pump(const Duration(milliseconds: 30));

      // 강조 타이머(140ms)가 끝나기 전에 화면을 통째로 치운다.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1200));
      expect(tester.takeException(), isNull);
    });
  });
}
