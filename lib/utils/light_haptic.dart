import 'package:flutter/services.dart';
import 'package:sudoku159/services/settings/app_settings_service.dart';

/// 가벼운 선택 햅틱. 설정에서 진동이 꺼져 있으면 아무것도 하지 않는다.
/// 실패해도 화면 동작에는 영향을 주지 않는다.
Future<void> lightHaptic({AppSettingsService? settings}) async {
  try {
    final enabled = await (settings ?? AppSettingsService()).getBool(
      AppSettingsService.vibrationEnabledKey,
      defaultValue: true,
    );
    if (enabled) await HapticFeedback.selectionClick();
  } catch (_) {}
}
