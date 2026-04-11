import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:mysudoku/firebase_options.dart';
import 'package:mysudoku/utils/app_logger.dart';

class FirebaseBootstrapService {
  FirebaseBootstrapService._();

  static final FirebaseBootstrapService instance = FirebaseBootstrapService._();

  bool _initializeAttempted = false;
  bool _isReady = false;

  bool get isReady => _isReady || Firebase.apps.isNotEmpty;

  Future<bool> initialize() async {
    if (_initializeAttempted) {
      return isReady;
    }
    _initializeAttempted = true;

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
  }
}
