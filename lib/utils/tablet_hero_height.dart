import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 아이패드(폭 > 600) 상단 히어로 이미지 높이. 이미지(2:1) 전체가 보이도록
/// 폭의 절반을 쓰되, 가로 모드에서 화면을 너무 차지하지 않게 높이의 40%와
/// 절대 상한(420)으로 제한한다. 기존 태블릿 값(276)보다 작아지지는 않는다.
double tabletHeroHeight(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return math.max(
    276.0,
    math.min(size.width / 2, math.min(420.0, size.height * 0.4)),
  );
}
