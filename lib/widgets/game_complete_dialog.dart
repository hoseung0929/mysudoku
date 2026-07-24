import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/theme/level_status_colors.dart';

/// 게임 완료 축하 다이얼로그 위젯
class GameCompleteDialog extends StatelessWidget {
  final int timeInSeconds;
  final int wrongCount;
  final bool isNewBestRecord;
  final String? challengeMessage;
  final VoidCallback onRestart;
  final VoidCallback onGoToLevelSelection;
  final VoidCallback? onOpenSettings;

  /// 같은 난이도의 다음 게임이 있을 때만 전달합니다.
  final VoidCallback? onNextPuzzle;

  const GameCompleteDialog({
    super.key,
    required this.timeInSeconds,
    required this.wrongCount,
    this.isNewBestRecord = false,
    this.challengeMessage,
    required this.onRestart,
    required this.onGoToLevelSelection,
    this.onOpenSettings,
    this.onNextPuzzle,
  });

  String get formattedTime {
    final hours = timeInSeconds ~/ 3600;
    final minutes = (timeInSeconds % 3600) ~/ 60;
    final seconds = timeInSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final onVar = cs.onSurfaceVariant;
    final levelPalette = LevelStatusPalette.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;
    final dialogMaxContentHeight = MediaQuery.of(context).size.height * 0.52;
    final dialogMaxWidth = isTablet ? 440.0 : double.infinity;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeSuffix = isDarkMode ? 'black' : 'white';
    final secondaryActionStyle = OutlinedButton.styleFrom(
      minimumSize: Size.fromHeight(isTablet ? 52 : 46),
      foregroundColor: onVar,
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      side: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: GoogleFonts.notoSans(
        fontSize: isTablet ? 16 : 14,
        fontWeight: FontWeight.w600,
      ),
    );
    final primaryActionStyle = ElevatedButton.styleFrom(
      minimumSize: Size.fromHeight(isTablet ? 56 : 50),
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
    return AlertDialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: cs.outlineVariant),
      ),
      title: Image.asset(
        isNewBestRecord
            ? 'assets/images/newbest_$themeSuffix.png'
            : 'assets/images/clear_$themeSuffix.png',
        height: isTablet ? 180 : 150,
      ),
      titlePadding: EdgeInsets.fromLTRB(24, isTablet ? 32 : 28, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 0.1, 24, 24),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: dialogMaxContentHeight,
          maxWidth: dialogMaxWidth,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (challengeMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 13 : 10,
                    vertical: isTablet ? 10 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department,
                          size: isTablet ? 22 : 18, color: onSurface),
                      SizedBox(width: isTablet ? 10 : 8),
                      Expanded(
                        child: Text(
                          challengeMessage!,
                          style: GoogleFonts.notoSans(
                            fontSize: isTablet ? 15 : 13,
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
                  padding: EdgeInsets.all(isTablet ? 15 : 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dialogSuggestedNextStep,
                        style: GoogleFonts.notoSans(
                          fontSize: isTablet ? 15 : 13,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                      SizedBox(height: isTablet ? 10 : 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (onOpenSettings != null)
                            ActionChip(
                              avatar: const Icon(
                                  Icons.notifications_active_outlined,
                                  size: 16),
                              label: Text(l10n.dialogSetTomorrowReminder),
                              onPressed: onOpenSettings,
                            ),
                          ActionChip(
                            avatar:
                                const Icon(Icons.explore_outlined, size: 16),
                            label: Text(l10n.dialogTryAnotherLevel),
                            onPressed: onGoToLevelSelection,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: isTablet ? 24 : 20),
              // 통계 정보
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: levelPalette.completedBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: levelPalette.completedBorder),
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
                              color: levelPalette.primaryPurple,
                              size: isTablet ? 24 : 20,
                            ),
                            SizedBox(width: isTablet ? 10 : 8),
                            Text(
                              l10n.dialogElapsedTime,
                              style: GoogleFonts.notoSans(
                                fontSize: isTablet ? 16 : 14,
                                color: onVar,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          formattedTime,
                          style: GoogleFonts.notoSans(
                            fontSize: isTablet ? 19 : 16,
                            fontWeight: FontWeight.bold,
                            color: levelPalette.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 10 : 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: levelPalette.primaryPurple,
                              size: isTablet ? 24 : 20,
                            ),
                            SizedBox(width: isTablet ? 10 : 8),
                            Text(
                              l10n.dialogWrongCount,
                              style: GoogleFonts.notoSans(
                                fontSize: isTablet ? 16 : 14,
                                color: onVar,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          l10n.dialogWrongCountValue(wrongCount),
                          style: GoogleFonts.notoSans(
                            fontSize: isTablet ? 19 : 16,
                            fontWeight: FontWeight.bold,
                            color: levelPalette.primaryPurple,
                          ),
                        ),
                      ],
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
          width: dialogMaxWidth,
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
              SizedBox(height: isTablet ? 14 : 12),
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
                      fontSize: isTablet ? 18 : 16,
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
