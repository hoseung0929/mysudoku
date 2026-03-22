import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static bool _muted = false;

  static bool get isMuted => _muted;

  static void setMuted(bool muted) {
    _muted = muted;
  }

  static void debug(String message) {
    if (!kDebugMode || _muted) return;
    debugPrint('[MySudoku] $message');
  }
}
