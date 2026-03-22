import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mysudoku/services/achievement_service.dart';

/// 게임 완료 축하 다이얼로그 위젯
class GameCompleteDialog extends StatelessWidget {
  final String shareSummary;
  final int timeInSeconds;
  final int wrongCount;
  final bool isNewBestRecord;
  final String? challengeMessage;
  final List<AchievementBadge> unlockedBadges;
  final VoidCallback onRestart;
  final VoidCallback onGoToLevelSelection;
  final VoidCallback onCopyResult;
  final VoidCallback onShareResult;

  // 색상 테마 정의
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color mintColor = Color(0xFFB8E6B8);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color textColor = Color(0xFF2C3E50);
  static const Color lightTextColor = Color(0xFF34495E);

  const GameCompleteDialog({
    super.key,
    required this.shareSummary,
    required this.timeInSeconds,
    required this.wrongCount,
    this.isNewBestRecord = false,
    this.challengeMessage,
    this.unlockedBadges = const [],
    required this.onRestart,
    required this.onGoToLevelSelection,
    required this.onCopyResult,
    required this.onShareResult,
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
          if (isNewBestRecord)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'NEW BEST',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          Text(
            '스도쿠를 완성했습니다!',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: lightTextColor,
            ),
          ),
          if (challengeMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: mintColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, size: 18, color: textColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      challengeMessage!,
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (unlockedBadges.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: goldColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: goldColor.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.military_tech, size: 18, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        '새 배지 획득',
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...unlockedBadges.map(
                    (badge) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            badge.icon,
                            size: 16,
                            color: badge.accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${badge.title} · ${badge.description}',
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: lightTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // 통계 정보
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mintColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mintColor.withValues(alpha: 0.3)),
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
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '공유용 결과',
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  shareSummary,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: lightTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: onCopyResult,
          icon: const Icon(Icons.copy, size: 18),
          label: Text(
            '결과 복사',
            style: GoogleFonts.notoSans(
              color: lightTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onShareResult,
          icon: const Icon(Icons.ios_share, size: 18),
          label: Text(
            '공유하기',
            style: GoogleFonts.notoSans(
              color: lightTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
