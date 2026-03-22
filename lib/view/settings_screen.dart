import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mysudoku/l10n/app_locale_scope.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/theme/app_theme.dart';
import 'package:mysudoku/theme/app_theme_scope.dart';
import 'package:mysudoku/widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _vibrationEnabledKey = 'vibration_enabled';
  bool _isVibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isVibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
    });
  }

  Future<void> _setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, value);
    if (!mounted) return;
    setState(() {
      _isVibrationEnabled = value;
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

  Future<void> _showNotificationsComingSoon() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsNotificationsComingSoonTitle),
        content: Text(l10n.settingsNotificationsComingSoonBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonOk),
          ),
        ],
      ),
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

    return Scaffold(
      appBar: _buildAppBar(),
      body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
    );
  }

  /// 앱바 위젯
  PreferredSizeWidget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    return CustomAppBar(
      title: l10n.settingsTitle,
      showNotificationIcon: false,
      showLogoutIcon: false,
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
            _buildSettingsTile(
              icon: Icons.notifications,
              title: l10n.settingsNotificationsTitle,
              subtitle: l10n.settingsNotificationsSubtitle,
              onTap: _showNotificationsComingSoon,
            ),
            _buildSettingsTile(
              icon: Icons.schedule,
              title: l10n.settingsNotificationTimeTitle,
              subtitle: l10n.settingsNotificationTimeSubtitle,
              onTap: _showNotificationsComingSoon,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsSection(
          l10n.settingsSectionAppearance,
          [
            _buildSettingsTile(
              icon: Icons.palette_outlined,
              title: l10n.settingsThemeTitle,
              subtitle: l10n.settingsThemeSubtitle,
              onTap: _showAppearancePicker,
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
              value: _isVibrationEnabled,
              onChanged: _setVibrationEnabled,
              secondary: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.mintColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
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
          color: AppTheme.mintColor.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
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
          l10n.settingsNotificationsComingSoonBody,
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
                    l10n.settingsTabletNotificationsBody,
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
