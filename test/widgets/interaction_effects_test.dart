import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/widgets/game_complete_dialog.dart';
import 'package:sudoku159/widgets/press_scale.dart';

Widget _app(Widget child, {bool reduceMotion = false, double textScale = 1}) {
  return MaterialApp(
    theme: AppTheme.lightTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reduceMotion,
        textScaler: TextScaler.linear(textScale),
      ),
      child: c!,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

double _scaleOf(WidgetTester tester) =>
    tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

void main() {
  group('PressScale', () {
    Widget tile(ValueNotifier<bool> pressed, {bool reduce = false}) => _app(
          ValueListenableBuilder<bool>(
            valueListenable: pressed,
            builder: (_, p, __) => PressScale(
              pressed: p,
              child: const SizedBox(width: 120, height: 60),
            ),
          ),
          reduceMotion: reduce,
        );

    testWidgets('shrinks to 0.98 when pressed and restores to 1.0',
        (tester) async {
      final pressed = ValueNotifier(false);
      await tester.pumpWidget(tile(pressed));
      expect(_scaleOf(tester), 1.0);
      final size = tester.getSize(find.byType(SizedBox).last);

      pressed.value = true;
      await tester.pump();
      expect(_scaleOf(tester), 0.98);
      // 레이아웃 크기(터치 영역)는 그대로다.
      expect(tester.getSize(find.byType(SizedBox).last), size);

      pressed.value = false;
      await tester.pump();
      expect(_scaleOf(tester), 1.0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.getRect(find.byType(SizedBox).last).size,
        size,
      );
    });

    testWidgets('does not scale with reduce motion', (tester) async {
      final pressed = ValueNotifier(true);
      await tester.pumpWidget(tile(pressed, reduce: true));
      await tester.pump();
      expect(_scaleOf(tester), 1.0);
    });

    testWidgets('a cancelled touch restores the card', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(_PressProbe(onTap: () => taps++)));
      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(_PressProbe)));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump();
      expect(_scaleOf(tester), 0.98);
      // 스크롤처럼 손가락이 크게 벗어나면 탭이 취소된다.
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_scaleOf(tester), 1.0);
      expect(taps, 0);
    });
  });

  group('GameCompleteDialog celebration header', () {
    Widget dialog({VoidCallback? onNext, VoidCallback? onList}) =>
        GameCompleteDialog(
          levelLabel: 'Beginner · Game 18',
          timeInSeconds: 125,
          wrongCount: 1,
          onRestart: () {},
          onGoToLevelSelection: onList ?? () {},
          onNextPuzzle: onNext,
        );

    double opacity(WidgetTester tester) => tester
        .widget<FadeTransition>(find
            .descendant(
              of: find.byType(GameCompleteDialog),
              matching: find.byType(FadeTransition),
            )
            .first)
        .opacity
        .value;

    testWidgets('mascot fades and scales in once over ~280ms', (tester) async {
      await tester.pumpWidget(_app(dialog(onNext: () {})));
      expect(opacity(tester), lessThan(0.2));
      await tester.pump(const Duration(milliseconds: 140));
      final mid = opacity(tester);
      expect(mid, inInclusiveRange(0.3, 0.99));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(tester), 1.0);

      // 다시 그려져도(화면 크기·글씨 크기 변경) 처음부터 재생하지 않는다.
      await tester.pumpWidget(_app(dialog(onNext: () {}), textScale: 1.2));
      await tester.pump();
      expect(opacity(tester), 1.0);
    });

    testWidgets('buttons work from the first frame and layout does not move',
        (tester) async {
      var next = 0;
      await tester.pumpWidget(_app(dialog(onNext: () => next++)));
      final before = tester.getTopLeft(find.text('You solved the puzzle'));
      final nextBefore = tester.getTopLeft(find.text('Next puzzle'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getTopLeft(find.text('You solved the puzzle')), before);
      expect(tester.getTopLeft(find.text('Next puzzle')), nextBefore);
      // 기록 숫자는 처음부터 최종 값.
      expect(find.text('02:05'), findsOneWidget);
      await tester.tap(find.text('Next puzzle'));
      expect(next, 1);
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('reduce motion shows the final state immediately',
        (tester) async {
      await tester.pumpWidget(_app(dialog(onNext: () {}), reduceMotion: true));
      expect(opacity(tester), 1.0);
    });

    testWidgets('closing quickly leaves no errors', (tester) async {
      await tester.pumpWidget(_app(dialog(onNext: () {})));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('small screen, dark, large text: no overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.darkTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: c!,
          ),
          home: Scaffold(body: dialog(onNext: () {})),
        ));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: 'scale $scale');
      }
    });
  });
}

class _PressProbe extends StatefulWidget {
  const _PressProbe({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_PressProbe> createState() => _PressProbeState();
}

class _PressProbeState extends State<_PressProbe> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: PressScale(
        pressed: _pressed,
        child: const ColoredBox(
          color: Colors.grey,
          child: SizedBox(width: 160, height: 80),
        ),
      ),
    );
  }
}
