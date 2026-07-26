import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/settings/force_update_service.dart';
import 'package:sudoku159/utils/app_logger.dart';

class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate> {
  final ForceUpdateService _service = ForceUpdateService();
  ForceUpdateInfo? _updateInfo;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final info = await _service.checkForUpdate();
    if (!mounted) return;
    setState(() {
      _updateInfo = info;
      _checked = true;
    });
  }

  Future<void> _openStore() async {
    final uri = Uri.tryParse(_updateInfo?.updateUrl ?? '');
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLogger.debug('스토어 링크 열기 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || _updateInfo == null) {
      return widget.child;
    }

    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final mascotSize = isTablet ? 160.0 : 120.0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/character.png',
                      width: mascotSize,
                      height: mascotSize,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.updateRequiredTitle,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.updateRequiredMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _openStore,
                      child: Text(l10n.updateNowButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
