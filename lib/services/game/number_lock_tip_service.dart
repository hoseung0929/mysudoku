import 'package:shared_preferences/shared_preferences.dart';

/// 숫자 고정(길게 누르기) 사용법을 한 번만 안내했는지 저장한다.
class NumberLockTipService {
  NumberLockTipService({SharedPreferences? prefs}) : _prefs = prefs;

  static const String _shownKey = 'number_lock_tip_shown_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _resolvedPrefs async {
    final existing = _prefs;
    if (existing != null) return existing;
    final loaded = await SharedPreferences.getInstance();
    _prefs = loaded;
    return loaded;
  }

  Future<bool> hasShownTip() async {
    final prefs = await _resolvedPrefs;
    return prefs.getBool(_shownKey) ?? false;
  }

  Future<void> markTipShown() async {
    final prefs = await _resolvedPrefs;
    await prefs.setBool(_shownKey, true);
  }
}
