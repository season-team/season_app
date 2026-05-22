import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:season_app/core/services/notification_service.dart';
import 'package:season_app/core/services/app_config_service.dart';
import 'package:season_app/firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;

  /// Initialize Firebase and related services
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔥 Firebase already initialized');
      return;
    }

    try {
      debugPrint('🔥 Initializing Firebase...');

      if (kIsWeb) {
        debugPrint('⚠️ Skipping Firebase on web (not configured)');
        await AppConfigService.initialize();
        return;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _isInitialized = true;
      debugPrint('✅ Firebase initialized successfully');

      await NotificationService().initialize();
      await AppConfigService.initialize();
    } catch (e) {
      debugPrint('❌ Error initializing Firebase: $e');
      await AppConfigService.initialize();
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;
}

