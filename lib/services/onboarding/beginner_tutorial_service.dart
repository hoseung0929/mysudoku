import 'package:shared_preferences/shared_preferences.dart';

enum BeginnerTutorialState { unseen, completed, dismissed }

/// 초보자용 첫 게임 가이드를 봤는지 여부를 로컬에 저장한다.
/// 문자열 키를 화면 코드에서 직접 다루지 않도록 이 서비스 하나로 캡슐화한다.
class BeginnerTutorialService {
  BeginnerTutorialService({SharedPreferences? prefs}) : _prefs = prefs;

  static const String stateKey = 'beginner_tutorial_state_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _resolvedPrefs async {
    final existing = _prefs;
    if (existing != null) return existing;
    final loaded = await SharedPreferences.getInstance();
    _prefs = loaded;
    return loaded;
  }

  Future<BeginnerTutorialState> getState() async {
    final prefs = await _resolvedPrefs;
    final raw = prefs.getString(stateKey);
    switch (raw) {
      case 'completed':
        return BeginnerTutorialState.completed;
      case 'dismissed':
        return BeginnerTutorialState.dismissed;
      default:
        return BeginnerTutorialState.unseen;
    }
  }

  Future<void> markCompleted() async {
    final prefs = await _resolvedPrefs;
    await prefs.setString(stateKey, 'completed');
  }

  Future<void> markDismissed() async {
    final prefs = await _resolvedPrefs;
    await prefs.setString(stateKey, 'dismissed');
  }
}
