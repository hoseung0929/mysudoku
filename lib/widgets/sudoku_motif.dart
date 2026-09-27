import 'package:flutter/material.dart';
import 'package:sudoku159/theme/level_status_colors.dart';

/// 스도쿠를 연상시키는 작은 장식 그래픽(3×3 격자 + 일부 옅은 채움).
/// 실제 보드나 진행 상태가 아니므로 숫자를 넣지 않는다. [checked]이면 오른쪽
/// 아래에 체크를 겹친다. 장식이라 터치와 스크린 리더에서 제외한다.
class SudokuMotif extends StatelessWidget {
  const SudokuMotif({
    super.key,
    required this.size,
    this.checked = false,
    this.animateCheck = false,
    this.onCheckAnimated,
  });

  final double size;
  final bool checked;

  /// 체크가 방금 생긴 경우에만 true. 체크 배지가 약 200ms 동안 나타난다.
  final bool animateCheck;
  final VoidCallback? onCheckAnimated;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final purple = LevelStatusPalette.of(context).primaryPurple;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _MotifPainter(
                  background: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  line: cs.outlineVariant,
                  fill: purple.withValues(alpha: 0.28),
                ),
              ),
              if (checked)
                Positioned(
                  right: -size * 0.08,
                  bottom: -size * 0.08,
                  child: FadeInOnce(
                    enabled: animateCheck,
                    onEnd: onCheckAnimated,
                    child: Container(
                      width: size * 0.42,
                      height: size * 0.42,
                      decoration: BoxDecoration(
                        color: purple,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: size * 0.28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotifPainter extends CustomPainter {
  _MotifPainter({
    required this.background,
    required this.line,
    required this.fill,
  });

  final Color background;
  final Color line;
  final Color fill;

  // 3×3 중 채울 칸(행 우선 인덱스). 규칙적이지 않게 흩어 놓는다.
  static const _filled = {0, 4, 5, 7};

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width * 0.16;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, Paint()..color = background);

    final cell = size.width / 3;
    canvas.save();
    canvas.clipRRect(rrect);
    for (final i in _filled) {
      canvas.drawRect(
        Rect.fromLTWH((i % 3) * cell, (i ~/ 3) * cell, cell, cell),
        Paint()..color = fill,
      );
    }
    final thin = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), thin);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), thin);
    }
    canvas.restore();
    canvas.drawRRect(
      rrect.deflate(0.75),
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_MotifPainter old) =>
      old.background != background || old.line != line || old.fill != fill;
}

/// [enabled]일 때 처음 그려지는 순간 한 번 200ms 동안 서서히 나타난다.
/// 동작 줄이기에서는 바로 보이고, 끝나면 [onEnd]를 알린다.
class FadeInOnce extends StatelessWidget {
  const FadeInOnce({
    super.key,
    required this.enabled,
    required this.child,
    this.onEnd,
  });

  final bool enabled;
  final Widget child;
  final VoidCallback? onEnd;

  @override
  Widget build(BuildContext context) {
    if (!enabled || MediaQuery.disableAnimationsOf(context)) {
      if (enabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onEnd?.call());
      }
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      onEnd: onEnd,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }
}
