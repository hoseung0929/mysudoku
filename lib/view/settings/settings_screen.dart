import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sudoku159/constants/app_config.dart';
import 'package:sudoku159/l10n/app_locale_scope.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/navigation/tab_scroll_controller.dart';
import 'package:sudoku159/presenter/settings/settings_controller.dart';
import 'package:sudoku159/services/onboarding/beginner_tutorial_service.dart';
import 'package:sudoku159/services/settings/notification_service.dart';
import 'package:sudoku159/theme/app_theme.dart';
import 'package:sudoku159/theme/app_theme_scope.dart';
import 'package:sudoku159/theme/level_status_colors.dart';
import 'package:sudoku159/theme/system_ui_style.dart';
import 'package:sudoku159/view/onboarding/beginner_tutorial_screen.dart';
import 'package:sudoku159/widgets/app_snackbar.dart';
import 'package:sudoku159/widgets/waddling_penguin_icon.dart';
import 'package:sudoku159/utils/tablet_hero_height.dart';
import 'package:sudoku159/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.notificationService,
    this.tutorialService,
    this.tabScrollController,
  });

  /// 테스트에서 OS 권한·실제 예약 없이 주입하기 위한 값. 기본은 실제 서비스.
  final NotificationService? notificationService;
  final BeginnerTutorialService? tutorialService;

  /// 하단 설정 탭을 다시 눌렀을 때 이 화면을 최상단으로 스크롤하도록
  /// 연결하는 콜백 창구. [MyHomePage]가 탭별로 하나씩 만들어 전달한다.
  final TabScrollController? tabScrollController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// 하단 플로팅 탭바 여유 — [HomeScreen._kHomeScrollBottomPad] 와 동일.
  static const double _kScrollBottomPad = 116;

  /// 설정 최상단 히어로 이미지(제목·부제 포함)의 고정 높이(상태바 제외).
  static const double _kSettingsHeroHeightPhone = 185;

  final SettingsController _settingsController = SettingsController();
  late final NotificationService _notificationService =
      widget.notificationService ?? NotificationService();
  late final BeginnerTutorialService _tutorialService =
      widget.tutorialService ?? BeginnerTutorialService();
  final ScrollController _scrollController = ScrollController();
  SettingsState _state = SettingsState.initial;

  /// 알림 ON/OFF 처리 중에는 스위치를 잠가 비동기 작업이 겹치지 않게 한다.
  bool _notificationBusy = false;

  /// 히어로가 상태바 영역 뒤로 완전히 넘어가기 전(true)인지 후(false)인지.
  bool _isTop = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scrollController.addListener(_handleScrollForStatusBar);
    widget.tabScrollController?.attach(_scrollToTop);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollForStatusBar);
    widget.tabScrollController?.detach(_scrollToTop);
    _scrollController.dispose();
    super.dispose();
  }

  /// 설정 탭을 다시 눌렀을 때 호출된다. 이미 최상단이면 아무 것도 하지
  /// 않고, '동작 줄이기'가 켜져 있으면 애니메이션 없이 바로 이동한다.
  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= 0) return;

    if (MediaQuery.disableAnimationsOf(context)) {
      _scrollController.jumpTo(0);
      return;
    }

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  double _currentHeroHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).width > 600
          ? tabletHeroHeight(context)
          : _kSettingsHeroHeightPhone;

  /// 히어로가 상태바 영역 뒤로 완전히 넘어가면 밝은(사진 위) 아이콘에서
  /// 테마 기준 아이콘으로 전환한다. [HomeScreen]과 같은 방식.
  void _handleScrollForStatusBar() {
    if (!mounted) return;
    final topInset = MediaQuery.paddingOf(context).top;
    final threshold = _currentHeroHeight(context) - topInset;
    final collapsed = _scrollController.offset >= threshold;
    if (collapsed == _isTop) {
      setState(() => _isTop = !collapsed);
    }
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

  /// ON: 권한 요청과 7일 예약이 모두 성공해야 ON으로 저장·표시한다.
  /// 거부·실패면 OFF로 되돌리고 부분 예약까지 정리한 뒤 안내한다.
  /// OFF: 사용자의 선택을 그대로 유지하고 예약 취소 실패는 로그만 남긴다.
  Future<void> _setNotificationsEnabled(bool value) async {
    if (_notificationBusy) return;
    setState(() => _notificationBusy = true);

    var enabled = false;
    ReminderEnableResult? result;
    if (value) {
      result = await _notificationService.enableReminders();
      enabled = result == ReminderEnableResult.enabled;
    } else {
      await _notificationService.disableReminders();
    }

    var nextState = _state.copyWith(notificationsEnabled: enabled);
    try {
      // 저장값을 결과와 맞추고, 직접 선택했으므로 첫 완료 안내는 다시 띄우지 않는다.
      nextState =
          await _settingsController.setNotificationsEnabled(_state, enabled);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('알림 설정 저장 실패: $e');
      }
    }
    if (!mounted) return;
    setState(() {
      _state = nextState;
      _notificationBusy = false;
    });

    if (result == null || result == ReminderEnableResult.enabled) return;
    final l10n = AppLocalizations.of(context)!;
    showAppSnackBar(
      context,
      result == ReminderEnableResult.denied
          ? l10n.settingsNotificationsPermissionDenied
          : l10n.notificationSetupFailed,
    );
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

  Future<void> _openPrivacyPolicy() async {
    await launchUrl(
      Uri.parse(AppConfig.privacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  /// 설정의 "게임 방법"(연습 퍼즐 다시 보기) 항목 노출 여부. 현재는 숨긴다.
  static const bool _showHowToPlay = false;

  Future<void> _openBeginnerTutorial() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BeginnerTutorialScreen(
          tutorialService: _tutorialService,
          isReplay: true,
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedLanguageCode = Localizations.localeOf(context).languageCode;
    // 예전에는 옵션마다 각자 Navigator.pop 후 AppLocaleScope.setAppLocale을
    // 부르는 동일한 코드가 5곳에 중복돼 있었다. 고른 Locale을 시트의 팝
    // 결과로만 반환하고, setAppLocale은 이 아래에서 한 곳에서만(정확히
    // 한 번) 호출하도록 정리했다.
    final selectedLocale = await showModalBottomSheet<Locale>(
      context: context,
      showDragHandle: true,
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
                onTap: () => Navigator.pop(ctx, const Locale('en')),
              ),
              if (!AppConfig.isJapan)
                _buildLanguageOption(
                  context: ctx,
                  label: l10n.settingsLanguageKorean,
                  languageCode: 'ko',
                  selectedLanguageCode: selectedLanguageCode,
                  onTap: () => Navigator.pop(ctx, const Locale('ko')),
                ),
              _buildLanguageOption(
                context: ctx,
                label: l10n.settingsLanguageJapanese,
                languageCode: 'ja',
                selectedLanguageCode: selectedLanguageCode,
                onTap: () => Navigator.pop(ctx, const Locale('ja')),
              ),
              if (!AppConfig.isJapan) ...[
                _buildLanguageOption(
                  context: ctx,
                  label: l10n.settingsLanguageChinese,
                  languageCode: 'zh',
                  selectedLanguageCode: selectedLanguageCode,
                  onTap: () => Navigator.pop(ctx, const Locale('zh')),
                ),
                _buildLanguageOption(
                  context: ctx,
                  label: l10n.settingsLanguageSpanish,
                  languageCode: 'es',
                  selectedLanguageCode: selectedLanguageCode,
                  onTap: () => Navigator.pop(ctx, const Locale('es')),
                ),
              ],
            ],
          ),
        );
      },
    );
    if (selectedLocale != null && mounted) {
      await AppLocaleScope.of(context).setAppLocale(selectedLocale);
    }
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor:
            isSelected ? colorScheme.primary.withValues(alpha: 0.12) : null,
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
      ),
    );
  }

  Future<void> _showAppAbout() async {
    final l10n = AppLocalizations.of(context)!;
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    final levelPalette = LevelStatusPalette.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WaddlingPenguinIcon(size: 96),
            const SizedBox(height: 16),
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
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Team929',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: levelPalette.primaryPurple,
                    ),
                  ),
                  TextSpan(
                    text: ' ${l10n.settingsAboutSupportEmail}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: levelPalette.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
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
    final horizontalPad = isTablet ? 24.0 : 16.0;
    // 외곽 최대 폭: 세로 1008(카드 약 960), 가로형(폭 > 900) 1120(카드 약 1072,
    // 화면 가장자리와 최소 32). 내부 좌우 패딩 24는 그대로.
    final isWide = screenWidth > 900;
    final outerMaxWidth = isWide ? math.min(1120.0, screenWidth - 64) : 1008.0;
    // 히어로 문구의 시작선을 카드 시작선과 맞춘다.
    final heroTextPad = isWide
        ? math.max(
            horizontalPad, (screenWidth - outerMaxWidth) / 2 + horizontalPad)
        : horizontalPad;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 히어로가 보이는 동안(_isTop)은 사진 위라 밝은 상태바 아이콘을
      // 강제하고, 스크롤로 넘어가면 현재 테마 기준으로 전환한다.
      value: systemOverlayStyleFor(
        _isTop ? Brightness.dark : Theme.of(context).brightness,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ListView(
          controller: _scrollController,
          // iOS 탄성 스크롤로 최상단에서 히어로 이미지가 아래로 밀려
          // 보이지 않게 클램핑 물리를 쓴다.
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(bottom: _kScrollBottomPad + bottomInset),
          children: [
            _buildHeroHeader(l10n, heroTextPad, topInset, isTablet),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: outerMaxWidth),
                child: Padding(
                  key: const Key('settings_content_padding'),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    isTablet ? 24 : 16,
                    horizontalPad,
                    0,
                  ),
                  child: _arrangeSections(
                    isTablet: isTablet,
                    sections: [
                      _buildThemeSection(),
                      _buildSettingsSection([
                        _buildSettingsSwitchTile(
                          icon: Icons.notifications_active_outlined,
                          iconColor: const Color(0xFFF4A261),
                          title: AppLocalizations.of(context)!
                              .settingsNotificationsTitle,
                          subtitle: AppLocalizations.of(context)!
                              .settingsNotificationsSubtitle,
                          value: _state.notificationsEnabled,
                          onChanged: _notificationBusy
                              ? null
                              : _setNotificationsEnabled,
                        ),
                      ]),
                      _buildSettingsSection([
                        _buildSettingsTile(
                          icon: Icons.language,
                          iconColor: const Color(0xFF5B8DD9),
                          title: AppLocalizations.of(context)!
                              .settingsLanguageTitle,
                          subtitle: AppLocalizations.of(context)!
                              .settingsLanguageSubtitle,
                          onTap: _showLanguagePicker,
                        ),
                      ]),
                      _buildSettingsSection([
                        _buildSettingsSwitchTile(
                          icon: Icons.vibration,
                          iconColor: const Color(0xFF4EAD7C),
                          title: AppLocalizations.of(context)!
                              .settingsVibrationTitle,
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
                      ]),
                      _buildSettingsSection([
                        if (_showHowToPlay)
                          _buildSettingsTile(
                            icon: Icons.school_outlined,
                            iconColor: const Color(0xFF5B8DD9),
                            title: AppLocalizations.of(context)!
                                .settingsHowToPlayTitle,
                            subtitle: AppLocalizations.of(context)!
                                .settingsHowToPlaySubtitle,
                            onTap: _openBeginnerTutorial,
                          ),
                        _buildSettingsTile(
                          icon: Icons.info_outline,
                          iconColor: const Color(0xFF9E9E9E),
                          title: AppLocalizations.of(context)!
                              .settingsAppInfoTitle,
                          subtitle: AppLocalizations.of(context)!
                              .settingsAppInfoSubtitle,
                          onTap: _showAppAbout,
                        ),
                        _buildSettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          iconColor: const Color(0xFF9E9E9E),
                          title: AppLocalizations.of(context)!
                              .settingsPrivacyTitle,
                          subtitle: AppLocalizations.of(context)!
                              .settingsPrivacySubtitle,
                          onTap: _openPrivacyPolicy,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 설정 섹션 배치: 폭 > 900이면 연관된 섹션끼리 2열(왼쪽: 테마·알림·언어,
  /// 오른쪽: 게임 설정·정보), 그 외는 기존 단일 열.
  Widget _arrangeSections({
    required bool isTablet,
    required List<Widget> sections,
  }) {
    final gap = isTablet ? 20.0 : 16.0;
    Widget column(List<Widget> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              items[i],
            ],
          ],
        );
    // 2열 전환은 화면 폭이 아니라 실제로 받은 콘텐츠 폭 기준: 각 열이 최소 480을
    // 확보할 때만. 부족하면(세로·Split View) 단일 열로 복귀.
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = (constraints.maxWidth - gap) / 2;
        if (columnWidth < 480 || sections.length < 5) {
          return column(sections);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: column(sections.sublist(0, 3))),
            SizedBox(width: gap),
            Expanded(child: column(sections.sublist(3))),
          ],
        );
      },
    );
  }

  Widget _buildThemeSection() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: EdgeInsets.fromLTRB(
        isTablet ? 22 : 18,
        isTablet ? 20 : 16,
        isTablet ? 22 : 18,
        isTablet ? 20 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isTablet ? 48 : 40,
                height: isTablet ? 48 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B8DD9).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.brightness_6_rounded,
                  color: const Color(0xFF5B8DD9).withValues(alpha: 0.85),
                  size: isTablet ? 24 : 20,
                ),
              ),
              SizedBox(width: isTablet ? 18 : 14),
              Text(
                l10n.settingsTheme,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: isTablet ? 19 : null,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 18 : 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              selected: {_state.themeMode},
              onSelectionChanged: (modes) => _setThemeMode(modes.first),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: cs.primary.withValues(alpha: 0.12),
                selectedForegroundColor: cs.primary,
                foregroundColor: cs.onSurfaceVariant,
                side: BorderSide(color: cs.outlineVariant),
                textStyle: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded,
                      size: isTablet ? 19 : 16),
                  label: Text(l10n.settingsThemeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon:
                      Icon(Icons.light_mode_rounded, size: isTablet ? 19 : 16),
                  label: Text(l10n.settingsThemeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded, size: isTablet ? 19 : 16),
                  label: Text(l10n.settingsThemeDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 설정 최상단 히어로 이미지: 작업실에서 조명·색상 도구를 정리하는 캐릭터
  /// 일러스트 위에 '설정' 제목과 부제를 겹쳐 보여준다. 상태바 영역까지
  /// 이미지를 확장하고, 본문과 함께 스크롤된다.
  Widget _buildHeroHeader(
    AppLocalizations l10n,
    double horizontalPad,
    double topInset,
    bool isTablet,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();
    final contentHeight = _currentHeroHeight(context);
    final height = topInset + contentHeight;

    return SizedBox(
      key: const Key('settings_hero_header'),
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Image.asset(
              'assets/images/settings_hero.webp',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
          // 상태 표시줄 가독성을 위한 위쪽 어두운 그라데이션. 다크 모드에서는
          // 오버레이를 10~15%p 더 진하게 적용한다.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: isDark ? 0.58 : 0.45),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.42],
              ),
            ),
          ),
          // 제목·부제 가독성을 위한 좌측 어두운 그라데이션.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: isDark ? 0.55 : 0.42),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.68],
              ),
            ),
          ),
          // 하단은 화면 배경색으로 자연스럽게 이어진다.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: contentHeight * 0.34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
          if (canPop)
            Positioned(
              left: horizontalPad - 8,
              top: topInset,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: isTablet ? 24 : 20),
                color: Colors.white,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          Positioned(
            left: horizontalPad,
            right: isTablet ? 260 : 150,
            bottom: 20,
            child: Semantics(
              header: true,
              child: Text(
                l10n.settingsHeroSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 28 : 18,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(List<Widget> children) {
    final cs = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
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
                indent: isTablet ? 88 : 72,
                endIndent: 0,
                color: cs.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingIcon(IconData icon, {Color? color}) {
    final c = color ?? AppTheme.mintColor;
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Container(
      width: isTablet ? 48 : 40,
      height: isTablet ? 48 : 40,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: c.withValues(alpha: 0.85),
        size: isTablet ? 24 : 20,
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
    final isTablet = MediaQuery.of(context).size.width > 600;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 22 : 18,
        vertical: isTablet ? 8 : 4,
      ),
      leading: _buildSettingIcon(icon, color: iconColor),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: isTablet ? 18 : null,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: isTablet ? 14 : null,
              color: cs.onSurfaceVariant,
            ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: isTablet ? 26 : null,
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
    required ValueChanged<bool>? onChanged,
    Color? iconColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;
    return SwitchListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 22 : 18,
        vertical: isTablet ? 8 : 4,
      ),
      value: value,
      onChanged: onChanged,
      secondary: _buildSettingIcon(icon, color: iconColor),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: isTablet ? 18 : null,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: isTablet ? 14 : null,
              color: cs.onSurfaceVariant,
            ),
      ),
    );
  }
}
