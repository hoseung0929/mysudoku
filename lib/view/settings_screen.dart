import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mysudoku/l10n/app_locale_scope.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/services/firebase_identity_service.dart';
import 'package:mysudoku/theme/app_theme.dart';
import 'package:mysudoku/view/settings/settings_controller.dart';

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
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsSection(
          l10n.settingsSectionCloud,
          [
            _buildSettingsTile(
              icon: _state.cloudAccount.isCrossDeviceReady
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_sync_outlined,
              title: l10n.settingsCloudAccountTitle,
              subtitle: _cloudAccountSubtitle(l10n),
              onTap: _showCloudComingSoonDialog,
            ),
            _buildSettingsTile(
              icon: Icons.sync_outlined,
              title: l10n.settingsCloudSyncNowTitle,
              subtitle: l10n.settingsCloudSyncNowSubtitle,
              onTap: _showCloudComingSoonDialog,
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
          l10n.settingsSectionGame,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.settingsMemoHighlightSubtitle,
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
                    l10n.settingsMemoHighlightSubtitle,
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

class _CloudCredentials {
  const _CloudCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}
