import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 아이패드(폭 > 600)에서 주요 게임 팝업을 키우기 위한 치수 모음.
/// 아이폰 값은 기존 그대로이고, 안전 영역 높이가 700 미만인 아이패드
/// (가로 모드 등)에서는 글자만 키우고 여백·그림은 아이폰 값을 쓴다.
class DialogMetrics {
  const DialogMetrics._({
    required this.isTablet,
    required this.compactHeight,
    required this.screenWidth,
    required this.safeHeight,
  });

  factory DialogMetrics.of(BuildContext context) {
    final media = MediaQuery.of(context);
    final safeHeight =
        media.size.height - media.padding.top - media.padding.bottom;
    final isTablet = media.size.width > 600;
    return DialogMetrics._(
      isTablet: isTablet,
      compactHeight: isTablet && safeHeight < 700,
      screenWidth: media.size.width,
      safeHeight: safeHeight,
    );
  }

  final bool isTablet;
  final bool compactHeight;
  final double screenWidth;
  final double safeHeight;

  /// 여백·간격: 아이패드이고 높이가 충분할 때만 태블릿 값.
  T spacing<T>(T phone, T tablet) =>
      isTablet && !compactHeight ? tablet : phone;

  /// 글자·크기: 아이패드면(낮은 높이 포함) 태블릿 값.
  T size<T>(T phone, T tablet) => isTablet ? tablet : phone;

  /// 팝업 바깥 좌우 여백(아이폰은 [phoneInset], 아이패드는 최소 32).
  double inset(double phoneInset) => isTablet ? 32 : phoneInset;

  /// 실제 팝업 최대 폭: 지정 폭과 `화면 폭 - 64` 중 작은 값(아이패드).
  double maxWidth({required double phone, required double tablet}) =>
      isTablet ? math.min(tablet, screenWidth - 64) : phone;

  /// 아이패드에서 팝업 높이는 안전 영역의 85%를 넘지 않는다.
  double? get maxHeight => isTablet ? safeHeight * 0.85 : null;
}
