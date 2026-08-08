import 'package:flutter/services.dart' show appFlavor;

/// flavor(--flavor global/japan)에 따라 달라지는 값들.
abstract final class AppConfig {
  AppConfig._();

  static bool get isJapan => appFlavor == 'japan';

  static String get privacyPolicyUrl => isJapan
      ? 'https://team929-support.github.io/nanpre159/privacy-policy'
      : 'https://team929-support.github.io/sudoku159/privacy-policy';
}
