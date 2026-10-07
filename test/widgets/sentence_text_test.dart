import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku159/widgets/sentence_text.dart';

void main() {
  test('splits into sentences for every supported language', () {
    expect(
      SentenceText.splitSentences(
          '기존 완료 기록은 그대로 유지돼요. 더 좋은 기록으로 완료하면 최고 기록만 업데이트돼요.'),
      ['기존 완료 기록은 그대로 유지돼요.', '더 좋은 기록으로 완료하면 최고 기록만 업데이트돼요.'],
    );
    expect(
      SentenceText.splitSentences('完了記録はそのまま残ります。ベスト記録が更新されます。'),
      ['完了記録はそのまま残ります。', 'ベスト記録が更新されます。'],
    );
    expect(SentenceText.splitSentences('No end mark'), ['No end mark']);
  });

  testWidgets('each sentence starts on its own line and nothing overflows',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 240,
            child: SentenceText('First one. Second one is a bit longer here.',
                style: TextStyle(fontSize: 14)),
          ),
        ),
      ),
    ));
    final first = tester.getTopLeft(find.text('First'));
    final second = tester.getTopLeft(find.text('Second'));
    expect(second.dy, greaterThan(first.dy));
    expect(tester.takeException(), isNull);
  });
}
