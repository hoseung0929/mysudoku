import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/settings/force_update_service.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/widgets/sentence_text.dart';
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
    final palette = LevelStatusPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final mascotSize = isTablet ? 220.0 : 170.0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: palette.screenBackground,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 장식 이미지(상태는 아래 텍스트가 전달한다).
                    ExcludeSemantics(
                      child: Image.asset(
                        'assets/images/records_summary_mascot.png',
                        width: mascotSize,
                        height: mascotSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.updateRequiredTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: palette.primaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 문장마다 새 줄에서 시작하고 단어 중간에서는 줄을 바꾸지 않는다.
                    Center(
                      child: SentenceText(
                        l10n.updateRequiredMessage,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: palette.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _openStore,
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primaryPurple,
                        foregroundColor:
                            isDark ? const Color(0xFF1F1B3A) : Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
