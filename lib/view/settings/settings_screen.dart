import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sudoku159/l10n/app_locale_scope.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/presenter/settings/settings_controller.dart';
import 'package:sudoku159/services/firebase/firebase_identity_service.dart';
import 'package:sudoku159/theme/app_colors.dart';
import 'package:sudoku159/theme/app_theme.dart';

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
                      _signOutCloudAccount();
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.settingsCloudSignOutAction),
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
                // TODO: 계정 세션 섹션 — 출시 후 활성화 예정
                // _buildSettingsSection(
                //   AppLocalizations.of(context)!.settingsSectionCloud,
                //   [
                //     _buildSettingsTile(
                //       icon: _state.cloudAccount.isCrossDeviceReady
                //           ? Icons.verified_user_outlined
                //           : Icons.person_outline,
                //       iconColor: const Color(0xFF4FA89F),
                //       title: AppLocalizations.of(context)!
                //           .settingsCloudAccountTitle,
                //       subtitle: _cloudAccountSubtitle(
                //         AppLocalizations.of(context)!,
                //       ),
                //       onTap: _showCloudAccountSheet,
                //     ),
                //   ],
                // ),
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: const Color(0xFF1A1A1A),
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
            color: AppColors.surface,
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

class _CloudCredentials {
  const _CloudCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}
