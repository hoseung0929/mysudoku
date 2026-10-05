import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/widgets/keep_words_text.dart';

void main() {
  testWidgets('wraps between words and never splits a word', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 190,
              child: KeepWordsText(
                '차곡차곡 쌓이는 나의 기록',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
    // 단어마다 한 덩어리로 그려지고, 어떤 단어도 두 줄로 쪼개지지 않는다.
    for (final word in ['차곡차곡', '쌓이는', '나의', '기록']) {
      final box = tester.getRect(find.text(word));
      expect(box.height, lessThan(30), reason: word);
      expect(box.right, lessThanOrEqualTo(190));
    }
    // 마지막 단어 "기록"이 통째로 같은 줄에 있거나 통째로 다음 줄로 간다.
    expect(tester.getRect(find.text('기록')).width, greaterThan(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes the full text to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KeepWordsText('a b c', style: TextStyle(fontSize: 14)),
        ),
      ),
    );
    expect(find.bySemanticsLabel('a b c'), findsOneWidget);
    handle.dispose();
  });
}
