import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// Native location service for Android and iOS
/// Sends location updates every 10 seconds to API for all groups
/// Works even when app is closed or terminated
class NativeLocationService {
  static const MethodChannel _channel = MethodChannel('season_app/location_service');

  /// Start native location service
  /// This will run in native code and send location updates every 10 seconds
  static Future<void> startService() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod('startLocationService');
        debugPrint('✅ Native location service started: $result');
      } else {
        debugPrint('⚠️ Native location service not supported on this platform');
      }
    } on PlatformException catch (e) {
      debugPrint('❌ Platform error starting native location service: ${e.message}');
      debugPrint('   Code: ${e.code}, Details: ${e.details}');
    } catch (e) {
      debugPrint('❌ Error starting native location service: $e');
    }
  }

  /// Stop native location service
  static Future<void> stopService() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await _channel.invokeMethod('stopLocationService');
        debugPrint('🛑 Native location service stopped: $result');
      }
    } on PlatformException catch (e) {
      debugPrint('❌ Platform error stopping native location service: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error stopping native location service: $e');
    }
  }
}

