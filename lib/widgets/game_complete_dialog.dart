import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 게임 완료 축하 다이얼로그 위젯
class GameCompleteDialog extends StatelessWidget {
  final int timeInSeconds;
  final int wrongCount;
  final VoidCallback onRestart;
  final VoidCallback onGoToLevelSelection;

  // 색상 테마 정의
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color mintColor = Color(0xFFB8E6B8);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF34495E);

  const GameCompleteDialog({
    super.key,
    required this.timeInSeconds,
    required this.wrongCount,
    required this.onRestart,
    required this.onGoToLevelSelection,
  });

  String get formattedTime {
    final minutes = timeInSeconds ~/ 60;
    final seconds = timeInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.celebration,
            color: goldColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            '축하합니다!',
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
            '스도쿠를 완성했습니다!',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: lightTextColor,
            ),
          ),
          const SizedBox(height: 20),
          // 통계 정보
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mintColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mintColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.timer,
                          color: textColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '소요 시간',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: lightTextColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formattedTime,
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: textColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '오답 횟수',
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: lightTextColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$wrongCount회',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
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
