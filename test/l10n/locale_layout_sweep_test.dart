import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/onboarding/beginner_tutorial_screen.dart';
import 'package:sudoku159/widgets/game_complete_dialog.dart';
import 'package:sudoku159/widgets/game_over_dialog.dart';

/// 지원 언어 전부에서 좁은 화면(360pt, 아이폰 미니급)과 큰 글씨로 주요 대화상자·
/// 연습 화면을 그려, 문구가 길어져 생기는 오버플로가 없는지 확인한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

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
              hintsUsed: 3,
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
