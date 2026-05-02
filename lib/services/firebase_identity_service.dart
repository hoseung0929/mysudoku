import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:mysudoku/services/firebase_bootstrap_service.dart';
import 'package:mysudoku/utils/app_logger.dart';

class FirebaseIdentityStatus {
  const FirebaseIdentityStatus({
    required this.isAvailable,
    required this.isSignedIn,
    required this.isAnonymous,
    this.email,
    this.uid,
  });

  const FirebaseIdentityStatus.unavailable()
      : isAvailable = false,
        isSignedIn = false,
        isAnonymous = false,
        email = null,
        uid = null;

  final bool isAvailable;
  final bool isSignedIn;
  final bool isAnonymous;
  final String? email;
  final String? uid;

  bool get isCrossDeviceReady => isAvailable && isSignedIn && !isAnonymous;
}

class FirebaseIdentityException implements Exception {
  const FirebaseIdentityException({
    required this.code,
    this.message,
  });

  final String code;
  final String? message;
}

class FirebaseIdentityService {
  FirebaseIdentityService({
    FirebaseAuth? auth,
    FirebaseBootstrapService? bootstrapService,
  })  : _auth = auth,
        _bootstrapService = bootstrapService ?? FirebaseBootstrapService.instance;

  FirebaseAuth? _auth;
  final FirebaseBootstrapService _bootstrapService;

  FirebaseAuth get _resolvedAuth => _auth ??= FirebaseAuth.instance;

  User? get currentUser =>
      _bootstrapService.isReady ? _resolvedAuth.currentUser : null;

  bool get isSignedIn => currentUser != null;

  bool get isAnonymousUser => currentUser?.isAnonymous ?? false;

  Future<FirebaseIdentityStatus> loadStatus() async {
    final isReady = await _bootstrapService.initialize();
    if (!isReady) {
      return const FirebaseIdentityStatus.unavailable();
    }

    return _statusFromUser(_resolvedAuth.currentUser);
  }

  Future<User?> ensureSignedIn() async {
    if (!await _bootstrapService.initialize()) {
      return null;
    }

    final existingUser = _resolvedAuth.currentUser;
    if (existingUser != null) {
      return existingUser;
    }

    try {
      final credential = await _resolvedAuth.signInAnonymously();
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (_shouldSilenceAnonymousSignInError(e.code)) {
        return null;
      }
      if (kDebugMode) {
        AppLogger.debug('익명 로그인 건너뜀(${e.code}): ${e.message ?? e}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('익명 로그인 건너뜀: $e');
      }
      return null;
    }
  }

  Future<FirebaseIdentityStatus> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!await _bootstrapService.initialize()) {
      throw const FirebaseIdentityException(code: 'firebase-unavailable');
    }

    try {
      final credential = await _resolvedAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _statusFromUser(credential.user);
    } on FirebaseAuthException catch (e) {
      throw FirebaseIdentityException(code: e.code, message: e.message);
    }
  }

  Future<FirebaseIdentityStatus> createOrLinkWithEmail({
    required String email,
    required String password,
  }) async {
    if (!await _bootstrapService.initialize()) {
      throw const FirebaseIdentityException(code: 'firebase-unavailable');
    }

    try {
      final currentUser = _resolvedAuth.currentUser;
      if (currentUser != null && currentUser.isAnonymous) {
        final credential = EmailAuthProvider.credential(
          email: email.trim(),
          password: password,
        );
        final linked = await currentUser.linkWithCredential(credential);
        return _statusFromUser(linked.user);
      }

      final created = await _resolvedAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _statusFromUser(created.user);
    } on FirebaseAuthException catch (e) {
      throw FirebaseIdentityException(code: e.code, message: e.message);
    }
  }

  Future<FirebaseIdentityStatus> signOut() async {
    if (!await _bootstrapService.initialize()) {
      return const FirebaseIdentityStatus.unavailable();
    }

    await _resolvedAuth.signOut();
    return _statusFromUser(_resolvedAuth.currentUser);
  }

  FirebaseIdentityStatus _statusFromUser(User? user) {
    if (!_bootstrapService.isReady) {
      return const FirebaseIdentityStatus.unavailable();
    }

    if (user == null) {
      return const FirebaseIdentityStatus(
        isAvailable: true,
        isSignedIn: false,
        isAnonymous: false,
      );
    }

    return FirebaseIdentityStatus(
      isAvailable: true,
      isSignedIn: true,
      isAnonymous: user.isAnonymous,
      email: user.email,
      uid: user.uid,
    );
  }

  bool _shouldSilenceAnonymousSignInError(String code) {
    switch (code) {
      case 'internal-error':
      case 'network-request-failed':
      case 'operation-not-allowed':
        return true;
      default:
        return false;
    }
  }
}
