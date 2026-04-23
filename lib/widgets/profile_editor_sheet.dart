import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mysudoku/l10n/app_localizations.dart';
import 'package:mysudoku/services/profile_image_service.dart';

typedef ProfileSaveCallback = Future<void> Function({
  required String? name,
  required bool removeImage,
  String? pickedImagePath,
});

Future<void> showProfileEditorSheet({
  required BuildContext context,
  required ProfileImageService profileImageService,
  required String? initialProfileName,
  required String? initialProfileImagePath,
  required ProfileSaveCallback onSave,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final colorScheme = Theme.of(context).colorScheme;
  final controller = TextEditingController(text: initialProfileName ?? '');
  var draftImagePath = initialProfileImagePath;
  var removeImage = false;
  final hasSavedImage = initialProfileImagePath != null &&
      File(initialProfileImagePath).existsSync();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final effectiveImagePath = removeImage ? null : draftImagePath;
          final hasImage = effectiveImagePath != null &&
              File(effectiveImagePath).existsSync();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Localizations.localeOf(context).languageCode == 'ko'
                        ? '프로필 편집'
                        : 'Edit profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Localizations.localeOf(context).languageCode == 'ko'
                        ? '사진과 이름을 한 번에 바꿀 수 있어요.'
                        : 'Update your photo and name together.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: hasImage
                              ? FileImage(File(effectiveImagePath))
                              : null,
                          child: hasImage
                              ? null
                              : Icon(
                                  Icons.person,
                                  size: 46,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.photo_camera,
                              size: 14,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final pickedPath = await profileImageService
                                .pickAndSaveProfileImage();
                            if (pickedPath == null) return;
                            setSheetState(() {
                              draftImagePath = pickedPath;
                              removeImage = false;
                            });
                          },
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            Localizations.localeOf(context).languageCode == 'ko'
                                ? '사진 변경'
                                : 'Change photo',
                          ),
                        ),
                      ),
                      if (hasSavedImage || hasImage) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              removeImage = true;
                              draftImagePath = null;
                            });
                          },
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'ko'
                                ? '사진 제거'
                                : 'Remove',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 20,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText:
                          Localizations.localeOf(context).languageCode == 'ko'
                              ? '이름'
                              : 'Name',
                      hintText: l10n.homeGuestTitle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ko'
                              ? '취소'
                              : 'Cancel',
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          await onSave(
                            name: controller.text,
                            removeImage: removeImage,
                            pickedImagePath: draftImagePath,
                          );
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ko'
                              ? '저장'
                              : 'Save',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
