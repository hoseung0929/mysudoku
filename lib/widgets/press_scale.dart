import 'package:flutter/material.dart';

/// 눌린 카드·타일을 중심 기준으로 살짝 줄였다가 복원한다.
///
/// 시각 변환만 하므로 레이아웃과 터치 영역은 바뀌지 않는다. 누를 때는 빠르게,
/// 뗄 때는 조금 더 천천히 돌아오며 튕기지 않는다. 동작 줄이기에서는 크기를
/// 바꾸지 않는다.
class PressScale extends StatelessWidget {
  const PressScale({super.key, required this.pressed, required this.child});

  static const double pressedScale = 0.98;
  static const Duration pressDuration = Duration(milliseconds: 90);
  static const Duration releaseDuration = Duration(milliseconds: 130);

  final bool pressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final active = pressed && !MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: active ? pressedScale : 1.0,
      duration: pressed ? pressDuration : releaseDuration,
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}
