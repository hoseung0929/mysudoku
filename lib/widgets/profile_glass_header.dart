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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final hasProfileImage =
        profileImagePath != null && File(profileImagePath!).existsSync();
    final trimmedName = profileName?.trim() ?? '';
    final hasName = trimmedName.isNotEmpty;
    final displayName = titleOverride ?? (hasName ? trimmedName : guestTitle);
    final languageCode = Localizations.localeOf(context).languageCode;
    final subtitleText = showSubtitle
        ? (subtitleOverride ??
            _buildGreetingMessage(
              languageCode: languageCode,
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

  String _buildGreetingMessage({
    required String languageCode,
    required int hour,
  }) {
    final period = _timePeriod(hour);
    switch (period) {
      case _GreetingTimePeriod.morning:
        if (languageCode == 'ko') return '가볍게 한 판 시작해볼까요?';
        if (languageCode == 'ja') return 'さあ、一局始めましょう。';
        if (languageCode == 'zh') return '从一局轻松的谜题开始吧。';
        if (languageCode == 'es') return 'Empieza con un puzle ligero.';
        return 'Start with a light puzzle.';
      case _GreetingTimePeriod.afternoon:
        if (languageCode == 'ko') return '집중 퍼즐 한 판, 딱 좋아요.';
        if (languageCode == 'ja') return '集中して一局、いかがですか。';
        if (languageCode == 'zh') return '现在适合专注解一局。';
        if (languageCode == 'es') return 'Un puzle de concentración te sienta bien ahora.';
        return 'A focused puzzle fits now.';
      case _GreetingTimePeriod.evening:
        if (languageCode == 'ko') return '차분하게 퍼즐로 마무리해요.';
        if (languageCode == 'ja') return '静かにパズルで締めくくりましょう。';
        if (languageCode == 'zh') return '静下心来，用一局谜题收尾吧。';
        if (languageCode == 'es') return 'Relájate con un puzle tranquilo.';
        return 'Wind down with a calm puzzle.';
    }
  }

  _GreetingTimePeriod _timePeriod(int hour) {
    if (hour >= 5 && hour < 12) return _GreetingTimePeriod.morning;
    if (hour >= 12 && hour < 18) return _GreetingTimePeriod.afternoon;
    return _GreetingTimePeriod.evening;
  }
}

enum _GreetingTimePeriod { morning, afternoon, evening }
