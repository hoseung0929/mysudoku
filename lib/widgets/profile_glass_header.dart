import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

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
    final avatarRadius = compact ? 22.0 : 25.0;
    final avatarIconSize = compact ? 28.0 : 31.0;
    final headerPadding = EdgeInsets.fromLTRB(
      16,
      (compact ? 18 : 22) + topInset,
      16,
      compact ? 14 : 18,
    );
    final profileGap = compact ? 14.0 : 18.0;
    final titleFontSize = compact ? 18.0 : 20.0;
    final subtitleFontSize = compact ? 11.0 : 11.5;
    final settingButtonSize = compact ? 40.0 : 42.0;
    final subtitleText = subtitleOverride ??
        _buildGreetingMessage(
          languageCode: languageCode,
          hour: DateTime.now().hour,
        );

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
            padding: headerPadding,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.surface,
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.9,
                                  ),
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor: colorScheme.primaryContainer,
                                backgroundImage: hasProfileImage
                                    ? FileImage(File(profileImagePath!))
                                    : null,
                                child: hasProfileImage
                                    ? null
                                    : Icon(
                                        Icons.person,
                                        size: avatarIconSize,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                              ),
                            ),
                            if (onTapEditProfile != null)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: onTapEditProfile,
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colorScheme.surface,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 10,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: profileGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: titleFontSize,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.9),
                                  fontSize: subtitleFontSize,
                                  height: 1.15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTapSettings,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: settingButtonSize,
                      height: settingButtonSize,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.55),
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
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
        return 'Start with a light puzzle.';
      case _GreetingTimePeriod.afternoon:
        if (languageCode == 'ko') return '집중 퍼즐 한 판, 딱 좋아요.';
        if (languageCode == 'ja') return '集中して一局、いかがですか。';
        return 'A focused puzzle fits now.';
      case _GreetingTimePeriod.evening:
        if (languageCode == 'ko') return '차분하게 퍼즐로 마무리해요.';
        if (languageCode == 'ja') return '静かにパズルで締めくくりましょう。';
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
