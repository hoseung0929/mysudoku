import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/services/achievement_service.dart';

extension AchievementRarityL10n on AchievementRarity {
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case AchievementRarity.common:
        return l10n.achievementRarityCommon;
      case AchievementRarity.rare:
        return l10n.achievementRarityRare;
      case AchievementRarity.epic:
        return l10n.achievementRarityEpic;
    }
  }
}
