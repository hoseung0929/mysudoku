import 'package:flutter/material.dart';

class SudokuGridBadge extends StatelessWidget {
  const SudokuGridBadge({
    super.key,
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      padding: EdgeInsets.all(size * 0.18),
      child: CustomPaint(
        painter: _SudokuGridPainter(color: color),
      ),
    );
  }
}

class _SudokuGridPainter extends CustomPainter {
  const _SudokuGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.shortestSide * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final thirdX = size.width / 3;
    final thirdY = size.height / 3;

    for (var i = 1; i < 3; i++) {
      final x = thirdX * i;
      final y = thirdY * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final outline = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.shortestSide * 0.16),
    );
    canvas.drawRRect(outline, paint);
  }

  @override
  bool shouldRepaint(covariant _SudokuGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
