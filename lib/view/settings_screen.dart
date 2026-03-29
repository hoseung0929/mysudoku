import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mysudoku/l10n/app_locale_scope.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/theme/app_theme.dart';
import 'package:mysudoku/theme/app_theme_scope.dart';
import 'package:mysudoku/view/settings/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _settingsController = SettingsController();
  SettingsState _state = SettingsState.initial;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final loaded = await _settingsController.load();
    if (!mounted) return;
    setState(() {
      _state = loaded;
    });
  }

  Future<void> _setVibrationEnabled(bool value) async {
    final nextState = await _settingsController.setVibrationEnabled(_state, value);
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value) {
      final granted = await _settingsController.requestNotificationPermissions();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsNotificationsPermissionDenied),
          ),
        );
        return;
      }
    }

    final nextState = await _settingsController.setNotificationsEnabled(
      _state,
      value,
    );
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _setStreakReminderEnabled(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value && !_state.notificationsEnabled) {
      final granted = await _settingsController.requestNotificationPermissions();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsNotificationsPermissionDenied),
          ),
        );
        return;
      }
    }

    final nextState = await _settingsController.setStreakReminderEnabled(
      _state,
      value,
    );
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _setGameCompleteNotificationEnabled(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value) {
      final granted = await _settingsController.requestNotificationPermissions();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsNotificationsPermissionDenied),
          ),
        );
        return;
      }
    }

    final nextState = await _settingsController.setGameCompleteNotificationEnabled(
      _state,
      value,
    );
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _setDailyGoalNotificationEnabled(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value) {
      final granted = await _settingsController.requestNotificationPermissions();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsNotificationsPermissionDenied),
          ),
        );
        return;
      }
    }

    final nextState = await _settingsController.setDailyGoalNotificationEnabled(
      _state,
      value,
    );
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _pickNotificationTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _state.notificationTime,
    );
    if (selected == null) return;

    final nextState = await _settingsController.setNotificationTime(
      _state,
      selected,
    );
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  String _formatNotificationTime(BuildContext context) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      _state.notificationTime,
    );
  }

  Future<void> _setKeepScreenAwake(bool value) async {
    final nextState = await _settingsController.setKeepScreenAwake(_state, value);
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _setOneHandModeEnabled(bool value) async {
    final nextState = await _settingsController.setOneHandModeEnabled(
      _state,
      value,
    );
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _setMemoHighlightEnabled(bool value) async {
    final nextState = await _settingsController.setMemoHighlightEnabled(
      _state,
      value,
    );
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _setSmartHintHighlightEnabled(bool value) async {
    final nextState = await _settingsController.setSmartHintHighlightEnabled(
      _state,
      value,
    );
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _showLanguagePicker() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.settingsLanguagePickerTitle,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ListTile(
                title: Text(l10n.settingsLanguageSystem),
                onTap: () async {
                  Navigator.pop(ctx);
                  await AppLocaleScope.of(context).setAppLocale(null);
                },
              ),
              ListTile(
                title: Text(l10n.settingsLanguageEnglish),
                onTap: () async {
                  Navigator.pop(ctx);
                  await AppLocaleScope.of(context)
                      .setAppLocale(const Locale('en'));
                },
              ),
              ListTile(
                title: Text(l10n.settingsLanguageKorean),
                onTap: () async {
                  Navigator.pop(ctx);
                  await AppLocaleScope.of(context)
                      .setAppLocale(const Locale('ko'));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAppearancePicker() async {
    final l10n = AppLocalizations.of(context)!;
    final scope = AppThemeScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.settingsAppearancePickerTitle,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ListTile(
                title: Text(l10n.settingsLanguageSystem),
                trailing: scope.themeMode == ThemeMode.system
                    ? const Icon(Icons.check, color: AppTheme.mintColor)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await scope.setThemeMode(ThemeMode.system);
                },
              ),
              ListTile(
                title: Text(l10n.settingsThemeModeLight),
                trailing: scope.themeMode == ThemeMode.light
                    ? const Icon(Icons.check, color: AppTheme.mintColor)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await scope.setThemeMode(ThemeMode.light);
                },
              ),
              ListTile(
                title: Text(l10n.settingsThemeModeDark),
                trailing: scope.themeMode == ThemeMode.dark
                    ? const Icon(Icons.check, color: AppTheme.mintColor)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await scope.setThemeMode(ThemeMode.dark);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAppAbout() async {
    final l10n = AppLocalizations.of(context)!;
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    showAboutDialog(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: l10n.settingsAboutVersionLabel(info.version),
      applicationLegalese: '© ${DateTime.now().year}',
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l10n.settingsAboutDeveloperNote),
        ),
      ],
    );
  }

  Future<void> _showPrivacyDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsPrivacyDialogTitle),
        content: SingleChildScrollView(
          child: Text(l10n.settingsPrivacyDialogBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDFBF6),
            Color(0xFFF7F4E8),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              Expanded(
                child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          if (canPop)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          Text(
            l10n.settingsTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            Localizations.localeOf(context).languageCode == 'ko'
                ? '차분한 플레이 환경'
                : 'Calm play setup',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 태블릿 레이아웃
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // 왼쪽 설정 목록
        SizedBox(
          width: 300,
          child: _buildSettingsList(),
        ),
        // 오른쪽 설정 콘텐츠
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _buildSettingsContent(),
          ),
        ),
      ],
    );
  }

  /// 모바일 레이아웃
  Widget _buildMobileLayout() {
    return _buildSettingsList();
  }

  /// 설정 목록 위젯
  Widget _buildSettingsList() {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsSection(
          l10n.settingsSectionNotifications,
          [
            SwitchListTile(
              value: _state.gameCompleteNotificationEnabled,
              onChanged: _setGameCompleteNotificationEnabled,
              secondary: _buildGameOptionIcon(Icons.emoji_events_outlined),
              title: Text(
                l10n.settingsGameCompleteNotifTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                l10n.settingsGameCompleteNotifSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SwitchListTile(
              value: _state.dailyGoalNotificationEnabled,
              onChanged: _setDailyGoalNotificationEnabled,
              secondary: _buildGameOptionIcon(Icons.flag_outlined),
              title: Text(
                l10n.settingsDailyGoalNotifTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                l10n.settingsDailyGoalNotifSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            SwitchListTile(
              value: _state.notificationsEnabled,
              onChanged: _setNotificationsEnabled,
              secondary: _buildGameOptionIcon(Icons.notifications_active_outlined),
              title: Text(
                l10n.settingsNotificationsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                l10n.settingsNotificationsSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SwitchListTile(
              value: _state.streakReminderEnabled,
              onChanged: _setStreakReminderEnabled,
              secondary: _buildGameOptionIcon(Icons.local_fire_department_outlined),
              title: Text(
                l10n.settingsStreakReminderTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                l10n.settingsStreakReminderSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            _buildSettingsTile(
              icon: Icons.schedule,
              title: l10n.settingsNotificationTimeTitle,
              subtitle:
                  '${l10n.settingsNotificationTimeSubtitle} · ${_formatNotificationTime(context)}',
              onTap: _pickNotificationTime,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsSection(
          l10n.settingsSectionLanguage,
          [
            _buildSettingsTile(
              icon: Icons.language,
              title: l10n.settingsLanguageTitle,
              subtitle: l10n.settingsLanguageSubtitle,
              onTap: _showLanguagePicker,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsSection(
          l10n.settingsSectionGame,
          [
            SwitchListTile(
              value: _state.isVibrationEnabled,
              onChanged: _setVibrationEnabled,
              secondary: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.mintColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.vibration,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
              ),
              title: Text(
                l10n.settingsVibrationTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                l10n.settingsVibrationSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            SwitchListTile(
              value: _state.keepScreenAwake,
              onChanged: _setKeepScreenAwake,
              secondary: _buildGameOptionIcon(Icons.screen_lock_portrait),
              title: Text(
                l10n.settingsKeepScreenAwakeTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                l10n.settingsKeepScreenAwakeSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SwitchListTile(
              value: _state.oneHandModeEnabled,
              onChanged: _setOneHandModeEnabled,
              secondary: _buildGameOptionIcon(Icons.pan_tool_alt_outlined),
              title: Text(
                l10n.settingsOneHandModeTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                l10n.settingsOneHandModeSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            _buildSettingsTile(
              icon: Icons.palette_outlined,
              title: l10n.settingsThemeTitle,
              subtitle: l10n.settingsThemeSubtitle,
              onTap: _showAppearancePicker,
            ),
            SwitchListTile(
              value: _state.memoHighlightEnabled,
              onChanged: _setMemoHighlightEnabled,
              secondary: _buildGameOptionIcon(Icons.filter_center_focus),
              title: Text(
                l10n.settingsMemoHighlightTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                l10n.settingsMemoHighlightSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            SwitchListTile(
              value: _state.smartHintHighlightEnabled,
              onChanged: _setSmartHintHighlightEnabled,
              secondary: _buildGameOptionIcon(Icons.tips_and_updates_outlined),
              title: Text(
                l10n.settingsSmartHintTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                l10n.settingsSmartHintSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsSection(
          l10n.settingsSectionInfo,
          [
            _buildSettingsTile(
              icon: Icons.info,
              title: l10n.settingsAppInfoTitle,
              subtitle: l10n.settingsAppInfoSubtitle,
              onTap: _showAppAbout,
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip,
              title: l10n.settingsPrivacyTitle,
              subtitle: l10n.settingsPrivacySubtitle,
              onTap: _showPrivacyDialog,
            ),
          ],
        ),
      ],
    );
  }

  /// 설정 섹션 위젯
  Widget _buildSettingsSection(String title, List<Widget> children) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildGameOptionIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.mintColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurface,
        size: 20,
      ),
    );
  }

  /// 설정 타일 위젯
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.mintColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: cs.onSurface,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: cs.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  /// 설정 콘텐츠 위젯 (태블릿 우측 패널)
  Widget _buildSettingsContent() {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text(
          l10n.settingsTabletNotificationsHeader,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.settingsNotificationsSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: cs.primary, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${l10n.settingsTabletNotificationsBody}\n${l10n.settingsNotificationTimeTitle}: ${_formatNotificationTime(context)}\n${l10n.settingsStreakReminderTitle}: ${_state.streakReminderEnabled ? l10n.gameMemoStateOn : l10n.gameMemoStateOff}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
