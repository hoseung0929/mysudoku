import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mysudoku/l10n/app_localizations.dart';

/// 게임 오버 다이얼로그 위젯
class GameOverDialog extends StatelessWidget {
  final int wrongCount;
  final VoidCallback onRestart;
  final VoidCallback onGoToLevelSelection;

  static const Color mintColor = Color(0xFFB8E6B8);
  static const Color pinkColor = Color(0xFFE6B8C8);

  const GameOverDialog({
    super.key,
    required this.wrongCount,
    required this.onRestart,
    required this.onGoToLevelSelection,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onVar = Theme.of(context).colorScheme.onSurfaceVariant;
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
            l10n.gameOverTitle,
            style: GoogleFonts.notoSans(
              color: onSurface,
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
            l10n.gameOverMessage,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: onVar,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: pinkColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pinkColor.withValues(alpha: 0.3)),
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
                  l10n.gameOverWrongLabel(wrongCount),
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
            l10n.dialogBackToLevels,
            style: GoogleFonts.notoSans(
              color: onVar,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onRestart,
          style: ElevatedButton.styleFrom(
            backgroundColor: mintColor,
            foregroundColor: const Color(0xFF1A2E24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            l10n.dialogPlayAgain,
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
