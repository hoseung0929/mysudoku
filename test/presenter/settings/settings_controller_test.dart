import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/presenter/settings/settings_controller.dart';
import 'package:sudoku159/services/settings/app_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('notifications default to off on a new install', () async {
    SharedPreferences.setMockInitialValues({});

    final state = await SettingsController().load();

    expect(state.notificationsEnabled, isFalse);
  });

  test(
      'turning notifications on in settings is saved and marks the prompt '
      'as seen', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = SettingsController();
    final enabled =
        await controller.setNotificationsEnabled(await controller.load(), true);
    final prefs = await SharedPreferences.getInstance();

    expect(enabled.notificationsEnabled, isTrue);
    expect((await controller.load()).notificationsEnabled, isTrue);
    expect(
      prefs.getBool(AppSettingsService.notificationOptInPromptSeenKey),
      isTrue,
    );
  });

  test('notification preference is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = SettingsController();
    final initial = await controller.load();

    final disabled = await controller.setNotificationsEnabled(initial, false);
    final reloaded = await controller.load();

    expect(disabled.notificationsEnabled, isFalse);
    expect(reloaded.notificationsEnabled, isFalse);
  });
}
