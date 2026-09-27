import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku159/services/onboarding/beginner_tutorial_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to unseen when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final service = BeginnerTutorialService();
    expect(await service.getState(), BeginnerTutorialState.unseen);
  });

  test('markCompleted persists across a fresh service instance', () async {
    SharedPreferences.setMockInitialValues({});
    await BeginnerTutorialService().markCompleted();
    expect(
      await BeginnerTutorialService().getState(),
      BeginnerTutorialState.completed,
    );
  });

  test('markDismissed persists across a fresh service instance', () async {
    SharedPreferences.setMockInitialValues({});
    await BeginnerTutorialService().markDismissed();
    expect(
      await BeginnerTutorialService().getState(),
      BeginnerTutorialState.dismissed,
    );
  });

  test('an unrecognized stored value falls back to unseen', () async {
    SharedPreferences.setMockInitialValues({
      BeginnerTutorialService.stateKey: 'garbage',
    });
    expect(
      await BeginnerTutorialService().getState(),
      BeginnerTutorialState.unseen,
    );
  });
}
