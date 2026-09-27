// 힌트 패널 인터랙션(등장·단계 전환) 전용 모션 테스트.
// 기능 자체(정답 계산, 저장 등)는 sudoku_game_hint_panel_test.dart가 다룬다.
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
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: SudokuGameScreen(game: game, level: level),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    return tester
        .widget<SudokuBoardGrid>(find.byType(SudokuBoardGrid))
        .presenter;
  }

  Finder hintButtonFinder() => find.ancestor(
        of: find.byIcon(Icons.lightbulb_outline),
        matching: find.byType(ProgressiveBlurButton),
      );

  Finder numberButtonFinder(String digit) =>
      find.widgetWithText(ProgressiveBlurButton, digit);

  const sizes = {
    'phone': Size(390, 844),
    'tablet landscape': Size(1024, 768),
  };

  for (final entry in sizes.entries) {
    group(entry.key, () {
      testWidgets(
          'the panel occupies exactly the keypad area and does not move it',
          (tester) async {
        await pumpGame(tester, entry.value);
        final numberButton = find.widgetWithText(ProgressiveBlurButton, '5');
        final boardBefore = tester.getRect(find.byType(SudokuBoardGrid));
        final keypadBefore = tester.getRect(numberButton.first);

        await tester.tap(hintButtonFinder());
        await tester.pump(); // 등장 애니메이션 시작(진행 중)

        // 보드·숫자패드 버튼의 실제 레이아웃 위치는 패널 등장으로 안 움직인다.
        expect(tester.getRect(find.byType(SudokuBoardGrid)), boardBefore);
        expect(tester.getRect(numberButton.first), keypadBefore);

        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.getRect(find.byType(SudokuBoardGrid)), boardBefore);
      });

      testWidgets('the panel box position is unchanged across step 1 → 2',
          (tester) async {
        await pumpGame(tester, entry.value);
        await tester.tap(hintButtonFinder());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        final panelBefore =
            tester.getRect(find.byType(ProgressiveBlurButton).first).size;
        final outerBefore = tester.getRect(find.byType(SudokuBoardGrid));

        await tester.tap(find.text('Tell me more'));
        await tester.pump(); // 1↔2단계 전환 중(중간 프레임)
        expect(tester.getRect(find.byType(SudokuBoardGrid)), outerBefore);

        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.getRect(find.byType(SudokuBoardGrid)), outerBefore);
        // 숫자패드 버튼 자체 크기도(=패널이 덮는 영역 크기) 변하지 않는다.
        expect(
          tester.getRect(find.byType(ProgressiveBlurButton).first).size,
          panelBefore,
        );
      });

      testWidgets(
          'taps during the entrance transition do not reach the keypad '
          'underneath', (tester) async {
        final presenter = await pumpGame(tester, entry.value);
        expect(presenter.isMemoMode, isFalse);

        await tester.tap(hintButtonFinder());
        await tester.pump(); // 애니메이션 시작, 아직 완료 전(140~160ms 남음)
        // 숫자패드 "8" 자리를 탭한다. 패널 버튼 중 어느 것도 눌리지
        // 않았는지(닫히거나 2단계로 넘어가지 않았는지)로, 뒤 숫자패드로도
        // 패널 자체로도 의도치 않은 히트가 없었음을 함께 확인한다.
        await tester.tap(numberButtonFinder('8'), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 40));
        expect(find.text('Hint · Where to look'), findsOneWidget);
        expect(presenter.getCellValue(0, 1), 0);
        expect(presenter.isMemoMode, isFalse);

        await tester.pump(const Duration(milliseconds: 200));
      });

      testWidgets(
          'reduce motion shows the panel and each step instantly, without '
          'sliding', (tester) async {
        await pumpGame(tester, entry.value, reduceMotion: true);
        await tester.tap(hintButtonFinder());
        await tester.pump(); // 지속 시간이 0이라 다음 프레임에 바로 완료
        expect(find.text('Hint · Where to look'), findsOneWidget);
        for (final switcher in tester.widgetList<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        )) {
          expect(switcher.duration, Duration.zero, reason: 'entrance');
        }

        await tester.tap(find.text('Tell me more'));
        await tester.pump();
        expect(find.text('Hidden single'), findsOneWidget);
        for (final switcher in tester.widgetList<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        )) {
          expect(switcher.duration, Duration.zero, reason: 'step change');
        }
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets(
      'filling the answer applies to the board before any animation '
      'finishes', (tester) async {
    final presenter = await pumpGame(tester, const Size(390, 844));
    await tester.tap(hintButtonFinder());
    await tester.pump(const Duration(milliseconds: 200));
    expect(presenter.getCellValue(0, 1), 0);

    await tester.tap(find.widgetWithText(TextButton, 'Fill in answer'));
    // 애니메이션(닫기 120ms)이 끝나기 전, 바로 다음 프레임에서 이미 반영됨.
    await tester.pump();
    expect(presenter.getCellValue(0, 1), 3);
    expect(presenter.isHintCell(0, 1), isTrue);

    // (0,1)을 채우면 세로줄도 함께 완성되어 예약된 줄 완성 타이머(490ms)가
    // 남는다. 테스트가 끝나기 전에 마저 흘려보낸다.
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('closing the panel right away does not crash after dispose',
      (tester) async {
    await pumpGame(tester, const Size(390, 844));
    await tester.tap(hintButtonFinder());
    await tester.pump();
    await tester.tap(find.byTooltip('Close hint'));
    // 닫기 애니메이션(120ms)이 끝나기 전에 화면 자체를 치운다.
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
