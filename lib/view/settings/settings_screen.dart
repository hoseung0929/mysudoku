import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mysudoku/l10n/app_locale_scope.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/presenter/settings/settings_controller.dart';
import 'package:mysudoku/services/firebase/firebase_identity_service.dart';
import 'package:mysudoku/theme/app_colors.dart';
import 'package:mysudoku/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _settingsController = SettingsController();
  SettingsState _state = SettingsState.initial;
  bool _isCloudActionInProgress = false;

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

  Future<void> _showCloudAccountSheet() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_state.cloudAccount.isAvailable) {
      _showSnackBar(l10n.settingsCloudErrorFirebaseUnavailable);
      return;
    }

    if (_state.cloudAccount.isCrossDeviceReady) {
      await showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.settingsCloudManageSheetTitle,
                    style:
                        Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.settingsCloudManageSheetBody,
                    style: Theme.of(sheetContext).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _syncCloudProgress();
                    },
                    icon: const Icon(Icons.sync),
                    label: Text(l10n.settingsCloudSyncNowTitle),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _signOutCloudAccount();
                    },
                    child: Text(l10n.settingsCloudSignOutAction),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.settingsCloudConnectSheetTitle,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsCloudConnectSheetBody,
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _promptCloudAuth(isCreateAccount: true);
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(l10n.settingsCloudCreateAccountAction),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _promptCloudAuth(isCreateAccount: false);
                  },
                  icon: const Icon(Icons.login),
                  label: Text(l10n.settingsCloudSignInAction),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptCloudAuth({required bool isCreateAccount}) async {
    final credentials = await _showCloudAuthDialog(
      isCreateAccount: isCreateAccount,
    );
    if (!mounted || credentials == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    if (credentials.email.isEmpty || credentials.password.isEmpty) {
      _showSnackBar(l10n.settingsCloudValidationMissingCredentials);
      return;
    }

    await _runCloudAction(
      action: () => isCreateAccount
          ? _settingsController.createCloudAccount(
              _state,
              email: credentials.email,
              password: credentials.password,
            )
          : _settingsController.signInWithEmail(
              _state,
              email: credentials.email,
              password: credentials.password,
            ),
      successMessage: isCreateAccount
          ? l10n.settingsCloudAuthSuccessCreate
          : l10n.settingsCloudAuthSuccessSignIn,
    );
  }

  Future<_CloudCredentials?> _showCloudAuthDialog({
    required bool isCreateAccount,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController(
      text: _state.cloudAccount.email ?? '',
    );
    final passwordController = TextEditingController();

    final result = await showDialog<_CloudCredentials>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isCreateAccount
                ? l10n.settingsCloudCreateDialogTitle
                : l10n.settingsCloudSignInDialogTitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
                decoration: InputDecoration(
                  labelText: l10n.settingsCloudEmailLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: l10n.settingsCloudPasswordLabel,
                ),
                onSubmitted: (_) {
                  Navigator.of(dialogContext).pop(
                    _CloudCredentials(
                      email: emailController.text.trim(),
                      password: passwordController.text,
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  _CloudCredentials(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                  ),
                );
              },
              child: Text(
                isCreateAccount
                    ? l10n.settingsCloudCreateAccountAction
                    : l10n.settingsCloudSignInAction,
              ),
            ),
          ],
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();
    return result;
  }

  Future<void> _syncCloudProgress() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_state.cloudAccount.isAvailable) {
      _showSnackBar(l10n.settingsCloudErrorFirebaseUnavailable);
      return;
    }
    if (!_state.cloudAccount.isSignedIn) {
      await _showCloudAccountSheet();
      return;
    }

    await _runCloudAction(
      action: () => _settingsController.syncCloudProgress(_state),
      successMessage: l10n.settingsCloudSyncSuccess,
    );
  }

  Future<void> _signOutCloudAccount() async {
    final l10n = AppLocalizations.of(context)!;
    await _runCloudAction(
      action: () => _settingsController.signOutCloudAccount(_state),
      successMessage: l10n.settingsCloudSignOutSuccess,
    );
  }

  Future<void> _runCloudAction({
    required Future<SettingsState> Function() action,
    required String successMessage,
  }) async {
    if (_isCloudActionInProgress) {
      return;
    }

    setState(() {
      _isCloudActionInProgress = true;
    });

    try {
      final nextState = await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _state = nextState;
      });
      _showSnackBar(successMessage);
    } on FirebaseIdentityException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_mapCloudErrorMessage(error));
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar(AppLocalizations.of(context)!.settingsCloudErrorGeneric);
    } finally {
      if (mounted) {
        setState(() {
          _isCloudActionInProgress = false;
        });
      }
    }
  }

  String _mapCloudErrorMessage(FirebaseIdentityException error) {
    final l10n = AppLocalizations.of(context)!;
    switch (error.code) {
      case 'firebase-unavailable':
        return l10n.settingsCloudErrorFirebaseUnavailable;
      case 'invalid-email':
        return l10n.settingsCloudErrorInvalidEmail;
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.settingsCloudErrorWrongPassword;
      case 'user-not-found':
        return l10n.settingsCloudErrorUserNotFound;
      case 'email-already-in-use':
        return l10n.settingsCloudErrorEmailAlreadyInUse;
      case 'weak-password':
        return l10n.settingsCloudErrorWeakPassword;
      default:
        return error.message ?? l10n.settingsCloudErrorGeneric;
    }
  }

  String _cloudAccountSubtitle(AppLocalizations l10n) {
    final cloudAccount = _state.cloudAccount;
    if (!cloudAccount.isAvailable) {
      return l10n.settingsCloudUnavailableSubtitle;
    }
    if (cloudAccount.isCrossDeviceReady) {
      return l10n.settingsCloudConnectedSubtitle(
        cloudAccount.identifier ?? 'account',
      );
    }
    if (cloudAccount.isAnonymous) {
      return l10n.settingsCloudAnonymousSubtitle;
    }
    return l10n.settingsCloudDisconnectedSubtitle;
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showCloudComingSoonDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('안내'),
        content: const Text('다음 버전에 제공 될 기능입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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
      backgroundColor: AppTheme.backgroundColor,
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
                _buildSettingsSection(
                  AppLocalizations.of(context)!.settingsSectionLanguage,
                  [
                    _buildSettingsTile(
                      icon: Icons.language,
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
                const SizedBox(height: 20),
                _buildSettingsSection(
                  AppLocalizations.of(context)!.settingsSectionCloud,
                  [
                    _buildSettingsTile(
                      icon: _state.cloudAccount.isCrossDeviceReady
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_sync_outlined,
                      title: AppLocalizations.of(context)!
                          .settingsCloudAccountTitle,
                      subtitle: _cloudAccountSubtitle(
                        AppLocalizations.of(context)!,
                      ),
                      onTap: _showCloudComingSoonDialog,
                    ),
                    _buildSettingsTile(
                      icon: Icons.sync_outlined,
                      title: AppLocalizations.of(context)!
                          .settingsCloudSyncNowTitle,
                      subtitle: AppLocalizations.of(
                        context,
                      )!
                          .settingsCloudSyncNowSubtitle,
                      onTap: _showCloudComingSoonDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSettingsSection(
                  AppLocalizations.of(context)!.settingsSectionInfo,
                  [
                    _buildSettingsTile(
                      icon: Icons.info_outline,
                      title: AppLocalizations.of(context)!.settingsAppInfoTitle,
                      subtitle:
                          AppLocalizations.of(context)!.settingsAppInfoSubtitle,
                      onTap: _showAppAbout,
                    ),
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: AppLocalizations.of(context)!.settingsPrivacyTitle,
                      subtitle:
                          AppLocalizations.of(context)!.settingsPrivacySubtitle,
                      onTap: _showPrivacyDialog,
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

  Widget _buildTopHeader() {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canPop)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingIcon(IconData icon) {
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: _buildSettingIcon(icon),
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
  }) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      value: value,
      onChanged: onChanged,
      secondary: _buildSettingIcon(icon),
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

class _CloudCredentials {
  const _CloudCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}
