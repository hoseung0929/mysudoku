import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/services/profile/profile_state_controller.dart';
import 'package:sudoku159/services/profile/profile_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String?> storedBio() async =>
      (await SharedPreferences.getInstance()).getString('profile_bio');

  group('ProfileStateService.save keeps the stored bio', () {
    setUp(() => SharedPreferences.setMockInitialValues({
          'profile_name': 'Old name',
          'profile_bio': 'Hello there',
        }));

    test('changing only the name does not touch the bio', () async {
      final snapshot = await ProfileStateService().save(
        name: 'New name',
        removeImage: false,
        currentImagePath: null,
      );
      expect(snapshot.name, 'New name');
      expect(snapshot.bio, 'Hello there');
      expect(await storedBio(), 'Hello there');
    });

    test('resetting to the default photo keeps name and bio', () async {
      final snapshot = await ProfileStateService().save(
        name: 'Old name',
        removeImage: true,
        currentImagePath: '/tmp/does-not-exist.png',
      );
      expect(snapshot.imagePath, isNull);
      expect(snapshot.bio, 'Hello there');
      expect(await storedBio(), 'Hello there');
    });

    test('picking a photo keeps the bio', () async {
      final snapshot = await ProfileStateService().save(
        name: 'Old name',
        removeImage: false,
        currentImagePath: null,
        pickedImagePath: '/tmp/new.png',
      );
      expect(snapshot.imagePath, '/tmp/new.png');
      expect(await storedBio(), 'Hello there');
    });

    test('an explicit bio value still writes or clears it (API unchanged)',
        () async {
      final service = ProfileStateService();
      await service.save(
        name: 'n',
        removeImage: false,
        currentImagePath: null,
        bio: 'Changed',
      );
      expect(await storedBio(), 'Changed');
      final cleared = await service.save(
        name: 'n',
        removeImage: false,
        currentImagePath: null,
        bio: '',
      );
      expect(cleared.bio, isNull);
      expect(await storedBio(), isNull);
    });
  });

  test('no stored bio: saving name/photo does not create one', () async {
    SharedPreferences.setMockInitialValues({});
    final snapshot = await ProfileStateService().save(
      name: 'Solo',
      removeImage: false,
      currentImagePath: null,
    );
    expect(snapshot.bio, isNull);
    expect(await storedBio(), isNull);
    expect(
      (await SharedPreferences.getInstance()).containsKey('profile_bio'),
      isFalse,
    );
  });

  test('controller: saving name only keeps the bio in state and storage',
      () async {
    SharedPreferences.setMockInitialValues({
      'profile_name': 'A',
      'profile_bio': 'Kept intro',
    });
    final controller = ProfileStateController.instance;
    await controller.refresh();
    expect(controller.bio, 'Kept intro');

    await controller.save(name: 'B', removeImage: false);
    expect(controller.name, 'B');
    expect(controller.bio, 'Kept intro');
    expect(await storedBio(), 'Kept intro');
  });
}
