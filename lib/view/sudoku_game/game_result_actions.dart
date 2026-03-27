import 'package:flutter/services.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/services/result_share_service.dart';
import 'package:share_plus/share_plus.dart';

class GameResultActions {
  GameResultActions({ResultShareService? resultShareService})
      : _resultShareService = resultShareService ?? ResultShareService();

  final ResultShareService _resultShareService;

  String buildResultText({
    required AppLocalizations l10n,
    required String localizedLevelName,
    required int gameNumber,
    required int clearTimeSeconds,
    required int wrongCount,
    required bool isNewBestRecord,
  }) {
    return _resultShareService.buildClearResultText(
      l10n: l10n,
      localizedLevelName: localizedLevelName,
      gameNumber: gameNumber,
      clearTimeSeconds: clearTimeSeconds,
      wrongCount: wrongCount,
      isNewBestRecord: isNewBestRecord,
    );
  }

  Future<void> copyResultText(String resultText) async {
    await Clipboard.setData(ClipboardData(text: resultText));
  }

  Future<void> shareResultText({
    required String resultText,
    required String subject,
  }) async {
    await Share.share(resultText, subject: subject);
  }
}
