import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const String vibrationEnabledKey = 'vibration_enabled';
  static const String keepScreenAwakeKey = 'keep_screen_awake';
  static const String highContrastEnabledKey = 'high_contrast_enabled';
  static const String largeTextEnabledKey = 'large_text_enabled';
  static const String memoHighlightEnabledKey = 'memo_highlight_enabled';
  static const String smartHintHighlightEnabledKey =
      'smart_hint_highlight_enabled';
  static const String oneHandModeEnabledKey = 'one_hand_mode_enabled';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String streakReminderEnabledKey = 'streak_reminder_enabled';
  static const String gameCompleteNotificationEnabledKey =
      'game_complete_notification_enabled';
  static const String dailyGoalNotificationEnabledKey =
      'daily_goal_notification_enabled';
  static const String notificationHourKey = 'notification_hour';
  static const String notificationMinuteKey = 'notification_minute';

  Future<bool> getBool(String key, {required bool defaultValue}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
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
