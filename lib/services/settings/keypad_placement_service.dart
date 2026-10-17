import 'package:shared_preferences/shared_preferences.dart';

/// 아이패드 게임 화면의 키패드 위치.
///
/// 세로형은 [center](기본)·[left]·[right], 가로형은 숫자 패널이 [left]·[right]
/// (기본 [right])만 쓴다. 두 방향의 값은 따로 저장한다.
enum KeypadPlacement { center, left, right }

class KeypadPlacementService {
  KeypadPlacementService({SharedPreferences? prefs}) : _prefs = prefs;

  static const String portraitKey = 'keypad_placement_portrait_v1';
  static const String landscapeKey = 'keypad_placement_landscape_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _resolvedPrefs async {
    final existing = _prefs;
    if (existing != null) return existing;
    final loaded = await SharedPreferences.getInstance();
    _prefs = loaded;
    return loaded;
  }

  Future<KeypadPlacement> portrait() async {
    final prefs = await _resolvedPrefs;
    return _parse(prefs.getString(portraitKey)) ?? KeypadPlacement.center;
  }

  /// 가로형에는 가운데가 없어, 저장값이 없거나 가운데면 오른쪽으로 본다.
  Future<KeypadPlacement> landscape() async {
    final prefs = await _resolvedPrefs;
    final value = _parse(prefs.getString(landscapeKey));
    return value == KeypadPlacement.left
        ? KeypadPlacement.left
        : KeypadPlacement.right;
  }

  Future<void> setPortrait(KeypadPlacement value) async {
    final prefs = await _resolvedPrefs;
    await prefs.setString(portraitKey, value.name);
  }

  Future<void> setLandscape(KeypadPlacement value) async {
    final prefs = await _resolvedPrefs;
    await prefs.setString(landscapeKey, value.name);
  }

  static KeypadPlacement? _parse(String? name) {
    for (final value in KeypadPlacement.values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
