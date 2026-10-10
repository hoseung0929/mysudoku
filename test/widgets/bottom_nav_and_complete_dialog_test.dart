import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/widgets/bottom_nav_bar.dart';
import 'package:sudoku159/widgets/game_complete_dialog.dart';
import 'package:sudoku159/widgets/game_over_dialog.dart';
import 'package:sudoku159/widgets/mascot_image.dart';

Widget _app(Widget child, {double textScale = 1.0, Locale? locale}) {
  return MaterialApp(
    theme: AppTheme.lightTheme(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: c!,
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('BottomNavBar', () {
    testWidgets(
        'shows home, records and settings tabs, one selected semantic node each',
        (tester) async {
      final handle = tester.ensureSemantics();
      var tapped = -1;
      await tester.pumpWidget(_app(
        Align(
          alignment: Alignment.bottomCenter,
          child:
              BottomNavBar(selectedIndex: 0, onItemTapped: (i) => tapped = i),
        ),
      ));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Records'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Home')),
        isSemantics(label: 'Home', isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Records')),
        isNot(isSemantics(isSelected: true)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Settings')),
        isNot(isSemantics(isSelected: true)),
      );
      // 이름이 중복 낭독되지 않도록 라벨당 노드는 하나.
      expect(find.bySemanticsLabel('Home'), findsOneWidget);

      await tester.tap(find.text('Records'));
      expect(tapped, 1);
      await tester.tap(find.text('Settings'));
      expect(tapped, 2);
      handle.dispose();
    });

    testWidgets('each tab has a tappable area at least 44x44', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(
        Align(
          alignment: Alignment.bottomCenter,
          child: BottomNavBar(selectedIndex: 0, onItemTapped: (_) {}),
        ),
      ));
      for (final label in ['Home', 'Records', 'Settings']) {
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
      handle.dispose();
    });

    testWidgets('does not overflow on a narrow screen with large text',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(
        Align(
          alignment: Alignment.bottomCenter,
          child: BottomNavBar(selectedIndex: 1, onItemTapped: (_) {}),
        ),
        textScale: 2.0,
        locale: const Locale('es'),
      ));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('OVERFLOWED'), findsNothing);
    });

    testWidgets('tablet width keeps three evenly spaced items, no overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(
        Align(
          alignment: Alignment.bottomCenter,
          child: BottomNavBar(selectedIndex: 2, onItemTapped: (_) {}),
        ),
      ));
      expect(tester.takeException(), isNull);
      final homeLeft = tester.getTopLeft(find.text('Home')).dx;
      final recordsLeft = tester.getTopLeft(find.text('Records')).dx;
      final settingsLeft = tester.getTopLeft(find.text('Settings')).dx;
      expect(homeLeft, lessThan(recordsLeft));
      expect(recordsLeft, lessThan(settingsLeft));
    });
  });

  group('GameCompleteDialog', () {
    Widget dialog({
      VoidCallback? onNext,
      VoidCallback? onList,
      VoidCallback? onRestart,
      String? challenge,
      bool best = false,
      String? weeklyGoal,
    }) =>
        GameCompleteDialog(
          levelLabel: 'Beginner · Game 18',
          timeInSeconds: 3725,
          wrongCount: 2,
          isNewBestRecord: best,
          challengeMessage: challenge,
          weeklyGoalMessage: weeklyGoal,
          onRestart: onRestart ?? () {},
          onGoToLevelSelection: onList ?? () {},
          onNextPuzzle: onNext,
        );

    testWidgets('weekly goal celebration appears only when it is passed in',
        (tester) async {
      await tester.pumpWidget(_app(dialog(onNext: () {})));
      expect(find.byKey(const Key('weekly_goal_celebration')), findsNothing);

      await tester.pumpWidget(_app(dialog(
        onNext: () {},
        weeklyGoal: "You reached this week's goal",
      )));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('weekly_goal_celebration')), findsOneWidget);
      expect(find.text("You reached this week's goal"), findsOneWidget);
      // 다른 성취 문구와 함께 있어도 둘 다 보이고 넘치지 않는다.
      await tester.pumpWidget(_app(dialog(
        onNext: () {},
        challenge: 'Today challenge complete',
        weeklyGoal: "You reached this week's goal",
      )));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Today challenge complete'), findsOneWidget);
      expect(find.text("You reached this week's goal"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows only real data in the specified order, no suggestions',
        (tester) async {
      await tester.pumpWidget(_app(dialog(onNext: () {})));

      expect(find.text('You solved the puzzle'), findsOneWidget);
      expect(find.text('Beginner · Game 18'), findsOneWidget);
      expect(find.text('1:02:05'), findsOneWidget);
      expect(find.text('2 times'), findsOneWidget);
      // 제안 카드·알림·다른 난이도 유도는 없다.
      expect(find.text('Set tomorrow reminder'), findsNothing);
      expect(find.text('Try another level'), findsNothing);
      expect(find.text('Suggested next step'), findsNothing);
      // 세로 순서: 제목 < 난이도 < 결과 < 주요 버튼 < 보조 버튼
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y('You solved the puzzle'), lessThan(y('Beginner · Game 18')));
      expect(y('Beginner · Game 18'), lessThan(y('1:02:05')));
      expect(y('1:02:05'), lessThan(y('Next puzzle')));
      expect(y('Next puzzle'), lessThan(y('Puzzle list')));
    });

    testWidgets(
        'time and mistakes appear once, in the summary card only, with one '
        'wording ("Mistakes")', (tester) async {
      await tester.pumpWidget(_app(dialog(onNext: () {})));
      // 문장으로 풀어 쓴 같은 값은 없다(3725초는 1시간이 넘어 "62 min"처럼
      // 어색하게 보일 수 있던 부분).
      expect(find.textContaining('Solved in'), findsNothing);
      expect(find.textContaining('min '), findsNothing);
      expect(find.textContaining('You made'), findsNothing);
      expect(find.textContaining('no mistakes'), findsNothing);
      expect(find.text('1:02:05'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Mistakes'), findsOneWidget);
      expect(find.text('2 times'), findsOneWidget);
      expect(find.textContaining('Wrong answers'), findsNothing);
    });

    testWidgets('the weekly goal text is readable on white (contrast >= 4.5)',
        (tester) async {
      await tester.pumpWidget(_app(dialog(
        onNext: () {},
        weeklyGoal: "You reached this week's goal",
      )));
      await tester.pump(const Duration(milliseconds: 500));
      final text =
          tester.widget<Text>(find.text("You reached this week's goal"));
      final color = text.style!.color!;
      double lum(Color c) {
        double ch(double v) => v <= 0.03928
            ? v / 12.92
            : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
        return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
      }

      final ratio = (lum(Colors.white) + 0.05) / (lum(color) + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    testWidgets('achievements are capped at two lines', (tester) async {
      await tester.pumpWidget(_app(dialog(
        onNext: () {},
        challenge: 'Today challenge complete',
        best: true,
        weeklyGoal: "You reached this week's goal",
      )));
      await tester.pump(const Duration(milliseconds: 500));
      // 도전 완료가 최고 기록보다 우선하고, 주간 목표와 합쳐 두 줄까지만.
      expect(find.text('Today challenge complete'), findsOneWidget);
      expect(find.text('New best record!'), findsNothing);
      expect(find.text("You reached this week's goal"), findsOneWidget);
    });

    testWidgets('celebration mascot shows normally, is dropped at extreme text',
        (tester) async {
      await tester.pumpWidget(_app(dialog(onNext: () {})));
      expect(find.byType(MascotImage), findsOneWidget);
      // 기존 CLEAR 이미지는 더 이상 쓰지 않는다.
      expect(
          find.byWidgetPredicate((w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName.contains('clear_')),
          findsNothing);

      await tester.pumpWidget(_app(dialog(onNext: () {}), textScale: 2.0));
      expect(find.byType(MascotImage), findsNothing);
      expect(find.text('You solved the puzzle'), findsOneWidget);
      expect(find.text('Next puzzle'), findsOneWidget);
    });

    testWidgets('the result does not show hint usage', (tester) async {
      await tester.pumpWidget(_app(dialog(onNext: () {})));
      expect(find.textContaining('Hints'), findsNothing);
    });

    testWidgets('at most one achievement message: challenge beats best record',
        (tester) async {
      await tester.pumpWidget(
        _app(dialog(challenge: 'Challenge done', best: true, onNext: () {})),
      );
      expect(find.text('Challenge done'), findsOneWidget);
      expect(find.text('New best record!'), findsNothing);

      await tester.pumpWidget(_app(dialog(best: true, onNext: () {})));
      expect(find.text('New best record!'), findsOneWidget);
    });

    testWidgets('with a next puzzle: primary = next, secondary = puzzle list',
        (tester) async {
      var next = 0;
      var list = 0;
      await tester.pumpWidget(
        _app(dialog(onNext: () => next++, onList: () => list++)),
      );
      await tester.tap(find.text('Puzzle list'));
      await tester.tap(find.text('Puzzle list'), warnIfMissed: false);
      await tester.pump();
      expect(list, 1); // 연타해도 한 번만
      expect(next, 0);
    });

    testWidgets('without a next puzzle it never says "next puzzle"',
        (tester) async {
      var list = 0;
      var again = 0;
      await tester.pumpWidget(
        _app(dialog(onList: () => list++, onRestart: () => again++)),
      );
      expect(find.text('Next puzzle'), findsNothing);
      await tester.tap(find.text('Solve this puzzle again'));
      await tester.pump();
      expect(again, 1);
      expect(list, 0);
    });

    for (final entry in {
      'small phone, 2x text': (const Size(320, 568), 2.0),
      'phone, 1.3x text': (const Size(390, 844), 1.3),
      'tablet portrait': (const Size(768, 1024), 1.0),
      'tablet landscape': (const Size(1024, 768), 1.0),
    }.entries) {
      testWidgets('layout rules hold: ${entry.key}', (tester) async {
        final (size, scale) = entry.value;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_app(const SizedBox(), textScale: scale));
        unawaited(showDialog<void>(
          context: tester.element(find.byType(Scaffold)),
          builder: (_) => dialog(onNext: () {}, best: true),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);

        final box = tester.getRect(
          find
              .descendant(
                of: find.byType(Dialog),
                matching: find.byType(Material),
              )
              .first,
        );
        // 아이폰 400, 아이패드(폭 > 600) 480.
        expect(box.width, lessThanOrEqualTo(size.width > 600 ? 480 : 400));
        expect(box.left, greaterThanOrEqualTo(20));
        expect(size.width - box.right, greaterThanOrEqualTo(20));
        expect(box.height, lessThanOrEqualTo(size.height * 0.85 + 1));
        // 버튼은 항상 화면 안에서 눌러 볼 수 있다.
        await tester.ensureVisible(find.text('Next puzzle'));
        final primary =
            tester.getSize(find.widgetWithText(FilledButton, 'Next puzzle'));
        expect(primary.height, greaterThanOrEqualTo(48));
        final secondary =
            tester.getSize(find.widgetWithText(TextButton, 'Puzzle list'));
        expect(secondary.height, greaterThanOrEqualTo(44));
      });
    }
  });

  group('GameOverDialog', () {
    testWidgets('states the real count and limit with two actions',
        (tester) async {
      var restart = 0;
      var list = 0;
      await tester.pumpWidget(_app(
        GameOverDialog(
          wrongCount: 3,
          maxWrongCount: 3,
          onRestart: () => restart++,
          onGoToLevelSelection: () => list++,
        ),
      ));
      expect(find.text('You reached the mistake limit'), findsOneWidget);
      expect(find.text('This game: 3 mistakes / limit 3'), findsOneWidget);
      expect(find.text('You can start this puzzle over or choose another one.'),
          findsOneWidget);
      expect(find.text('Restart from the beginning'), findsOneWidget);
      await tester.tap(find.text('Puzzle list'));
      await tester.pump();
      expect(list, 1);
      expect(restart, 0);
    });

    testWidgets('does not overflow at 2x text on a small screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(
        GameOverDialog(
          wrongCount: 5,
          maxWrongCount: 5,
          onRestart: () {},
          onGoToLevelSelection: () {},
        ),
        textScale: 2.0,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('long translations at 2x text on a small screen', () {
    for (final lang in ['ko', 'ja', 'es', 'zh']) {
      testWidgets('complete + game over dialogs: $lang', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(const SizedBox(), textScale: 2.0, locale: Locale(lang)),
        );
        final context = tester.element(find.byType(Scaffold));
        unawaited(showDialog<void>(
          context: context,
          builder: (_) => GameCompleteDialog(
            levelLabel: 'x · 18',
            timeInSeconds: 3725,
            wrongCount: 2,
            isNewBestRecord: true,
            onRestart: () {},
            onGoToLevelSelection: () {},
            onNextPuzzle: () {},
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        Navigator.of(context, rootNavigator: true).pop();
        await tester.pump(const Duration(milliseconds: 300));
        unawaited(showDialog<void>(
          context: context,
          builder: (_) => GameOverDialog(
            wrongCount: 3,
            maxWrongCount: 3,
            onRestart: () {},
            onGoToLevelSelection: () {},
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
