import 'package:flutter/material.dart';
import 'package:sudoku159/widgets/keep_words_text.dart';

/// 안내 문구를 문장 단위로 나눠 한 문장씩 새 줄에서 시작하게 보여 주는 가운데
/// 정렬 텍스트. 한 문장이 한 줄보다 길면 [KeepWordsText]처럼 단어 단위로만
/// 줄을 바꾼다(띄어쓰기가 없는 일본어·중국어 문장은 일반 텍스트로 자연 줄바꿈).
/// 번역 문구에 줄바꿈 문자를 넣지 않고도 모든 언어에서 문장이 중간에서 끊기지
/// 않게 하려는 용도다.
class SentenceText extends StatelessWidget {
  const SentenceText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  /// 문장 끝 기호(. ! ? 。 ！ ？)와 뒤따르는 공백까지를 한 문장으로 자른다.
  static List<String> splitSentences(String text) {
    final matches = RegExp(r'[^.!?。！？]+[.!?。！？]*').allMatches(text);
    return [
      for (final m in matches)
        if (m.group(0)!.trim().isNotEmpty) m.group(0)!.trim(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sentences = splitSentences(text);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final sentence in sentences)
            if (sentence.contains(RegExp(r'\s')))
              KeepWordsText(
                sentence,
                alignment: WrapAlignment.center,
                style: style,
              )
            else
              Text(sentence, textAlign: TextAlign.center, style: style),
        ],
      ),
    );
  }
}
