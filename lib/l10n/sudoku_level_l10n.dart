import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/model/sudoku_level.dart';

/// DB/로직용 `name`(한글 키)과 UI 표시용 문자열을 매핑합니다.
extension SudokuLevelL10n on SudokuLevel {
  String localizedName(AppLocalizations l10n) {
    switch (name) {
      case '초급':
        return l10n.levelBeginner;
      case '중급':
        return l10n.levelIntermediate;
      case '고급':
        return l10n.levelAdvanced;
      case '전문가':
        return l10n.levelExpert;
      case '마스터':
        return l10n.levelMaster;
      default:
        return name;
    }
  }

  String localizedDescription(AppLocalizations l10n) {
    switch (name) {
      case '초급':
        return l10n.levelDescBeginner;
      case '중급':
        return l10n.levelDescIntermediate;
      case '고급':
        return l10n.levelDescAdvanced;
      case '전문가':
        return l10n.levelDescExpert;
      case '마스터':
        return l10n.levelDescMaster;
      default:
        return description;
    }
  }
}

/// DB [level_name] 문자열(한글 키) → 현재 로케일 표시명.
extension SudokuDbLevelNameL10n on String {
  String localizedSudokuLevelName(AppLocalizations l10n) {
    for (final level in SudokuLevel.levels) {
      if (level.name == this) {
        return level.localizedName(l10n);
      }
    }
    return this;
  }
}
