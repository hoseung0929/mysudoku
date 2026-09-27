import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/settings/app_settings_service.dart';
import 'package:sudoku159/services/settings/notification_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:sudoku159/view/settings/settings_screen.dart';

import '../../helpers/fake_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  const failureText =
      "We couldn't set up reminders. Please try again later in Settings.";

  Finder notificationSwitch() => find.ancestor(
        of: find.byIcon(Icons.notifications_active_outlined),
        matching: find.byType(SwitchListTile),
      );

  SwitchListTile tile(WidgetTester tester) =>
      tester.widget<SwitchListTile>(notificationSwitch());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpSettings(
    WidgetTester tester,
    FakeGateway gateway, {
    Map<String, Object> prefs = const {},
    Size size = const Size(390, 844),
    double textScale = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: SettingsScreen(
          notificationService: notificationServiceWith(gateway),
        ),
      ),
    );
    await settle(tester);
  }

  Future<bool?> enabledPref() async => (await SharedPreferences.getInstance())
      .getBool(AppSettingsService.notificationsEnabledKey);

  testWidgets('ON only after permission and scheduling both succeed',
      (tester) async {
    final gateway = FakeGateway();
    await pumpSettings(tester, gateway);
    expect(tile(tester).value, isFalse);

    await tester.tap(notificationSwitch());
    await settle(tester);
    expect(tile(tester).value, isTrue);
    expect(await enabledPref(), isTrue);
    expect(gateway.pending, hasLength(7));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('permission denied returns the switch to OFF', (tester) async {
    final gateway = FakeGateway(grant: false);
    await pumpSettings(tester, gateway);
    await tester.tap(notificationSwitch());
    await settle(tester);
    expect(tile(tester).value, isFalse);
    expect(await enabledPref(), isFalse);
    expect(
      find.text('Notification permission is required to turn reminders on.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(failureText), findsNothing);
  });

  for (final failure in [
    (
      name: 'permission error',
      gateway: () => FakeGateway(throwOnPermission: true)
    ),
    (
      name: 'scheduling error',
      gateway: () => FakeGateway(throwOnScheduleAt: 4)
    ),
  ]) {
    testWidgets('${failure.name} returns to OFF and clears reminders',
        (tester) async {
      final gateway = failure.gateway();
      await pumpSettings(tester, gateway);
      await tester.tap(notificationSwitch());
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(tile(tester).value, isFalse);
      expect(await enabledPref(), isFalse);
      expect(gateway.pending, isEmpty);
      expect(find.text(failureText), findsOneWidget);
      expect(tile(tester).onChanged, isNotNull);
    });
  }

  testWidgets('switch is locked while a change is in progress', (tester) async {
    final gateway = FakeGateway()..holdPermission = Completer();
    await pumpSettings(tester, gateway);

    await tester.tap(notificationSwitch());
    await tester.pump();
    expect(tile(tester).onChanged, isNull);
    await tester.tap(notificationSwitch());
    await tester.pump();
    expect(gateway.permissionRequests, 1);

    gateway.holdPermission!.complete();
    await settle(tester);
    expect(tile(tester).value, isTrue);
    expect(tile(tester).onChanged, isNotNull);
    expect(gateway.pending, hasLength(7));
  });

  testWidgets('turning OFF cancels reminders and keeps OFF on cancel errors',
      (tester) async {
    for (final throwOnCancel in [false, true]) {
      final gateway = FakeGateway(throwOnCancel: throwOnCancel);
      await tester.pumpWidget(const SizedBox()); // 이전 회차 화면 상태 제거
      await pumpSettings(
        tester,
        gateway,
        prefs: {AppSettingsService.notificationsEnabledKey: true},
      );
      expect(tile(tester).value, isTrue);
      await tester.tap(notificationSwitch());
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(tile(tester).value, isFalse, reason: '$throwOnCancel');
      expect(await enabledPref(), isFalse);
      if (!throwOnCancel) {
        expect(
          gateway.cancelled,
          containsAll(NotificationService.dailyReminderIds),
        );
      }
      expect(gateway.permissionRequests, 0);
    }
  });

  testWidgets('small screen with large text while busy has no overflow',
      (tester) async {
    final gateway = FakeGateway()..holdPermission = Completer();
    await pumpSettings(
      tester,
      gateway,
      size: const Size(320, 568),
      textScale: 2.0,
    );
    await tester.ensureVisible(notificationSwitch());
    await tester.pumpAndSettle();
    await tester.tap(notificationSwitch());
    await tester.pump();
    expect(tester.takeException(), isNull);
    // 실제로 눌려서 busy(잠금) 상태가 됐는지 확인한다.
    expect(tile(tester).onChanged, isNull);
    gateway.holdPermission!.complete();
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(tile(tester).onChanged, isNotNull);
  });
}
