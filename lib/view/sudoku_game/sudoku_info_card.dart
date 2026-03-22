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

  static const Color _onPastel = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bg = accentColor ?? cs.surfaceContainerHigh;
    final Color fg = accentColor != null ? _onPastel : cs.onSurface;
    final Color ic = accentColor != null ? _onPastel : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ic),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
