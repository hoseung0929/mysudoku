import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 게임 상단/태블릿 정보 영역의 작은 카드
class SudokuInfoCard extends StatelessWidget {
  const SudokuInfoCard(
    this.label,
    this.value,
    this.icon, {
    super.key,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bg = accentColor?.withValues(alpha: 0.18) ?? cs.surfaceContainerHigh;
    final Color fg = accentColor ?? cs.onSurface;
    final Color ic = accentColor ?? cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor?.withValues(alpha: 0.28) ?? cs.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ic),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
