import 'package:dio/dio.dart';

class CountryDetectionService {
  static String? _cachedCountryCode;
  
  /// Get country code from IP address
  /// Returns 3-letter country code (e.g., "EGY", "SAU")
  static Future<String?> getCountryCodeFromIP() async {
    // Return cached value if available
    if (_cachedCountryCode != null) {
      print('📍 Using cached country code: $_cachedCountryCode');
      return _cachedCountryCode;
    }

    print('🌍 Starting country detection...');

    // Try multiple APIs with better error handling
    final apis = [
      _tryIpInfo, // Try ipinfo.io first (more reliable, better rate limits)
      _tryCountryIs, // Simple country detection API
      _tryIpWhoIs, // Alternative geolocation API
      _tryIpApiCom, // Try ip-api.com
      _tryIpApiCo,
      _tryIpify,
    ];

    for (final api in apis) {
      try {
        final code = await api();
        if (code != null) {
          _cachedCountryCode = code;
          print('✅ Country detection successful: $code');
          return code;
        }
      } catch (e) {
        print('⚠️ API failed: $e');
        // Silently continue to next API
        continue;
      }
    }

    // Default fallback
    print('⚠️ All APIs failed, using default: SAU');
    return 'SAU'; // Default to Saudi Arabia
  }

  /// Try ipinfo.io API (better rate limits)
  static Future<String?> _tryIpInfo() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://ipinfo.io/json',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final countryCode = response.data['country'] as String?;
        if (countryCode != null && countryCode.length == 2) {
          final code = _mapCountryCodeTo3Letter(countryCode);
          print('✅ Country detected from ipinfo.io: $code');
          return code;
        }
      } else {
        print('⚠️ ipinfo.io returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error with ipinfo.io: $e');
    }
    return null;
  }

  /// Try country.is API (simple and fast)
  static Future<String?> _tryCountryIs() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.country.is',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final countryCode = response.data['country'] as String?;
        if (countryCode != null && countryCode.length == 2) {
          final code = _mapCountryCodeTo3Letter(countryCode);
          print('✅ Country detected from country.is: $code');
          return code;
        }
      } else {
        print('⚠️ country.is returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error with country.is: $e');
    }
    return null;
  }

  /// Try ipwho.is API
  static Future<String?> _tryIpWhoIs() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://ipwho.is/',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final countryCode = response.data['country_code'] as String?;
        if (countryCode != null && countryCode.length == 2) {
          final code = _mapCountryCodeTo3Letter(countryCode);
          print('✅ Country detected from ipwho.is: $code');
          return code;
        }
      } else {
        print('⚠️ ipwho.is returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error with ipwho.is: $e');
    }
    return null;
  }

  /// Try ipapi.co API
  static Future<String?> _tryIpApiCo() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://ipapi.co/json/',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500, // Don't throw on 4xx
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final countryCode = response.data['country_code'] as String?;
        if (countryCode != null && countryCode.length == 2) {
          final code = _mapCountryCodeTo3Letter(countryCode);
          print('✅ Country detected from ipapi.co: $code');
          return code;
        }
      } else {
        print('⚠️ ipapi.co returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error with ipapi.co: $e');
    }
    return null;
  }

  /// Try ipinfo.io API (better rate limits)
  static Future<String?> _tryIpInfo2() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://ipinfo.io/json',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final countryCode = response.data['country'] as String?;
        if (countryCode != null && countryCode.length == 2) {
          final code = _mapCountryCodeTo3Letter(countryCode);
          print('✅ Country detected from ipinfo.io: $code');
          return code;
        }
      } else {
        print('⚠️ ipinfo.io returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error with ipinfo.io: $e');
    }
    return null;
  }

  /// Try country.is API (simple and fast)
  static Future<String?> _tryCountryIs2() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.country.is',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final countryCode = response.data['country'] as String?;
        if (countryCode != null && countryCode.length == 2) {
          final code = _mapCountryCodeTo3Letter(countryCode);
          print('✅ Country detected from country.is: $code');
          return code;
        }
      } else {
        print('⚠️ country.is returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error with country.is: $e');
    }
    return null;
  }

  /// Try ipwho.is API
  static Future<String?> _tryIpWhoIs2() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://ipwho.is/',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final countryCode = response.data['country_code'] as String?;
        if (countryCode != null && countryCode.length == 2) {
          final code = _mapCountryCodeTo3Letter(countryCode);
          print('✅ Country detected from ipwho.is: $code');
          return code;
        }
      } else {
        print('⚠️ ipwho.is returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error with ipwho.is: $e');
    }
    return null;
  }

  /// Try ip-api.com API
  static Future<String?> _tryIpApiCom() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://ip-api.com/json/',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500, // Don't throw on 4xx
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final countryCode = response.data['countryCode'] as String?;
        if (countryCode != null && countryCode.length == 2) {
          final code = _mapCountryCodeTo3Letter(countryCode);
          print('✅ Country detected from ip-api.com: $code');
          return code;
        }
      } else {
        print('⚠️ ip-api.com returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error with ip-api.com: $e');
    }
    return null;
  }

  /// Try ipify API (simpler, more reliable)
  static Future<String?> _tryIpify() async {
    try {
      final dio = Dio();
      // First get IP
      final ipResponse = await dio.get(
        'https://api.ipify.org?format=json',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (ipResponse.statusCode == 200 && ipResponse.data != null) {
        final ip = ipResponse.data['ip'] as String?;
        if (ip != null) {
          // Then get location from ip-api.com using the IP
          final locationResponse = await dio.get(
            'https://ip-api.com/json/$ip',
            options: Options(
              receiveTimeout: const Duration(seconds: 5),
              sendTimeout: const Duration(seconds: 5),
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (locationResponse.statusCode == 200 && locationResponse.data != null) {
            final countryCode = locationResponse.data['countryCode'] as String?;
            if (countryCode != null && countryCode.length == 2) {
              final code = _mapCountryCodeTo3Letter(countryCode);
              print('✅ Country detected from ipify+ip-api: $code');
              return code;
            }
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  /// Map 2-letter country code to 3-letter code
  static String _mapCountryCodeTo3Letter(String code2) {
    const mapping = {
      'SA': 'SAU', // Saudi Arabia
      'EG': 'EGY', // Egypt
      'AE': 'ARE', // UAE
      'KW': 'KWT', // Kuwait
      'QA': 'QAT', // Qatar
      'BH': 'BHR', // Bahrain
      'OM': 'OMN', // Oman
      'JO': 'JOR', // Jordan
      'LB': 'LBN', // Lebanon
      'IQ': 'IRQ', // Iraq
      'YE': 'YEM', // Yemen
      'SY': 'SYR', // Syria
      'US': 'USA', // United States
      'GB': 'GBR', // United Kingdom
      'FR': 'FRA', // France
      'DE': 'DEU', // Germany
      'IT': 'ITA', // Italy
      'ES': 'ESP', // Spain
      'TR': 'TUR', // Turkey
      'IN': 'IND', // India
      'CN': 'CHN', // China
      'JP': 'JPN', // Japan
      'KR': 'KOR', // South Korea
    };
    return mapping[code2.toUpperCase()] ?? code2.toUpperCase();
  }

  /// Clear cached country code
  static void clearCache() {
    _cachedCountryCode = null;
  }

  /// Get cached country code
  static String? get cachedCountryCode => _cachedCountryCode;
}
