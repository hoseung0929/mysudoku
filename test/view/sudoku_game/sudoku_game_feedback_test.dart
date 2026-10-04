import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_game_feature_policy.dart';
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

  final level = SudokuLevel.levels.first;
  final maxWrong = SudokuGameFeaturePolicy.forLevel(level).maxWrongCount;
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
  // 입력 한 번이 만드는 이벤트가 칸마다 다른 보드(완성 가능한 줄이 없는 칸,
  // 숫자만 완성되는 칸, 줄과 숫자가 함께 완성되는 칸 …).
  //  (7,7)=3: 일반 정답   (8,7)=7: 숫자 7 완료   (3,2)=9: 열 2와 숫자 9 완료
  //  (0,1)=3: 열 1 완성(숫자 3은 (7,7)이 남아 있을 때까지 미완)
  final blanks = [
    (0, 1),
    (2, 6),
    (3, 2),
    (3, 6),
    (6, 6),
    (7, 6),
    (7, 7),
    (8, 5),
    (8, 7),
  ];
  final puzzle = solution.map((row) => List<int>.from(row)).toList();
  for (final (r, c) in blanks) {
    puzzle[r][c] = 0;
  }

  Future<SudokuGamePresenter> pumpGame(
    WidgetTester tester, {
    List<List<int>>? board,
    bool reduceMotion = false,
    bool vibration = true,
    Size size = const Size(390, 844),
    double textScale = 1.0,
    ThemeData? theme,
  }) async {
    SharedPreferences.setMockInitialValues({
      'vibration_enabled': vibration,
      'number_lock_tip_shown_v1': true,
    });
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
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: SudokuGameScreen(
          game: SudokuGame(
            board: board ?? puzzle,
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

  List<String> trackHaptics(WidgetTester tester) {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add(
            (call.arguments as String).replaceFirst('HapticFeedbackType.', ''),
          );
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    return calls;
  }

  void tapCell(WidgetTester tester, int row, int col) {
    tester
        .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
        .onCellTapped(row, col);
  }

  // 칸을 고른 뒤(선택 진동은 따로 본다) 숫자 버튼을 눌러 입력한다.
  Future<void> input(
    WidgetTester tester,
    List<String> haptics,
    int row,
    int col,
    int value,
  ) async {
    tapCell(tester, row, col);
    await tester.pump();
    haptics.removeWhere((h) => h == 'selectionClick');
    final button = find.byKey(ValueKey('number-button-$value'));
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 5));

  testWidgets('plain correct input: one light impact, no message',
      (tester) async {
    final presenter = await pumpGame(tester);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 7, 7, 3);
    expect(presenter.getCellValue(7, 7), 3);
    expect(haptics, ['lightImpact']);
    expect(find.textContaining('completed'), findsNothing);
    expect(find.textContaining('filled in all'), findsNothing);
    await settle(tester);
  });

  testWidgets('a completed digit: no top message, one medium impact',
      (tester) async {
    await pumpGame(tester);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 8, 7, 7);
    expect(find.text('You filled in all the 7s'), findsNothing);
    expect(haptics, ['mediumImpact']);
    await settle(tester);
  });

  testWidgets(
      'a column and a digit at once: no top message, one '
      'haptic', (tester) async {
    await pumpGame(tester);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 3, 2, 9);
    expect(find.textContaining('cleared'), findsNothing);
    expect(find.textContaining('filled in all the 9s'), findsNothing);
    expect(haptics, ['mediumImpact']);
    // 숫자 9칸 전체 강조는 생략된다.
    final grid = tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid));
    expect(grid.digitCompleteActive.values.any((v) => v), isFalse);
    await settle(tester);
  });

  testWidgets('a wrong answer: no top message, one medium impact',
      (tester) async {
    final presenter = await pumpGame(tester);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 7, 7, 5);
    expect(presenter.wrongCount, 1);
    expect(haptics, ['mediumImpact']);
    expect(find.byKey(const Key('game-feedback-pill')), findsNothing);
    await settle(tester);
  });

  testWidgets('game over uses a short two-pulse pattern, not three strong ones',
      (tester) async {
    final presenter = await pumpGame(tester);
    final haptics = trackHaptics(tester);
    // 서로 다른 칸에 서로 다른 오답을 최대 횟수만큼 넣는다.
    const wrongInputs = [
      (7, 7, 5),
      (7, 6, 9),
      (8, 5, 4),
      (6, 6, 7),
      (3, 6, 2),
    ];
    for (final (r, c, v) in wrongInputs.take(maxWrong)) {
      await input(tester, haptics, r, c, v);
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(presenter.isGameOver, isTrue);
    expect(haptics, [
      for (var i = 0; i < maxWrong - 1; i++) 'mediumImpact', // 오답
      'heavyImpact', 'mediumImpact', // 게임 오버: 짧은 2회 패턴
    ]);
    await settle(tester);
  });

  testWidgets(
      'number-lock input after a plain correct is only a selection '
      'click', (tester) async {
    final presenter = await pumpGame(tester);
    final haptics = trackHaptics(tester);
    await tester.longPress(
      find.byKey(const ValueKey('number-button-3')),
      warnIfMissed: false,
    );
    await tester.pump();
    haptics.clear(); // 고정 진동은 따로 검증한다.
    tapCell(tester, 7, 7);
    await tester.pump();
    expect(presenter.getCellValue(7, 7), 3);
    expect(haptics, ['selectionClick']);
    await settle(tester);
  });

  testWidgets('reduce motion does not turn the vibration off', (tester) async {
    await pumpGame(tester, reduceMotion: true);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 7, 7, 3);
    expect(haptics, ['lightImpact']);
    await settle(tester);
  });

  testWidgets('vibration off: no haptics even with motion on', (tester) async {
    await pumpGame(tester, vibration: false);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 7, 7, 3);
    await input(tester, haptics, 8, 7, 7);
    expect(haptics, isEmpty);
    await settle(tester);
  });

  testWidgets(
      'puzzle complete: no lower feedback, one heavy impact at the peak',
      (tester) async {
    final lastBlank = solution.map((r) => List<int>.from(r)).toList()
      ..[8][7] = 0;
    final presenter = await pumpGame(tester, board: lastBlank);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 8, 7, 7);
    expect(presenter.isGameComplete, isTrue);
    expect(find.textContaining('filled in all'), findsNothing);
    expect(find.textContaining('cleared'), findsNothing);
    expect(haptics, isEmpty); // 입력 자체에서는 하위 진동 없음
    // 글로우 정점(약 300ms) 전에는 울리지 않고, 그 직후 한 번 울린다.
    await tester.pump(const Duration(milliseconds: 250));
    expect(haptics, isEmpty);
    await tester.pump(const Duration(milliseconds: 100));
    expect(haptics, ['heavyImpact']);
    // 결과창이 열린 뒤에도 더 울리지 않는다.
    await tester.pump(const Duration(milliseconds: 600));
    expect(haptics, ['heavyImpact']);
    await settle(tester);
  });
}
