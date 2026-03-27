import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:mysudoku/services/app_settings_service.dart';
import 'package:mysudoku/services/challenge_progress_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    AppSettingsService? settingsService,
    ChallengeProgressService? challengeProgressService,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _settingsService = settingsService ?? AppSettingsService(),
        _challengeProgressService =
            challengeProgressService ?? ChallengeProgressService();

  static const int defaultReminderHour = 20;
  static const int defaultReminderMinute = 0;

  static const int _dailyChallengeReminderId = 1001;
  static const int _streakReminderId = 1002;
  static const int _gameCompleteNotificationId = 1003;
  static const int _dailyGoalNotificationId = 1004;
  static const String _dailyChallengeChannelId = 'daily_challenge_reminders';
  static const String _dailyChallengeChannelName = 'Daily challenge reminders';
  static const String _gameCompleteChannelId = 'game_complete_notifications';
  static const String _gameCompleteChannelName = 'Game complete notifications';
  static const String _goalChannelId = 'goal_notifications';
  static const String _goalChannelName = 'Goal notifications';

  final FlutterLocalNotificationsPlugin _plugin;
  final AppSettingsService _settingsService;
  final ChallengeProgressService _challengeProgressService;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(initializationSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();

    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final iosImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final macImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();

    final androidGranted =
        await androidImplementation?.requestNotificationsPermission();
    final iosGranted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final macGranted = await macImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return androidGranted ?? iosGranted ?? macGranted ?? true;
  }

  Future<void> resyncFromStoredSettings() async {
    final enabled = await _settingsService.getBool(
      AppSettingsService.notificationsEnabledKey,
      defaultValue: false,
    );
    final streakReminderEnabled = await _settingsService.getBool(
      AppSettingsService.streakReminderEnabledKey,
      defaultValue: false,
    );
    final hour = await _settingsService.getInt(
      AppSettingsService.notificationHourKey,
      defaultValue: defaultReminderHour,
    );
    final minute = await _settingsService.getInt(
      AppSettingsService.notificationMinuteKey,
      defaultValue: defaultReminderMinute,
    );

    await syncReminders(
      challengeReminderEnabled: enabled,
      streakReminderEnabled: streakReminderEnabled,
      hour: hour,
      minute: minute,
    );
  }

  Future<void> syncReminders({
    required bool challengeReminderEnabled,
    required bool streakReminderEnabled,
    required int hour,
    required int minute,
  }) async {
    await initialize();
    await _plugin.cancel(_dailyChallengeReminderId);
    await _plugin.cancel(_streakReminderId);

    final challengeSummary = await _challengeProgressService.load();
    if (challengeSummary.isTodayChallengeCleared) {
      return;
    }

    if (challengeReminderEnabled) {
      await _plugin.zonedSchedule(
        _dailyChallengeReminderId,
        _titleForLocale(WidgetsBinding.instance.platformDispatcher.locale),
        _bodyForLocale(WidgetsBinding.instance.platformDispatcher.locale),
        _nextInstance(hour: hour, minute: minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyChallengeChannelId,
            _dailyChallengeChannelName,
            channelDescription:
                'Reminds you to finish today\'s Sudoku challenge.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    if (streakReminderEnabled && challengeSummary.streakDays > 0) {
      final streakTime = _shiftedTime(hour: hour, minute: minute, hours: 1);
      await _plugin.zonedSchedule(
        _streakReminderId,
        _streakTitleForLocale(
          WidgetsBinding.instance.platformDispatcher.locale,
          challengeSummary.streakDays,
        ),
        _streakBodyForLocale(
          WidgetsBinding.instance.platformDispatcher.locale,
          challengeSummary.streakDays,
        ),
        _nextInstance(hour: streakTime.$1, minute: streakTime.$2),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyChallengeChannelId,
            _dailyChallengeChannelName,
            channelDescription:
                'Reminds you to keep your Sudoku streak going.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> showGameCompleteNotification({
    required String levelName,
    required int gameNumber,
    required bool isNewBestRecord,
  }) async {
    await initialize();
    final enabled = await _settingsService.getBool(
      AppSettingsService.gameCompleteNotificationEnabledKey,
      defaultValue: false,
    );
    if (!enabled) {
      return;
    }

    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    await _plugin.show(
      _gameCompleteNotificationId,
      _gameCompleteTitleForLocale(locale),
      _gameCompleteBodyForLocale(
        locale,
        levelName: levelName,
        gameNumber: gameNumber,
        isNewBestRecord: isNewBestRecord,
      ),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _gameCompleteChannelId,
          _gameCompleteChannelName,
          channelDescription:
              'Celebrates when you finish a Sudoku puzzle.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showDailyGoalAchievedNotification({
    required int weeklyClearCount,
    required int weeklyGoalTarget,
  }) async {
    await initialize();
    final enabled = await _settingsService.getBool(
      AppSettingsService.dailyGoalNotificationEnabledKey,
      defaultValue: false,
    );
    if (!enabled) {
      return;
    }

    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    await _plugin.show(
      _dailyGoalNotificationId,
      _goalTitleForLocale(locale),
      _goalBodyForLocale(
        locale,
        weeklyClearCount: weeklyClearCount,
        weeklyGoalTarget: weeklyGoalTarget,
      ),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _goalChannelId,
          _goalChannelName,
          channelDescription: 'Celebrates when you reach your weekly goal.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  String _titleForLocale(Locale locale) {
    if (locale.languageCode == 'ko') {
      return '오늘의 도전을 잊지 마세요';
    }
    return 'Don’t forget today’s challenge';
  }

  String _bodyForLocale(Locale locale) {
    if (locale.languageCode == 'ko') {
      return '아직 완료하지 않은 오늘의 스도쿠 도전이 기다리고 있어요.';
    }
    return 'Your unfinished Sudoku challenge for today is still waiting.';
  }

  String _streakTitleForLocale(Locale locale, int streakDays) {
    if (locale.languageCode == 'ko') {
      return '$streakDays일 연속 플레이를 이어가세요';
    }
    return 'Keep your $streakDays-day streak going';
  }

  String _streakBodyForLocale(Locale locale, int streakDays) {
    if (locale.languageCode == 'ko') {
      return '오늘 한 판만 더 풀면 $streakDays일 연속 기록을 지킬 수 있어요.';
    }
    return 'Finish one puzzle today to protect your $streakDays-day streak.';
  }

  String _gameCompleteTitleForLocale(Locale locale) {
    if (locale.languageCode == 'ko') {
      return '스도쿠를 완료했어요';
    }
    return 'Puzzle completed';
  }

  String _gameCompleteBodyForLocale(
    Locale locale, {
    required String levelName,
    required int gameNumber,
    required bool isNewBestRecord,
  }) {
    if (locale.languageCode == 'ko') {
      final suffix = isNewBestRecord ? ' 새로운 최고 기록도 달성했어요.' : '';
      return '$levelName · 게임 $gameNumber 클리어.$suffix';
    }
    final suffix = isNewBestRecord ? ' You also set a new best record.' : '';
    return '$levelName · Game $gameNumber cleared.$suffix';
  }

  String _goalTitleForLocale(Locale locale) {
    if (locale.languageCode == 'ko') {
      return '주간 목표를 달성했어요';
    }
    return 'Weekly goal achieved';
  }

  String _goalBodyForLocale(
    Locale locale, {
    required int weeklyClearCount,
    required int weeklyGoalTarget,
  }) {
    if (locale.languageCode == 'ko') {
      return '최근 7일 동안 $weeklyClearCount판을 완료해 목표 $weeklyGoalTarget판을 채웠어요.';
    }
    return 'You cleared $weeklyClearCount puzzles in the last 7 days and reached your goal of $weeklyGoalTarget.';
  }

  tz.TZDateTime _nextInstance({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  (int, int) _shiftedTime({
    required int hour,
    required int minute,
    required int hours,
  }) {
    final totalMinutes = (hour * 60) + minute + (hours * 60);
    final normalizedMinutes = totalMinutes % (24 * 60);
    return (normalizedMinutes ~/ 60, normalizedMinutes % 60);
  }
}
