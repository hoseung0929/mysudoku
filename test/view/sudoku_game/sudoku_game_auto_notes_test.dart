import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/presenter/game/sudoku_game_presenter.dart';
import 'package:sudoku159/services/game/auto_notes_tip_service.dart';
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
    final onFinder = find.text('Memo ON');
    final finder = onFinder.evaluate().isNotEmpty
        ? onFinder.first
        : find.text('Memo').first;
    await tapV(tester, finder);
    await tester.pump();
  }

  testWidgets('long-pressing Memo with no existing notes fills all blanks',
      (tester) async {
    final presenter = await pumpGame(tester);
    await longPressV(tester, find.text('Memo').first);
    await tester.pump();

    expect(presenter.getCellNotes(0, 1), isNotEmpty);
    expect(presenter.getCellNotes(0, 2), isNotEmpty);
    expect(presenter.getCellNotes(4, 4), isNotEmpty);
    expect(presenter.autoNotesUsed, isTrue);
    expect(find.byIcon(Icons.auto_awesome), findsWidgets);
  });

  testWidgets(
      'long-pressing Memo with existing notes asks to confirm; cancel keeps them',
      (tester) async {
    final presenter = await pumpGame(tester);
    await tapMemoButton(tester); // 메모 모드 ON
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(7);
    final priorNotes = presenter.getCellNotes(0, 1);
    expect(priorNotes, {7});

    await longPressV(tester, find.text('Memo ON').first);
    await tester.pump();
    expect(find.text('Refill all notes?'), findsOneWidget);

    await tapV(tester, find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(presenter.getCellNotes(0, 1), priorNotes);
    expect(presenter.autoNotesUsed, isFalse);
  });

  testWidgets('confirming the refill replaces existing notes', (tester) async {
    final presenter = await pumpGame(tester);
    await tapMemoButton(tester); // 메모 모드 ON
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(7);
    expect(presenter.getCellNotes(0, 1), {7});

    await longPressV(tester, find.text('Memo ON').first);
    await tester.pump();
    await tapV(tester, find.text('Refill notes'));
    await tester.pumpAndSettle();

    expect(presenter.getCellNotes(0, 1), isNot({7}));
    expect(presenter.autoNotesUsed, isTrue);
  });

  testWidgets('blocked while the hint panel is open', (tester) async {
    final presenter = await pumpGame(tester);
    await tapV(tester, find.text('Hint'));
    await tester.pump();

    // 힌트 패널이 열려 있으면 `_canUseAutoNotes`가 false가 되어
    // `_buildMobileActionButton`이 메모 버튼을 감싸는 길게 누르기용
    // GestureDetector 자체를 만들지 않는다(onLongPress가 null이면 감싸지
    // 않음). 힌트 패널이 그 영역 전체를 히트테스트 차단 레이어로 덮고
    // 있어 실제로 long-press를 실행하면 좌표가 다른 위젯에 맞아 hit-test
    // 경고가 나므로, 대신 "길게 누르기 콜백이 아예 연결되지 않았는지"를
    // 위젯 트리로 직접 확인한다.
    final memoText = find.text('Memo').first;
    final longPressWrapper = find.ancestor(
      of: memoText,
      matching: find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onLongPress != null,
      ),
    );
    expect(longPressWrapper, findsNothing);

    expect(presenter.autoNotesUsed, isFalse);
    expect(find.text('Refill all notes?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduce motion applies instantly without errors', (tester) async {
    final presenter = await pumpGame(tester, reduceMotion: true);
    await longPressV(tester, find.text('Memo').first);
    await tester.pump();
    expect(presenter.autoNotesUsed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing the screen right after long-press does not crash',
      (tester) async {
    await pumpGame(tester);
    await longPressV(tester, find.text('Memo').first);
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('turning memo mode on shows a one-time tip', (tester) async {
    await pumpGame(tester);
    await tapMemoButton(tester); // OFF -> ON, 최초 1회
    await tester.pump();
    expect(
      find.text(
        'Tip: long-press Notes to fill in all candidate numbers at once.',
      ),
      findsOneWidget,
    );
    expect(await AutoNotesTipService().hasShownTip(), isTrue);
  });

  testWidgets('the tip is not shown again once already recorded as seen',
      (tester) async {
    // 이전 세션에서 이미 안내를 봤다고 가정한다(별도 화면 인스턴스로 확인해
    // SnackBar가 사라지는 타이밍에 기대지 않는다).
    await pumpGame(tester);
    await AutoNotesTipService().markTipShown();
    await tapMemoButton(tester); // OFF -> ON
    await tester.pump();
    expect(
      find.text(
        'Tip: long-press Notes to fill in all candidate numbers at once.',
      ),
      findsNothing,
    );
  });

  testWidgets('small screen with large text has no overflow', (tester) async {
    await pumpGame(tester, size: const Size(320, 568));
    await longPressV(tester, find.text('Memo').first);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet landscape has no overflow', (tester) async {
    await pumpGame(tester, size: const Size(1024, 768));
    await longPressV(tester, find.text('Memo').first);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
