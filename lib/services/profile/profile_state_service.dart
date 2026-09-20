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

  /// 이름·사진을 저장한다.
  ///
  /// [bio]가 null이면 저장된 자기소개는 **건드리지 않고 그대로 유지**한다
  /// (편집 화면이 더 이상 소개를 다루지 않으므로 이름·사진만 바꿔도 지워지면
  /// 안 된다). 소개를 실제로 바꾸거나 지우려면 빈 문자열을 포함한 값을
  /// 명시적으로 넘긴다.
  Future<ProfileStateSnapshot> save({
    required String? name,
    required bool removeImage,
    required String? currentImagePath,
    String? pickedImagePath,
    String? bio,
  }) async {
    await _profileImageService.saveProfileName(name);
    if (bio != null) {
      await _profileImageService.saveProfileBio(bio);
    }
    if (removeImage) {
      await _profileImageService.clearProfileImage();
    }

    final trimmedName = name?.trim() ?? '';
    final savedBio = bio == null
        ? await _profileImageService.getProfileBio()
        : (bio.trim().isEmpty ? null : bio.trim());
    return ProfileStateSnapshot(
      name: trimmedName.isEmpty ? null : trimmedName,
      imagePath: removeImage ? null : (pickedImagePath ?? currentImagePath),
      bio: savedBio,
    );
  }
}
