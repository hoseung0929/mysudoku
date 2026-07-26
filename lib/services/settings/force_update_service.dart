import 'dart:io' show Platform;

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  static const String _minVersionIosKey = 'min_version_ios';
  static const String _minVersionAndroidKey = 'min_version_android';
  static const String _updateUrlIosKey = 'update_url_ios';
  static const String _updateUrlAndroidKey = 'update_url_android';

  Future<ForceUpdateInfo?> checkForUpdate() async {
    try {
      final remoteConfig = _remoteConfig ??= FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(hours: 6),
        ),
      );
      await remoteConfig.setDefaults(const {
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
