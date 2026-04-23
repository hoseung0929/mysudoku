import 'package:mysudoku/services/profile_image_service.dart';

class ProfileStateSnapshot {
  const ProfileStateSnapshot({
    required this.name,
    required this.imagePath,
  });

  final String? name;
  final String? imagePath;
}

class ProfileStateService {
  ProfileStateService({
    ProfileImageService? profileImageService,
  }) : _profileImageService = profileImageService ?? ProfileImageService();

  final ProfileImageService _profileImageService;

  ProfileImageService get profileImageService => _profileImageService;

  Future<ProfileStateSnapshot> load() async {
    final imagePath = await _profileImageService.getProfileImagePath();
    final name = await _profileImageService.getProfileName();
    return ProfileStateSnapshot(
      name: name,
      imagePath: imagePath,
    );
  }

  Future<ProfileStateSnapshot> save({
    required String? name,
    required bool removeImage,
    required String? currentImagePath,
    String? pickedImagePath,
  }) async {
    await _profileImageService.saveProfileName(name);
    if (removeImage) {
      await _profileImageService.clearProfileImage();
    }

    final trimmedName = name?.trim() ?? '';
    return ProfileStateSnapshot(
      name: trimmedName.isEmpty ? null : trimmedName,
      imagePath: removeImage ? null : (pickedImagePath ?? currentImagePath),
    );
  }
}
