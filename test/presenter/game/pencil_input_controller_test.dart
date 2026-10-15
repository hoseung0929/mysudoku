import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/presenter/game/pencil_input_controller.dart';
import 'package:sudoku159/services/game/pencil_digit_recognizer.dart';

void main() {
  PencilInputController make(
    PencilDigitRecognizer recognizer,
    List<(int, int, int)> confirmed,
  ) =>
      PencilInputController(
        recognizer: recognizer,
        onConfirmed: (r, c, d) => confirmed.add((r, c, d)),
      );

  test('Scribble text: only a single 1-9 digit is a clear result', () async {
    const recognizer = ScribbleTextDigitRecognizer();
    expect((await recognizer.recognize('5')).digit, 5);
    expect((await recognizer.recognize(' 7 ')).digit, 7);
    for (final bad in ['0', 'a', '12', '', '１0']) {
      expect((await recognizer.recognize(bad)).isFailure, isTrue, reason: bad);
    }
  });

  testWidgets('clear result: waits for strokes, previews, then confirms once',
      (tester) async {
    {
      final confirmed = <(int, int, int)>[];
      final c = make(const ScribbleTextDigitRecognizer(), confirmed);
      c.submitText(2, 3, '4');
      expect(c.phase, PencilCellPhase.recognizing);
      await tester.pump(const Duration(milliseconds: 200));
      expect(confirmed, isEmpty); // 아직 추가 획을 기다리는 중
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(c.phase, PencilCellPhase.recognized);
      expect(c.previewDigit, 4);
      expect(confirmed, isEmpty);
      await tester.pump(const Duration(milliseconds: 160));
      expect(confirmed, [(2, 3, 4)]);
      expect(c.phase, PencilCellPhase.idle);
    }
  });

  testWidgets('an extra stroke restarts the wait and the latest text wins',
      (tester) async {
    {
      final confirmed = <(int, int, int)>[];
      final c = make(const ScribbleTextDigitRecognizer(), confirmed);
      c.submitText(0, 0, '1');
      await tester.pump(const Duration(milliseconds: 300));
      c.submitText(0, 0, '4'); // 4는 여러 획: 두 번째 획으로 바뀜
      await tester.pump(const Duration(milliseconds: 300));
      expect(confirmed, isEmpty);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(confirmed, [(0, 0, 4)]);
    }
  });

  testWidgets(
      'failure never confirms a digit (so it can never count as a mistake)',
      (tester) async {
    {
      final confirmed = <(int, int, int)>[];
      final c = make(const ScribbleTextDigitRecognizer(), confirmed);
      c.submitText(1, 1, '0');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(c.phase, PencilCellPhase.error);
      await tester.pump(const Duration(seconds: 2));
      expect(c.phase, PencilCellPhase.idle);
      expect(confirmed, isEmpty);
    }
  });

  testWidgets('ambiguous result waits for a choice and does not confirm',
      (tester) async {
    {
      final confirmed = <(int, int, int)>[];
      final c = make(
        FakePencilDigitRecognizer(
          const DigitRecognitionResult.ambiguous([1, 7, 9]),
        ),
        confirmed,
      );
      c.submitText(4, 4, '?');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(c.phase, PencilCellPhase.ambiguous);
      expect(c.candidates, [1, 7, 9]);
      await tester.pump(const Duration(seconds: 5));
      expect(confirmed, isEmpty); // 후보 선택 전에는 입력되지 않는다
      c.chooseCandidate(7);
      expect(confirmed, [(4, 4, 7)]);
      expect(c.phase, PencilCellPhase.idle);
    }
  });

  testWidgets('rewrite and cancel drop the pending result without confirming',
      (tester) async {
    {
      final confirmed = <(int, int, int)>[];
      final c = make(
        FakePencilDigitRecognizer(
          const DigitRecognitionResult.ambiguous([3, 8]),
        ),
        confirmed,
      );
      c.submitText(0, 1, '?');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      c.rewrite();
      expect(c.phase, PencilCellPhase.idle);
      expect(c.candidates, isEmpty);

      final clear = make(const ScribbleTextDigitRecognizer(), confirmed);
      clear.submitText(0, 1, '6');
      clear.cancel(); // 다른 셀 선택·필기 OFF 등
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(confirmed, isEmpty);
    }
  });
}
