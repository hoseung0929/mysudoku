import 'package:flutter/widgets.dart';
import 'package:mysudoku/l10n/app_localizations.dart';

/// [AppLocalizations.of]의 null-안전 래퍼 (테스트·오버레이 등에서 delegate가 없을 때).
extension BuildContextL10n on BuildContext {
  AppLocalizations? get l10nOrNull => AppLocalizations.of(this);
}
