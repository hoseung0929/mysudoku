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

/// 하단 기능 버튼(메모·힌트·지우기)이 이미지 에셋으로 상태를 보여 주는지 확인한다.
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
  final board = solution.map((row) => List<int>.from(row)).toList()
    ..[0][1] = 0
    ..[0][2] = 0
    ..[4][4] = 0;

  const memoOff = 'assets/images/game_control_memo_off.png';
  const memoOn = 'assets/images/game_control_memo_on.png';
  const hintAvailable = 'assets/images/game_control_hint_available.png';
  const hintExhausted = 'assets/images/game_control_hint_exhausted.png';
  const erase = 'assets/images/game_control_erase.png';

  Future<SudokuGamePresenter> pumpGame(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    ThemeData? theme,
    int? restoredHints,
  }) async {
    SharedPreferences.setMockInitialValues({});
    if (restoredHints != null) {
      await GameStateService().saveSession(
        levelName: level.name,
        gameNumber: 1,
        board: board,
        notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
        elapsedSeconds: 30,
        hintsRemaining: restoredHints,
        wrongCount: 0,
        isMemoMode: false,
      );
    }
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: SudokuGameScreen(
          game: SudokuGame(
            board: board,
            solution: solution,
            emptyCells: level.emptyCells,
            levelName: level.name,
            gameNumber: 1,
          ),
          level: level,
          restoreSavedSession: restoredHints != null,
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

  Finder asset(String name) => find.byWidgetPredicate((w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == name);

  Finder memoButton() => find.byKey(const ValueKey('game-action-memo'));
  Finder hintButton() => find.byKey(const ValueKey('game-action-hint'));

  testWidgets('labels are shown under the images; memo ON swaps in place',
      (tester) async {
    await pumpGame(tester);
    expect(find.text('Memo'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
    expect(find.text('Erase'), findsOneWidget);
    expect(find.text('Memo ON'), findsNothing);
    // 라벨은 이미지 아래에 있다.
    for (final entry in {
      memoOff: 'Memo',
      hintAvailable: 'Hint',
      erase: 'Erase',
    }.entries) {
      final image = tester.getRect(asset(entry.key));
      final label = tester.getRect(find.text(entry.value));
      expect(label.top, greaterThanOrEqualTo(image.bottom - 0.5),
          reason: entry.value);
      expect(label.top - image.bottom, lessThan(8), reason: entry.value);
    }
    final offRect = tester.getRect(asset(memoOff));
    final offLabel = tester.getRect(find.text('Memo'));
    final buttonRect = tester.getRect(memoButton());

    await tester.tap(memoButton());
    await tester.pump();
    expect(asset(memoOn), findsOneWidget);
    expect(asset(memoOff), findsNothing);
    expect(find.text('Memo ON'), findsOneWidget);
    final onRect = tester.getRect(asset(memoOn));
    // 같은 크기·같은 중심: 전환해도 이미지와 라벨이 움직이지 않는다.
    expect(onRect.size, offRect.size);
    expect(onRect.center.dx, closeTo(offRect.center.dx, 0.5));
    expect(onRect.center.dy, closeTo(offRect.center.dy, 0.5));
    expect(tester.getRect(find.text('Memo ON')).center.dy,
        closeTo(offLabel.center.dy, 0.5));
    expect(tester.getRect(memoButton()), buttonRect);
  });

  testWidgets('memo ON uses a lavender background and a purple border',
      (tester) async {
    await pumpGame(tester);
    Decoration? decorationOf() {
      final ink = find.descendant(
        of: memoButton(),
        matching: find.byType(Ink),
      );
      return tester.widget<Ink>(ink.first).decoration;
    }

    final off = decorationOf() as BoxDecoration;
    await tester.tap(memoButton());
    await tester.pump();
    final on = decorationOf() as BoxDecoration;
    expect(on.color, const Color(0xFFEFEBFF));
    final border = (on.border as Border).top;
    expect(border.color.a, closeTo(0.38, 0.02));
    expect(border.color.toARGB32() & 0xFFFFFF, 0x4A3F99);
    expect(on.color, isNot(off.color));
    // 탁한 회녹색(예전 활성색)은 더 쓰지 않는다.
    expect(on.color, isNot(const Color(0xFFB8E6B8)));
  });

  testWidgets('hint: available image with the exact count badge',
      (tester) async {
    final presenter = await pumpGame(tester);
    expect(asset(hintAvailable), findsOneWidget);
    expect(asset(hintExhausted), findsNothing);
    expect(find.text('${presenter.hintsRemaining}'), findsWidgets);
    final hintButton = find.ancestor(
      of: asset(hintAvailable),
      matching: find.byType(InkWell),
    );
    expect(hintButton, findsWidgets);
  });

  testWidgets('hint: exhausted image, no badge, button disabled',
      (tester) async {
    final presenter = await pumpGame(tester, restoredHints: 0);
    expect(presenter.hintsRemaining, 0);
    expect(asset(hintExhausted), findsOneWidget);
    expect(asset(hintAvailable), findsNothing);
    // 개수 배지(18pt 원)가 없다.
    expect(
      find.byWidgetPredicate((w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == const Color(0xFF457B9D)),
      findsNothing,
    );
    // 눌러도 힌트 패널이 열리지 않는다.
    await tester.tap(hintButton(), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Hint · Where to look'), findsNothing);
    expect(presenter.hintsRemaining, 0);
  });

  testWidgets('erase: one image; disabled dims the whole button',
      (tester) async {
    final presenter = await pumpGame(tester);
    expect(asset(erase), findsOneWidget);
    Finder dimmed() => find.ancestor(
          of: asset(erase),
          matching:
              find.byWidgetPredicate((w) => w is Opacity && w.opacity < 1.0),
        );
    // 선택한 칸이 없으면 비활성: 이미지는 그대로, 버튼 전체가 흐려진다.
    expect(dimmed(), findsWidgets);

    // 사용자가 입력한 칸을 선택하면 활성: 흐림이 없고 이미지는 그대로다.
    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(3);
    await tester.pump();
    expect(asset(erase), findsOneWidget);
    expect(dimmed(), findsNothing);
    await tester.pump(const Duration(seconds: 3)); // 줄 완성 효과 타이머
  });

  testWidgets('images use per-button sizes on one centerline', (tester) async {
    await pumpGame(tester);
    final memo = tester.getRect(asset(memoOff));
    final hint = tester.getRect(asset(hintAvailable));
    final eraser = tester.getRect(asset(erase));
    // 피사체 크기 보정: 메모 30 < 힌트 32 < 지우기 34.
    expect(memo.width, closeTo(30, 0.5));
    expect(hint.width, closeTo(32, 0.5));
    expect(eraser.width, closeTo(34, 0.5));
    // 이미지 윗면이 같은 줄에 가깝게 놓이도록 가운데 정렬 기준이 같다.
    expect(hint.center.dy, closeTo(memo.center.dy, 2));
    expect(eraser.center.dy, closeTo(memo.center.dy, 2));
  });

  testWidgets('erase disabled: dimmed to 0.6 but still readable',
      (tester) async {
    await pumpGame(tester);
    final dim = tester.widget<Opacity>(find
        .ancestor(of: asset(erase), matching: find.byType(Opacity))
        .evaluate()
        .map((e) => find.byWidget(e.widget))
        .firstWhere((f) => tester.widget<Opacity>(f).opacity < 1.0));
    expect(dim.opacity, closeTo(0.6, 0.001));
    // 이미지 자체에는 겹친 내용 투명도(0.36)가 걸리지 않는다.
    final contentOpacities = find
        .descendant(
            of: find.byKey(const ValueKey('game-action-erase')),
            matching: find.byType(Opacity))
        .evaluate()
        .map((e) => (e.widget as Opacity).opacity);
    expect(contentOpacities.every((o) => o >= 0.99), isTrue);
  });

  testWidgets('hint badge sits inside the button corner', (tester) async {
    await pumpGame(tester);
    final badge = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == const Color(0xFF457B9D));
    expect(badge, findsOneWidget);
    final badgeRect = tester.getRect(badge);
    final buttonRect = tester.getRect(hintButton());
    expect(badgeRect.size, const Size(18, 18));
    // 배지가 버튼 오른쪽 위 모서리 안쪽(또는 경계)에 걸친다.
    expect(badgeRect.right, lessThanOrEqualTo(buttonRect.right + 0.5));
    expect(badgeRect.top, greaterThanOrEqualTo(buttonRect.top - 0.5));
  });

  testWidgets('accessibility names follow each button state', (tester) async {
    final handle = tester.ensureSemantics();
    final presenter = await pumpGame(tester);
    expect(find.bySemanticsLabel('Notes mode off'), findsOneWidget);
    expect(find.bySemanticsLabel('Hint, 5 left'), findsOneWidget);
    // 지우기: 지울 것이 없으면 기존 이름(Erase), 선택한 입력이 있으면 구체화된 이름.
    expect(find.bySemanticsLabel('Erase'), findsOneWidget);
    expect(find.bySemanticsLabel('Erase selected cell'), findsNothing);

    presenter.selectCell(0, 1);
    presenter.setSelectedCellValue(3);
    await tester.pump();
    expect(find.bySemanticsLabel('Erase selected cell'), findsOneWidget);

    await tester.tap(memoButton());
    await tester.pump();
    expect(find.bySemanticsLabel('Notes mode on'), findsOneWidget);
    // 이미지는 장식이라 따로 읽히지 않는다.
    expect(find.bySemanticsLabel('game_control_memo_on'), findsNothing);
    await tester.pump(const Duration(seconds: 3)); // 줄 완성 효과 타이머를 흘려보낸다.
    handle.dispose();
  });

  testWidgets('accessibility: exhausted hints read "No hints left"',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpGame(tester, restoredHints: 0);
    expect(find.bySemanticsLabel('No hints left'), findsOneWidget);
    handle.dispose();
  });

  for (final config in [
    ('small phone, 2x text', const Size(320, 568), 2.0),
    ('phone dark, 1.3x text', const Size(390, 844), 1.3),
    ('iPad landscape', const Size(1024, 768), 1.0),
  ]) {
    testWidgets('no overflow: ${config.$1}', (tester) async {
      await pumpGame(
        tester,
        size: config.$2,
        textScale: config.$3,
        theme: config.$1.contains('dark') ? AppTheme.darkTheme() : null,
      );
      expect(tester.takeException(), isNull);
      expect(asset(memoOff), findsOneWidget);
      expect(asset(hintAvailable), findsOneWidget);
      expect(asset(erase), findsOneWidget);
    });
  }
}
