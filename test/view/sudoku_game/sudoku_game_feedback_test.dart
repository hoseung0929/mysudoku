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

  testWidgets('plain correct input: one medium impact, no message',
      (tester) async {
    final presenter = await pumpGame(tester);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 7, 7, 3);
    expect(presenter.getCellValue(7, 7), 3);
    expect(haptics, ['mediumImpact']);
    expect(find.textContaining('completed'), findsNothing);
    expect(find.textContaining('filled in all'), findsNothing);
    await settle(tester);
  });

  testWidgets('a completed digit: no top message, one heavy impact',
      (tester) async {
    await pumpGame(tester);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 8, 7, 7);
    expect(find.text('You filled in all the 7s'), findsNothing);
    expect(haptics, ['heavyImpact']);
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
    expect(haptics, ['heavyImpact']);
    // 숫자 9칸 전체 강조는 생략된다.
    final grid = tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid));
    expect(grid.digitCompleteActive.values.any((v) => v), isFalse);
    await settle(tester);
  });

  testWidgets('a wrong answer: no top message, one heavy impact',
      (tester) async {
    final presenter = await pumpGame(tester);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 7, 7, 5);
    expect(presenter.wrongCount, 1);
    expect(haptics, ['heavyImpact']);
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
      for (var i = 0; i < maxWrong - 1; i++) 'heavyImpact', // 오답
      'heavyImpact', 'mediumImpact', // 게임 오버: 짧은 2회 패턴
    ]);
    await settle(tester);
  });

  testWidgets(
      'number-lock input is a light impact, distinct from a cell-selection '
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
    expect(haptics, ['lightImpact']);
    await settle(tester);
  });

  testWidgets(
      'number lock: weak tick while holding, heavy impact when the pin sets',
      (tester) async {
    await pumpGame(tester);
    final haptics = trackHaptics(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('number-button-3'))),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(haptics, isEmpty); // 일반 탭 길이에서는 아직 울리지 않는다.
    await tester.pump(const Duration(milliseconds: 100)); // 200ms
    expect(haptics, ['selectionClick']);
    await tester.pump(const Duration(milliseconds: 200)); // 400ms: 350ms 지남
    expect(haptics, ['selectionClick', 'heavyImpact']);
    await gesture.up();
    await tester.pump();
    expect(haptics, ['selectionClick', 'heavyImpact']);
    await settle(tester);
  });

  testWidgets('a quick number tap gets no hold tick and no lock vibration',
      (tester) async {
    final presenter = await pumpGame(tester);
    tapCell(tester, 7, 7);
    await tester.pump();
    final haptics = trackHaptics(tester);
    await tester.tap(find.byKey(const ValueKey('number-button-3')),
        warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(presenter.getCellValue(7, 7), 3);
    expect(haptics, ['mediumImpact']); // 입력 진동 하나뿐
    await settle(tester);
  });

  testWidgets('number lock: the button fills while held, gone on release',
      (tester) async {
    await pumpGame(tester);
    final fill = find.byKey(const ValueKey('number-lock-fill-3'));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('number-button-3'))),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(fill, findsNothing); // 빠른 탭에서는 번쩍이지 않는다.
    await tester.pump(const Duration(milliseconds: 100)); // 150ms
    expect(fill, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100)); // 250ms, 아직 누르는 중
    expect(fill, findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(fill, findsNothing);
    await settle(tester);
  });

  testWidgets(
      'number lock: unlocking covers first, then the pin and border leave',
      (tester) async {
    await pumpGame(tester);
    final button = find.byKey(const ValueKey('number-button-3'));
    final pin = find.byKey(const ValueKey('number-lock-3'));
    final border = find.byKey(const ValueKey('number-lock-border-3'));
    await tester.longPress(button, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(pin, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 16)); // 효과 시작 프레임
    await tester.pump(const Duration(milliseconds: 280)); // 거의 다 덮음
    expect(find.byKey(const ValueKey('number-lock-fill-3')), findsOneWidget);
    // 고정의 역순: 덮는 동안 핀과 보라 테두리는 그대로 보인다.
    double opacity(Finder f) => tester
        .widgetList<FadeTransition>(
            find.ancestor(of: f, matching: find.byType(FadeTransition)))
        .fold(1.0, (o, w) => o * w.opacity.value);
    expect(pin, findsOneWidget);
    expect(border, findsOneWidget);
    expect(opacity(pin), 1.0);
    expect(opacity(border), 1.0);
    await tester.pump(const Duration(milliseconds: 80)); // 해제됨(350ms 이후)
    await tester.pump(const Duration(milliseconds: 110)); // 사라지는 후반
    final pinScale = tester
        .widget<ScaleTransition>(find
            .ancestor(of: pin, matching: find.byType(ScaleTransition))
            .first)
        .scale
        .value;
    expect(pinScale, lessThan(1.0)); // 나타날 때의 역순으로 작아진다.
    expect(pin, findsOneWidget);
    expect(border, findsOneWidget);
    expect(opacity(pin), lessThan(1.0));
    expect(opacity(border), lessThan(1.0));
    await tester.pump(const Duration(milliseconds: 200)); // 다 사라짐
    expect(pin, findsNothing);
    expect(border, findsNothing);
    await gesture.up();
    await tester.pump();
    expect(find.byKey(const ValueKey('number-lock-fill-3')), findsNothing);
    await settle(tester);
  });

  testWidgets(
      'number lock: fills up from the bottom, unlock covers from the top',
      (tester) async {
    await pumpGame(tester);
    final button = find.byKey(const ValueKey('number-button-3'));
    final fill = find.byKey(const ValueKey('number-lock-fill-3'));

    var gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 150));
    var rect = tester.getRect(fill);
    // 채움이 들어 있는 버튼 모양(눌려 줄어든 상태 그대로) 기준으로 비교한다.
    final clip =
        find.ancestor(of: fill, matching: find.byType(ClipRRect)).first;
    var buttonRect = tester.getRect(clip);
    expect(rect.bottom, moreOrLessEquals(buttonRect.bottom, epsilon: 1));
    expect(rect.top, greaterThan(buttonRect.top + 1));
    await tester.pump(const Duration(milliseconds: 250)); // 고정됨
    // 고정 테두리는 툭 나타나지 않고 서서히 나타나는 중이다.
    final border = find.byKey(const ValueKey('number-lock-border-3'));
    expect(border, findsOneWidget);
    expect(
      tester
          .widget<FadeTransition>(find
              .ancestor(of: border, matching: find.byType(FadeTransition))
              .first)
          .opacity
          .value,
      lessThan(1.0),
    );
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('number-lock-3')), findsOneWidget);

    gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 150));
    rect = tester.getRect(fill);
    buttonRect = tester.getRect(clip);
    expect(rect.top, moreOrLessEquals(buttonRect.top, epsilon: 1));
    expect(rect.bottom, lessThan(buttonRect.bottom - 1));
    await gesture.up();
    await settle(tester);
  });

  testWidgets('number lock: sliding off while held clears the fill',
      (tester) async {
    await pumpGame(tester);
    final fill = find.byKey(const ValueKey('number-lock-fill-3'));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('number-button-3'))),
    );
    await tester.pump(const Duration(milliseconds: 16)); // 효과 시작 프레임
    await tester.pump(const Duration(milliseconds: 150));
    expect(fill, findsOneWidget);
    await gesture.moveBy(const Offset(0, 30)); // 길게 누르기가 취소되는 거리
    await tester.pump(const Duration(milliseconds: 400));
    expect(fill, findsNothing); // 고정된 것처럼 꽉 찬 채로 남지 않는다.
    expect(find.byKey(const ValueKey('number-lock-3')), findsNothing);
    await gesture.up();
    await settle(tester);
  });

  testWidgets(
      'selecting a filled cell does not highlight its number on the pad',
      (tester) async {
    await pumpGame(tester);
    tapCell(tester, 1, 6); // 주어진 3: 보드에서만 같은 숫자를 강조한다.
    await tester.pump();
    final button = tester.widget<ProgressiveBlurButton>(
      find.byKey(const ValueKey('number-button-3')),
    );
    expect(button.isActive, isFalse);
    await settle(tester);
  });

  testWidgets('a quick tap never shows the fill', (tester) async {
    await pumpGame(tester);
    tapCell(tester, 7, 7);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('number-button-3')),
        warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('number-lock-fill-3')), findsNothing);
    await settle(tester);
  });

  testWidgets('reduce motion skips the fill', (tester) async {
    await pumpGame(tester, reduceMotion: true);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('number-button-3'))),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey('number-lock-fill-3')), findsNothing);
    await gesture.up();
    await settle(tester);
  });

  testWidgets('reduce motion does not turn the vibration off', (tester) async {
    await pumpGame(tester, reduceMotion: true);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 7, 7, 3);
    expect(haptics, ['mediumImpact']);
    await settle(tester);
  });

  testWidgets('notes input: one selection click, not an impact',
      (tester) async {
    final presenter = await pumpGame(tester);
    final haptics = trackHaptics(tester);
    await tester.tap(find.byKey(const ValueKey('game-action-memo')));
    await tester.pump();
    haptics.clear(); // 메모 모드 전환 자체의 진동은 따로 본다.
    tapCell(tester, 7, 7);
    await tester.pump();
    haptics.clear(); // 칸 선택 진동
    await tester.tap(find.byKey(const ValueKey('number-button-3')),
        warnIfMissed: false);
    await tester.pump();
    expect(presenter.getCellNotes(7, 7), {3});
    expect(haptics, ['selectionClick']);
    await settle(tester);
  });

  testWidgets('a progress milestone alone: one light impact', (tester) async {
    // 41칸을 비운 보드: 진행률은 (채운 칸 / 41). 줄·열·박스·숫자가 완성되지 않는
    // 칸만 골라 10칸을 채우고(24.4%), 11번째 입력으로 25%를 넘긴다.
    final checker = solution.map((row) => List<int>.from(row)).toList();
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if ((r + c) % 2 == 0) checker[r][c] = 0;
      }
    }
    final presenter = await pumpGame(tester, board: checker);
    for (final (r, c) in [
      (0, 0),
      (0, 2),
      (0, 4),
      (2, 0),
      (2, 2),
      (2, 4),
      (4, 0),
      (4, 4),
      (6, 0),
      (6, 2),
    ]) {
      presenter.selectCell(r, c);
      presenter.setSelectedCellValue(solution[r][c]);
      await tester.pump();
    }
    expect(presenter.progress, lessThan(0.25));
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 8, 2, solution[8][2]);
    expect(presenter.progress, greaterThanOrEqualTo(0.25));
    expect(haptics, ['lightImpact']);
    await settle(tester);
  });

  testWidgets('a column completed alone: one heavy impact', (tester) async {
    final presenter = await pumpGame(tester);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 0, 1, 3);
    expect(presenter.getCellValue(0, 1), 3);
    expect(haptics, ['heavyImpact']);
    await settle(tester);
  });

  testWidgets('vibration off: a wrong answer is silent too', (tester) async {
    final presenter = await pumpGame(tester, vibration: false);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 7, 7, 5);
    expect(presenter.wrongCount, 1);
    expect(haptics, isEmpty);
    await settle(tester);
  });

  testWidgets('reduce motion keeps the strong haptics', (tester) async {
    await pumpGame(tester, reduceMotion: true);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 7, 7, 5); // 오답
    expect(haptics, ['heavyImpact']);
    await settle(tester);
  });

  testWidgets('the undo button is hidden by default; the other actions stay',
      (tester) async {
    await pumpGame(tester);
    expect(find.byKey(const ValueKey('game-action-undo')), findsNothing);
    expect(find.byIcon(Icons.undo_rounded), findsNothing);
    expect(find.byKey(const ValueKey('game-action-memo')), findsWidgets);
    expect(find.byKey(const ValueKey('game-action-hint')), findsWidgets);
    expect(find.byKey(const ValueKey('game-action-erase')), findsWidgets);
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
      'puzzle complete: medium at input, heavy at the glow peak, popup after hold',
      (tester) async {
    final lastBlank = solution.map((r) => List<int>.from(r)).toList()
      ..[8][7] = 0;
    final presenter = await pumpGame(tester, board: lastBlank);
    final haptics = trackHaptics(tester);
    await input(tester, haptics, 8, 7, 7);
    expect(presenter.isGameComplete, isTrue);
    expect(find.textContaining('filled in all'), findsNothing);
    expect(find.textContaining('cleared'), findsNothing);
    expect(haptics, ['mediumImpact']); // 마지막 숫자 확정 순간
    // 첫 번째 확산 정점(약 710ms) 전에는 더 울리지 않고, 그 직후 heavy 한 번.
    await tester.pump(const Duration(milliseconds: 400));
    expect(haptics, ['mediumImpact']);
    await tester.pump(const Duration(milliseconds: 350));
    expect(haptics, ['mediumImpact', 'heavyImpact']);
    // 연출 중(2.3초)에는 오버레이가 있고 결과창은 아직 없다.
    await tester.pump(const Duration(milliseconds: 1300));
    expect(
        find.byKey(const ValueKey('puzzle-complete-overlay')), findsOneWidget);
    // 팝업은 마지막 빛이 옅어지는 중(약 2.2초)에 예약된다. 오버레이는 약 2.3초에 사라진다
    // (결과창 자체는 기록 저장 후 열려 위젯 테스트에서는 확인하지 않는다).
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 30));
    expect(
        find.byKey(const ValueKey('puzzle-complete-overlay')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('puzzle-complete-overlay')), findsNothing);
    // 결과창이 열린 뒤에도 더 울리지 않는다.
    await tester.pump(const Duration(milliseconds: 600));
    expect(haptics, ['mediumImpact', 'heavyImpact']);
    await settle(tester);
  });
}
