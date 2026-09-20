import 'package:flutter/material.dart';
import 'package:sudoku159/services/settings/app_settings_service.dart';

class SettingsState {
  const SettingsState({
    required this.isVibrationEnabled,
    required this.keepScreenAwake,
    required this.oneHandModeEnabled,
    required this.memoHighlightEnabled,
    required this.themeMode,
  });

  final bool isVibrationEnabled;
  final bool keepScreenAwake;
  final bool oneHandModeEnabled;
  final bool memoHighlightEnabled;
  final ThemeMode themeMode;

  SettingsState copyWith({
    bool? isVibrationEnabled,
    bool? keepScreenAwake,
    bool? oneHandModeEnabled,
    bool? memoHighlightEnabled,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      oneHandModeEnabled: oneHandModeEnabled ?? this.oneHandModeEnabled,
      memoHighlightEnabled: memoHighlightEnabled ?? this.memoHighlightEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  static const SettingsState initial = SettingsState(
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
      isVibrationEnabled: vibrationEnabled,
      keepScreenAwake: keepScreenAwake,
      oneHandModeEnabled: oneHandModeEnabled,
      memoHighlightEnabled: memoHighlightEnabled,
      themeMode: ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)],
    );
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
