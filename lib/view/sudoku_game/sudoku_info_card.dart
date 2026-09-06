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
    // 배경/라벨은 중립 톤으로 차분하게 두고, 아이콘·값에만 포인트 색을 준다
    // (카드 여러 개가 나란히 있을 때 퍼즐 보드보다 시각적으로 튀지 않도록).
    final Color ic = accentColor ?? cs.onSurfaceVariant;
    final Color valueColor = accentColor ?? cs.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ic),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
