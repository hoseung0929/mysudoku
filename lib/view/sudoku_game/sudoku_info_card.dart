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
    this.progressValue,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;

  /// 0.0~1.0이면 카드 하단에 얇은 진행률 바를 추가로 그린다 (null이면 안 그림).
  final double? progressValue;

  static const double _verticalPadding = 16; // 기존 20에서 20% 축소
  static const double _horizontalPadding = 14;
  static const double _progressBarHeight = 5;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 배경은 중립 톤으로 차분하게 두고, 아이콘·값에만 포인트 색을 준다
    // (카드 여러 개가 나란히 있을 때 퍼즐 보드보다 시각적으로 튀지 않도록).
    final Color ic = accentColor ?? cs.onSurfaceVariant;
    final Color valueColor = accentColor ?? cs.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: _verticalPadding,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 26, color: ic),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  // 제목이 너무 연해 보이지 않도록 onSurfaceVariant보다 한 단계
                  // 진한 onSurface를 사용. 값(굵고 포인트색)과의 계층은 유지됨.
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.notoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
          if (progressValue != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(_progressBarHeight / 2),
              child: LinearProgressIndicator(
                value: progressValue!.clamp(0.0, 1.0),
                minHeight: _progressBarHeight,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(valueColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
