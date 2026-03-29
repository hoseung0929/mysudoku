import 'package:flutter/material.dart';
import 'package:mysudoku/services/app_settings_service.dart';
import 'package:mysudoku/services/notification_service.dart';

class SettingsState {
  const SettingsState({
    required this.isVibrationEnabled,
    required this.notificationsEnabled,
    required this.streakReminderEnabled,
    required this.gameCompleteNotificationEnabled,
    required this.dailyGoalNotificationEnabled,
    required this.keepScreenAwake,
    required this.oneHandModeEnabled,
    required this.memoHighlightEnabled,
    required this.smartHintHighlightEnabled,
    required this.notificationTime,
  });

  final bool isVibrationEnabled;
  final bool notificationsEnabled;
  final bool streakReminderEnabled;
  final bool gameCompleteNotificationEnabled;
  final bool dailyGoalNotificationEnabled;
  final bool keepScreenAwake;
  final bool oneHandModeEnabled;
  final bool memoHighlightEnabled;
  final bool smartHintHighlightEnabled;
  final TimeOfDay notificationTime;

  SettingsState copyWith({
    bool? isVibrationEnabled,
    bool? notificationsEnabled,
    bool? streakReminderEnabled,
    bool? gameCompleteNotificationEnabled,
    bool? dailyGoalNotificationEnabled,
    bool? keepScreenAwake,
    bool? oneHandModeEnabled,
    bool? memoHighlightEnabled,
    bool? smartHintHighlightEnabled,
    TimeOfDay? notificationTime,
  }) {
    return SettingsState(
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      streakReminderEnabled:
          streakReminderEnabled ?? this.streakReminderEnabled,
      gameCompleteNotificationEnabled:
          gameCompleteNotificationEnabled ??
          this.gameCompleteNotificationEnabled,
      dailyGoalNotificationEnabled:
          dailyGoalNotificationEnabled ?? this.dailyGoalNotificationEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      oneHandModeEnabled: oneHandModeEnabled ?? this.oneHandModeEnabled,
      memoHighlightEnabled:
          memoHighlightEnabled ?? this.memoHighlightEnabled,
      smartHintHighlightEnabled:
          smartHintHighlightEnabled ?? this.smartHintHighlightEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }

  static const SettingsState initial = SettingsState(
    isVibrationEnabled: true,
    notificationsEnabled: false,
    streakReminderEnabled: false,
    gameCompleteNotificationEnabled: false,
    dailyGoalNotificationEnabled: false,
    keepScreenAwake: false,
    oneHandModeEnabled: false,
    memoHighlightEnabled: true,
    smartHintHighlightEnabled: true,
    notificationTime: TimeOfDay(
      hour: NotificationService.defaultReminderHour,
      minute: NotificationService.defaultReminderMinute,
    ),
  );
}

class SettingsController {
  SettingsController({
    AppSettingsService? settingsService,
    NotificationService? notificationService,
  })  : _settingsService = settingsService ?? AppSettingsService(),
        _notificationService = notificationService ?? NotificationService();

  final AppSettingsService _settingsService;
  final NotificationService _notificationService;

