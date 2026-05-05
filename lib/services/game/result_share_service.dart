import 'package:mysudoku/l10n/app_localizations.dart';

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
      l10n.shareClearStats(_formatSeconds(clearTimeSeconds), wrongCount),
      l10n.shareClearTags,
    ].where((line) => line.isNotEmpty).join('\n');
  }

  String formatClearSummary({
    required AppLocalizations l10n,
    required int clearTimeSeconds,
    required int wrongCount,
  }) {
    return l10n.shareSummaryPattern(
      _formatSeconds(clearTimeSeconds),
      wrongCount,
    );
  }

  String _formatSeconds(int value) {
    final hours = value ~/ 3600;
    final minutes = (value % 3600) ~/ 60;
    final seconds = value % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
