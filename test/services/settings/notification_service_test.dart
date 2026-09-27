import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/services/settings/app_settings_service.dart';
import 'package:sudoku159/services/settings/notification_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/fake_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  final seoul = tz.getLocation('Asia/Seoul');

  tz.TZDateTime at(int hour, {int minute = 0}) =>
      tz.TZDateTime(seoul, 2026, 9, 24, hour, minute);

  group('planReminders', () {
    test('before 8 PM without play: today plus six more days', () {
      final plans = NotificationService.planReminders(
        now: at(19, minute: 59),
        playedToday: false,
        streakDays: 0,
        locale: const Locale('ko'),
      );
      expect(plans, hasLength(7));
      expect(plans.first.when, tz.TZDateTime(seoul, 2026, 9, 24, 20));
      expect(plans.last.when, tz.TZDateTime(seoul, 2026, 9, 30, 20));
      expect(plans.map((p) => p.id), NotificationService.dailyReminderIds);
    });

    test('after 8 PM without play: starts tomorrow', () {
      final plans = NotificationService.planReminders(
        now: at(20, minute: 1),
        playedToday: false,
        streakDays: 0,
        locale: const Locale('en'),
      );
      expect(plans, hasLength(7));
      expect(plans.first.when, tz.TZDateTime(seoul, 2026, 9, 25, 20));
    });

    test('already played today: skips today, keeps the next seven days', () {
      final plans = NotificationService.planReminders(
        now: at(9),
        playedToday: true,
        streakDays: 0,
        locale: const Locale('en'),
      );
      expect(plans.first.when, tz.TZDateTime(seoul, 2026, 9, 25, 20));
      expect(plans.last.when, tz.TZDateTime(seoul, 2026, 10, 1, 20));
    });

    test('times are 8 PM in the given time zone, across month end', () {
      final ny = tz.getLocation('America/New_York');
      final plans = NotificationService.planReminders(
        now: tz.TZDateTime(ny, 2026, 10, 30, 21),
        playedToday: false,
        streakDays: 0,
        locale: const Locale('en'),
      );
      for (final plan in plans) {
        expect(plan.when.location, ny);
        expect(plan.when.hour, 20);
        expect(plan.when.minute, 0);
      }
      // 11월 1일 서머타임 종료일에도 현지 20시를 유지한다.
      expect(plans[1].when, tz.TZDateTime(ny, 2026, 11, 1, 20));
    });

    test('streak copy only where the streak is certain', () {
      final notPlayed = NotificationService.planReminders(
        now: at(10),
        playedToday: false,
        streakDays: 4,
        locale: const Locale('en'),
      );
      expect(notPlayed.first.title, contains('4'));
      expect(notPlayed.skip(1).every((p) => !p.title.contains('4')), isTrue);

      final played = NotificationService.planReminders(
        now: at(10),
        playedToday: true,
        streakDays: 5,
        locale: const Locale('en'),
      );
      // 첫 예약(내일)만 연속 문구, 이후는 일반 문구.
      expect(played.first.title, contains('5'));
      expect(played.skip(1).every((p) => !p.title.contains('5')), isTrue);

      final lateNotPlayed = NotificationService.planReminders(
        now: at(22),
        playedToday: false,
        streakDays: 4,
        locale: const Locale('en'),
      );
      // 오늘 밤에 풀지 않으면 끊기므로 내일 알림에도 숫자를 넣지 않는다.
      expect(lateNotPlayed.every((p) => !p.title.contains('4')), isTrue);
    });
  });

  group('copy', () {
    test('every supported language has distinct daily-puzzle copy', () {
      final titles = <String>{};
      for (final code in ['en', 'ko', 'ja', 'zh', 'es']) {
        final copy = NotificationService.reminderCopyForLocale(Locale(code));
        expect(copy.title, isNotEmpty, reason: code);
        expect(copy.body, isNotEmpty, reason: code);
        expect(copy.channelName, isNotEmpty, reason: code);
        titles.add(copy.title);
      }
      expect(titles, hasLength(5));
      expect(
        NotificationService.reminderCopyForLocale(const Locale('ko')).title,
        '오늘의 스도쿠 한 판을 시작해보세요',
      );
      expect(
        NotificationService.reminderCopyForLocale(const Locale('ko')).body,
        '오늘 퍼즐을 아직 완료하지 않았어요. 가볍게 한 판 풀어보세요.',
      );
    });

    test('streak copy includes the streak length in every language', () {
      for (final code in ['en', 'ko', 'ja', 'zh', 'es']) {
        final copy = NotificationService.reminderCopyForLocale(
          Locale(code),
          streakDays: 7,
        );
        expect(copy.title, contains('7'), reason: code);
        expect(copy.body, contains('7'), reason: code);
      }
    });

    test('app language overrides the device language', () {
      expect(
        NotificationService.resolveReminderLocale(
          savedLanguageCode: 'ja',
          platformLocale: const Locale('ko'),
        ).languageCode,
        'ja',
      );
      expect(
        NotificationService.resolveReminderLocale(
          savedLanguageCode: 'system',
          platformLocale: const Locale('es'),
        ).languageCode,
        'es',
      );
    });
  });

  group('syncReminders', () {
    late FakeGateway gateway;

    NotificationService service({String? lastClearDate, int streak = 0}) =>
        NotificationService(
          gateway: gateway,
          challengeProgressService: FakeProgress(
            lastClearDate: lastClearDate,
            activityStreakDays: streak,
          ),
          appSettingsService: AppSettingsService(),
          now: () => at(10),
        );

    setUp(() => gateway = FakeGateway());

    test('ON schedules seven reminders in the app language', () async {
      SharedPreferences.setMockInitialValues({
        AppSettingsService.notificationsEnabledKey: true,
        AppSettingsService.localeKey: 'ja',
      });
      await service().syncReminders();
      expect(gateway.pending.keys, NotificationService.dailyReminderIds);
      expect(
        gateway.pending.values.first.title,
        NotificationService.reminderCopyForLocale(const Locale('ja')).title,
      );
      expect(gateway.permissionRequests, 0);
    });

    test('played today: today excluded, following days kept', () async {
      SharedPreferences.setMockInitialValues({
        AppSettingsService.notificationsEnabledKey: true,
      });
      await service(lastClearDate: '2026-09-24').syncReminders();
      expect(gateway.pending, hasLength(7));
      final dates = gateway.pending.values.map((p) => p.when.day).toList();
      expect(dates.first, 25);
    });

    test('OFF (and the new default) cancels legacy and daily IDs', () async {
      for (final values in [
        {AppSettingsService.notificationsEnabledKey: false},
        <String, Object>{},
      ]) {
        SharedPreferences.setMockInitialValues(values);
        gateway = FakeGateway();
        await service().syncReminders();
        expect(gateway.pending, isEmpty);
        expect(
          gateway.cancelled,
          containsAll([
            ...NotificationService.legacyReminderIds,
            ...NotificationService.dailyReminderIds,
          ]),
        );
      }
    });

    test('repeated syncs never duplicate reminders', () async {
      SharedPreferences.setMockInitialValues({
        AppSettingsService.notificationsEnabledKey: true,
      });
      final notifications = service();
      await notifications.syncReminders();
      await notifications.syncReminders();
      await notifications.syncReminders();
      expect(gateway.pending, hasLength(7));
    });
  });

  group('bootstrapOnLaunch', () {
    NotificationService service(FakeGateway gateway) => NotificationService(
          gateway: gateway,
          challengeProgressService: FakeProgress(),
          appSettingsService: AppSettingsService(),
          now: () => at(10),
        );

    test('new install: no permission request, reminders stay off', () async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeGateway();
      await service(gateway).bootstrapOnLaunch(isIos: true);
      expect(gateway.permissionRequests, 0);
      expect(gateway.pending, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppSettingsService.notificationsEnabledKey), isNull);
    });

    test('previous-version iOS user who already allowed keeps reminders',
        () async {
      SharedPreferences.setMockInitialValues({});
      final gateway = FakeGateway()..iosGranted = true;
      await service(gateway).bootstrapOnLaunch(isIos: true);
      expect(gateway.permissionRequests, 0);
      expect(gateway.pending, hasLength(7));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppSettingsService.notificationsEnabledKey), isTrue);
      expect(
        prefs.getBool(AppSettingsService.notificationOptInPromptSeenKey),
        isTrue,
      );
    });

    test('a saved OFF choice is never overridden', () async {
      SharedPreferences.setMockInitialValues({
        AppSettingsService.notificationsEnabledKey: false,
      });
      final gateway = FakeGateway()..iosGranted = true;
      await service(gateway).bootstrapOnLaunch(isIos: true);
      expect(gateway.pending, isEmpty);
      expect(gateway.permissionRequests, 0);
    });
  });

  group('enableReminders / disableReminders', () {
    Future<bool?> enabledPref() async => (await SharedPreferences.getInstance())
        .getBool(AppSettingsService.notificationsEnabledKey);

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('granted and scheduled: ON with seven reminders', () async {
      final gateway = FakeGateway();
      final result = await notificationServiceWith(gateway).enableReminders();
      expect(result, ReminderEnableResult.enabled);
      expect(await enabledPref(), isTrue);
      expect(gateway.pending, hasLength(7));
    });

    test('denied: OFF and every reminder cancelled', () async {
      final gateway = FakeGateway(grant: false);
      final result = await notificationServiceWith(gateway).enableReminders();
      expect(result, ReminderEnableResult.denied);
      expect(await enabledPref(), isFalse);
      expect(gateway.pending, isEmpty);
      expect(
        gateway.cancelled,
        containsAll([
          ...NotificationService.legacyReminderIds,
          ...NotificationService.dailyReminderIds,
        ]),
      );
    });

    test('permission request throws: failed, OFF, cancelled', () async {
      final gateway = FakeGateway(throwOnPermission: true);
      final result = await notificationServiceWith(gateway).enableReminders();
      expect(result, ReminderEnableResult.failed);
      expect(await enabledPref(), isFalse);
      expect(gateway.cancelled, isNotEmpty);
    });

    test('scheduling fails midway: failed, OFF, partial reminders removed',
        () async {
      final gateway = FakeGateway(throwOnScheduleAt: 3);
      final result = await notificationServiceWith(gateway).enableReminders();
      expect(result, ReminderEnableResult.failed);
      expect(await enabledPref(), isFalse);
      expect(gateway.pending, isEmpty);
    });

    test('disable never throws even if cancelling fails', () async {
      SharedPreferences.setMockInitialValues({
        AppSettingsService.notificationsEnabledKey: true,
      });
      final gateway = FakeGateway(throwOnCancel: true);
      await notificationServiceWith(gateway).disableReminders();
      expect(await enabledPref(), isFalse);
    });
  });
}
