import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:season_app/core/constants/api_endpoints.dart';
import 'package:season_app/core/services/native_location_service.dart';
import 'package:season_app/core/services/location_service.dart';

// Shared instance to track background location
StreamSubscription<Position>? _backgroundLocationSubscription;

// Key for storing group IDs in SharedPreferences
const String _groupIdsKey = 'tracked_group_ids';

// Helper function to start background service
Future<void> initializeBackgroundLocationService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: false, // Disable foreground mode to avoid crashes
      notificationChannelId: 'location_updates',
      initialNotificationTitle: 'Season',
      initialNotificationContent: 'Location tracking active',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(),
  );

  debugPrint('✅ Background location service initialized');
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Service runs in separate isolate - handle location updates here
  debugPrint('🚀 Background service started');
  
  // Get stored group IDs and auth token
  final prefs = await SharedPreferences.getInstance();
  
  // Safely get auth token - handle type mismatches
  String? token;
  try {
    final tokenValue = prefs.get('auth_token');
    if (tokenValue is String) {
      token = tokenValue;
    } else {
      // Try with flutter prefix
      final flutterTokenValue = prefs.get('flutter.auth_token');
      if (flutterTokenValue is String) {
        token = flutterTokenValue;
      }
    }
  } catch (e) {
    debugPrint('⚠️ Error reading auth token in background service: $e');
  }
  
  // Safely get group IDs
  List<String> storedIds = [];
  try {
    final idsValue = prefs.get(_groupIdsKey);
    if (idsValue is List) {
      storedIds = idsValue.cast<String>();
    } else {
      storedIds = prefs.getStringList(_groupIdsKey) ?? [];
    }
  } catch (e) {
    debugPrint('⚠️ Error reading group IDs in background service: $e');
    // Try alternative key
    try {
      storedIds = prefs.getStringList(_groupIdsKey) ?? [];
    } catch (e2) {
      debugPrint('⚠️ Error reading group IDs with getStringList: $e2');
    }
  }
  
  final groupIds = storedIds.map((id) => int.tryParse(id)).whereType<int>().toList();
  
  if (token == null || groupIds.isEmpty) {
    debugPrint('❌ No auth token or group IDs found in background service');
    return;
  }

  // Initialize Dio client
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      headers: {'Authorization': 'Bearer $token'},
      receiveTimeout: const Duration(seconds: 10),
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  Position? lastPosition;
  DateTime lastUpdateTime = DateTime.now();

  // Start position stream in background isolate
  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 10,
      // Removed timeLimit to prevent timeout errors - stream continues indefinitely
    ),
  ).listen(
    (Position position) {
      final now = DateTime.now();
      final timeSinceLastUpdate = now.difference(lastUpdateTime);

      if (lastPosition == null ||
          timeSinceLastUpdate.inSeconds >= 30 ||
          Geolocator.distanceBetween(
                lastPosition!.latitude,
                lastPosition!.longitude,
                position.latitude,
                position.longitude,
              ) >= 10) {
        lastPosition = position;
        lastUpdateTime = now;

        // Send location update to ALL groups
        for (final groupId in groupIds) {
          dio.post(
            ApiEndpoints.groupLocation.replaceFirst('{id}', groupId.toString()),
            data: {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
          ).then((response) {
            debugPrint('✅ [Background] Location updated for group $groupId');
          }).catchError((e) {
            debugPrint('❌ [Background] Location update failed for group $groupId: $e');
          });
        }
      }
    },
    onError: (error) {
      // Handle timeout and other location errors gracefully
      debugPrint('⚠️ [Background] Location stream error (non-critical): $error');
      // Don't stop the stream on timeout - it will continue automatically
    },
    cancelOnError: false, // Continue listening even after errors
  );

  // Handle stop service command
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

/// Fetch all user groups and store their IDs
Future<List<int>> fetchAndStoreGroupIds() async {
  debugPrint('📋 Fetching user groups...');
  
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  
  if (token == null) {
    debugPrint('❌ No auth token found');
    return [];
  }

  try {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {'Authorization': 'Bearer $token'},
        receiveTimeout: const Duration(seconds: 10),
        connectTimeout: const Duration(seconds: 10),
      ),
    );

    final response = await dio.get(ApiEndpoints.groups);
    final data = response.data['data'] as List<dynamic>?;
    
    if (data == null) {
      debugPrint('❌ No groups data in response');
      return [];
    }

    final groupIds = data
        .map((group) => group['id'] as int?)
        .whereType<int>()
        .toList();

    // Store group IDs in SharedPreferences as JSON array string for native code
    // Native code expects JSON array format: "[1,2,3]"
    if (groupIds.isNotEmpty) {
      final groupIdsJson = '[' + groupIds.join(',') + ']';
      await prefs.setString('flutter.tracked_group_ids', groupIdsJson);
      
      // Also store as comma-separated string for native code compatibility
      await prefs.setString('tracked_group_ids', groupIds.join(','));
      
      // Also store as string list for Flutter code compatibility
      await prefs.setStringList(
        _groupIdsKey,
        groupIds.map((id) => id.toString()).toList(),
      );
      
      debugPrint('✅ Fetched and stored ${groupIds.length} group IDs: $groupIds');
      debugPrint('✅ Stored JSON: $groupIdsJson');
      debugPrint('✅ Stored comma-separated: ${groupIds.join(",")}');
    } else {
      debugPrint('⚠️ No group IDs to store');
      // Clear any existing group IDs if user has no groups
      await prefs.remove('flutter.tracked_group_ids');
      await prefs.remove('tracked_group_ids');
    }
    return groupIds;
  } catch (e) {
    debugPrint('❌ Error fetching groups: $e');
    // Return stored group IDs if fetch fails
    final storedIds = prefs.getStringList(_groupIdsKey) ?? [];
    return storedIds.map((id) => int.tryParse(id)).whereType<int>().toList();
  }
}

