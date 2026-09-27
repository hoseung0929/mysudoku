import 'dart:async';

import 'package:sudoku159/services/challenge/challenge_progress_service.dart';
import 'package:sudoku159/services/settings/app_settings_service.dart';
import 'package:sudoku159/services/settings/local_notifications_gateway.dart';
import 'package:sudoku159/services/settings/notification_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 플러그인 대신 예약·취소 호출만 기록한다. 실패 상황도 재현할 수 있다.
class FakeGateway extends LocalNotificationsGateway {
  FakeGateway({
    this.grant = true,
    this.throwOnPermission = false,
    this.throwOnScheduleAt,
    this.throwOnCancel = false,
  });

  bool grant;
  bool throwOnPermission;

  /// 이 순번(0부터)의 예약에서 예외를 던진다. 그 전 예약은 남는다(부분 예약).
  int? throwOnScheduleAt;
  bool throwOnCancel;

  /// 설정하면 권한 요청이 이 Future가 끝날 때까지 기다린다.
  Completer<void>? holdPermission;

  final Map<int, ({String title, String body, tz.TZDateTime when})> pending =
      {};
  final List<int> cancelled = [];
  int permissionRequests = 0;
  int scheduleCalls = 0;
  bool iosGranted = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refreshLocalTimezone() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (holdPermission != null) await holdPermission!.future;
    if (throwOnPermission) throw Exception('permission failed');
    return grant;
  }

  @override
  Future<bool> isIosPermissionGranted() async => iosGranted;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    if (throwOnScheduleAt == scheduleCalls++) {
      throw Exception('schedule failed');
    }
    pending[id] = (title: title, body: body, when: when);
  }

  @override
  Future<void> cancel(int id) async {
    if (throwOnCancel) throw Exception('cancel failed');
    cancelled.add(id);
    pending.remove(id);
  }
}

class FakeProgress extends ChallengeProgressService {
  FakeProgress({this.lastClearDate, this.activityStreakDays = 0});

  final String? lastClearDate;
  final int activityStreakDays;

  @override
  Future<ChallengeProgressSummary> load({
    List<Map<String, dynamic>>? recentRecords,
    List<Map<String, dynamic>>? recentClearEvents,
  }) async {
    return ChallengeProgressSummary(
      streakDays: 0,
      activityStreakDays: activityStreakDays,
      isTodayChallengeCleared: false,
      todayChallengeLevelName: '초급',
      todayChallengeGameNumber: 1,
      lastClearDate: lastClearDate,
      weeklyClearCount: 0,
      weeklyGoalTarget: 5,
      perfectClearCount: 0,
    );
  }
}

/// 가짜 플러그인을 끼운 실제 [NotificationService] (서울 시간 오전 10시 기준).
NotificationService notificationServiceWith(FakeGateway gateway) {
  tzdata.initializeTimeZones();
  final seoul = tz.getLocation('Asia/Seoul');
  return NotificationService(
    gateway: gateway,
    challengeProgressService: FakeProgress(),
    appSettingsService: AppSettingsService(),
    now: () => tz.TZDateTime(seoul, 2026, 9, 24, 10),
  );
}
