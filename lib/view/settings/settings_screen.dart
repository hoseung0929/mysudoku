import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sudoku159/l10n/app_locale_scope.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/presenter/settings/settings_controller.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/theme/app_theme_scope.dart';

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
    final nextState =
        await _settingsController.setVibrationEnabled(_state, value);
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _setKeepScreenAwake(bool value) async {
    final nextState =
        await _settingsController.setKeepScreenAwake(_state, value);
    if (!mounted) return;
    setState(() {
      _state = nextState;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final nextState = await _settingsController.setThemeMode(_state, mode);
    if (!mounted) return;
    setState(() => _state = nextState);
    await AppThemeScope.of(context).setThemeMode(mode);
  }

  Future<void> _showPrivacyPolicy() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(l10n.settingsPrivacyDialogTitle),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        content: Text(
          l10n.settingsPrivacyDialogBody,
          textAlign: TextAlign.start,
          strutStyle: const StrutStyle(
            fontSize: 14,
            height: 1.65,
            forceStrutHeight: true,
          ),
          style: const TextStyle(fontSize: 14, height: 1.65),
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

  Future<void> _showLanguagePicker() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedLanguageCode = Localizations.localeOf(context).languageCode;
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
              _buildLanguageOption(
                context: ctx,
                label: l10n.settingsLanguageEnglish,
                languageCode: 'en',
                selectedLanguageCode: selectedLanguageCode,
                onTap: () async {
                  Navigator.pop(ctx);
                  await AppLocaleScope.of(context)
                      .setAppLocale(const Locale('en'));
                },
              ),
              _buildLanguageOption(
                context: ctx,
                label: l10n.settingsLanguageKorean,
                languageCode: 'ko',
                selectedLanguageCode: selectedLanguageCode,
                onTap: () async {
                  Navigator.pop(ctx);
                  await AppLocaleScope.of(context)
                      .setAppLocale(const Locale('ko'));
                },
              ),
              _buildLanguageOption(
                context: ctx,
                label: l10n.settingsLanguageJapanese,
                languageCode: 'ja',
                selectedLanguageCode: selectedLanguageCode,
                onTap: () async {
                  Navigator.pop(ctx);
                  await AppLocaleScope.of(context)
                      .setAppLocale(const Locale('ja'));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String label,
    required String languageCode,
    required String selectedLanguageCode,
    required VoidCallback onTap,
  }) {
    final isSelected = languageCode == selectedLanguageCode;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(
        label,
        strutStyle: const StrutStyle(
          fontSize: 16,
          height: 1.3,
          forceStrutHeight: true,
        ),
        style: textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          height: 1.3,
          color: colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_rounded,
              color: colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }

  Future<void> _showAppAbout() async {
    final l10n = AppLocalizations.of(context)!;
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.appTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.settingsAboutVersionLabel(info.version),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.settingsAboutDeveloperNote,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              '© ${DateTime.now().year}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
            ),
          ],
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 920 : 680),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 28 : 16,
                16,
                isTablet ? 28 : 16,
                28,
              ),
              children: [
                _buildTopHeader(),
                const SizedBox(height: 20),
                _buildThemeSection(),
                const SizedBox(height: 20),
                _buildSettingsSection(
                  AppLocalizations.of(context)!.settingsSectionLanguage,
                  [
                    _buildSettingsTile(
                      icon: Icons.language,
                      iconColor: const Color(0xFF5B8DD9),
                      title:
                          AppLocalizations.of(context)!.settingsLanguageTitle,
                      subtitle: AppLocalizations.of(context)!
                          .settingsLanguageSubtitle,
                      onTap: _showLanguagePicker,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSettingsSection(
                  AppLocalizations.of(context)!.settingsSectionGame,
                  [
                    _buildSettingsSwitchTile(
                      icon: Icons.vibration,
                      iconColor: const Color(0xFF4EAD7C),
                      title:
                          AppLocalizations.of(context)!.settingsVibrationTitle,
                      subtitle: AppLocalizations.of(
                        context,
                      )!
                          .settingsVibrationSubtitle,
                      value: _state.isVibrationEnabled,
                      onChanged: _setVibrationEnabled,
                    ),
                    _buildSettingsSwitchTile(
                      icon: Icons.screen_lock_portrait,
                      iconColor: const Color(0xFF4EAD7C),
                      title: AppLocalizations.of(
                        context,
                      )!
                          .settingsKeepScreenAwakeTitle,
                      subtitle: AppLocalizations.of(
                        context,
                      )!
                          .settingsKeepScreenAwakeSubtitle,
                      value: _state.keepScreenAwake,
                      onChanged: _setKeepScreenAwake,
                    ),
                  ],
                ),
                _buildSettingsSection(
                  AppLocalizations.of(context)!.settingsSectionInfo,
                  [
                    _buildSettingsTile(
                      icon: Icons.info_outline,
                      iconColor: const Color(0xFF9E9E9E),
                      title: AppLocalizations.of(context)!.settingsAppInfoTitle,
                      subtitle:
                          AppLocalizations.of(context)!.settingsAppInfoSubtitle,
                      onTap: _showAppAbout,
                    ),
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: const Color(0xFF9E9E9E),
                      title: AppLocalizations.of(context)!.settingsPrivacyTitle,
                      subtitle:
                          AppLocalizations.of(context)!.settingsPrivacySubtitle,
                      onTap: _showPrivacyPolicy,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            l10n.settingsDisplaySection,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B8DD9).withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.brightness_6_rounded,
                      color: const Color(0xFF5B8DD9).withValues(alpha: 0.85),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    l10n.settingsTheme,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SegmentedButton<ThemeMode>(
                selected: {_state.themeMode},
                onSelectionChanged: (modes) => _setThemeMode(modes.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: cs.primary.withValues(alpha: 0.12),
                  selectedForegroundColor: cs.primary,
                  foregroundColor: cs.onSurfaceVariant,
                  side: BorderSide(color: cs.outlineVariant),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_rounded, size: 16),
                    label: Text(l10n.settingsThemeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_rounded, size: 16),
                    label: Text(l10n.settingsThemeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_rounded, size: 16),
                    label: Text(l10n.settingsThemeDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (canPop)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: colorScheme.onSurface,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsTitle,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 0,
                    color: cs.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingIcon(IconData icon, {Color? color}) {
    final c = color ?? AppTheme.mintColor;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: c.withValues(alpha: 0.85),
        size: 20,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: _buildSettingIcon(icon, color: iconColor),
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

  Widget _buildSettingsSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      value: value,
      onChanged: onChanged,
      secondary: _buildSettingIcon(icon, color: iconColor),
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
    );
  }
}
