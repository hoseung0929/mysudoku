import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class InstallIdService {
  InstallIdService({SharedPreferences? prefs}) : _prefs = prefs;

  static const String installIdKey = 'install_id';

  SharedPreferences? _prefs;

  Future<String> getOrCreate() async {
    final prefs = await _resolvedPrefs;
    final existing = prefs.getString(installIdKey)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = _generateInstallId();
    await prefs.setString(installIdKey, created);
    return created;
  }

  Future<SharedPreferences> get _resolvedPrefs async {
    final existing = _prefs;
    if (existing != null) {
      return existing;
    }
    final loaded = await SharedPreferences.getInstance();
    _prefs = loaded;
    return loaded;
  }

  String _generateInstallId() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final random = Random.secure();
    final suffix = List.generate(
      16,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return 'install-$now-$suffix';
  }
}
