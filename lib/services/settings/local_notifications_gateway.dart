import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// [NotificationService]가 쓰는 로컬 알림 플러그인 호출만 모은 얇은 래퍼.
/// 테스트에서 OS 권한 팝업·실제 예약 없이 호출을 확인할 수 있도록 주입한다.
class LocalNotificationsGateway {
  LocalNotificationsGateway({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    await refreshLocalTimezone();
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(initializationSettings);
    _initialized = true;
  }

  /// 기기 시간대가 바뀌었을 수 있으므로 동기화할 때마다 다시 읽는다.
  Future<void> refreshLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      // 시간대 이름을 못 읽으면 timezone 패키지의 기본값을 유지한다.
    }
  }

  /// OS 권한을 요청한다. 사용자가 명시적으로 켤 때만 호출한다.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final mac = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
    final macGranted =
        await mac?.requestPermissions(alert: true, badge: true, sound: true);
    return androidGranted ?? iosGranted ?? macGranted ?? true;
  }

  /// 팝업 없이 현재 iOS 알림 권한이 허용돼 있는지만 확인한다.
  Future<bool> isIosPermissionGranted() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final options = await ios?.checkPermissions();
    return options?.isEnabled ?? false;
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
}
