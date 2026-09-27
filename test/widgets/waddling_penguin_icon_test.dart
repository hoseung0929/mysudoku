import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/widgets/waddling_penguin_icon.dart';

Widget _app(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: c!,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

/// MaterialApp/Scaffold 자체도 자신의 Transform을 갖고 있으므로, 검증은
/// 항상 펭귄 위젯 하위로만 좁혀서 찾는다.
Finder _transforms() => find.descendant(
      of: find.byType(WaddlingPenguinIcon),
      matching: find.byType(Transform),
    );

/// [Transform.rotate]가 만든 회전 각도를 행렬에서 역산한다.
double _rotationAngleOf(Transform t) {
  final m = t.transform;
  return math.atan2(m.entry(1, 0), m.entry(0, 0));
}

/// [Transform.translate]가 만든 평행이동 오프셋.
Offset _translationOf(Transform t) {
  final v = t.transform.getTranslation();
  return Offset(v.x, v.y);
}

void main() {
  group('WaddlingPenguinIcon', () {
    testWidgets('active=true -> reduce motion ON shows a static neutral pose',
        (tester) async {
      await tester.pumpWidget(_app(const WaddlingPenguinIcon(active: true)));
      // 애니메이션이 정자세가 아닌 지점까지 진행되게 한다.
      await tester.pump(const Duration(milliseconds: 250));
      expect(_transforms(), findsWidgets);

      await tester.pumpWidget(
        _app(const WaddlingPenguinIcon(active: true), reduceMotion: true),
      );
      await tester.pump();

      // 정지 이미지로 바뀌어 더 이상 회전·이동 변환이 없다.
      expect(_transforms(), findsNothing);
      expect(
        find.descendant(
          of: find.byType(WaddlingPenguinIcon),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );

      // ticker가 백그라운드에서 계속 돌지 않는지 확인: 더 진행해도 여전히
      // 정지 이미지 그대로다.
      await tester.pump(const Duration(seconds: 1));
      expect(_transforms(), findsNothing);
    });

    testWidgets(
        'reduce motion ON with active flipped to false -> OFF keeps the '
        'neutral pose', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(WaddlingPenguinIcon(key: key, active: true), reduceMotion: true),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 동작 줄이기 상태에서 active를 false로 바꾼다.
      await tester.pumpWidget(
        _app(WaddlingPenguinIcon(key: key, active: false), reduceMotion: true),
      );
      await tester.pump();

      // 동작 줄이기를 해제한다.
      await tester.pumpWidget(
        _app(WaddlingPenguinIcon(key: key, active: false), reduceMotion: false),
      );
      await tester.pump();

      final rotate = tester.widgetList<Transform>(_transforms()).toList();
      expect(rotate, hasLength(2));
      // 이전 위치에서 기울거나 뜬 채로 멈춰 있지 않고 정자세(0)여야 한다.
      expect(_rotationAngleOf(rotate[1]), closeTo(0, 0.001));
      expect(_translationOf(rotate[0]), Offset.zero);

      // 계속 정지 상태를 유지한다(반복 ticker가 다시 돌지 않음).
      await tester.pump(const Duration(seconds: 1));
      final rotateAfter = tester.widgetList<Transform>(_transforms()).toList();
      expect(_rotationAngleOf(rotateAfter[1]), closeTo(0, 0.001));
      expect(_translationOf(rotateAfter[0]), Offset.zero);
    });

    testWidgets(
        'reduce motion ON with active flipped to true -> OFF resumes moving',
        (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _app(WaddlingPenguinIcon(key: key, active: false), reduceMotion: true),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 동작 줄이기 상태에서 active를 true로 바꾼다 — 아직은 움직이지 않는다.
      await tester.pumpWidget(
        _app(WaddlingPenguinIcon(key: key, active: true), reduceMotion: true),
      );
      await tester.pump();
      expect(_transforms(), findsNothing);

      // 동작 줄이기를 해제하면 그제서야 움직임이 재개된다.
      await tester.pumpWidget(
        _app(WaddlingPenguinIcon(key: key, active: true), reduceMotion: false),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final rotate = tester.widgetList<Transform>(_transforms()).toList();
      expect(rotate, hasLength(2));
      expect(_rotationAngleOf(rotate[1]).abs(), greaterThan(0.001));
    });

    testWidgets('active=false never starts a repeating ticker', (tester) async {
      await tester.pumpWidget(_app(const WaddlingPenguinIcon(active: false)));
      await tester.pump(const Duration(seconds: 2));

      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      final rotate = tester.widgetList<Transform>(_transforms()).toList();
      expect(rotate, hasLength(2));
      expect(_rotationAngleOf(rotate[1]), closeTo(0, 0.001));
      expect(_translationOf(rotate[0]), Offset.zero);
    });

    testWidgets('removing the widget mid-animation throws nothing',
        (tester) async {
      await tester.pumpWidget(_app(const WaddlingPenguinIcon(active: true)));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
