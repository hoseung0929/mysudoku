import 'package:flutter/material.dart';
import 'package:sudoku159/theme/app_colors.dart';
import 'package:sudoku159/widgets/press_scale.dart';

/// Progressive Blur 스타일의 버튼 위젯
class ProgressiveBlurButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color? blurColor;
  final double borderRadius;
  final bool isActive;

  /// 누르는 동안 살짝 줄어드는 눌림 반응을 켤지 여부. 기본값 false로 두어
  /// 이 버튼을 쓰는 다른 화면(메모·힌트·되돌리기 원형 버튼 등)의 동작은
  /// 그대로 유지하고, 게임 숫자패드처럼 명시적으로 요청한 곳에서만 켠다.
  final bool enablePressScale;

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
    this.enablePressScale = false,
  });

  @override
  State<ProgressiveBlurButton> createState() => _ProgressiveBlurButtonState();
}

class _ProgressiveBlurButtonState extends State<ProgressiveBlurButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final effectiveBlurColor = widget.blurColor ?? widget.backgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = Theme.of(context).colorScheme.surface;
    final baseBorderColor = context.colors.border;
    final surfaceColor = widget.isActive
        ? Color.lerp(baseColor, widget.backgroundColor, isDark ? 0.78 : 0.48)!
        : isEnabled
            ? Color.lerp(
                baseColor, widget.backgroundColor, isDark ? 0.40 : 0.22)!
            : context.colors.surfaceSubtle;
    final borderColor = widget.isActive
        ? Color.lerp(baseBorderColor, effectiveBlurColor, isDark ? 1.0 : 0.86)!
        : isEnabled
            ? Color.lerp(baseBorderColor, effectiveBlurColor, 0.28)!
            : context.colors.border;
    final contentOpacity = isEnabled
        ? 1.0
        : widget.isActive
            ? 0.72
            : 0.36;

    final button = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: widget.enablePressScale ? _setPressed : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Ink(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: borderColor,
                width: widget.isActive ? (isDark ? 2.2 : 1.8) : 1,
              ),
            ),
            child: Opacity(
              opacity: contentOpacity,
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (!widget.enablePressScale) {
      return button;
    }
    // 숫자패드용: 누르는 동안 0.97로 살짝 줄어든다(동작 줄이기에서는
    // PressScale 내부에서 자동으로 생략됨).
    return PressScale(pressed: _pressed, scale: 0.97, child: button);
  }
}
