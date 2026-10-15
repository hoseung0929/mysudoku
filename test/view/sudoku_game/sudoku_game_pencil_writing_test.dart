import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/view/sudoku_game/pencil_writing_widgets.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_board_grid.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';

/// Apple Pencil 필기 입력(1단계): 토글·최초 안내·인식 흐름·실패/후보 처리.
import 'package:sudoku159/utils/app_logger.dart';
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
  // puzzleBoard[0][1]이 빈 칸, [0][0]은 주어진 숫자.
  final board = [
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
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];

  Future<void> pumpGame(
    WidgetTester tester, {
    required Size size,
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = SudokuGame(
      board: board,
      solution: solution,
      emptyCells: level.emptyCells,
      levelName: level.name,
      gameNumber: 1,
    );
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SudokuGameScreen(game: game, level: level),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder toggle() => find.byKey(const ValueKey('pencil-writing-toggle'));

  Future<void> selectCell(WidgetTester tester, int row, int col) async {
    final cells = find.descendant(
      of: find.byType(SudokuBoardGrid),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(cells.at(row * 9 + col));
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
  }

  testWidgets('the toggle is shown on iPad and hidden on iPhone',
      (tester) async {
    await pumpGame(tester, size: const Size(834, 1194));
    expect(toggle(), findsOneWidget);
    await settle(tester);

    await pumpGame(tester, size: const Size(390, 844));
    expect(toggle(), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('default OFF: no writing overlay; ON creates it and is saved',
      (tester) async {
    await pumpGame(tester, size: const Size(834, 1194));
    await selectCell(tester, 0, 1);
    expect(find.byType(TextField), findsNothing); // OFF

    await tester.tap(toggle());
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    // 최초 켬: 비모달 안내가 한 번 보인다.
    expect(find.byKey(const ValueKey('pencil-coachmark-ok')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pencil-coachmark-ok')));
    await tester.pump();
    expect(find.byKey(const ValueKey('pencil-coachmark-ok')), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('pencil_writing_enabled_v1'), isTrue);
    expect(prefs.getBool('pencil_writing_coachmark_seen_v1'), isTrue);
    await settle(tester);
  });

  testWidgets('saved ON state and a seen coachmark are restored',
      (tester) async {
    await pumpGame(
      tester,
      size: const Size(834, 1194),
      prefs: const {
        'pencil_writing_enabled_v1': true,
        'pencil_writing_coachmark_seen_v1': true,
      },
    );
    await selectCell(tester, 0, 1);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const ValueKey('pencil-coachmark-ok')), findsNothing);
    await settle(tester);
  });

  testWidgets('a given (fixed) cell never gets a writing field',
      (tester) async {
    await pumpGame(
      tester,
      size: const Size(834, 1194),
      prefs: const {'pencil_writing_enabled_v1': true},
    );
    await selectCell(tester, 0, 0); // 주어진 숫자 5
    expect(find.byType(TextField), findsNothing);
    await settle(tester);
  });

  testWidgets('a clear digit is entered through the normal input rules',
      (tester) async {
    await pumpGame(
      tester,
      size: const Size(834, 1194),
      prefs: const {'pencil_writing_enabled_v1': true},
    );
    await selectCell(tester, 0, 1);
    await tester.enterText(find.byType(TextField), '3'); // 정답
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('0 / 5'), findsOneWidget);
    await settle(tester);
  });

  testWidgets(
      'a wrong recognized digit counts as a mistake only after it is placed',
      (tester) async {
    await pumpGame(
      tester,
      size: const Size(834, 1194),
      prefs: const {'pencil_writing_enabled_v1': true},
    );
    await selectCell(tester, 0, 1);
    await tester.enterText(find.byType(TextField), '4'); // 오답(정답 3)
    await tester.pump();
    expect(find.text('0 / 5'), findsOneWidget); // 인식 대기 중엔 오답 아님
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('1 / 5'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('recognition failure shows a hint and is never a mistake',
      (tester) async {
    await pumpGame(
      tester,
      size: const Size(834, 1194),
      prefs: const {'pencil_writing_enabled_v1': true},
    );
    await selectCell(tester, 0, 1);
    await tester.enterText(find.byType(TextField), '0');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Please write a digit from 1 to 9 again'), findsOneWidget);
    expect(find.text('0 / 5'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('selecting another cell cancels a pending writing',
      (tester) async {
    await pumpGame(
      tester,
      size: const Size(834, 1194),
      prefs: const {'pencil_writing_enabled_v1': true},
    );
    await selectCell(tester, 0, 1);
    await tester.enterText(find.byType(TextField), '3');
    await tester.pump(const Duration(milliseconds: 100));
    await selectCell(tester, 0, 2); // 다른 셀 선택
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('0 / 5'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('candidate bar lists candidates and a rewrite action',
      (tester) async {
    int? chosen;
    var rewritten = false;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: PencilCandidateBar(
            candidates: const [1, 7, 9],
            onChoose: (d) => chosen = d,
            onRewrite: () => rewritten = true,
          ),
        ),
      ),
    ));
    expect(find.text('Choose the recognized digit'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pencil-candidate-7')));
    expect(chosen, 7);
    await tester.tap(find.byKey(const ValueKey('pencil-rewrite')));
    expect(rewritten, isTrue);
  });
}
