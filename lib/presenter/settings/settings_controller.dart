import 'package:flutter/material.dart';
import 'package:sudoku159/services/settings/app_settings_service.dart';

class SettingsState {
  const SettingsState({
    required this.notificationsEnabled,
    required this.isVibrationEnabled,
    required this.keepScreenAwake,
    required this.oneHandModeEnabled,
    required this.memoHighlightEnabled,
    required this.themeMode,
  });

  final bool notificationsEnabled;
  final bool isVibrationEnabled;
  final bool keepScreenAwake;
  final bool oneHandModeEnabled;
  final bool memoHighlightEnabled;
  final ThemeMode themeMode;

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? isVibrationEnabled,
    bool? keepScreenAwake,
    bool? oneHandModeEnabled,
    bool? memoHighlightEnabled,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      oneHandModeEnabled: oneHandModeEnabled ?? this.oneHandModeEnabled,
      memoHighlightEnabled: memoHighlightEnabled ?? this.memoHighlightEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  static const SettingsState initial = SettingsState(
    notificationsEnabled: AppSettingsService.notificationsEnabledDefault,
    isVibrationEnabled: true,
    keepScreenAwake: false,
    oneHandModeEnabled: false,
    memoHighlightEnabled: true,
    themeMode: ThemeMode.system,
  );
}

class SettingsController {
  SettingsController({
    AppSettingsService? settingsService,
  }) : _settingsService = settingsService ?? AppSettingsService();

  final AppSettingsService _settingsService;

  Future<SettingsState> load() async {
    final notificationsEnabled = await _settingsService.getBool(
      AppSettingsService.notificationsEnabledKey,
      defaultValue: AppSettingsService.notificationsEnabledDefault,
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
    final themeModeIndex = await _settingsService.getInt(
      AppSettingsService.themeModeKey,
      defaultValue: ThemeMode.system.index,
    );

    return SettingsState(
      notificationsEnabled: notificationsEnabled,
      isVibrationEnabled: vibrationEnabled,
      keepScreenAwake: keepScreenAwake,
      oneHandModeEnabled: oneHandModeEnabled,
      memoHighlightEnabled: memoHighlightEnabled,
      themeMode: ThemeMode
          .values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)],
    );
  }

  Future<SettingsState> setNotificationsEnabled(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(
      AppSettingsService.notificationsEnabledKey,
      value,
    );
    // 설정에서 직접 선택했으면 첫 완료 후 알림 안내를 다시 띄우지 않는다.
    await _settingsService.setBool(
      AppSettingsService.notificationOptInPromptSeenKey,
      true,
    );
    return state.copyWith(notificationsEnabled: value);
  }

  Future<SettingsState> setVibrationEnabled(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(
        AppSettingsService.vibrationEnabledKey, value);
    return state.copyWith(isVibrationEnabled: value);
  }

  Future<SettingsState> setKeepScreenAwake(
    SettingsState state,
    bool value,
  ) async {
    await _settingsService.setBool(
        AppSettingsService.keepScreenAwakeKey, value);
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

  Future<SettingsState> setThemeMode(
    SettingsState state,
    ThemeMode value,
  ) async {
    await _settingsService.setInt(AppSettingsService.themeModeKey, value.index);
    return state.copyWith(themeMode: value);
  }
}
