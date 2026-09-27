import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/settings/app_settings_service.dart';
import 'package:sudoku159/services/settings/local_notifications_gateway.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:timezone/timezone.dart' as tz;

/// 예약할 알림 한 건(날짜별 고정 ID, 발송 시각, 문구).
class ReminderPlan {
  const ReminderPlan({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  final int id;
  final tz.TZDateTime when;
  final String title;
  final String body;
}

/// [NotificationService.enableReminders] 결과.
enum ReminderEnableResult {
  /// 권한 허용과 7일 예약에 모두 성공해 ON으로 저장됨.
  enabled,

  /// 사용자가 OS 권한을 거부해 OFF로 저장됨.
  denied,

  /// 권한 요청·예약 중 오류가 나 OFF로 되돌리고 예약을 정리함.
  failed,
}

class NotificationService {
  NotificationService({
    LocalNotificationsGateway? gateway,
    ChallengeProgressService? challengeProgressService,
    AppSettingsService? appSettingsService,
    tz.TZDateTime Function()? now,
  })  : _gateway = gateway ?? LocalNotificationsGateway(),
        _challengeProgressService =
            challengeProgressService ?? ChallengeProgressService(),
        _appSettingsService = appSettingsService ?? AppSettingsService(),
        _now = now ?? (() => tz.TZDateTime.now(tz.local));

  /// 이전 버전(하루 3회·1회 알림)에서 쓰던 ID. 매 동기화마다 계속 취소한다.
  @visibleForTesting
  static const List<int> legacyReminderIds = [1001, 1002, 1003];

  /// 앞으로 7일치 저녁 알림에 쓰는 고정 ID 범위(첫 예약일부터 순서대로).
  @visibleForTesting
  static const int firstDailyReminderId = 1100;
  @visibleForTesting
  static const int scheduleDays = 7;
  @visibleForTesting
  static List<int> get dailyReminderIds => List.generate(
        scheduleDays,
        (index) => firstDailyReminderId + index,
      );

  static const int _reminderHour = 20;
  static const String _dailyChallengeChannelId = 'daily_challenge_reminders';

  final LocalNotificationsGateway _gateway;
  final ChallengeProgressService _challengeProgressService;
  final AppSettingsService _appSettingsService;
  final tz.TZDateTime Function() _now;

  Future<void> initialize() => _gateway.initialize();

  /// OS 권한을 요청한다. 사용자가 알림을 켜기로 선택했을 때만 호출한다.
  Future<bool> requestPermissions() async {
    await initialize();
    return _gateway.requestPermission();
  }

  /// 팝업 없이 iOS 알림 권한이 이미 허용돼 있는지 확인한다.
  Future<bool> isIosPermissionGranted() async {
    await initialize();
    return _gateway.isIosPermissionGranted();
  }

  /// 앱 시작 시 호출한다. OS 권한은 절대 요청하지 않는다. 신규 설치는 알림이
  /// 꺼진 상태로 시작하고, 첫 퍼즐 완료 후 안내를 거쳐 사용자가 직접 켠다.
  Future<void> bootstrapOnLaunch({required bool isIos}) async {
    await initialize();
    final stored = await _appSettingsService.getStoredBool(
      AppSettingsService.notificationsEnabledKey,
    );
    // 이전 버전은 저장값 없이 알림을 켠 상태로 동작했다. 그때 이미 iOS 권한을
    // 허용한 사용자는 팝업 없이 확인만 해서 켠 상태를 이어 준다.
    if (stored == null && isIos && await _gateway.isIosPermissionGranted()) {
      await _appSettingsService.setBool(
        AppSettingsService.notificationsEnabledKey,
        true,
      );
      await _appSettingsService.setBool(
        AppSettingsService.notificationOptInPromptSeenKey,
        true,
      );
    }
    await syncReminders();
  }

  /// 알림이 켜져 있으면 앞으로 7일간 매일 저녁 8시 알림을 미리 예약한다.
  /// 오늘 이미 한 판을 완료했거나 오늘 8시가 지났으면 내일부터 예약한다.
  ///
  /// 로컬 알림은 발송 순간에 조건을 다시 확인할 수 없으므로 앱 시작, 게임
  /// 완료, 설정·언어 변경 때마다 전부 취소하고 현재 상태로 다시 예약한다.
  Future<void> syncReminders() async {
    await initialize();
    await _gateway.refreshLocalTimezone();
    await cancelReminders();

    final enabled = await _appSettingsService.getBool(
      AppSettingsService.notificationsEnabledKey,
      defaultValue: AppSettingsService.notificationsEnabledDefault,
    );
    if (!enabled) return;
    await _scheduleUpcomingReminders();
  }

  /// 사용자가 알림을 켜기로 선택했을 때(첫 완료 안내·설정 화면) 호출한다.
  /// 권한 요청과 7일 예약이 모두 성공해야 설정을 ON으로 저장한다. 거부되거나
  /// 도중에 실패하면 OFF로 저장하고 부분 예약된 알림까지 취소한다.
  /// 예외를 밖으로 던지지 않는다.
  Future<ReminderEnableResult> enableReminders() async {
    try {
      final granted = await requestPermissions();
      if (!granted) {
        await disableReminders();
        return ReminderEnableResult.denied;
      }
      await initialize();
      await _gateway.refreshLocalTimezone();
      await cancelReminders();
      await _scheduleUpcomingReminders();
      await _appSettingsService.setBool(
        AppSettingsService.notificationsEnabledKey,
        true,
      );
      return ReminderEnableResult.enabled;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('알림 켜기 실패: $e');
      }
      await disableReminders();
      return ReminderEnableResult.failed;
    }
  }

  /// 설정을 OFF로 저장하고 예약된 알림(레거시 포함)을 모두 취소한다.
  /// 저장·취소 중 하나가 실패해도 나머지는 계속 시도하며 예외를 던지지 않는다.
  Future<void> disableReminders() async {
    try {
      await _appSettingsService.setBool(
        AppSettingsService.notificationsEnabledKey,
        false,
      );
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('알림 OFF 저장 실패: $e');
      }
    }
    try {
      await cancelReminders();
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('예약 알림 취소 실패: $e');
      }
    }
  }

  Future<void> _scheduleUpcomingReminders() async {
    final summary = await _challengeProgressService.load();
    final now = _now();
    final plans = planReminders(
      now: now,
      playedToday: summary.lastClearDate ==
          ChallengeProgressService.formatLocalDate(now),
      streakDays: summary.activityStreakDays,
      locale: await _effectiveLocale(),
    );
    final channel = reminderCopyForLocale(await _effectiveLocale());
    for (final plan in plans) {
      await _gateway.schedule(
        id: plan.id,
        title: plan.title,
        body: plan.body,
        when: plan.when,
        channelId: _dailyChallengeChannelId,
        channelName: channel.channelName,
        channelDescription: channel.channelDescription,
      );
    }
  }

  Future<void> cancelReminders() async {
    await initialize();
    for (final id in [...legacyReminderIds, ...dailyReminderIds]) {
      await _gateway.cancel(id);
    }
  }

  /// [now]의 시간대 기준으로 7일치 저녁 8시 알림을 계산한다.
  ///
  /// 연속 일수 문구는 그 날짜의 연속 상태를 지금 확신할 수 있을 때만 쓴다:
  /// 오늘 아직 안 풀었을 때의 오늘 알림, 오늘 이미 풀었을 때의 내일 알림.
  /// 그 이후 날짜는 그 사이 플레이 여부를 알 수 없어 일반 문구를 쓴다.
  @visibleForTesting
  static List<ReminderPlan> planReminders({
    required tz.TZDateTime now,
    required bool playedToday,
    required int streakDays,
    required Locale locale,
  }) {
    final todayAtEight = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      _reminderHour,
    );
    final startOffset = !playedToday && todayAtEight.isAfter(now) ? 0 : 1;
    final plans = <ReminderPlan>[];
    for (int index = 0; index < scheduleDays; index++) {
      final dayOffset = startOffset + index;
      final when = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day + dayOffset,
        _reminderHour,
      );
      final streakIsCertain = streakDays > 0 &&
          ((dayOffset == 0 && !playedToday) || (dayOffset == 1 && playedToday));
      final copy = reminderCopyForLocale(
        locale,
        streakDays: streakIsCertain ? streakDays : 0,
      );
      plans.add(ReminderPlan(
        id: firstDailyReminderId + index,
        when: when,
        title: copy.title,
        body: copy.body,
      ));
    }
    return plans;
  }

  Future<Locale> _effectiveLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(AppSettingsService.localeKey);
    return resolveReminderLocale(
      savedLanguageCode: savedCode,
      platformLocale: WidgetsBinding.instance.platformDispatcher.locale,
    );
  }

  @visibleForTesting
  static Locale resolveReminderLocale({
    required String? savedLanguageCode,
    required Locale platformLocale,
  }) {
    if (savedLanguageCode != null &&
        savedLanguageCode.isNotEmpty &&
        savedLanguageCode != 'system') {
      return Locale(savedLanguageCode);
    }
    return platformLocale;
  }

  @visibleForTesting
  static ({
    String title,
    String body,
    String channelName,
    String channelDescription,
  }) reminderCopyForLocale(
    Locale locale, {
    int streakDays = 0,
  }) {
    final hasStreak = streakDays > 0;
    switch (locale.languageCode) {
      case 'ko':
        return (
          title:
              hasStreak ? '$streakDays일 연속 기록을 이어가세요' : '오늘의 스도쿠 한 판을 시작해보세요',
          body: hasStreak
              ? '오늘 퍼즐을 한 판 완료하면 $streakDays일 연속 기록이 이어져요.'
              : '오늘 퍼즐을 아직 완료하지 않았어요. 가볍게 한 판 풀어보세요.',
          channelName: '매일 퍼즐 알림',
          channelDescription: '오늘 퍼즐을 아직 완료하지 않았을 때 저녁에 알려드려요.',
        );
      case 'ja':
        return (
          title: hasStreak ? '$streakDays日連続の記録を続けましょう' : '今日の数独を1局はじめましょう',
          body: hasStreak
              ? '今日パズルを1局クリアすると、$streakDays日連続の記録が続きます。'
              : '今日のパズルはまだクリアしていません。気軽に1局どうぞ。',
          channelName: '毎日のパズル通知',
          channelDescription: '今日のパズルをまだクリアしていないとき、夜にお知らせします。',
        );
      case 'zh':
        return (
          title: hasStreak ? '继续保持 $streakDays 天连续记录' : '来解今天的一局数独吧',
          body: hasStreak
              ? '今天完成一局谜题，就能延续 $streakDays 天的连续记录。'
              : '今天还没有完成谜题。轻松来解一局吧。',
          channelName: '每日谜题提醒',
          channelDescription: '当天还没有完成谜题时，会在晚上提醒你。',
        );
      case 'es':
        return (
          title: hasStreak
              ? 'Mantén tu racha de $streakDays días'
              : 'Empieza hoy una partida de sudoku',
          body: hasStreak
              ? 'Completa un puzle hoy para mantener tu racha de $streakDays días.'
              : 'Todavía no has completado ningún puzle hoy. Prueba una partida tranquila.',
          channelName: 'Recordatorio diario de puzles',
          channelDescription:
              'Te avisa por la noche si todavía no has completado un puzle ese día.',
        );
      default:
        return (
          title: hasStreak
              ? 'Keep your $streakDays-day streak going'
              : 'Start today\'s sudoku',
          body: hasStreak
              ? 'Finish one puzzle today to keep your $streakDays-day streak going.'
              : 'You haven\'t finished a puzzle today yet. Try a quick one.',
          channelName: 'Daily puzzle reminder',
          channelDescription:
              'Reminds you in the evening if you haven\'t finished a puzzle that day.',
        );
    }
  }
}
