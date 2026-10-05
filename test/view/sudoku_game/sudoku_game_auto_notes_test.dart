import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/services/game/auto_notes_tip_service.dart';
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
  // (0,1)/(0,2)/(4,4)만 비워, 자동 메모를 적용해도 퍼즐이 끝나지 않는다.
  final safeBoard = solution.map((row) => List<int>.from(row)).toList()
    ..[0][1] = 0
    ..[0][2] = 0
    ..[4][4] = 0;

  Future<SudokuGamePresenter> pumpGame(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool reduceMotion = false,
    bool restore = false,
  }) async {
    if (!restore) SharedPreferences.setMockInitialValues({});
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

  Future<void> tapV(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  Future<void> longPressV(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.longPress(finder);
  }

  /// 메모 버튼을 실제로 눌러서(프레젠터를 직접 건드리지 않고) 라벨이
  /// "Memo"↔"Memo ON"으로 정상적으로 다시 그려지게 한다.
  Future<void> tapMemoButton(WidgetTester tester) async {
    final onFinder = find.byKey(const ValueKey('game-action-memo'));
    final finder = onFinder.evaluate().isNotEmpty
        ? onFinder.first
        : find.byKey(const ValueKey('game-action-memo'));
    await tapV(tester, finder);
    await tester.pump();
  }

  // 자동 메모는 향후 유료 편의 기능으로 보존만 하고 사용자에게는 노출하지 않는다
  // (`_autoNotesEnabled = false`). 후보 계산·`applyAutoNotes()` 단위 테스트는
  // test/presenter/game/auto_notes_test.dart에서 그대로 유지한다.
  const confirmTitle = 'Refill all notes?';
  const tipText =
      'Tip: long-press Notes to fill in all candidate numbers at once.';

  testWidgets('long-pressing Memo does nothing: no notes, no dialog',
      (tester) async {
    final presenter = await pumpGame(tester);
    await longPressV(tester, find.byKey(const ValueKey('game-action-memo')));
    await tester.pump();

    for (final cell in [(0, 1), (0, 2), (4, 4)]) {
      expect(presenter.getCellNotes(cell.$1, cell.$2), isEmpty);
    }
    expect(presenter.autoNotesUsed, isFalse);
    expect(find.text(confirmTitle), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long-press with existing notes shows no confirm dialog',
      (tester) async {
    final presenter = await pumpGame(tester);
    await tapMemoButton(tester); // 메모 모드 ON
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(7);
    expect(presenter.getCellNotes(0, 1), {7});

    await longPressV(tester, find.byKey(const ValueKey('game-action-memo')));
    await tester.pump();
    expect(find.text(confirmTitle), findsNothing);
    expect(presenter.getCellNotes(0, 1), {7}); // 직접 쓴 메모는 그대로
    expect(presenter.autoNotesUsed, isFalse);
  });

  testWidgets('the memo button has no auto-notes badge or long-press hook',
      (tester) async {
    await pumpGame(tester);
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
    final longPressWrapper = find.ancestor(
      of: find.byKey(const ValueKey('game-action-memo')),
      matching: find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onLongPress != null,
      ),
    );
    expect(longPressWrapper, findsNothing);
  });

  testWidgets('the memo button has no long-press accessibility hint',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpGame(tester);
    final node =
        tester.getSemantics(find.bySemanticsLabel('Notes mode off').first);
    expect(node.hint, isNot(contains('long')));
    expect(node.hint, isEmpty);
    handle.dispose();
  });

  testWidgets('normal memo mode toggling and manual candidates still work',
      (tester) async {
    final presenter = await pumpGame(tester);
    expect(presenter.isMemoMode, isFalse);
    await tapMemoButton(tester);
    expect(presenter.isMemoMode, isTrue);
    expect(find.byKey(const ValueKey('game-action-memo')), findsWidgets);

    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(7);
    presenter.setSelectedCellValue(9);
    expect(presenter.getCellNotes(0, 1), {7, 9});
    presenter.setSelectedCellValue(7);
    expect(presenter.getCellNotes(0, 1), {9});

    await tapMemoButton(tester);
    expect(presenter.isMemoMode, isFalse);
  });

  testWidgets('turning memo mode on no longer shows the auto-notes tip',
      (tester) async {
    await pumpGame(tester);
    await tapMemoButton(tester); // OFF -> ON
    await tester.pump();
    expect(find.text(tipText), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    // 안내를 봤다고 기록하지도 않는다(유료 기능 재개 때 처음부터 안내할 수 있게).
    expect(await AutoNotesTipService().hasShownTip(), isFalse);
  });

  testWidgets('a saved session with autoNotesUsed restores without errors',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await GameStateService().saveSession(
      levelName: level.name,
      gameNumber: 1,
      board: safeBoard,
      notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
      elapsedSeconds: 40,
      hintsRemaining: 3,
      wrongCount: 0,
      isMemoMode: false,
      autoNotesUsed: true,
    );
    final presenter = await pumpGame(tester, restore: true);
    expect(presenter.autoNotesUsed, isTrue);
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small screen with large text has no overflow', (tester) async {
    await pumpGame(tester, size: const Size(320, 568));
    await longPressV(tester, find.byKey(const ValueKey('game-action-memo')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet landscape has no overflow and no badge', (tester) async {
    await pumpGame(tester, size: const Size(1024, 768));
    await longPressV(tester, find.byKey(const ValueKey('game-action-memo')));
    await tester.pump();
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
