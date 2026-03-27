import 'package:flutter/material.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/services/onboarding_service.dart';
import 'package:mysudoku/view/sudoku_game/game_guide_item.dart';

class GameGuideFlow {
  const GameGuideFlow._();

  static Future<bool> showIfNeeded({
    required BuildContext context,
    required OnboardingService onboardingService,
    required bool hasShownGuide,
  }) async {
    if (hasShownGuide) {
      return false;
    }

    final shouldShow = await onboardingService.shouldShowGameGuide();
    if (!shouldShow) {
      return false;
    }

    if (!context.mounted) {
      return true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          final l10n = AppLocalizations.of(sheetContext)!;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.gameGuideTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(sheetContext).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                GameGuideItem(
                  title: l10n.gameGuideTapCellTitle,
                  description: l10n.gameGuideTapCellBody,
                ),
                const SizedBox(height: 10),
                GameGuideItem(
                  title: l10n.gameGuideMistakesTitle,
                  description: l10n.gameGuideMistakesBody,
                ),
                const SizedBox(height: 10),
                GameGuideItem(
                  title: l10n.gameGuideColorsTitle,
                  description: l10n.gameGuideColorsBody,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.gameGuidePlayButton),
                  ),
                ),
              ],
            ),
          );
        },
      );

      await onboardingService.markGameGuideSeen();
    });

    return true;
  }
}
