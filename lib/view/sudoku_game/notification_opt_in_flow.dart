import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/settings/app_settings_service.dart';
import 'package:sudoku159/services/settings/notification_service.dart';
import 'package:sudoku159/utils/app_logger.dart';

/// 첫 퍼즐 완료 후 한 번만 보여 주는 앱 내부 알림 안내.
/// 사용자가 "알림 받기"를 눌렀을 때만 OS 권한을 요청한다.
class NotificationOptInFlow {
  NotificationOptInFlow({
    AppSettingsService? settingsService,
    NotificationService? notificationService,
  })  : _settings = settingsService ?? AppSettingsService(),
        _notificationService = notificationService ?? NotificationService();

  final AppSettingsService _settings;
  final NotificationService _notificationService;

  /// 아직 안내를 본 적이 없고 알림이 꺼져 있을 때만 보여 준다.
  Future<bool> shouldShow() async {
    final seen = await _settings.getBool(
      AppSettingsService.notificationOptInPromptSeenKey,
      defaultValue: false,
    );
    if (seen) return false;
    final enabled = await _settings.getBool(
      AppSettingsService.notificationsEnabledKey,
      defaultValue: AppSettingsService.notificationsEnabledDefault,
    );
    return !enabled;
  }

  /// 예외를 밖으로 던지지 않는다. 호출한 쪽(게임 완료 흐름)의 다음 동작이
  /// 알림 처리 결과에 막히지 않도록 모든 실패를 여기서 정리한다.
  Future<void> maybeShow(BuildContext context) async {
    try {
      await _showAndApply(context);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('첫 완료 알림 안내 처리 실패: $e');
      }
    }
  }

  Future<void> _showAndApply(BuildContext context) async {
    if (!await shouldShow() || !context.mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const NotificationOptInDialog(),
    );
    // 뒤로가기·바깥 터치(null)는 "나중에"와 같다. 어느 쪽이든 다시 묻지 않는다.
    try {
      await _settings.setBool(
        AppSettingsService.notificationOptInPromptSeenKey,
        true,
      );
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('알림 안내 표시 기록 저장 실패: $e');
      }
    }
    if (accepted != true) return;

    final result = await _notificationService.enableReminders();
    if (result == ReminderEnableResult.enabled || !context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == ReminderEnableResult.denied
              ? l10n.notificationOptInDenied
              : l10n.notificationSetupFailed,
        ),
      ),
    );
  }
}

class NotificationOptInDialog extends StatelessWidget {
  const NotificationOptInDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      key: const ValueKey('notification-opt-in-dialog'),
      scrollable: true,
      icon: const Icon(Icons.notifications_active_outlined),
      title: Text(l10n.notificationOptInTitle, textAlign: TextAlign.center),
      content: Text(l10n.notificationOptInBody, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
          child: Text(l10n.notificationOptInLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          child: Text(l10n.notificationOptInAccept),
        ),
      ],
    );
  }
}
