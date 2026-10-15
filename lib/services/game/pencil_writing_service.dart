import 'package:shared_preferences/shared_preferences.dart';

/// Apple Pencil 필기 입력 설정(켜짐 여부, 최초 안내 확인 여부)을 저장한다.
/// 필기 획·이미지는 저장하지 않는다.
class PencilWritingService {
  PencilWritingService({SharedPreferences? prefs}) : _prefs = prefs;

  static const String _enabledKey = 'pencil_writing_enabled_v1';
  static const String _coachmarkKey = 'pencil_writing_coachmark_seen_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _resolvedPrefs async {
    final existing = _prefs;
    if (existing != null) return existing;
    final loaded = await SharedPreferences.getInstance();
    _prefs = loaded;
    return loaded;
  }

  /// 최초 기본값은 꺼짐.
  Future<bool> isEnabled() async {
    final prefs = await _resolvedPrefs;
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await _resolvedPrefs;
    await prefs.setBool(_enabledKey, value);
  }

  Future<bool> hasSeenCoachmark() async {
    final prefs = await _resolvedPrefs;
    return prefs.getBool(_coachmarkKey) ?? false;
  }

  Future<void> markCoachmarkSeen() async {
    final prefs = await _resolvedPrefs;
    await prefs.setBool(_coachmarkKey, true);
  }
}
