import 'dart:io';
import 'dart:ui' show ImageFilter;

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
    this.onTapEditProfile,
  });

  final bool isTop;
  final String? profileName;
  final String guestTitle;
  final String? profileImagePath;
  final VoidCallback onTapSettings;
  final String? sectionLabel;
  final VoidCallback? onTapEditProfile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final hasProfileImage =
        profileImagePath != null && File(profileImagePath!).existsSync();
    final trimmedName = profileName?.trim() ?? '';
    final hasName = trimmedName.isNotEmpty;
    final displayName = hasName ? trimmedName : guestTitle;
    final isKorean = Localizations.localeOf(context).languageCode == 'ko';
    final subtitleText = hasName
        ? (isKorean
            ? '안녕, $displayName! 오늘 하루는 어땠나요?'
            : '$displayName, ready for one calm puzzle today?')
        : (isKorean ? '안녕! 오늘 하루는 어땠나요?' : 'One calm puzzle for today.');
    final subtitleWithSection = (sectionLabel == null || sectionLabel!.isEmpty)
        ? subtitleText
        : '${sectionLabel!} · $subtitleText';

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF6).withValues(alpha: 0.34),
            border: Border(
              bottom: BorderSide(
                color: isTop
                    ? Colors.transparent
                    : colorScheme.outlineVariant.withValues(alpha: 0.28),
                width: 0.8,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 22 + topInset, 16, 18),
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
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: 0.9),
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: colorScheme.primaryContainer,
                                backgroundImage: hasProfileImage
                                    ? FileImage(File(profileImagePath!))
                                    : null,
                                child: hasProfileImage
                                    ? null
                                    : Icon(
                                        Icons.person,
                                        size: 31,
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
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitleWithSection,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.55,
                          ),
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
}
