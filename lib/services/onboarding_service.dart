import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _homeOnboardingSeenKey = 'home_onboarding_seen';
  static const String _gameGuideSeenKey = 'game_guide_seen';

  Future<bool> shouldShowHomeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_homeOnboardingSeenKey) ?? false);
  }

  Future<void> markHomeOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeOnboardingSeenKey, true);
  }

  Future<bool> shouldShowGameGuide() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_gameGuideSeenKey) ?? false);
  }

  Future<void> markGameGuideSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gameGuideSeenKey, true);
  }
}
