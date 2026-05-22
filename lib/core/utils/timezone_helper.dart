import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:season_app/core/services/country_detection_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Device IANA timezone (e.g. Africa/Cairo, Asia/Riyadh) for reminders & API payloads.
class TimezoneHelper {
  TimezoneHelper._();

  static bool _initialized = false;
  static String? _cachedDeviceTimezone;

  /// Maps app country codes (from IP detection) to IANA time zones.
  static const Map<String, String> countryCodeToTimezone = {
    'EGY': 'Africa/Cairo',
    'SAU': 'Asia/Riyadh',
    'ARE': 'Asia/Dubai',
    'KWT': 'Asia/Kuwait',
    'QAT': 'Asia/Qatar',
    'BHR': 'Asia/Bahrain',
    'OMN': 'Asia/Muscat',
    'JOR': 'Asia/Amman',
    'LBN': 'Asia/Beirut',
    'IRQ': 'Asia/Baghdad',
    'YEM': 'Asia/Aden',
    'SYR': 'Asia/Damascus',
    'TUR': 'Europe/Istanbul',
    'USA': 'America/New_York',
    'GBR': 'Europe/London',
    'FRA': 'Europe/Paris',
    'DEU': 'Europe/Berlin',
  };

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();
      _initialized = true;
      debugPrint('✅ Timezone data initialized');
      await warmCache();
    } catch (e) {
      debugPrint('⚠️ Error initializing timezone data: $e');
    }
  }

  /// Preload device timezone (call from main after [initialize]).
  static Future<void> warmCache() async {
    _cachedDeviceTimezone = await _resolveDeviceTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(_cachedDeviceTimezone!));
      debugPrint('🌍 Local TZ set to $_cachedDeviceTimezone');
    } catch (e) {
      debugPrint('⚠️ Could not set tz.local: $e');
    }
  }

  /// Returns IANA timezone for the device / region (cached after first call).
  static Future<String> getDeviceTimezone() async {
    await initialize();
    return _cachedDeviceTimezone ??= await _resolveDeviceTimezone();
  }

  static Future<String> _resolveDeviceTimezone() async {
    // 1) OS timezone (Android ZoneId, iOS NSTimeZone) — most accurate
    if (!kIsWeb) {
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        final normalized = _normalizeAndValidate(info.identifier);
        if (normalized != null) {
          debugPrint('🌍 Timezone from device: $normalized');
          return normalized;
        }
      } catch (e) {
        debugPrint('⚠️ FlutterTimezone failed: $e');
      }
    }

    // 2) Country from IP → regional timezone (Cairo vs Riyadh, etc.)
    try {
      final country = await CountryDetectionService.getCountryCodeFromIP();
      final fromCountry = country != null ? countryCodeToTimezone[country] : null;
      if (fromCountry != null && _isValidTimezone(fromCountry)) {
        debugPrint('🌍 Timezone from country $country: $fromCountry');
        return fromCountry;
      }
    } catch (e) {
      debugPrint('⚠️ Country timezone fallback failed: $e');
    }

    // 3) Dart DateTime name when it is already IANA
    final now = DateTime.now();
    final name = now.timeZoneName;
    if (name.contains('/')) {
      final normalized = _normalizeAndValidate(name);
      if (normalized != null) {
        debugPrint('🌍 Timezone from DateTime.timeZoneName: $normalized');
        return normalized;
      }
    }

    // 4) Offset + country (never force Riyadh for all UTC+3)
    final offsetHours = now.timeZoneOffset.inHours;
    final country = await CountryDetectionService.getCountryCodeFromIP();
    final fromOffset = _timezoneFromOffsetAndCountry(offsetHours, country);
    debugPrint('🌍 Timezone from offset ($offsetHours) + country ($country): $fromOffset');
    return fromOffset;
  }

  static String? _normalizeAndValidate(String raw) {
    final normalized = _normalizeIdentifier(raw.trim());
    return _isValidTimezone(normalized) ? normalized : null;
  }

  static bool _isValidTimezone(String id) {
    try {
      tz.getLocation(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _normalizeIdentifier(String id) {
    const aliases = <String, String>{
      'Europe/Kiev': 'Europe/Kyiv',
      'Etc/UTC': 'UTC',
      'Etc/GMT': 'UTC',
    };
    if (aliases.containsKey(id)) return aliases[id]!;
    return id;
  }

  static String _timezoneFromOffsetAndCountry(int hours, String? countryCode) {
    if (countryCode != null) {
      final mapped = countryCodeToTimezone[countryCode];
      if (mapped != null) return mapped;
    }

    switch (hours) {
      case 3:
        return 'Asia/Riyadh';
      case 2:
        return 'Africa/Cairo';
      case 0:
        return 'Europe/London';
      case -5:
        return 'America/New_York';
      case -8:
        return 'America/Los_Angeles';
      default:
        return 'Africa/Cairo';
    }
  }

  static tz.TZDateTime getCurrentTime([String? timezoneName]) {
    final location = timezoneName != null
        ? tz.getLocation(timezoneName)
        : tz.local;
    return tz.TZDateTime.now(location);
  }

  static tz.TZDateTime toTZDateTime(DateTime dateTime, String timezoneName) {
    final location = tz.getLocation(timezoneName);
    return tz.TZDateTime.from(dateTime, location);
  }
}
