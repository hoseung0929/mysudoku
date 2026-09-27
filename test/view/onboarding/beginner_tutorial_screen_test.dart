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

  testWidgets('rule steps advance with Next and highlight a region each time',
      (tester) async {
    await pumpTutorial(tester);
    expect(find.text('Rule: rows'), findsOneWidget);
    var grid = tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid));
    expect(grid.hintRegionCells, isNotEmpty);
    final rowRegion = grid.hintRegionCells;

    await tapV(tester, find.text('Next'));
    await tester.pump();
    expect(find.text('Rule: columns'), findsOneWidget);
    grid = tester.widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid));
    expect(grid.hintRegionCells, isNot(rowRegion));

    await tapV(tester, find.text('Next'));
    await tester.pump();
    expect(find.text('Rule: 3×3 boxes'), findsOneWidget);

    await tapV(tester, find.text('Next'));
    await tester.pump();
    expect(find.text('Enter a number'), findsOneWidget);
  });

  Future<void> goToInputStep(WidgetTester tester) async {
    await tapV(tester, find.text('Next'));
    await tester.pump();
    await tapV(tester, find.text('Next'));
    await tester.pump();
    await tapV(tester, find.text('Next'));
    await tester.pump();
  }

  testWidgets('wrong digit shows an explanation, correct digit advances',
      (tester) async {
    await pumpTutorial(tester);
    await goToInputStep(tester);
    expect(find.text('Enter a number'), findsOneWidget);

    // (0,0)의 정답은 5. 다른 숫자를 넣으면 왜 안 되는지 안내만 하고 실수로
    // 세지 않는다(연습 세션은 실수 제한 자체가 사실상 무제한).
    await tapV(tester, find.widgetWithText(OutlinedButton, '3'));
    await tester.pump();
    expect(
      find.text(
        'That number is already used in this row, column, or box. Try another number.',
      ),
      findsOneWidget,
    );

    await tapV(tester, find.widgetWithText(OutlinedButton, '5'));
    await tester.pump();
    expect(find.text('Notes and erasing'), findsOneWidget);
  });

  testWidgets('adding then erasing a note advances to the hint step',
      (tester) async {
    await pumpTutorial(tester);
    await goToInputStep(tester);
    await tapV(tester, find.widgetWithText(OutlinedButton, '5'));
    await tester.pump();
    expect(find.text('Notes and erasing'), findsOneWidget);

    await tapV(tester, find.widgetWithText(OutlinedButton, '7'));
    await tester.pump();
    expect(find.text('Now tap that same number again to erase the note.'),
        findsOneWidget);

    await tapV(tester, find.widgetWithText(OutlinedButton, '7'));
    await tester.pump();
    expect(find.text('Hints'), findsOneWidget);
  });

  Future<void> goToHintStep(WidgetTester tester) async {
    await goToInputStep(tester);
    await tapV(tester, find.widgetWithText(OutlinedButton, '5'));
    await tester.pump();
    await tapV(tester, find.widgetWithText(OutlinedButton, '7'));
    await tester.pump();
    await tapV(tester, find.widgetWithText(OutlinedButton, '7'));
    await tester.pump();
  }

  testWidgets('opening and filling the hint completes the guide',
      (tester) async {
    await pumpTutorial(tester);
    await goToHintStep(tester);
    expect(find.text('Hints'), findsOneWidget);

    await tapV(tester, find.text('Open hint'));
    await tester.pump();
    expect(find.byType(SudokuHintPanel), findsOneWidget);

    await tapV(tester, find.widgetWithText(TextButton, 'Fill in answer'));
    await tester.pump();
    expect(find.text("You're ready!"), findsOneWidget);
    expect(find.text('Start my first puzzle'), findsOneWidget);
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
    await tapV(tester, find.text('Open hint'));
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
    await tapV(tester, find.text('Open hint'));
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
    await tapV(tester, find.text('Open hint'));
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
      await tapV(tester, find.text('Open hint'));
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
      await tapV(tester, find.text('Open hint'));
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
