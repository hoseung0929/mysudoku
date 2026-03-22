import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mysudoku/theme/app_theme.dart';
import 'package:mysudoku/widgets/progressive_blur_button.dart';

/// 태블릿 패널의 메모/힌트/일시정지 등 액션 버튼
class SudokuGameActionButton extends StatelessWidget {
  const SudokuGameActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ProgressiveBlurButton(
      onPressed: onPressed,
      width: 92,
      height: 64,
      borderRadius: 20,
      backgroundColor: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.textColor, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
