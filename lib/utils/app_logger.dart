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
    debugPrint('[Sudoku159] $message');
  }

  /// 실패를 남긴다. [debug]와 달리 릴리즈에서도 기록한다(음소거만 존중).
  static void error(String message, [Object? error]) {
    if (_muted) return;
    debugPrint('[Sudoku159] ERROR $message${error != null ? ': $error' : ''}');
  }
}
