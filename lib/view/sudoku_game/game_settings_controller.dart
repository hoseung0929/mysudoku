import 'package:mysudoku/services/app_settings_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class GameViewSettings {
  const GameViewSettings({
    required this.isVibrationEnabled,
    required this.keepScreenAwake,
    required this.oneHandModeEnabled,
    required this.memoHighlightEnabled,
    required this.smartHintHighlightEnabled,
  });

  final bool isVibrationEnabled;
  final bool keepScreenAwake;
  final bool oneHandModeEnabled;
  final bool memoHighlightEnabled;
  final bool smartHintHighlightEnabled;
}

class GameSettingsController {
  GameSettingsController({AppSettingsService? appSettingsService})
      : _appSettingsService = appSettingsService ?? AppSettingsService();

  final AppSettingsService _appSettingsService;
  bool _keepScreenAwakeApplied = false;

  Future<GameViewSettings> load() async {
    final vibrationEnabled = await _appSettingsService.getBool(
      AppSettingsService.vibrationEnabledKey,
      defaultValue: true,
    );
    final keepScreenAwake = await _appSettingsService.getBool(
      AppSettingsService.keepScreenAwakeKey,
      defaultValue: false,
    );
    final oneHandModeEnabled = await _appSettingsService.getBool(
      AppSettingsService.oneHandModeEnabledKey,
      defaultValue: false,
    );
    final memoHighlightEnabled = await _appSettingsService.getBool(
      AppSettingsService.memoHighlightEnabledKey,
      defaultValue: true,
    );
    final smartHintHighlightEnabled = await _appSettingsService.getBool(
      AppSettingsService.smartHintHighlightEnabledKey,
      defaultValue: true,
    );

    await WakelockPlus.toggle(enable: keepScreenAwake);
    _keepScreenAwakeApplied = keepScreenAwake;

    return GameViewSettings(
      isVibrationEnabled: vibrationEnabled,
      keepScreenAwake: keepScreenAwake,
      oneHandModeEnabled: oneHandModeEnabled,
      memoHighlightEnabled: memoHighlightEnabled,
      smartHintHighlightEnabled: smartHintHighlightEnabled,
    );
  }

  Future<void> dispose() async {
    if (_keepScreenAwakeApplied) {
      await WakelockPlus.disable();
      _keepScreenAwakeApplied = false;
    }
  }
}
