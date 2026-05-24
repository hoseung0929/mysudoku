import 'package:flutter/material.dart';
import 'package:sudoku159/theme/app_colors.dart';

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
    final baseColor = Theme.of(context).colorScheme.surface;
    final baseBorderColor = context.colors.border;
    final surfaceColor = isActive
        ? Color.lerp(baseColor, backgroundColor, 0.48)!
        : isEnabled
            ? Color.lerp(baseColor, backgroundColor, 0.22)!
            : context.colors.surfaceSubtle;
    final borderColor = isActive
        ? Color.lerp(baseBorderColor, effectiveBlurColor, 0.86)!
        : isEnabled
            ? Color.lerp(baseBorderColor, effectiveBlurColor, 0.28)!
            : context.colors.border;
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
