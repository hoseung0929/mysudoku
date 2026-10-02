import 'package:flutter/material.dart';

/// 처음 나타날 때 0에서 [value]까지 채워지고, 값이 바뀌면 이어서 전환되는
/// 진행바. 동작 줄이기에서는 바로 최종 값을 보여준다.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.fillColor,
    required this.trackColor,
    this.minHeight = 6,
    this.duration = const Duration(milliseconds: 300),
  });

  /// 0.0~1.0
  final double value;
  final Color fillColor;
  final Color trackColor;
  final double minHeight;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: reduceMotion ? Duration.zero : duration,
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => LinearProgressIndicator(
          minHeight: minHeight,
          value: v,
          backgroundColor: trackColor,
          valueColor: AlwaysStoppedAnimation<Color>(fillColor),
        ),
      ),
    );
  }
}
