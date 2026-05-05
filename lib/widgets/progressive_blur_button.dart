import 'package:flutter/material.dart';

/// Progressive Blur 스타일의 버튼 위젯
class ProgressiveBlurButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color? blurColor;
  final double borderRadius;
  final bool isActive;

  const ProgressiveBlurButton({
    super.key,
    this.onPressed,
    required this.child,
    this.width = 95,
    this.height = 70,
    this.backgroundColor = const Color(0xFFB8E6B8), // 파스텔 민트
    this.blurColor,
    this.borderRadius = 28,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final effectiveBlurColor = blurColor ?? backgroundColor;
    final surfaceColor = isActive
        ? Color.lerp(
            Colors.white,
            backgroundColor,
            0.48,
          )!
        : isEnabled
            ? Color.lerp(
                Colors.white,
                backgroundColor,
                0.22,
              )!
            : const Color(0xFFFAFAF9);
    final borderColor = isActive
        ? Color.lerp(
            const Color(0xFFE5E5E3),
            effectiveBlurColor,
            0.86,
          )!
        : isEnabled
            ? Color.lerp(
                const Color(0xFFE5E5E3),
                effectiveBlurColor,
                0.28,
              )!
            : const Color(0xFFDDDDDA);
    final contentOpacity = isEnabled
        ? 1.0
        : isActive
            ? 0.72
            : 0.36;

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
                width: isActive ? 1.8 : 1,
              ),
            ),
            child: Opacity(
              opacity: contentOpacity,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
