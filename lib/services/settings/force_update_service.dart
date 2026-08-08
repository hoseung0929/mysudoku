import 'dart:io' show Platform;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:sudoku159/constants/app_config.dart';
import 'package:sudoku159/utils/app_logger.dart';

class ForceUpdateInfo {
  const ForceUpdateInfo({required this.updateUrl});

  final String updateUrl;
}

class ForceUpdateService {
  ForceUpdateService({
    FirebaseRemoteConfig? remoteConfig,
    PackageInfo? packageInfo,
  })  : _remoteConfig = remoteConfig,
        _packageInfo = packageInfo;

  FirebaseRemoteConfig? _remoteConfig;
  PackageInfo? _packageInfo;

  // Firebase 프로젝트를 global/japan이 공유하므로, 강제 업데이트 최소버전이
  // 서로 덮어쓰지 않도록 japan은 별도 키를 씁니다.
  static String get _minVersionIosKey =>
      AppConfig.isJapan ? 'min_version_ios_japan' : 'min_version_ios';
  static String get _minVersionAndroidKey => AppConfig.isJapan
      ? 'min_version_android_japan'
      : 'min_version_android';
  static String get _updateUrlIosKey =>
      AppConfig.isJapan ? 'update_url_ios_japan' : 'update_url_ios';
  static String get _updateUrlAndroidKey => AppConfig.isJapan
      ? 'update_url_android_japan'
      : 'update_url_android';

  Future<ForceUpdateInfo?> checkForUpdate() async {
    try {
      final remoteConfig = _remoteConfig ??= FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 6),
        ),
      );
      await remoteConfig.setDefaults({
        _minVersionIosKey: '',
        _minVersionAndroidKey: '',
        _updateUrlIosKey: '',
        _updateUrlAndroidKey: '',
      });
      await remoteConfig.fetchAndActivate().timeout(const Duration(seconds: 10));

      final minVersion = remoteConfig
          .getString(Platform.isIOS ? _minVersionIosKey : _minVersionAndroidKey)
          .trim();
      final updateUrl = remoteConfig
          .getString(Platform.isIOS ? _updateUrlIosKey : _updateUrlAndroidKey)
          .trim();
      if (minVersion.isEmpty || updateUrl.isEmpty) {
        return null;
      }

      final packageInfo = _packageInfo ??= await PackageInfo.fromPlatform();
      if (isVersionBelow(packageInfo.version, minVersion)) {
        return ForceUpdateInfo(updateUrl: updateUrl);
      }
      return null;
    } catch (e) {
      if (kDebugMode) AppLogger.debug('강제 업데이트 확인 실패: $e');
      return null;
    }
  }

  static bool isVersionBelow(String current, String requiredMinVersion) {
    final currentParts = _parseVersion(current);
    final requiredParts = _parseVersion(requiredMinVersion);
    final length = currentParts.length > requiredParts.length
        ? currentParts.length
        : requiredParts.length;
    for (var i = 0; i < length; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final r = i < requiredParts.length ? requiredParts[i] : 0;
      if (c != r) return c < r;
    }
    return false;
  }

  static List<int> _parseVersion(String version) {
    return version
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }
}
