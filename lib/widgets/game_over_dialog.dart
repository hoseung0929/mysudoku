import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 게임 오버 다이얼로그 위젯
class GameOverDialog extends StatelessWidget {
  final int wrongCount;
  final VoidCallback onRestart;
  final VoidCallback onGoToLevelSelection;

  // 색상 테마 정의
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color mintColor = Color(0xFFB8E6B8);
  static const Color pinkColor = Color(0xFFE6B8C8);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF34495E);

  const GameOverDialog({
    super.key,
    required this.wrongCount,
    required this.onRestart,
    required this.onGoToLevelSelection,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            color: Colors.red.shade600,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            '게임 오버',
            style: GoogleFonts.notoSans(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '오답이 3개를 초과했습니다.',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: lightTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pinkColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pinkColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '오답: $wrongCount/3',
                  style: GoogleFonts.notoSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onGoToLevelSelection,
          child: Text(
            '레벨 선택으로',
            style: GoogleFonts.notoSans(
              color: lightTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onRestart,
          style: ElevatedButton.styleFrom(
            backgroundColor: mintColor,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '다시 시작',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
