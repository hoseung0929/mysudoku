import 'package:flutter_test/flutter_test.dart';
import 'package:mysudoku/services/onboarding_service.dart';
import 'package:mysudoku/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogger.setMuted(true);

  group('OnboardingService', () {
    late OnboardingService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = OnboardingService();
    });

    test('shows home onboarding only once', () async {
      expect(await service.shouldShowHomeOnboarding(), isTrue);

      await service.markHomeOnboardingSeen();

      expect(await service.shouldShowHomeOnboarding(), isFalse);
    });

    test('shows game guide only once', () async {
      expect(await service.shouldShowGameGuide(), isTrue);

      await service.markGameGuideSeen();

      expect(await service.shouldShowGameGuide(), isFalse);
    });
  });
}
