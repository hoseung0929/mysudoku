import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String localeKey = 'app_locale';
  static const String notificationsEnabledKey = 'notifications_enabled';

  /// 저장값이 없을 때의 알림 설정. 신규 설치는 끈 상태로 시작하고, 첫 퍼즐
  /// 완료 후 안내를 거쳐 사용자가 직접 켠다.
  static const bool notificationsEnabledDefault = false;

  /// 첫 완료 후 알림 안내를 이미 보여 줬는지(반복 노출 방지).
  static const String notificationOptInPromptSeenKey =
      'notification_opt_in_prompt_seen';
  static const String vibrationEnabledKey = 'vibration_enabled';
  static const String keepScreenAwakeKey = 'keep_screen_awake';
  static const String memoHighlightEnabledKey = 'memo_highlight_enabled';
  static const String smartHintHighlightEnabledKey =
      'smart_hint_highlight_enabled';
  static const String oneHandModeEnabledKey = 'one_hand_mode_enabled';
  // int: ThemeMode.index (0=system, 1=light, 2=dark). 키 없으면 system(0) 기본값.
  static const String themeModeKey = 'theme_mode';

  Future<bool> getBool(String key, {required bool defaultValue}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  /// 저장값이 없으면 null(기본값과 "사용자가 저장한 값"을 구분할 때 사용).
  Future<bool?> getStoredBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<int> getInt(String key, {required int defaultValue}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }
}
