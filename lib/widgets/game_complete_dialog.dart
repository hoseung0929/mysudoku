import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
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
  final VoidCallback? onOpenSettings;

  /// 같은 난이도의 다음 게임이 있을 때만 전달합니다.
  final VoidCallback? onNextPuzzle;

  static const Color mintColor = Color(0xFF285B3F);
  static const Color goldColor = Color(0xFFF4A261);

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
    this.onOpenSettings,
    this.onNextPuzzle,
  });

  String get formattedTime {
    final minutes = timeInSeconds ~/ 60;
    final seconds = timeInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final onVar = cs.onSurfaceVariant;
    final shareBg = cs.surfaceContainerHighest;
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    final dialogMaxContentHeight = MediaQuery.of(context).size.height * 0.52;
    final secondaryActionStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(46),
      foregroundColor: onVar,
      side: BorderSide(color: cs.outlineVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: GoogleFonts.notoSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
    final primaryActionStyle = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      backgroundColor: mintColor,
      foregroundColor: const Color(0xFFFDFBF6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFDF9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFFE4DED3)),
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
            l10n.dialogCongratulations,
            style: GoogleFonts.notoSans(
              color: onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: dialogMaxContentHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNewBestRecord)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.dialogNewBest,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                ),
              Text(
                l10n.dialogSudokuComplete,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: onVar,
                ),
              ),
              if (challengeMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F0E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department,
                          size: 18, color: onSurface),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          challengeMessage!,
                          style: GoogleFonts.notoSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F0E5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE4DED3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isKorean ? '다음 행동 추천' : 'Suggested next step',
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (onOpenSettings != null)
                            ActionChip(
                              avatar: const Icon(
                                  Icons.notifications_active_outlined,
                                  size: 16),
                              label: Text(isKorean
                                  ? '내일 알림 설정'
                                  : 'Set tomorrow reminder'),
                              onPressed: onOpenSettings,
                            ),
                          ActionChip(
                            avatar:
                                const Icon(Icons.explore_outlined, size: 16),
                            label: Text(
                                isKorean ? '다른 난이도 보기' : 'Try another level'),
                            onPressed: onGoToLevelSelection,
                          ),
                        ],
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
                    color: const Color(0xFFF6F0E5),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: goldColor.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.military_tech, size: 18, color: onSurface),
                          const SizedBox(width: 8),
                          Text(
                            l10n.dialogNewBadges,
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
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
                                    color: onVar,
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
                  color: const Color(0xFFEFF4EF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4DED3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              color: onSurface,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.dialogElapsedTime,
                              style: GoogleFonts.notoSans(
                                fontSize: 14,
                                color: onVar,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          formattedTime,
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
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
                            Icon(
                              Icons.error_outline,
                              color: onSurface,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.dialogWrongCount,
                              style: GoogleFonts.notoSans(
                                fontSize: 14,
                                color: onVar,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          l10n.dialogWrongCountValue(wrongCount),
                          style: GoogleFonts.notoSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
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
                  color: shareBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dialogSharePreview,
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shareSummary,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: onVar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      buttonPadding: EdgeInsets.zero,
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onGoToLevelSelection,
                  style: secondaryActionStyle,
                  child: Text(l10n.dialogBackToLevels),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNextPuzzle ?? onRestart,
                  style: primaryActionStyle,
                  child: Text(
                    onNextPuzzle != null
                        ? l10n.dialogNextPuzzle
                        : l10n.dialogPlayAgain,
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
