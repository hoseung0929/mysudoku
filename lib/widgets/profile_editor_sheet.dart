import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/profile/profile_image_service.dart';

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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final pickedPath = await profileImageService
                                .pickAndSaveProfileImage();
                            if (pickedPath == null) return;
                            setSheetState(() {
                              draftImagePath = pickedPath;
                              removeImage = false;
                            });
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                backgroundImage: hasImage
                                    ? FileImage(File(effectiveImagePath))
                                    : null,
                                child: hasImage
                                    ? null
                                    : Icon(
                                        Icons.person,
                                        size: 44,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: colorScheme.onSurface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.photo_camera,
                                    size: 13,
                                    color: colorScheme.surface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasSavedImage || hasImage) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.onSurfaceVariant,
                              textStyle: const TextStyle(fontSize: 12.5),
                            ),
                            onPressed: () {
                              setSheetState(() {
                                removeImage = true;
                                draftImagePath = null;
                              });
                            },
                            child: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ko'
                                  ? '사진 제거'
                                  : 'Remove photo',
                            ),
                          ),
                        ] else
                          const SizedBox(height: 16),
                      ],
                    ),
                  ),
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
                      counterText: '',
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
