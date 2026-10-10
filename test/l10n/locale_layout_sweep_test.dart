import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/model/sudoku_game.dart';
import 'package:sudoku159/model/sudoku_level.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/onboarding/beginner_tutorial_screen.dart';
import 'package:sudoku159/view/sudoku_game/sudoku_game_screen.dart';
import 'package:sudoku159/widgets/game_complete_dialog.dart';
import 'package:sudoku159/widgets/game_over_dialog.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// 지원 언어 전부에서 좁은 화면(360pt, 아이폰 미니급)과 큰 글씨로 주요 대화상자·
/// 연습 화면을 그려, 문구가 길어져 생기는 오버플로가 없는지 확인한다.
class _NoopWakelock extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {}

  @override
  Future<bool> get enabled async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);
  wakelockPlusPlatformInstance = _NoopWakelock();

  const locales = ['en', 'ko', 'ja', 'es', 'zh'];
  const scales = [1.0, 1.3];

  Future<void> pump(
    WidgetTester tester,
    String code,
    double scale,
    Widget Function(AppLocalizations l10n) build, {
    Size size = const Size(360, 640),
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        locale: Locale(code),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => build(AppLocalizations.of(context)!),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  for (final code in locales) {
    for (final scale in scales) {
      final tag = '$code x$scale';

      testWidgets('complete dialog: $tag', (tester) async {
        await pump(
          tester,
          code,
          scale,
          (l10n) => Scaffold(
            body: GameCompleteDialog(
              levelLabel: l10n.levelPuzzleNumber(159),
              timeInSeconds: 3725,
              wrongCount: 2,
              isNewBestRecord: true,
              challengeMessage: l10n.challengeCompletedToday,
              weeklyGoalMessage: l10n.gameResultWeeklyGoalAchieved,
              onRestart: () {},
              onGoToLevelSelection: () {},
              onNextPuzzle: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('game over dialog: $tag', (tester) async {
        await pump(
          tester,
          code,
          scale,
          (l10n) => Scaffold(
            body: GameOverDialog(
              wrongCount: 5,
              maxWrongCount: 5,
              onRestart: () {},
              onGoToLevelSelection: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('restart menu and confirm dialog: $tag', (tester) async {
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
        final board = solution.map((r) => List<int>.from(r)).toList()
          ..[0][1] = 0
          ..[4][4] = 0;
        final level = SudokuLevel.levels.first;
        await pump(
          tester,
          code,
          scale,
          (l10n) => SudokuGameScreen(
            game: SudokuGame(
              board: board,
              solution: solution,
              emptyCells: level.emptyCells,
              levelName: level.name,
              gameNumber: 1,
            ),
            level: level,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.replay_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        expect(find.byType(FilledButton), findsWidgets);
      });

      testWidgets('practice puzzle: $tag', (tester) async {
        await pump(
          tester,
          code,
          scale,
          (l10n) => const BeginnerTutorialScreen(),
        );
        expect(tester.takeException(), isNull);
        // 안내 카드 안의 규칙 선택 버튼이 아래 숫자패드와 겹치지 않는다.
        final chip = tester.getRect(
          find.byKey(const ValueKey('tutorial-rule-box')),
        );
        final pad =
            tester.getRect(find.byKey(const ValueKey('tutorial-number-1')));
        expect(chip.bottom, lessThanOrEqualTo(pad.top));
      });
    }
  }
}
