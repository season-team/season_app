import 'package:season_app/core/services/local_storage_service.dart';

class OnboardingService {
  static const String _completedKey = 'onboarding_completed';

  /// `null` means the key was never written (app install before this feature).
  static bool? get rawCompletedFlag => LocalStorageService.getBool(_completedKey);

  static bool hasCompletedOnboarding() {
    return LocalStorageService.getBool(_completedKey) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    await LocalStorageService.saveBool(_completedKey, true);
  }
}
