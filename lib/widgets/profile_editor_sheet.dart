import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sudoku159/l10n/app_localizations.dart';
import 'package:sudoku159/services/profile/profile_image_service.dart';
import 'package:sudoku159/theme/app_colors.dart';

typedef ProfileSaveCallback = Future<void> Function({
  required String? name,
  required bool removeImage,
  String? pickedImagePath,
  String? bio,
});

Future<void> showProfileEditorSheet({
  required BuildContext context,
  required ProfileImageService profileImageService,
  required String? initialProfileName,
  required String? initialProfileImagePath,
  required ProfileSaveCallback onSave,
  String? initialBio,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _ProfileEditorContent(
        profileImageService: profileImageService,
        initialProfileName: initialProfileName,
        initialProfileImagePath: initialProfileImagePath,
        initialBio: initialBio,
        onSave: onSave,
      );
    },
  );
}

class _ProfileEditorContent extends StatefulWidget {
  final ProfileImageService profileImageService;
  final String? initialProfileName;
  final String? initialProfileImagePath;
  final String? initialBio;
  final ProfileSaveCallback onSave;

  const _ProfileEditorContent({
    required this.profileImageService,
    required this.initialProfileName,
    required this.initialProfileImagePath,
    required this.initialBio,
    required this.onSave,
  });

  @override
  State<_ProfileEditorContent> createState() => _ProfileEditorContentState();
}

class _ProfileEditorContentState extends State<_ProfileEditorContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  String? _draftImagePath;
  bool _useDefaultProfile = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialProfileName ?? '');
    _bioController = TextEditingController(text: widget.initialBio ?? '');
    _draftImagePath = widget.initialProfileImagePath;
    _useDefaultProfile = widget.initialProfileImagePath == null ||
        !File(widget.initialProfileImagePath!).existsSync();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final languageCode = Localizations.localeOf(context).languageCode;
    final bioMaxLength = languageCode == 'ko' || languageCode == 'ja' ? 20 : 40;

    final hasImage = !_useDefaultProfile &&
        _draftImagePath != null &&
        File(_draftImagePath!).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    l10n.profileEditorTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile preview
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: colors.borderLight,
                          backgroundImage: hasImage
                              ? FileImage(File(_draftImagePath!))
                              : const AssetImage(
                                  'assets/images/character.png',
                                ) as ImageProvider,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text
                              : l10n.homeGuestTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile image selection
                  _buildOptionTile(
                    icon: Icons.person,
                    imageAsset: 'assets/images/character.png',
                    iconBgColor: colors.borderLight,
                    title: l10n.profileEditorDefaultProfile,
                    subtitle: l10n.profileEditorDefaultProfileDesc,
                    selected: _useDefaultProfile,
                    onTap: () {
                      setState(() {
                        _useDefaultProfile = true;
                        _draftImagePath = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildOptionTile(
                    icon: Icons.add,
                    iconBgColor: colors.borderLight,
                    title: l10n.profileEditorPickFromAlbum,
                    subtitle: l10n.profileEditorPickFromAlbumDesc,
                    selected: !_useDefaultProfile,
                    onTap: () async {
                      final pickedPath = await widget.profileImageService
                          .pickAndSaveProfileImage();
                      if (pickedPath == null) return;
                      setState(() {
                        _useDefaultProfile = false;
                        _draftImagePath = pickedPath;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Name input
                  TextField(
                    controller: _nameController,
                    maxLength: 20,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.profileEditorNameLabel,
                      hintText: l10n.homeGuestTitle,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bio input
                  Text(
                    l10n.profileEditorBioLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLength: bioMaxLength,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: l10n.profileEditorBioHint,
                      hintStyle: TextStyle(color: colors.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.profileEditorBioFooter,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.commonSave,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    String? imageAsset,
  }) {
    final colors = context.colors;
    final accentColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accentColor : colors.border,
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: imageAsset != null
                  ? ClipOval(
                      child: Image.asset(imageAsset, fit: BoxFit.cover),
                    )
                  : Icon(icon, size: 22, color: colors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? accentColor : colors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await widget.onSave(
      name: _nameController.text,
      removeImage: _useDefaultProfile,
      pickedImagePath: _draftImagePath,
      bio: _bioController.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
