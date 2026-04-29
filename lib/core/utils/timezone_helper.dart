import 'package:flutter/foundation.dart' show debugPrint;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Helper class for timezone operations
class TimezoneHelper {
  static bool _initialized = false;

  /// Initialize timezone data
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      tz_data.initializeTimeZones();
      _initialized = true;
      debugPrint('✅ Timezone data initialized');
    } catch (e) {
      debugPrint('⚠️ Error initializing timezone data: $e');
    }
  }

  /// Get device timezone name (e.g., "Africa/Cairo", "America/New_York")
  /// Uses DateTime.now().timeZoneName on most platforms
  static Future<String> getDeviceTimezone() async {
    try {
      // Initialize timezones if not already done
      await initialize();

      // Get timezone name from DateTime
      final now = DateTime.now();
      final timeZoneName = now.timeZoneName;
      
      // On some platforms, timeZoneName might return offset (e.g., "+02:00")
      // Try to get the IANA timezone name
      String? timezone;
      
      // For Windows/Linux, timeZoneName might be offset-based
      // For mobile (Android/iOS), it usually returns IANA names
      if (timeZoneName.contains('/') || timeZoneName.contains('_')) {
        // Likely an IANA timezone name (e.g., "Africa/Cairo", "Asia/Riyadh", "America/New_York")
        timezone = timeZoneName;
        
        // Validate that the timezone exists in the timezone database
        try {
          tz.getLocation(timezone);
        } catch (e) {
          // If timezone doesn't exist, fall back to offset detection
          debugPrint('⚠️ Invalid timezone name: $timezone, falling back to offset detection');
          final offset = now.timeZoneOffset;
          timezone = _timezoneFromOffset(offset);
        }
      } else {
        // Fallback: try to detect timezone from offset
        final offset = now.timeZoneOffset;
        timezone = _timezoneFromOffset(offset);
      }

      if (timezone.isNotEmpty) {
        debugPrint('🌍 Detected user timezone: $timezone');
        return timezone;
      }
    } catch (e) {
      debugPrint('⚠️ Error getting device timezone: $e');
    }

    // Default fallback
    debugPrint('⚠️ Using default timezone: Africa/Cairo');
    return 'Africa/Cairo';
  }

  /// Convert timezone offset to approximate IANA timezone
  /// This is a fallback when timeZoneName doesn't provide IANA names
  static String _timezoneFromOffset(Duration offset) {
    final hours = offset.inHours;
    
    // Common timezones based on offset (approximate)
    switch (hours) {
      case 3:
        // UTC+3: Saudi Arabia (Asia/Riyadh), Egypt, Kenya, etc.
        // Default to Asia/Riyadh as it's more common in the region
        return 'Asia/Riyadh'; // Saudi Arabia (UTC+3, no DST)
      case 2:
        return 'Africa/Cairo'; // Egypt Standard Time (UTC+2)
      case 0:
        return 'Europe/London'; // GMT (UTC+0)
      case -5:
        return 'America/New_York'; // EST (UTC-5)
      case -6:
        return 'America/Chicago'; // CST (UTC-6)
      case -7:
        return 'America/Denver'; // MST (UTC-7)
      case -8:
        return 'America/Los_Angeles'; // PST (UTC-8)
      default:
        // Default fallback: Try Asia/Riyadh first, then Cairo
        return hours == 3 ? 'Asia/Riyadh' : 'Africa/Cairo';
    }
  }

  /// Get current time in specified timezone
  static tz.TZDateTime getCurrentTime([String? timezoneName]) {
    final location = timezoneName != null 
        ? tz.getLocation(timezoneName) 
        : tz.local;
    return tz.TZDateTime.now(location);
  }

  /// Convert DateTime to TZDateTime in specified timezone
  static tz.TZDateTime toTZDateTime(DateTime dateTime, String timezoneName) {
    final location = tz.getLocation(timezoneName);
    return tz.TZDateTime.from(dateTime, location);
  }
}

