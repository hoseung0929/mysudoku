import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/l10n/sudoku_level_l10n.dart';
import 'package:mysudoku/services/home_dashboard_service.dart';

extension QuickStartOptionL10n on QuickStartOption {
  String localizedTitle(AppLocalizations l10n) {
    switch (kind) {
      case QuickStartKind.recommended:
        return l10n.challengeQuickStartRecommendedTitle;
      case QuickStartKind.beginner:
        return l10n.challengeQuickStartBeginnerTitle;
      case QuickStartKind.random:
        return l10n.challengeQuickStartRandomTitle;
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    switch (kind) {
      case QuickStartKind.recommended:
        return l10n.challengeQuickStartRecommendedBody(
          level.localizedName(l10n),
        );
      case QuickStartKind.beginner:
        return l10n.challengeQuickStartBeginnerBody;
      case QuickStartKind.random:
        return l10n.challengeQuickStartRandomBody;
    }
  }
}
