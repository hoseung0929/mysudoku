import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/onboarding/beginner_tutorial_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/onboarding/beginner_tutorial_screen.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_board_grid.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_hint_panel.dart';
import 'package:sudoku159/widgets/progressive_blur_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  Future<void> pumpTutorial(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1.0,
    bool reduceMotion = false,
    bool isReplay = false,
    BeginnerTutorialService? tutorialService,
    bool resetPrefs = true,
  }) async {
    if (resetPrefs) {
      SharedPreferences.setMockInitialValues({});
    }
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
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: BeginnerTutorialScreen(
          isReplay: isReplay,
          tutorialService: tutorialService,
        ),
      ),
    );
    await tester.pump();
  }

  /// 시스템 뒤로 가기(Android 뒤로 가기·iOS 스와이프)를 흉내낸다.
  Future<void> simulateSystemBack(WidgetTester tester) async {
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
  }

  // 화면이 스크롤 가능하므로(작은 화면·큰 글씨 대응), 탭 전에 항상 보이게 한다.
  Future<void> tapV(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  Finder numberKey(int n) => find.byKey(ValueKey('tutorial-number-$n'));

  /// 실제 게임처럼 대상 칸을 직접 눌러 선택한다.
  Future<void> tapCell(WidgetTester tester, int row, int col) async {
    final box = tester.getRect(find.byType(SudokuBoardGrid));
    final cell = box.width / 9;
    await tester.tapAt(Offset(
      box.left + cell * (col + 0.5),
      box.top + cell * (row + 0.5),
    ));
    await tester.pump();
  }

  Future<void> tapMemoButton(WidgetTester tester) async {
    await tapV(tester, find.byIcon(Icons.edit_note));
  }

  testWidgets('shows the practice title and a 1 / 5 progress label',
      (tester) async {
    await pumpTutorial(tester);
    expect(find.text('Practice puzzle'), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget);
    // 타이머·일시정지·더보기는 연습에 필요 없다.
    expect(find.byTooltip('Pause'), findsNothing);
    expect(find.byTooltip('More options'), findsNothing);
    // 별도 구현한 작은 OutlinedButton 숫자패드는 더 이상 없다.
    expect(find.byType(OutlinedButton), findsNothing);
    for (var n = 1; n <= 9; n++) {
      expect(numberKey(n), findsOneWidget);
    }
  });

  testWidgets('basic rules: one step, region buttons change the highlight',
      (tester) async {
    await pumpTutorial(tester);
    expect(find.text('Basic rules'), findsOneWidget);
    var grid = tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid));
    final rowRegion = grid.hintRegionCells;
    expect(rowRegion, isNotEmpty);

    await tapV(tester, find.byKey(const ValueKey('tutorial-rule-column')));
    await tester.pump();
    grid = tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid));
    final columnRegion = grid.hintRegionCells;
    expect(columnRegion, isNot(rowRegion));

    await tapV(tester, find.byKey(const ValueKey('tutorial-rule-box')));
    await tester.pump();
    grid = tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid));
    expect(grid.hintRegionCells, isNot(columnRegion));
    expect(grid.hintRegionCells, isNot(rowRegion));

    // 세 항목을 모두 확인하지 않아도 다음으로 진행할 수 있다.
    await tapV(tester, find.text('Next'));
    await tester.pump();
    expect(find.text('Enter a number'), findsOneWidget);
    expect(find.text('2 / 5'), findsOneWidget);
  });

  Future<void> goToInputStep(WidgetTester tester) async {
    await tapV(tester, find.text('Next'));
    await tester.pump();
  }

  testWidgets('input step does not select the cell for the user',
      (tester) async {
    await pumpTutorial(tester);
    await goToInputStep(tester);
    // 칸을 고르지 않고 숫자만 눌러도 진행되지 않는다.
    await tapV(tester, numberKey(5));
    await tester.pump();
    expect(find.text('Enter a number'), findsOneWidget);
    expect(find.text('Note candidates'), findsNothing);
    // 강조 칸이 아닌 다른 칸을 눌러도 진행되지 않는다.
    await tapCell(tester, 3, 3);
    await tapV(tester, numberKey(5));
    await tester.pump();
    expect(find.text('Enter a number'), findsOneWidget);
  });

  testWidgets('wrong digit shows an explanation, correct digit advances',
      (tester) async {
    await pumpTutorial(tester);
    await goToInputStep(tester);
    await tapCell(tester, 0, 0);

    // (0,0)의 정답은 5. 다른 숫자를 넣으면 왜 안 되는지 안내만 하고 실수로
    // 세지 않는다(연습 세션은 실수 제한 자체가 사실상 무제한).
    await tapV(tester, numberKey(3));
    await tester.pump();
    expect(
      find.text(
        "A number already in the same row, column, or 3×3 box can't go here.",
      ),
      findsOneWidget,
    );

    await tapV(tester, numberKey(5));
    await tester.pump();
    expect(find.text('Note candidates'), findsOneWidget);
    expect(find.text('3 / 5'), findsOneWidget);
  });

  Future<void> goToMemoStep(WidgetTester tester) async {
    await goToInputStep(tester);
    await tapCell(tester, 0, 0);
    await tapV(tester, numberKey(5));
    await tester.pump();
  }

  testWidgets('memo step needs the real memo button and a chosen cell',
      (tester) async {
    await pumpTutorial(tester);
    await goToMemoStep(tester);
    expect(find.text('Note candidates'), findsOneWidget);

    const erased = 'Tap the same number again to erase a note.';

    // 메모를 켰어도 칸을 직접 선택하지 않았다면 입력되지 않는다.
    await tapMemoButton(tester);
    await tester.pump();
    await tapV(tester, numberKey(7));
    await tester.pump();
    expect(find.text(erased), findsNothing);

    // 메모를 끈 채로 칸을 선택해 숫자를 눌러도 후보가 적히지 않는다
    // (자동으로 메모가 켜지지도 않는다).
    await tapMemoButton(tester);
    await tester.pump();
    await tapCell(tester, 4, 4);
    await tapV(tester, numberKey(7));
    await tester.pump();
    expect(find.text(erased), findsNothing);
  });

  testWidgets('adding then erasing a note advances to the hint step',
      (tester) async {
    await pumpTutorial(tester);
    await goToMemoStep(tester);
    await tapMemoButton(tester);
    await tester.pump();
    await tapCell(tester, 4, 4);

    await tapV(tester, numberKey(7));
    await tester.pump();
    expect(find.text('Tap the same number again to erase a note.'),
        findsOneWidget);

    await tapV(tester, numberKey(7));
    await tester.pump();
    expect(find.text('Use a hint'), findsOneWidget);
    expect(find.text('4 / 5'), findsOneWidget);
  });

  Future<void> goToHintStep(WidgetTester tester) async {
    await goToMemoStep(tester);
    await tapMemoButton(tester);
    await tester.pump();
    await tapCell(tester, 4, 4);
    await tapV(tester, numberKey(7));
    await tester.pump();
    await tapV(tester, numberKey(7));
    await tester.pump();
  }

  Finder hintButton() => find.byIcon(Icons.lightbulb_outline);

  testWidgets('opening and filling the hint completes the guide',
      (tester) async {
    await pumpTutorial(tester);
    await goToHintStep(tester);
    expect(find.text('Use a hint'), findsOneWidget);

    await tapV(tester, hintButton());
    await tester.pump();
    expect(find.byType(SudokuHintPanel), findsOneWidget);

    await tapV(tester, find.widgetWithText(TextButton, 'Fill in answer'));
    await tester.pump();
    expect(find.text("You're ready!"), findsOneWidget);
    expect(find.text('Start my first puzzle'), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget);
  });

  testWidgets('controls are enabled only for the current step', (tester) async {
    await pumpTutorial(tester);
    bool enabled(Finder f) =>
        tester
            .widget<ProgressiveBlurButton>(find.ancestor(
                of: f, matching: find.byType(ProgressiveBlurButton)))
            .onPressed !=
        null;
    // 규칙 단계: 숫자·메모·힌트 모두 비활성.
    expect(
        tester.widget<ProgressiveBlurButton>(numberKey(1)).onPressed, isNull);
    expect(enabled(find.byIcon(Icons.edit_note)), isFalse);
    expect(enabled(find.byIcon(Icons.lightbulb_outline)), isFalse);

    await goToInputStep(tester);
    expect(tester.widget<ProgressiveBlurButton>(numberKey(1)).onPressed,
        isNotNull);
    expect(enabled(find.byIcon(Icons.edit_note)), isFalse);

    await tapCell(tester, 0, 0);
    await tapV(tester, numberKey(5));
    await tester.pump();
    expect(enabled(find.byIcon(Icons.edit_note)), isTrue);
    expect(enabled(find.byIcon(Icons.lightbulb_outline)), isFalse);
    // 되돌리기·지우기는 연습에서 쓰지 않는다.
    expect(enabled(find.byIcon(Icons.undo_rounded)), isFalse);
    expect(enabled(find.byIcon(Icons.backspace_outlined)), isFalse);
  });

  for (final size in const [Size(390, 844), Size(393, 852), Size(430, 932)]) {
    testWidgets('fits on one screen without scrolling: $size', (tester) async {
      await pumpTutorial(tester, size: size);
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(Scaffold),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.maxScrollExtent, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('small screens scroll to every control without overflow',
      (tester) async {
    await pumpTutorial(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
    await goToInputStep(tester);
    for (final finder in [
      numberKey(9),
      find.byIcon(Icons.edit_note),
      find.byIcon(Icons.lightbulb_outline),
      find.byIcon(Icons.backspace_outlined),
    ]) {
      await tester.ensureVisible(finder);
      await tester.pump();
      expect(finder, findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduce motion swaps the guide card instantly', (tester) async {
    await pumpTutorial(tester, reduceMotion: true);
    await tapV(tester, find.text('Next'));
    await tester.pump();
    expect(find.text('Enter a number'), findsOneWidget);
    expect(find.text('Basic rules'), findsNothing);
  });

  testWidgets('practice never touches records or saved games', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpTutorial(tester, resetPrefs: false);
    await goToHintStep(tester);
    await tapV(tester, hintButton());
    await tester.pump();
    await tapV(tester, find.widgetWithText(TextButton, 'Fill in answer'));
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getKeys().where((k) => k.startsWith('game_')),
      isEmpty,
    );
  });

  testWidgets('completing the guide marks it completed and pops',
      (tester) async {
    final service = BeginnerTutorialService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      BeginnerTutorialScreen(tutorialService: service),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    SharedPreferences.setMockInitialValues({});
    await tapV(tester, find.text('open'));
    await tester.pumpAndSettle();
    await goToHintStep(tester);
    await tapV(tester, hintButton());
    await tester.pump();
    await tapV(tester, find.widgetWithText(TextButton, 'Fill in answer'));
    await tester.pump();
    await tapV(tester, find.text('Start my first puzzle'));
    await tester.pumpAndSettle();

    expect(find.byType(BeginnerTutorialScreen), findsNothing);
    expect(await service.getState(), BeginnerTutorialState.completed);
  });

  testWidgets('closing early marks it dismissed and pops', (tester) async {
    final service = BeginnerTutorialService();
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      BeginnerTutorialScreen(tutorialService: service),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tapV(tester, find.text('open'));
    await tester.pumpAndSettle();
    await tapV(tester, find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(BeginnerTutorialScreen), findsNothing);
    expect(await service.getState(), BeginnerTutorialState.dismissed);
  });

  testWidgets('replay mode shows Done instead of the first-puzzle button',
      (tester) async {
    await pumpTutorial(tester, isReplay: true);
    await goToHintStep(tester);
    await tapV(tester, hintButton());
    await tester.pump();
    await tapV(tester, find.widgetWithText(TextButton, 'Fill in answer'));
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Start my first puzzle'), findsNothing);
  });

  testWidgets('small screen with large text has no overflow', (tester) async {
    await pumpTutorial(
      tester,
      size: const Size(320, 568),
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
    await goToInputStep(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet landscape renders without errors', (tester) async {
    await pumpTutorial(tester, size: const Size(1024, 768));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduce motion does not error through the whole flow',
      (tester) async {
    await pumpTutorial(tester, reduceMotion: true);
    await goToHintStep(tester);
    await tapV(tester, hintButton());
    await tester.pump();
    await tapV(tester, find.widgetWithText(TextButton, 'Fill in answer'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing right after opening does not crash', (tester) async {
    await pumpTutorial(tester);
    await tapV(tester, find.byIcon(Icons.close));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  group('replay preserves existing tutorial state (settings "다시 보기")', () {
    testWidgets('completed + replay + close early -> stays completed',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = BeginnerTutorialService();
      await service.markCompleted();
      await pumpTutorial(
        tester,
        isReplay: true,
        tutorialService: service,
        resetPrefs: false,
      );
      await tapV(tester, find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(await service.getState(), BeginnerTutorialState.completed);
    });

    testWidgets('dismissed + replay + complete -> stays dismissed',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = BeginnerTutorialService();
      await service.markDismissed();
      await pumpTutorial(
        tester,
        isReplay: true,
        tutorialService: service,
        resetPrefs: false,
      );
      await goToHintStep(tester);
      await tapV(tester, hintButton());
      await tester.pump();
      await tapV(tester, find.widgetWithText(TextButton, 'Fill in answer'));
      await tester.pump();
      await tapV(tester, find.text('Done'));
      await tester.pumpAndSettle();
      expect(await service.getState(), BeginnerTutorialState.dismissed);
    });

    testWidgets('unseen + replay + close early -> stays unseen',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = BeginnerTutorialService();
      await pumpTutorial(
        tester,
        isReplay: true,
        tutorialService: service,
        resetPrefs: false,
      );
      await tapV(tester, find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(await service.getState(), BeginnerTutorialState.unseen);
    });

    testWidgets('first-run (not replay) completing sets completed',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = BeginnerTutorialService();
      await pumpTutorial(
        tester,
        isReplay: false,
        tutorialService: service,
        resetPrefs: false,
      );
      await goToHintStep(tester);
      await tapV(tester, hintButton());
      await tester.pump();
      await tapV(tester, find.widgetWithText(TextButton, 'Fill in answer'));
      await tester.pump();
      await tapV(tester, find.text('Start my first puzzle'));
      await tester.pumpAndSettle();
      expect(await service.getState(), BeginnerTutorialState.completed);
    });

    testWidgets('first-run (not replay) closing early sets dismissed',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = BeginnerTutorialService();
      await pumpTutorial(
        tester,
        isReplay: false,
        tutorialService: service,
        resetPrefs: false,
      );
      await tapV(tester, find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(await service.getState(), BeginnerTutorialState.dismissed);
    });
  });

  group('system back button', () {
    testWidgets('first-run system back marks dismissed', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = BeginnerTutorialService();
      await pumpTutorial(
        tester,
        tutorialService: service,
        resetPrefs: false,
      );
      await simulateSystemBack(tester);
      await tester.pumpAndSettle();
      expect(await service.getState(), BeginnerTutorialState.dismissed);
      expect(find.byType(BeginnerTutorialScreen), findsNothing);
    });

    testWidgets('replay system back leaves the existing state untouched',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = BeginnerTutorialService();
      await service.markCompleted();
      await pumpTutorial(
        tester,
        isReplay: true,
        tutorialService: service,
        resetPrefs: false,
      );
      await simulateSystemBack(tester);
      await tester.pumpAndSettle();
      expect(await service.getState(), BeginnerTutorialState.completed);
      expect(find.byType(BeginnerTutorialScreen), findsNothing);
    });

    testWidgets('pressing back twice quickly does not throw or double-pop',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = BeginnerTutorialService();
      await pumpTutorial(
        tester,
        tutorialService: service,
        resetPrefs: false,
      );
      await simulateSystemBack(tester);
      await simulateSystemBack(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(await service.getState(), BeginnerTutorialState.dismissed);
    });

    testWidgets('close button then an immediate system back does not throw',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = BeginnerTutorialService();
      await pumpTutorial(
        tester,
        tutorialService: service,
        resetPrefs: false,
      );
      await tapV(tester, find.byIcon(Icons.close));
      await simulateSystemBack(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(await service.getState(), BeginnerTutorialState.dismissed);
    });
  });
}