/// Get stored group IDs from SharedPreferences
Future<List<int>> getStoredGroupIds() async {
  final prefs = await SharedPreferences.getInstance();
  final storedIds = prefs.getStringList(_groupIdsKey) ?? [];
  return storedIds.map((id) => int.tryParse(id)).whereType<int>().toList();
}

/// Start background location tracking for all user groups
Future<void> startBackgroundLocationTracking() async {
  try {
    debugPrint('📍 Starting background location tracking for all groups');
    
  // Step 1: Start native location service - it will request permissions natively
  // Native code handles all permission requests and location updates
  debugPrint('📍 Starting native location service - permissions will be requested natively');
  
  // Step 2: Get auth token
  final prefs = await SharedPreferences.getInstance();
  
  // Safely get auth token - handle case where it might be stored incorrectly
  String? token;
  try {
    final tokenValue = prefs.get('auth_token');
    if (tokenValue is String) {
      token = tokenValue;
    } else if (tokenValue is List) {
      // Handle edge case where token might be stored as List
      debugPrint('⚠️ Auth token stored as List, trying to convert...');
      token = null;
    } else {
      token = null;
    }
  } catch (e) {
    debugPrint('⚠️ Error reading auth token: $e');
    token = null;
  }
  
  // Also try with flutter prefix
  if (token == null) {
    try {
      final flutterToken = prefs.get('flutter.auth_token');
      if (flutterToken is String) {
        token = flutterToken;
      }
    } catch (e) {
      debugPrint('⚠️ Error reading flutter.auth_token: $e');
    }
  }
  
  if (token == null || token.isEmpty) {
    debugPrint('❌ No auth token found');
    return;
  }

  // Fetch and store group IDs FIRST (before starting native service)
  List<int> groupIds = [];
  try {
    groupIds = await fetchAndStoreGroupIds();
    debugPrint('✅ Fetched ${groupIds.length} group IDs');
  } catch (e, stackTrace) {
    debugPrint('❌ Error fetching group IDs: $e');
    debugPrint('Stack trace: $stackTrace');
    // Try to get stored group IDs as fallback
    try {
      final storedIds = prefs.getStringList(_groupIdsKey) ?? [];
      groupIds = storedIds.map((id) => int.tryParse(id)).whereType<int>().toList();
      debugPrint('✅ Using stored group IDs: $groupIds');
    } catch (e2) {
      debugPrint('❌ Error reading stored group IDs: $e2');
      return;
    }
  }
  
  if (groupIds.isEmpty) {
    debugPrint('⚠️ No groups found, location tracking not started');
    // Don't start service if no groups
    return;
  }
  
  // Verify group IDs were stored correctly - safely read without type casting
  String? storedJson;
  String? storedComma;
  try {
    final jsonValue = prefs.get('flutter.tracked_group_ids');
    if (jsonValue is String) {
      storedJson = jsonValue;
    } else {
      debugPrint('⚠️ flutter.tracked_group_ids is not a String, it is: ${jsonValue.runtimeType}');
    }
  } catch (e) {
    debugPrint('⚠️ Error reading flutter.tracked_group_ids: $e');
  }
  
  try {
    final commaValue = prefs.get('tracked_group_ids');
    if (commaValue is String) {
      storedComma = commaValue;
    } else {
      debugPrint('⚠️ tracked_group_ids is not a String, it is: ${commaValue.runtimeType}');
    }
  } catch (e) {
    debugPrint('⚠️ Error reading tracked_group_ids: $e');
  }
  
  debugPrint('🔍 Verification - Stored JSON: "$storedJson"');
  debugPrint('🔍 Verification - Stored comma: "$storedComma"');

  // Ensure group IDs are persisted before starting native service
  // Wait a bit to ensure SharedPreferences is flushed
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Verify again after delay - safely read without type casting
  String? verifyJson;
  String? verifyComma;
  try {
    final jsonValue = prefs.get('flutter.tracked_group_ids');
    if (jsonValue is String) {
      verifyJson = jsonValue;
    }
  } catch (e) {
    debugPrint('⚠️ Error reading flutter.tracked_group_ids for verification: $e');
  }
  
  try {
    final commaValue = prefs.get('tracked_group_ids');
    if (commaValue is String) {
      verifyComma = commaValue;
    }
  } catch (e) {
    debugPrint('⚠️ Error reading tracked_group_ids for verification: $e');
  }
  
  debugPrint('🔍 Post-delay verification - JSON: "$verifyJson"');
  debugPrint('🔍 Post-delay verification - Comma: "$verifyComma"');
  
  // Force SharedPreferences to commit
  await prefs.setBool('_location_service_ready', true);
  await prefs.remove('_location_service_ready');

  // Start native location service (Android/iOS) - sends updates every 10 seconds
  try {
    await NativeLocationService.startService();
    debugPrint('✅ Native location service started with ${groupIds.length} group IDs');
  } catch (e, stackTrace) {
    debugPrint('⚠️ Error starting native location service: $e');
    debugPrint('Stack trace: $stackTrace');
  }

  // Also start Flutter background service as fallback
  try {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      debugPrint('✅ Flutter background service started');
    }
  } catch (e) {
    debugPrint('⚠️ Error starting Flutter background service: $e');
  }

  // Cancel existing subscription if any
  await _backgroundLocationSubscription?.cancel();

  // Initialize Dio client
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      headers: {'Authorization': 'Bearer $token'},
      receiveTimeout: const Duration(seconds: 10),
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  Position? lastPosition;
  DateTime lastUpdateTime = DateTime.now();

  // Start position stream - works in both foreground and background
  // This handles location updates for ALL screens and ALL groups
  _backgroundLocationSubscription = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 10, // Update when moved 10 meters
      // Removed timeLimit to prevent timeout errors - stream continues indefinitely
    ),
  ).listen(
    (Position position) {
      final now = DateTime.now();
      final timeSinceLastUpdate = now.difference(lastUpdateTime);

      // Send update if moved significantly or 30 seconds passed
      if (lastPosition == null ||
          timeSinceLastUpdate.inSeconds >= 30 ||
          Geolocator.distanceBetween(
                lastPosition!.latitude,
                lastPosition!.longitude,
                position.latitude,
                position.longitude,
              ) >= 10) {
        lastPosition = position;
        lastUpdateTime = now;

        // Send location update to ALL groups (works on any screen, foreground or background)
        for (final groupId in groupIds) {
          dio.post(
            ApiEndpoints.groupLocation.replaceFirst('{id}', groupId.toString()),
            data: {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
          ).then((response) {
            debugPrint('✅ [Global] Location updated for group $groupId: ${position.latitude}, ${position.longitude}');
          }).catchError((e) {
            debugPrint('❌ [Global] Location update failed for group $groupId: $e');
          });
        }
      }
    },
    onError: (error) {
      // Handle timeout and other location errors gracefully
      debugPrint('⚠️ [Global] Location stream error (non-critical): $error');
      // Don't stop the stream on timeout - it will continue automatically
    },
    cancelOnError: false, // Continue listening even after errors
  );

    debugPrint('✅ Background location tracking started for ${groupIds.length} groups');
  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL ERROR in startBackgroundLocationTracking: $e');
    debugPrint('Error type: ${e.runtimeType}');
    debugPrint('Stack trace: $stackTrace');
    // Don't rethrow - just log the error so the app doesn't crash
  }
}

/// Stop background location tracking
Future<void> stopBackgroundLocationTracking() async {
  debugPrint('🛑 Stopping background location tracking');
  
  // Stop native location service
  try {
    await NativeLocationService.stopService();
    debugPrint('✅ Native location service stopped');
  } catch (e) {
    debugPrint('⚠️ Error stopping native location service: $e');
  }
  
  // Cancel location subscription
  await _backgroundLocationSubscription?.cancel();
  _backgroundLocationSubscription = null;
  
  debugPrint('✅ Background location tracking stopped');
}

/// Refresh group IDs (call when groups change)
Future<void> refreshGroupIds() async {
  debugPrint('🔄 Refreshing group IDs...');
  final groupIds = await fetchAndStoreGroupIds();
  
  // If tracking is active, restart it with new group IDs
  if (_backgroundLocationSubscription != null) {
    await stopBackgroundLocationTracking();
    await startBackgroundLocationTracking();
  }
  
  debugPrint('✅ Group IDs refreshed: $groupIds');
}

