import 'package:flutter/foundation.dart';
import 'package:sudoku159/services/profile/profile_image_service.dart';
import 'package:sudoku159/services/profile/profile_state_service.dart';

/// 프로필 이름/자기소개/이미지를 앱 전역에서 공유하는 단일 소스.
/// 여러 화면이 각자 로컬 상태를 들고 있으면 한쪽에서 수정해도 다른 화면에
/// 반영되지 않는 문제가 있어, 이 컨트롤러 하나를 모든 화면이 구독합니다.
class ProfileStateController extends ChangeNotifier {
  ProfileStateController._internal();

  static final ProfileStateController instance =
      ProfileStateController._internal();

  final ProfileStateService _service = ProfileStateService();

  String? name;
  String? imagePath;
  String? bio;
  bool _loaded = false;

  ProfileImageService get profileImageService => _service.profileImageService;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await refresh();
  }

  Future<void> refresh() async {
    final snapshot = await _service.load();
    name = snapshot.name;
    imagePath = snapshot.imagePath;
    bio = snapshot.bio;
    _loaded = true;
    notifyListeners();
  }

  Future<void> save({
    required String? name,
    required bool removeImage,
    String? pickedImagePath,
    String? bio,
  }) async {
    final snapshot = await _service.save(
      name: name,
      removeImage: removeImage,
      currentImagePath: imagePath,
      pickedImagePath: pickedImagePath,
      bio: bio,
    );
    this.name = snapshot.name;
    imagePath = snapshot.imagePath;
    this.bio = snapshot.bio;
    _loaded = true;
    notifyListeners();
  }
}
