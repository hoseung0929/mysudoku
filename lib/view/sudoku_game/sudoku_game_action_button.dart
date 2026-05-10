import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sudoku159/widgets/progressive_blur_button.dart';

/// 태블릿 패널의 메모/힌트/일시정지 등 액션 버튼
class SudokuGameActionButton extends StatelessWidget {
  const SudokuGameActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final effectiveLabelColor = Theme.of(context).colorScheme.onSurface;
    return ProgressiveBlurButton(
      onPressed: onPressed,
      width: 92,
      height: 64,
      borderRadius: 22,
      backgroundColor: backgroundColor,
      isActive: isActive,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: effectiveLabelColor, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: effectiveLabelColor,
            ),
          ),
        ],
      ),
    );
  }
}