  Future<SettingsState> load() async {
    final notificationsEnabled = await _settingsService.getBool(
      AppSettingsService.notificationsEnabledKey,
      defaultValue: false,
    );
    final streakReminderEnabled = await _settingsService.getBool(
      AppSettingsService.streakReminderEnabledKey,
      defaultValue: false,
    );
    final gameCompleteNotificationEnabled = await _settingsService.getBool(
      AppSettingsService.gameCompleteNotificationEnabledKey,
      defaultValue: false,
    );
    final dailyGoalNotificationEnabled = await _settingsService.getBool(
      AppSettingsService.dailyGoalNotificationEnabledKey,
      defaultValue: false,
    );
    final notificationHour = await _settingsService.getInt(
      AppSettingsService.notificationHourKey,
      defaultValue: NotificationService.defaultReminderHour,
    );
    final notificationMinute = await _settingsService.getInt(
      AppSettingsService.notificationMinuteKey,
      defaultValue: NotificationService.defaultReminderMinute,
    );
    final vibrationEnabled = await _settingsService.getBool(
      AppSettingsService.vibrationEnabledKey,
      defaultValue: true,
    );
    final keepScreenAwake = await _settingsService.getBool(
      AppSettingsService.keepScreenAwakeKey,
      defaultValue: false,
    );
    final oneHandModeEnabled = await _settingsService.getBool(
      AppSettingsService.oneHandModeEnabledKey,
      defaultValue: false,
    );
    final memoHighlightEnabled = await _settingsService.getBool(
      AppSettingsService.memoHighlightEnabledKey,
      defaultValue: true,
    );
    final smartHintHighlightEnabled = await _settingsService.getBool(
      AppSettingsService.smartHintHighlightEnabledKey,
      defaultValue: true,
    );

    return SettingsState(
      notificationsEnabled: notificationsEnabled,
      streakReminderEnabled: streakReminderEnabled,
      gameCompleteNotificationEnabled: gameCompleteNotificationEnabled,
      dailyGoalNotificationEnabled: dailyGoalNotificationEnabled,
      notificationTime: TimeOfDay(
        hour: notificationHour,
        minute: notificationMinute,
      ),
      isVibrationEnabled: vibrationEnabled,
      keepScreenAwake: keepScreenAwake,
      oneHandModeEnabled: oneHandModeEnabled,
      memoHighlightEnabled: memoHighlightEnabled,
      smartHintHighlightEnabled: smartHintHighlightEnabled,
    );
  }

  Future<SettingsState> setVibrationEnabled(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(AppSettingsService.vibrationEnabledKey, value);
    return state.copyWith(isVibrationEnabled: value);
  }

  Future<bool> requestNotificationPermissions() async {
    return _notificationService.requestPermissions();
  }

  Future<SettingsState> setNotificationsEnabled(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(
      AppSettingsService.notificationsEnabledKey,
      value,
    );
    await _notificationService.syncReminders(
      challengeReminderEnabled: value,
      streakReminderEnabled: state.streakReminderEnabled,
      hour: state.notificationTime.hour,
      minute: state.notificationTime.minute,
    );
    return state.copyWith(notificationsEnabled: value);
  }

  Future<SettingsState> setStreakReminderEnabled(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(
      AppSettingsService.streakReminderEnabledKey,
      value,
    );
    await _notificationService.syncReminders(
      challengeReminderEnabled: state.notificationsEnabled,
      streakReminderEnabled: value,
      hour: state.notificationTime.hour,
      minute: state.notificationTime.minute,
    );
    return state.copyWith(streakReminderEnabled: value);
  }

  Future<SettingsState> setGameCompleteNotificationEnabled(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(
      AppSettingsService.gameCompleteNotificationEnabledKey,
      value,
    );
    return state.copyWith(gameCompleteNotificationEnabled: value);
  }

  Future<SettingsState> setDailyGoalNotificationEnabled(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(
      AppSettingsService.dailyGoalNotificationEnabledKey,
      value,
    );
    return state.copyWith(dailyGoalNotificationEnabled: value);
  }

  Future<SettingsState> setNotificationTime(
    SettingsState state,
    TimeOfDay selected,
  ) async {
    await _settingsService.setInt(
      AppSettingsService.notificationHourKey,
      selected.hour,
    );
    await _settingsService.setInt(
      AppSettingsService.notificationMinuteKey,
      selected.minute,
    );
    await _notificationService.syncReminders(
      challengeReminderEnabled: state.notificationsEnabled,
      streakReminderEnabled: state.streakReminderEnabled,
      hour: selected.hour,
      minute: selected.minute,
    );
    return state.copyWith(notificationTime: selected);
  }

  Future<SettingsState> setKeepScreenAwake(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(AppSettingsService.keepScreenAwakeKey, value);
    return state.copyWith(keepScreenAwake: value);
  }

  Future<SettingsState> setOneHandModeEnabled(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(
      AppSettingsService.oneHandModeEnabledKey,
      value,
    );
    return state.copyWith(oneHandModeEnabled: value);
  }

  Future<SettingsState> setMemoHighlightEnabled(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(
      AppSettingsService.memoHighlightEnabledKey,
      value,
    );
    return state.copyWith(memoHighlightEnabled: value);
  }

  Future<SettingsState> setSmartHintHighlightEnabled(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(
      AppSettingsService.smartHintHighlightEnabledKey,
      value,
    );
    return state.copyWith(smartHintHighlightEnabled: value);
  }
}
