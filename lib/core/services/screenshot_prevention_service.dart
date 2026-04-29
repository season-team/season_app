import 'package:screen_protector/screen_protector.dart';

class ScreenshotPreventionService {
  /// Enable screenshot prevention and protect data leakage
  static Future<void> enableScreenshotPrevention() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn(); // Blurs recent apps preview
    } catch (e) {
      // Handle error silently - screenshot prevention may not be supported on all platforms
      print('Error enabling screenshot prevention: $e');
    }
  }

  /// Disable screenshot prevention
  static Future<void> disableScreenshotPrevention() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    } catch (e) {
      // Handle error silently
      print('Error disabling screenshot prevention: $e');
    }
  }
}
