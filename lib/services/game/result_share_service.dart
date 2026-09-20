import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/utils/time_format.dart';

class ResultShareService {
  String buildClearResultText({
    required AppLocalizations l10n,
    required String localizedLevelName,
    required int gameNumber,
    required int clearTimeSeconds,
    required int wrongCount,
    required bool isNewBestRecord,
  }) {
    final badge = isNewBestRecord ? '${l10n.dialogNewBest}\n' : '';
    return [
      badge,
      l10n.shareClearHeader,
      l10n.shareClearLine(localizedLevelName, gameNumber),
      l10n.shareClearStats(formatElapsedSeconds(clearTimeSeconds), wrongCount),
      l10n.shareClearTags,
    ].where((line) => line.isNotEmpty).join('\n');
  }

  String formatClearSummary({
    required AppLocalizations l10n,
    required int clearTimeSeconds,
    required int wrongCount,
  }) {
    return l10n.shareSummaryPattern(
      formatElapsedSeconds(clearTimeSeconds),
      wrongCount,
    );
  }
}
