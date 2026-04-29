import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:season_app/core/services/auth_service.dart';
import 'package:season_app/core/services/dio_client.dart';
import 'package:season_app/core/services/safety_radius_alarm_service.dart';
import 'package:season_app/core/services/background_location_service.dart';
import 'package:season_app/features/groups/providers.dart';

class AppStateService {
  /// Clear all app state including authentication, groups, and other user data
  static Future<void> clearAllAppState(WidgetRef ref) async {
    try {
      // Stop safety radius monitoring
      SafetyRadiusAlarmService().stopMonitoring();
      
      // Stop background location tracking
      await stopBackgroundLocationTracking();
      
      // Clear authentication data
      await AuthService.logout();
      
      // Clear Dio tokens
      DioHelper.instance.clearTokens();
      
      // Clear groups controller state
      ref.read(groupsControllerProvider.notifier).clearAllData();
      
      // Clear any other providers that might hold user data
      // Add more providers here as needed
      
    } catch (e) {
      print('Error clearing app state: $e');
      // Even if there's an error, try to clear what we can
      await AuthService.clearAll();
    }
  }
  
  /// Clear only authentication data (for partial logout)
  static Future<void> clearAuthData() async {
    await AuthService.logout();
    DioHelper.instance.clearTokens();
  }
}
