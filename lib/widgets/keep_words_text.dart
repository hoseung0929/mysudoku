import 'package:flutter/material.dart';

/// 공백으로 나뉜 단어를 줄 중간에서 끊지 않고 단어 단위로만 줄바꿈하는 짧은 문구용
/// 텍스트. 한글은 기본 줄바꿈이 글자 사이에서도 일어나 "나의 기/록"처럼 마지막
/// 한 글자만 다음 줄로 넘어가므로, 좁은 폭의 큰 제목에 쓴다. 말줄임과 줄 수 제한은
/// 없으니 두어 줄 안에 들어오는 짧은 문구에만 쓴다.
class KeepWordsText extends StatelessWidget {
  const KeepWordsText(
    this.text, {
    super.key,
    required this.style,
    this.alignment = WrapAlignment.start,
  });

  final String text;
  final TextStyle style;

  /// 줄 안의 가로 정렬(가운데 정렬 문구는 [WrapAlignment.center]).
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final fontSize = style.fontSize ?? 14;
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Wrap(
        alignment: alignment,
        runAlignment: alignment,
        spacing: fontSize * 0.28,
        children: [for (final word in words) Text(word, style: style)],
      ),
    );
  }
}
