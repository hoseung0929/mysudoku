import 'package:sudoku159/services/profile/profile_image_service.dart';

class ProfileStateSnapshot {
  const ProfileStateSnapshot({
    required this.name,
    required this.imagePath,
    this.bio,
  });

  final String? name;
  final String? imagePath;
  final String? bio;
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
    final bio = await _profileImageService.getProfileBio();
    return ProfileStateSnapshot(
      name: name,
      imagePath: imagePath,
      bio: bio,
    );
  }

  Future<ProfileStateSnapshot> save({
    required String? name,
    required bool removeImage,
    required String? currentImagePath,
    String? pickedImagePath,
    String? bio,
  }) async {
    await _profileImageService.saveProfileName(name);
    await _profileImageService.saveProfileBio(bio);
    if (removeImage) {
      await _profileImageService.clearProfileImage();
    }

    final trimmedName = name?.trim() ?? '';
    final trimmedBio = bio?.trim() ?? '';
    return ProfileStateSnapshot(
      name: trimmedName.isEmpty ? null : trimmedName,
      imagePath: removeImage ? null : (pickedImagePath ?? currentImagePath),
      bio: trimmedBio.isEmpty ? null : trimmedBio,
    );
  }
}
