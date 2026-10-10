import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 완료한 퍼즐 칸에 붙이는 결과 스티커: 완료는 `CLEAR`, 힌트·실수 없이 푼 퍼즐은
/// `PERFECT!`. 앱의 `\ CLEAR! /` 글자 그림과 같은 계열로, 언어와 관계없이 같은
/// 영어 단어 이미지를 쓴다(화면 읽기는 각 화면에서 번역된 문장으로 따로 알려 준다).
/// 라이트·다크 모드용 이미지가 따로 있다.
class PuzzleResultSticker extends StatelessWidget {
  const PuzzleResultSticker({
    super.key,
    required this.perfect,
    this.width = 54,
    this.tiltDegrees = -2,
  });

  /// true면 PERFECT!, false면 CLEAR.
  final bool perfect;

  /// 스티커 상자의 가로 길이. 이미지마다 비율이 조금 달라 높이를 고정한 상자
  /// 안에 비율을 유지해 맞춘다(칸마다 높이가 들쭉날쭉하지 않게).
  final double width;

  /// 붙인 느낌을 주는 기울기(도). 칸에서는 약 -2°, 범례 견본은 -6°.
  final double tiltDegrees;

  static String assetFor({required bool perfect, required bool dark}) =>
      'assets/images/level_badge_${perfect ? 'perfect' : 'clear'}_'
      '${dark ? 'dark' : 'light'}.png';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: tiltDegrees * math.pi / 180,
        child: Image.asset(
          assetFor(perfect: perfect, dark: dark),
          width: width,
          height: width * 0.42,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          // 화면에 그리는 크기의 약 3배까지만 디코딩한다.
          cacheWidth: (width * 3).round(),
        ),
      ),
    );
  }
}
