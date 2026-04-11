import 'package:flutter/material.dart';
import 'package:mysudoku/services/app_settings_service.dart';
import 'package:mysudoku/services/firebase_identity_service.dart';
import 'package:mysudoku/services/game_state_service.dart';
import 'package:mysudoku/services/notification_service.dart';

class CloudAccountState {
  const CloudAccountState({
    required this.isAvailable,
    required this.isSignedIn,
    required this.isAnonymous,
    this.email,
    this.uid,
  });

  const CloudAccountState.unavailable()
      : isAvailable = false,
        isSignedIn = false,
        isAnonymous = false,
        email = null,
        uid = null;

  final bool isAvailable;
  final bool isSignedIn;
  final bool isAnonymous;
  final String? email;
  final String? uid;

  bool get isCrossDeviceReady => isAvailable && isSignedIn && !isAnonymous;

  String? get identifier => email ?? uid;

  factory CloudAccountState.fromIdentity(FirebaseIdentityStatus status) {
    return CloudAccountState(
      isAvailable: status.isAvailable,
      isSignedIn: status.isSignedIn,
      isAnonymous: status.isAnonymous,
      email: status.email,
      uid: status.uid,
    );
  }
}

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
    required this.notificationTime,
    required this.cloudAccount,
  });

  final bool isVibrationEnabled;
  final bool notificationsEnabled;
  final bool streakReminderEnabled;
  final bool gameCompleteNotificationEnabled;
  final bool dailyGoalNotificationEnabled;
  final bool keepScreenAwake;
  final bool oneHandModeEnabled;
  final bool memoHighlightEnabled;
  final TimeOfDay notificationTime;
  final CloudAccountState cloudAccount;

  SettingsState copyWith({
    bool? isVibrationEnabled,
    bool? notificationsEnabled,
    bool? streakReminderEnabled,
    bool? gameCompleteNotificationEnabled,
    bool? dailyGoalNotificationEnabled,
    bool? keepScreenAwake,
    bool? oneHandModeEnabled,
    bool? memoHighlightEnabled,
    TimeOfDay? notificationTime,
    CloudAccountState? cloudAccount,
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
      notificationTime: notificationTime ?? this.notificationTime,
      cloudAccount: cloudAccount ?? this.cloudAccount,
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
    notificationTime: TimeOfDay(
      hour: NotificationService.defaultReminderHour,
      minute: NotificationService.defaultReminderMinute,
    ),
    cloudAccount: CloudAccountState.unavailable(),
  );
}

class SettingsController {
  SettingsController({
    AppSettingsService? settingsService,
    NotificationService? notificationService,
    FirebaseIdentityService? identityService,
    GameStateService? gameStateService,
  })  : _settingsService = settingsService ?? AppSettingsService(),
        _notificationService = notificationService ?? NotificationService(),
        _identityService = identityService ?? FirebaseIdentityService(),
        _gameStateService = gameStateService ?? GameStateService();

  final AppSettingsService _settingsService;
  final NotificationService _notificationService;
  final FirebaseIdentityService _identityService;
  final GameStateService _gameStateService;

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
    final cloudAccount = CloudAccountState.fromIdentity(
      await _identityService.loadStatus(),
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
      cloudAccount: cloudAccount,
    );
  }

  Future<SettingsState> refreshCloudAccount(SettingsState state) async {
    return state.copyWith(
      cloudAccount: CloudAccountState.fromIdentity(
        await _identityService.loadStatus(),
      ),
    );
  }

  Future<SettingsState> signInWithEmail(
    SettingsState state, {
    required String email,
    required String password,
  }) async {
    final status = await _identityService.signInWithEmail(
      email: email,
      password: password,
    );
    await _gameStateService.syncBidirectional();
    return state.copyWith(
      cloudAccount: CloudAccountState.fromIdentity(status),
    );
  }

  Future<SettingsState> createCloudAccount(
    SettingsState state, {
    required String email,
    required String password,
  }) async {
    final status = await _identityService.createOrLinkWithEmail(
      email: email,
      password: password,
    );
    await _gameStateService.syncBidirectional();
    return state.copyWith(
      cloudAccount: CloudAccountState.fromIdentity(status),
    );
  }

  Future<SettingsState> syncCloudProgress(SettingsState state) async {
    await _gameStateService.syncBidirectional();
    return refreshCloudAccount(state);
  }

  Future<SettingsState> signOutCloudAccount(SettingsState state) async {
    final status = await _identityService.signOut();
    return state.copyWith(
      cloudAccount: CloudAccountState.fromIdentity(status),
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
}
