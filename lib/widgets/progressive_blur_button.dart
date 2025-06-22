import 'dart:ui';
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

  const ProgressiveBlurButton({
    super.key,
    this.onPressed,
    required this.child,
    this.width = 95,
    this.height = 70,
    this.backgroundColor = const Color(0xFFB8E6B8), // 파스텔 민트
    this.blurColor,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBlurColor = blurColor ?? backgroundColor.withOpacity(0.6);

    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progressive Blur Background Layer
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.transparent,
                          effectiveBlurColor.withOpacity(0.2),
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcOver,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            backgroundColor.withOpacity(0.9),
                            effectiveBlurColor.withOpacity(0.7),
                            effectiveBlurColor.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(
                          color: backgroundColor.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: backgroundColor.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: effectiveBlurColor.withOpacity(0.6),
                            blurRadius: 8,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Main Content Layer
            child,
          ],
        ),
      ),
    );
  }
}
