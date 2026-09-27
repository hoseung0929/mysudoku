import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';

class ProfileGlassHeader extends StatelessWidget {
  const ProfileGlassHeader({
    super.key,
    required this.isTop,
    required this.profileName,
    required this.guestTitle,
    required this.profileImagePath,
    required this.onTapSettings,
    this.sectionLabel,
    this.titleOverride,
    this.subtitleOverride,
    this.onTapEditProfile,
    this.compact = false,
    this.showSubtitle = false,
    this.streakDays = 0,
    this.streakPlayedToday = false,
  });

  final bool isTop;
  final String? profileName;
  final String guestTitle;
  final String? profileImagePath;
  final VoidCallback onTapSettings;
  final String? sectionLabel;
  final String? titleOverride;
  final String? subtitleOverride;
  final VoidCallback? onTapEditProfile;
  final bool compact;

  /// 이름 아래 인사말/소개를 보여줄지. 홈 헤더는 시작 행동보다 튀지 않도록
  /// 기본적으로 한 줄(아바타 · 이름 · 설정)만 보여준다. 소개 데이터와 편집
  /// 기능은 그대로이며 여기서만 생략한다.
  final bool showSubtitle;

  /// 하루 1판 이상 완료한 날의 연속 일수(기록 화면과 같은 기준). 0이면 숨긴다.
  final int streakDays;

  /// 오늘 이미 한 판을 완료했는지. 아니면 연속이 끊길 수 있음을 옅게 표시한다.
  final bool streakPlayedToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final topInset = MediaQuery.paddingOf(context).top;
    final hasProfileImage =
        profileImagePath != null && File(profileImagePath!).existsSync();
    final trimmedName = profileName?.trim() ?? '';
    final hasName = trimmedName.isNotEmpty;
    final displayName = titleOverride ?? (hasName ? trimmedName : guestTitle);
    final subtitleText = showSubtitle
        ? (subtitleOverride ??
            greetingMessage(
              l10n: l10n,
              hour: DateTime.now().hour,
            ))
        : null;

    // 상태바 영역(topInset) 아래로 기본 64: 위아래 여백 8 + 조작 영역 48.
    // 고정 높이가 아니라 최소 높이라서 큰 글씨·긴 이름이면 늘어난다.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isTop
                ? colorScheme.surface
                : colorScheme.surface.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: isTop
                    ? Colors.transparent
                    : colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTapEditProfile,
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: 0.9),
                                  width: 1.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 19,
                                backgroundColor: colorScheme.primaryContainer,
                                backgroundImage: hasProfileImage
                                    ? FileImage(File(profileImagePath!))
                                    : const AssetImage(
                                        'assets/images/character.png',
                                      ) as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 이름은 최대 두 줄. 줄이지 않고 높이가 늘어난다.
                                  Text(
                                    displayName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                      height: 1.2,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  if (subtitleText != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitleText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.9),
                                        fontSize: 11.5,
                                        height: 1.15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (streakDays > 0) ...[
                  const SizedBox(width: 4),
                  _StreakChip(
                    days: streakDays,
                    playedToday: streakPlayedToday,
                  ),
                ],
                const SizedBox(width: 4),
                Tooltip(
                  message: AppLocalizations.of(context)!.settingsTitle,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTapSettings,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 시간대별 환영 문구. 홈 헤더 부제와 홈 상단 히어로 배너가 함께 쓴다.
  static String greetingMessage({
    required AppLocalizations l10n,
    required int hour,
  }) {
    final period = _timePeriod(hour);
    switch (period) {
      case _GreetingTimePeriod.morning:
        return l10n.homeGreetingMorning;
      case _GreetingTimePeriod.afternoon:
        return l10n.homeGreetingAfternoon;
      case _GreetingTimePeriod.evening:
        return l10n.homeGreetingEvening;
    }
  }

  static _GreetingTimePeriod _timePeriod(int hour) {
    if (hour >= 5 && hour < 12) return _GreetingTimePeriod.morning;
    if (hour >= 12 && hour < 18) return _GreetingTimePeriod.afternoon;
    return _GreetingTimePeriod.evening;
  }
}

enum _GreetingTimePeriod { morning, afternoon, evening }

/// 헤더의 연속 일수 칩. 오늘 완료했으면 채운 불꽃, 아직이면 테두리만 둔
/// 옅은 불꽃으로 "오늘 한 판이면 이어진다"는 상태를 구분한다.
class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days, required this.playedToday});

  final int days;
  final bool playedToday;

  static const _flameColor = Color(0xFFE8833A);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final message =
        playedToday ? l10n.homeStreakActive(days) : l10n.homeStreakAtRisk(days);
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        container: true,
        label: message,
        excludeSemantics: true,
        // 칩은 이름·설정 버튼과 한 줄을 나눠 쓰므로 큰 글씨에서는 1.3배까지만
        // 키운다(전체 내용은 툴팁·스크린 리더 문장으로 전달된다).
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  key: const ValueKey('home-streak-chip'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: playedToday
                        ? _flameColor.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: playedToday
                          ? Colors.transparent
                          : colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 18,
                        color: playedToday
                            ? _flameColor
                            : colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        l10n.homeStreakChip(days),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: playedToday
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
