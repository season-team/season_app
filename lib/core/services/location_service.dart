import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  /// Request location permissions including background location (all the time)
  /// This will request both "while in use" and "all the time" permissions
  static Future<bool> requestPermissions() async {
    debugPrint('📍 Requesting location permissions...');
    
    // Step 1: Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('📍 Current permission status: $permission');
    
    // Step 2: Request basic location permission first (while in use)
    if (permission == LocationPermission.denied) {
      debugPrint('📍 Requesting basic location permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('📍 Permission after request: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permission denied');
        return false;
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission permanently denied - opening settings');
        await openAppSettings();
        return false;
      }
    }
    
    // Step 3: Request background location permission (all the time) for Android 10+
    // This is required for location updates when app is terminated
    if (permission == LocationPermission.whileInUse) {
      debugPrint('📍 Requesting background location permission (all the time)...');
      
      try {
        // Use permission_handler to request background location
        // Check if Permission.locationAlways is available first
        final locationAlwaysPermission = Permission.locationAlways;
        final backgroundStatus = await locationAlwaysPermission.request();
        debugPrint('📍 Background location permission status: $backgroundStatus');
        
        if (backgroundStatus.isGranted) {
          debugPrint('✅ Background location permission granted (all the time)');
          return true;
        } else if (backgroundStatus.isPermanentlyDenied) {
          debugPrint('❌ Background location permission permanently denied - opening settings');
          await openAppSettings();
          return false;
        } else {
          debugPrint('⚠️ Background location permission denied, but basic permission granted');
          // Still return true if basic permission is granted (works in foreground/background)
          return true;
        }
      } catch (e, stackTrace) {
        debugPrint('⚠️ Error requesting background location permission: $e');
        debugPrint('Stack trace: $stackTrace');
        // If Permission.locationAlways is not available or fails, still return true
        // Basic permission is granted, which works for foreground and background (not terminated)
        return true;
      }
    }
    
    // Step 4: Check if we have "always" permission
    if (permission == LocationPermission.always) {
      debugPrint('✅ Location permission already granted (all the time)');
      return true;
    }
    
    debugPrint('✅ Location permission granted');
    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static Stream<Position> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update when moved 10 meters
      // Removed timeLimit to prevent timeout errors - stream will continue indefinitely
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  static Future<double> getDistanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) async {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}

