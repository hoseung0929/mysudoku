import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:mysudoku/firebase_options.dart';
import 'package:mysudoku/utils/app_logger.dart';

class FirebaseBootstrapService {
  FirebaseBootstrapService._();

  static final FirebaseBootstrapService instance = FirebaseBootstrapService._();

  bool _isReady = false;
  Future<bool>? _initializing;

  bool get isReady => _isReady || Firebase.apps.isNotEmpty;

  Future<bool> initialize() async {
    if (isReady) {
      _isReady = true;
      return true;
    }
    final inFlight = _initializing;
    if (inFlight != null) {
      return inFlight;
    }

    _initializing = () async {
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
        _isReady = true;
      } catch (e) {
        _isReady = false;
        if (kDebugMode) {
          AppLogger.debug('Firebase 초기화 건너뜀: $e');
        }
      }

      return isReady;
    }();

    final result = await _initializing!;
    if (result) {
      _initializing = null;
      return true;
    }
    // 실패한 경우에는 이후 호출에서 재시도할 수 있게 잠금을 해제한다.
    _initializing = null;
    return false;
  }
}
