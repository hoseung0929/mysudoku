import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    ChallengeProgressService? challengeProgressService,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _challengeProgressService =
            challengeProgressService ?? ChallengeProgressService();

  static const int _morningReminderId = 1001;
  static const int _noonReminderId = 1002;
  static const int _eveningReminderId = 1003;
  static const String _dailyChallengeChannelId = 'daily_challenge_reminders';
  static const String _dailyChallengeChannelName = 'Daily challenge reminders';

  /// (알림 ID, 시, 분) — 하루 세 번(아침/점심/저녁) 오늘의 챌린지를 리마인드한다.
  static const List<(int, int, int)> _reminderSlots = [
    (_morningReminderId, 9, 0),
    (_noonReminderId, 13, 0),
    (_eveningReminderId, 20, 0),
  ];

  final FlutterLocalNotificationsPlugin _plugin;
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

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final macImplementation = _plugin.resolvePlatformSpecificImplementation<
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

  /// 오늘 퍼즐을 한 판도 안 깼으면 아침/점심/저녁 세 번 리마인드를 예약한다.
  /// 이미 지난 시간대는 자동으로 다음 날로 넘어가서 예약된다. 스트릭이 있으면
  /// 스트릭 문구를, 없으면 일반 챌린지 문구를 쓴다.
  ///
  /// 앱을 열 때, 그리고 게임을 클리어한 직후에 호출해서 항상 최신 상태로
  /// 다시 맞춘다 — 로컬 알림은 발송 순간에 조건을 재확인할 수 없어서, 오늘
  /// 이미 한 판 깼다면 이 호출 시점에 남은 시간대 알림을 미리 취소해야 한다.
  Future<void> syncReminders() async {
    await initialize();
    for (final slot in _reminderSlots) {
      await _plugin.cancel(slot.$1);
    }

    final challengeSummary = await _challengeProgressService.load();
    final todayStr = ChallengeProgressService.formatLocalDate(DateTime.now());
    final hasPlayedToday = challengeSummary.lastClearDate == todayStr;
    if (hasPlayedToday) {
      return;
    }

    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final useStreakCopy = challengeSummary.streakDays > 0;
    final title = useStreakCopy
        ? _streakTitleForLocale(locale, challengeSummary.streakDays)
        : _titleForLocale(locale);
    final body = useStreakCopy
        ? _streakBodyForLocale(locale, challengeSummary.streakDays)
        : _bodyForLocale(locale);

    for (final slot in _reminderSlots) {
      await _plugin.zonedSchedule(
        slot.$1,
        title,
        body,
        _nextInstance(hour: slot.$2, minute: slot.$3),
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
      );
    }
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
}
